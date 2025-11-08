import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:geolocator/geolocator.dart';


enum ConsentStatus {
  personalized,
  nonPersonalized,
}

class AdsManager {
  final List<int> noteIds;
  final String nativeAdId;
  final String bannerAdId;
  final String interstitialAdId;

  final ValueNotifier<int> loadedAdsCount = ValueNotifier(0);
  final Map<int, NativeAd> _nativeAds = {};
  final Map<int, BannerAd> _bannerAds = {};
  final Map<int, ValueNotifier<bool>> _nativeReady = {};
  final Map<int, ValueNotifier<bool>> _bannerReady = {};
  final Map<int, String> _loadedAdPositions = {};
  final Map<int, int> _nativeRetry = {};
  final Map<int, int> _bannerRetry = {};
  InterstitialAd? _interstitialAd;

  final Random _random = Random();
  final int _maxRetries = 50;
  final Map<int, Timer> _retryTimers = {};
  bool _isDisposed = false;
  Map<int, String> get adPositions => _loadedAdPositions;
  bool isAdShowing = false;
  final ColorScheme? colorScheme;

  ConsentStatus consentStatus = ConsentStatus.personalized;

  static const Set<String> _eeaCountryCodes = {
    'AT','BE','BG','HR','CY','CZ','DK','EE','FI','FR','DE',
    'GR','HU','IS','IE','IT','LV','LI','LT','LU','MT','NL',
    'NO','PL','PT','RO','SK','SI','ES','SE'
  };


  AdsManager({
    required this.noteIds,
    required this.nativeAdId,
    required this.bannerAdId,
    required this.interstitialAdId,
    this.colorScheme,
  });

  /// Initialize Mobile Ads SDK & setup consent
  Future<void> initialize() async {
    if (_isDisposed) return;
    await MobileAds.instance.initialize();
    await _requestUserConsent();
    _loadInterstitial();
    _setupAds();
  }
  AdRequest _adRequest() {
    return AdRequest(
      nonPersonalizedAds: consentStatus == ConsentStatus.nonPersonalized,
    );
  }


  Future<void> _requestUserConsent() async {
    try {
      final requestConfiguration = RequestConfiguration(
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        maxAdContentRating: MaxAdContentRating.g,
      );

      await MobileAds.instance.updateRequestConfiguration(requestConfiguration);

      bool isEEAUser = await _detectEEAUser();
      consentStatus = isEEAUser
          ? ConsentStatus.nonPersonalized
          : ConsentStatus.personalized;
    } catch (e) {
      consentStatus = ConsentStatus.personalized;
    }
  }


  Future<bool> _detectEEAUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      double latitude = position.latitude;
      double longitude = position.longitude;

      return await _isLocationInEEA(latitude, longitude);
    } catch (e) {
      return false;
    }
  }


  Future<bool> _isLocationInEEA(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isEmpty) return false;

      String? countryCode = placemarks.first.isoCountryCode;
      if (countryCode == null) return false;

      return _eeaCountryCodes.contains(countryCode.toUpperCase());
    } catch (e) {
      return false;
    }
  }






  void _setupAds() {
    final totalItems = noteIds.length;
    final nativeCount = AdsCount.nativeAdCount(totalItems);
    final bannerCount = AdsCount.bannerAdCount(totalItems);
    final occupiedPositions = <int>{};

    // Load native ads first
    for (int i = 0; i < nativeCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      loadNativeAd(index);
    }

    // Load banner ads
    for (int i = 0; i < bannerCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      loadBannerAd(index);
    }
  }

  void loadNativeAd(int index) {
    if (_isDisposed ||
        (_nativeAds.containsKey(index) && _nativeReady[index]?.value == true)) {
      return;
    }

    _nativeAds[index]?.dispose();
    _nativeReady[index] ??= ValueNotifier(false);
    _nativeRetry[index] = (_nativeRetry[index] ?? 0) + 1;

    final ad = NativeAd(
      adUnitId: nativeAdId,
      factoryId: 'listTile',
      request: _adRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (_isDisposed) return;
          _nativeAds[index] = ad as NativeAd;
          _nativeReady[index]?.value = true;
          _nativeRetry[index] = 0;
          _loadedAdPositions[index] = 'native';
          loadedAdsCount.value++;
          debugPrint("Native Ad Loaded at index $index");
        },
        onAdFailedToLoad: (ad, error) {
          if (_isDisposed) return;
          ad.dispose();
          _nativeAds.remove(index);
          _nativeReady[index]?.value = false;
          loadedAdsCount.value = max(0, loadedAdsCount.value - 1);
          debugPrint("Native Ad Failed at index $index: $error");

          _scheduleRetry(index, isNative: true);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: colorScheme?.surface ?? Colors.white,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme?.primary ?? Colors.blue,
          backgroundColor: colorScheme?.secondary ?? Colors.grey,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme?.onSurface ?? Colors.black,
          style: NativeTemplateFontStyle.italic,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme?.secondary ?? Colors.grey,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme?.tertiary ?? Colors.green,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
      ),
    );

    ad.load();
  }

  void loadBannerAd(int index) {
    if (_isDisposed ||
        (_bannerAds.containsKey(index) && _bannerReady[index]?.value == true)) {
      return;
    }

    _bannerAds[index]?.dispose();
    _bannerReady[index] ??= ValueNotifier(false);
    _bannerRetry[index] = (_bannerRetry[index] ?? 0) + 1;

    final ad = BannerAd(
      adUnitId: bannerAdId,
      size: AdSize.banner,
      request: _adRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (_isDisposed) return;
          _bannerAds[index] = ad as BannerAd;
          _bannerReady[index]?.value = true;
          _bannerRetry[index] = 0;
          _loadedAdPositions[index] = 'banner';
          loadedAdsCount.value++;
          debugPrint("Banner Ad Loaded at index $index");
        },
        onAdFailedToLoad: (ad, error) {
          if (_isDisposed) return;
          ad.dispose();
          _bannerAds.remove(index);
          _bannerReady[index]?.value = false;
          loadedAdsCount.value = max(0, loadedAdsCount.value - 1);
          debugPrint("Banner Ad Failed at index $index: $error");

          _scheduleRetry(index, isNative: false);
        },
      ),
    );

    ad.load();
  }

  void _scheduleRetry(int index, {required bool isNative, bool resetRetry = false}) {
    if (_isDisposed) return;

    if (resetRetry) {
      if (isNative) _nativeRetry[index] = 0;
      else _bannerRetry[index] = 0;
    }

    final attempt = isNative ? (_nativeRetry[index] ?? 1) : (_bannerRetry[index] ?? 1);
    if (attempt >= _maxRetries) return;

    final targetCount = isNative
        ? AdsCount.nativeAdCount(noteIds.length)
        : AdsCount.bannerAdCount(noteIds.length);
    final currentCount = isNative ? _nativeAds.length : _bannerAds.length;
    if (currentCount >= targetCount) return;

    final delay = _retryDelay(attempt);

    _retryTimers[index]?.cancel();
    _retryTimers[index] = Timer(delay, () {
      if (isNative) {
        _nativeRetry[index] = attempt + 1;
        loadNativeAd(index);
      } else {
        _bannerRetry[index] = attempt + 1;
        loadBannerAd(index);
      }
    });
  }

  Duration _retryDelay(int attempt) =>
      Duration(seconds: min(10 * pow(2, attempt - 1).toInt(), 120));

  void _loadInterstitial() {
    if (_isDisposed) return;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: _adRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) => isAdShowing = true,
            onAdDismissedFullScreenContent: (ad) {
              isAdShowing = false;
              ad.dispose();
              _loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              isAdShowing = false;
              ad.dispose();
              _loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (_) {
          _interstitialAd = null;
          if (!_isDisposed) Future.delayed(const Duration(seconds: 5), _loadInterstitial);
        },
      ),
    );
  }

  void showInterstitial() {
    if (_interstitialAd != null && !_isDisposed) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  Widget getAdWidget(int index) {
    final type = _loadedAdPositions[index];
    if (type == 'native') {
      final ad = _nativeAds[index];
      if (ad != null && _nativeReady[index]?.value == true) {
        final useSmallTemplate = index % 2 == 0;
        final constraints = useSmallTemplate
            ? const BoxConstraints(minWidth: 320, minHeight: 90, maxWidth: 400, maxHeight: 200)
            : const BoxConstraints(minWidth: 320, minHeight: 320, maxWidth: 400, maxHeight: 350);
        return ConstrainedBox(
          constraints: constraints,
          child: AdWidget(ad: ad),
        );
      }
    } else if (type == 'banner') {
      final ad = _bannerAds[index];
      if (ad != null && _bannerReady[index]?.value == true) {
        return SizedBox(
          width: double.infinity,
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        );
      }
    }
    return const SizedBox.shrink();
  }

  int countAdsBefore(int noteIndex) {
    int count = 0;
    _loadedAdPositions.keys.forEach((adIndex) {
      if (adIndex < noteIndex) count++;
    });
    return count;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _retryTimers.values.forEach((t) => t.cancel());
    _retryTimers.clear();
    _nativeAds.values.forEach((ad) => ad.dispose());
    _nativeAds.clear();
    _bannerAds.values.forEach((ad) => ad.dispose());
    _bannerAds.clear();
    _interstitialAd?.dispose();
    _interstitialAd = null;

    _nativeReady.clear();
    _bannerReady.clear();
    _loadedAdPositions.clear();
    _nativeRetry.clear();
    _bannerRetry.clear();
  }

  int _findAvailableIndex(Set<int> occupied, int totalItems) {
    if (occupied.length >= totalItems) return -1;

    int tries = 0;
    while (tries < 100) {
      int index = _random.nextInt(totalItems);
      if (!occupied.contains(index)) return index;
      tries++;
    }

    for (int i = 0; i < totalItems; i++) {
      if (!occupied.contains(i)) return i;
    }
    return -1;
  }

  void refreshAds() {
    if (_isDisposed) return;

    _nativeAds.forEach((_, ad) => ad.dispose());
    _nativeAds.clear();
    _nativeReady.forEach((_, notifier) => notifier.value = false);
    _nativeRetry.clear();

    _bannerAds.forEach((_, ad) => ad.dispose());
    _bannerAds.clear();
    _bannerReady.forEach((_, notifier) => notifier.value = false);
    _bannerRetry.clear();

    _loadedAdPositions.clear();
    loadedAdsCount.value = 0;

    final totalItems = noteIds.length;
    final nativeCount = AdsCount.nativeAdCount(totalItems);
    final bannerCount = AdsCount.bannerAdCount(totalItems);
    final occupiedPositions = <int>{};

    for (int i = 0; i < nativeCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      _scheduleRetry(index, isNative: true, resetRetry: true);
    }

    for (int i = 0; i < bannerCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      _scheduleRetry(index, isNative: false, resetRetry: true);
    }
  }
}

class AdsCount {
  static int nativeAdCount(int totalItems) {
    if (totalItems <= 10) return 0;
    if (totalItems <= 20) return 1;
    if (totalItems <= 40) return 2;
    if (totalItems <= 80) return 4;
    if (totalItems <= 160) return 8;
    return (totalItems / 15).ceil();
  }

  static int bannerAdCount(int totalItems) {
    if (totalItems <= 10) return 2;
    if (totalItems <= 20) return 3;
    if (totalItems <= 40) return 6;
    if (totalItems <= 80) return 12;
    if (totalItems <= 160) return 24;
    return (totalItems / 5).ceil();
  }
}
