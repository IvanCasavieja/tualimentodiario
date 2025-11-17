import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_units.dart';

const String _envInterstitialUnitId = String.fromEnvironment(
  'INTERSTITIAL_AD_UNIT_ID',
);

String _resolveInterstitialId() {
  if (kDebugMode) {
    return Platform.isAndroid
        ? 'ca-app-pub-3940256099942544/1033173712'
        : 'ca-app-pub-3940256099942544/4411468910';
  }
  if (_envInterstitialUnitId.isNotEmpty) {
    return _envInterstitialUnitId;
  }
  return kDefaultInterstitialAdUnitId;
}

class InterstitialAdManager {
  InterstitialAdManager._internal() {
    _loadAd();
  }

  static final InterstitialAdManager instance =
      InterstitialAdManager._internal();

  InterstitialAd? _interstitialAd;
  bool _isLoading = false;
  bool _isShowing = false;
  Completer<void>? _loadCompleter;

  Future<void> loadAd() => _loadAd();

  Future<void> _loadAd() {
    if (_interstitialAd != null) {
      return Future.value();
    }
    if (_isLoading) {
      return _loadCompleter?.future ?? Future.value();
    }
    _isLoading = true;
    final completer = Completer<void>();
    _loadCompleter = completer;

    InterstitialAd.load(
      adUnitId: _resolveInterstitialId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isLoading = false;
          _loadCompleter?.complete();
          _loadCompleter = null;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _loadCompleter?.complete();
          _loadCompleter = null;
        },
      ),
    );

    return completer.future;
  }

  Future<bool> showAdIfAvailable() async {
    if (_isShowing) return false;
    if (_interstitialAd == null) {
      await _loadAd();
    }
    if (_interstitialAd == null) return false;

    final completer = Completer<bool>();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowing = false;
        ad.dispose();
        _interstitialAd = null;
        _loadAd();
        completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowing = false;
        ad.dispose();
        _interstitialAd = null;
        _loadAd();
        completer.complete(false);
      },
    );

    _interstitialAd!.show();
    return completer.future;
  }
}
