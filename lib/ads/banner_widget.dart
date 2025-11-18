import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_units.dart';

const String _releaseBannerId = String.fromEnvironment('BANNER_AD_UNIT_ID');
const _horizontalPadding = 16.0;

String _resolveAdUnitId() {
  if (kDebugMode) {
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/6300978111'
        : 'ca-app-pub-3940256099942544/2934735716';
  }
  if (_releaseBannerId.isNotEmpty) {
    return _releaseBannerId;
  }
  return kDefaultBannerAdUnitId;
}

/// Banner discreto que se mantiene en la parte inferior sin interferir.
class PersistentBannerAd extends StatefulWidget {
  const PersistentBannerAd({super.key});

  @override
  State<PersistentBannerAd> createState() => _PersistentBannerAdState();
}

class _PersistentBannerAdState extends State<PersistentBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int _lastAdaptiveWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoadAdaptiveBanner();
  }

  void _maybeLoadAdaptiveBanner() {
    final widthForAd = _calculateAdaptiveWidth(context);
    if (widthForAd <= 0 || widthForAd == _lastAdaptiveWidth) return;
    _lastAdaptiveWidth = widthForAd;
    _loadAdaptiveBanner(widthForAd);
  }

  int _calculateAdaptiveWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width - (_horizontalPadding * 2);
    return width > 0 ? width.toInt() : 0;
  }

  Future<void> _loadAdaptiveBanner(int width) async {
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      width,
    );
    if (!mounted) return;

    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    setState(() {});

    late final BannerAd bannerAd;
    bannerAd = BannerAd(
      size: size ?? AdSize.banner,
      adUnitId: _resolveAdUnitId(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() {
            _isLoaded = true;
            _bannerAd = bannerAd;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _isLoaded = false;
            _bannerAd = null;
          });
        },
      ),
      request: const AdRequest(),
    );

    bannerAd.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final height = _bannerAd!.size.height.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _horizontalPadding,
        vertical: 8,
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
