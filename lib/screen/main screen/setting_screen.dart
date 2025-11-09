import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../service/provider/theme_provider.dart';
import '../../service/provider/view_type_provider.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String _version = '';
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
    _loadVersion();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Mode Row
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 1,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Theme Mode',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      Transform.scale(
                        scale: .8,
                        child: Switch(
                          value: themeProvider.isDarkMode(context),
                          activeThumbColor: Colors.white,
                          activeTrackColor: Colors.white24,
                          inactiveThumbColor: Colors.black,
                          inactiveTrackColor: Colors.black12,
                          onChanged: (value) {
                            themeProvider.toggleTheme(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Note View Style Row
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Consumer<ViewTypeProvider>(
                        builder: (context, viewProvider, _) {
                          // inactive text shows the view that is NOT active
                          final inactiveText = viewProvider.isGridView
                              ? 'List'
                              : 'Grid';
                          return Text(
                            'Note View Style: $inactiveText',
                            style: TextStyle(
                              fontSize: 18,
                              color: colorScheme.primary,
                            ),
                          );
                        },
                      ),
                      Consumer<ViewTypeProvider>(
                        builder: (context, viewProvider, _) {
                          return Transform.scale(
                            scale: 0.8,
                            child: Switch(
                              value: viewProvider.isGridView,
                              activeThumbColor:
                                  Colors.blue, // active view thumb
                              inactiveThumbColor:
                                  Colors.blue, // inactive thumb color
                              inactiveTrackColor: colorScheme.onPrimary
                                  .withOpacity(0.3),
                              onChanged: (value) {
                                viewProvider.toggleView(value);
                                setState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // App Version Row
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'App Version:',
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        _version,
                        style: TextStyle(
                          fontSize: 18,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Banner Ad below version
              if (_isBannerLoaded && _bannerAd != null)
                Container(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.transparent,
                  ),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _loadBanner() {
    _bannerAd = BannerAd(
      adUnitId:
          'ca-app-pub-7237142331361857/9810896707', // Replace with your Ad Unit ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isBannerLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _version = info.version;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _version = "Unknown";
      });
    }
  }
}
