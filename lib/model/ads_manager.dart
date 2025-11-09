import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum ConsentStatus { personalized, nonPersonalized }

class AdsManager {
  final List<int> noteIds;
  final String nativeAdId;
  final String bannerAdId;
  final String interstitialAdId;
  final ColorScheme? colorScheme;

  final ValueNotifier<int> loadedAdsCount = ValueNotifier(0);
  final Map<int, NativeAd> _nativeAds = {};
  final Map<int, BannerAd> _bannerAds = {};
  final Map<int, ValueNotifier<bool>> _nativeReady = {};
  final Map<int, ValueNotifier<bool>> _bannerReady = {};
  final Map<int, String> _loadedAdPositions = {};
  final Map<int, int> _nativeRetry = {};
  final Map<int, int> _bannerRetry = {};
  final Map<int, Timer> _retryTimers = {};

  InterstitialAd? _interstitialAd;
  bool _isDisposed = false;
  bool isAdShowing = false;

  ConsentStatus consentStatus = ConsentStatus.personalized;
  Map<int, String> get adPositions => _loadedAdPositions;

  final Random _random = Random();
  final int _maxRetries = 50;

  AdsManager({
    required this.noteIds,
    required this.nativeAdId,
    required this.bannerAdId,
    required this.interstitialAdId,
    this.colorScheme,
  });

  /// Initialize Mobile Ads SDK and setup ads
  Future<void> initialize() async {
    if (_isDisposed) return;
    await MobileAds.instance.initialize();
    _loadInterstitial();
    _setupAds();
  }

  AdRequest _adRequest() {
    return AdRequest(
      nonPersonalizedAds: consentStatus == ConsentStatus.nonPersonalized,
    );
  }

  /// Determine ad positions and load initial ads
  void _setupAds() {
    final totalItems = noteIds.length;
    final nativeCount = AdsCount.nativeAdCount(totalItems);
    final bannerCount = AdsCount.bannerAdCount(totalItems);
    final occupiedPositions = <int>{};

    for (int i = 0; i < nativeCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      loadNativeAd(index);
    }

    for (int i = 0; i < bannerCount; i++) {
      int index = _findAvailableIndex(occupiedPositions, totalItems);
      if (index == -1) break;
      occupiedPositions.add(index);
      loadBannerAd(index);
    }
  }

  /// Load a Native Ad
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
        },
        onAdFailedToLoad: (ad, error) {
          if (_isDisposed) return;
          ad.dispose();
          _nativeAds.remove(index);
          _nativeReady[index]?.value = false;
          loadedAdsCount.value = max(0, loadedAdsCount.value - 1);
          _scheduleRetry(index, isNative: true);
        },
      ),

      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,


        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.deepPurple,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),


        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.deepPurpleAccent,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 18.0,
        ),

        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[800]!,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),

        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey[600]!,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.italic,
          size: 13.0,
        ),
      ),
    );

    ad.load();
  }

  /// Load a Banner Ad
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
        },
        onAdFailedToLoad: (ad, error) {
          if (_isDisposed) return;
          ad.dispose();
          _bannerAds.remove(index);
          _bannerReady[index]?.value = false;
          loadedAdsCount.value = max(0, loadedAdsCount.value - 1);
          _scheduleRetry(index, isNative: false);
        },
      ),
    );

    ad.load();
  }

  /// Retry failed ads with exponential backoff
  void _scheduleRetry(
    int index, {
    required bool isNative,
    bool resetRetry = false,
  }) {
    if (_isDisposed) return;

    if (resetRetry) {
      if (isNative) {
        _nativeRetry[index] = 0;
      } else {
        _bannerRetry[index] = 0;
      }
    }

    final attempt = isNative
        ? (_nativeRetry[index] ?? 1)
        : (_bannerRetry[index] ?? 1);
    if (attempt >= _maxRetries) return;

    final targetCount = isNative
        ? AdsCount.nativeAdCount(noteIds.length)
        : AdsCount.bannerAdCount(noteIds.length);
    final currentCount = isNative ? _nativeAds.length : _bannerAds.length;
    if (currentCount >= targetCount) return;

    final delay = Duration(seconds: min(10 * pow(2, attempt - 1).toInt(), 120));

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

  /// Load Interstitial Ad
  void _loadInterstitial() {
    if (_isDisposed) return;

    InterstitialAd.load(
      adUnitId: interstitialAdId,
      request: _adRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
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
          if (!_isDisposed) {
            Future.delayed(const Duration(seconds: 5), _loadInterstitial);
          }
        },
      ),
    );
  }

  /// Show Interstitial Ad
  void showInterstitial() {
    if (_interstitialAd != null && !_isDisposed) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  /// Return ad widget for a given index
  Widget getAdWidget(int index) {
    final type = _loadedAdPositions[index];
    if (type == 'native') {
      final ad = _nativeAds[index];
      if (ad != null && _nativeReady[index]?.value == true) {
        final bool useSmallTemplate = index % 2 == 0;
        final constraints = useSmallTemplate
            ? const BoxConstraints(
          minWidth: 320,
          minHeight: 120,
          maxWidth: 400,
          maxHeight: 200,
        )
            : const BoxConstraints(
          minWidth: 320,
          minHeight: 300,
          maxWidth: 400,
          maxHeight: 350,
        );


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

  /// Refresh all ads
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

  /// Dispose all ads and timers
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (var t in _retryTimers.values) {
      t.cancel();
    }
    _retryTimers.clear();

    for (var ad in _nativeAds.values) {
      ad.dispose();
    }
    for (var ad in _bannerAds.values) {
      ad.dispose();
    }
    _interstitialAd?.dispose();

    _nativeAds.clear();
    _bannerAds.clear();
    _nativeReady.clear();
    _bannerReady.clear();
    _loadedAdPositions.clear();
    _nativeRetry.clear();
    _bannerRetry.clear();
  }

  /// Find a random available index for ad placement
  int _findAvailableIndex(Set<int> occupied, int totalItems) {
    if (occupied.length >= totalItems) return -1;

    int tries = 0;
    while (tries < 100) {
      int index = _random.nextInt(totalItems);
      if (!occupied.contains(index)) return index;
      tries++;
    }

    // fallback linear search
    for (int i = 0; i < totalItems; i++) {
      if (!occupied.contains(i)) return i;
    }

    return -1;
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
