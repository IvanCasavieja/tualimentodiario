import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// IDs configurables por --dart-define para asegurar que el formato coincida en release.
// Ejemplo:
// flutter run --dart-define=APP_OPEN_AD_UNIT_ID=ca-app-pub-xxx/yyy \
//            --dart-define=INTERSTITIAL_AD_UNIT_ID=ca-app-pub-xxx/zzz
const String kReleaseAppOpenId = String.fromEnvironment('APP_OPEN_AD_UNIT_ID');
const String kReleaseInterstitialId =
    String.fromEnvironment('INTERSTITIAL_AD_UNIT_ID');

/// Gestiona la carga y muestra de App Open Ads (pantalla completa al inicio).
class AppOpenAdManager {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;
  Completer<void>? _loadCompleter;
  int _retryAttempts = 0;

  // Interstitial fallback
  InterstitialAd? _interstitialAd;
  bool _isShowingInterstitial = false;
  Completer<void>? _interstitialLoadCompleter;

  static final AppOpenAdManager instance = AppOpenAdManager._internal();
  AppOpenAdManager._internal();

  // Usa el ID proporcionado en release y el ID de prueba en debug.
  String get adUnitId {
    if (kDebugMode) {
      // IDs de prueba oficiales de Google
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/3419835294' // App Open test (Android)
          : 'ca-app-pub-3940256099942544/5662855259'; // App Open test (iOS)
    }
    // App Open REAL (debe ser de tipo App Open en AdMob)
    if (kReleaseAppOpenId.isNotEmpty) return kReleaseAppOpenId;
    // Fallback al valor existente (si no coincide el formato veras error code=3)
    return 'ca-app-pub-8476168641501489/7443303959';
  }

  // Interstitial (fallback) ad unit
  String get interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Interstitial test (Android)
          : 'ca-app-pub-3940256099942544/4411468910'; // Interstitial test (iOS)
    }
    // Interstitial REAL
    if (kReleaseInterstitialId.isNotEmpty) return kReleaseInterstitialId;
    // Fallback por defecto: tu ID interstitial real
    return 'ca-app-pub-8476168641501489/9536096653';
  }

  bool get _isAdAvailable => _appOpenAd != null;

  /// Consideramos un tiempo maximo de cache para el anuncio.
  bool _isAdFresh() {
    final t = _loadTime;
    if (t == null) return false;
    // Valido por 4 horas
    return DateTime.now().difference(t) < const Duration(hours: 4);
  }

  void loadAd() {
    // Evitar recargas innecesarias si hay uno fresco disponible
    if (_isAdAvailable && _isAdFresh()) return;
    _loadCompleter = Completer<void>();
    debugPrint('[Ads] Loading AppOpenAd (unit: ' + adUnitId + ')...');
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _loadTime = DateTime.now();
          _loadCompleter?.complete();
          _retryAttempts = 0;
          debugPrint('[Ads] AppOpenAd loaded');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _loadCompleter?.complete();
          debugPrint('[Ads] AppOpenAd failed to load: ${error.code} - ${error.message}');
          // Reintento simple con backoff limitado para mejorar probabilidad de carga
          if (_retryAttempts < 2) {
            _retryAttempts++;
            Future.delayed(Duration(milliseconds: 800 * _retryAttempts), loadAd);
          }
          // Fallback a interstitial si el ad unit no coincide con App Open
          if (error.code == 3 && (error.message?.contains("doesn't match format") ?? false)) {
            debugPrint('[Ads] Falling back to InterstitialAd due to format mismatch');
            loadInterstitial();
          }
        },
      ),
    );
  }

  /// Muestra el anuncio si esta listo. Tras mostrar, vuelve a cargar uno nuevo.
  void showAdIfAvailable() {
    if (_isShowingAd) return;
    if (!_isAdAvailable) {
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        debugPrint('[Ads] AppOpenAd failed to show: ${error.code} - ${error.message}');
        loadAd();
      },
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('[Ads] AppOpenAd showed');
      },
    );

    _appOpenAd!.show();
    _appOpenAd = null;
  }

  /// Espera hasta que haya un anuncio disponible o se cumpla el timeout.
  Future<bool> waitForAvailability({Duration timeout = const Duration(seconds: 6)}) async {
    if (_isAdAvailable) return true;
    // Si no hay carga en curso, inicia una
    if (_loadCompleter == null) {
      loadAd();
    }
    try {
      await (_loadCompleter?.future.timeout(timeout) ?? Future.value());
    } catch (_) {}
    return _isAdAvailable;
  }

  /// Espera hasta `timeout` y si se pudo cargar, muestra el anuncio.
  Future<bool> showWhenAvailable({Duration timeout = const Duration(seconds: 6)}) async {
    final ready = await waitForAvailability(timeout: timeout);
    if (ready) {
      showAdIfAvailable();
      return true;
    }
    return false;
  }

  // ---------------- Interstitial fallback ----------------
  void loadInterstitial() {
    if (_interstitialAd != null) return;
    debugPrint('[Ads] Loading InterstitialAd (unit: ' + interstitialAdUnitId + ')...');
    _interstitialLoadCompleter = Completer<void>();
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialLoadCompleter?.complete();
          debugPrint('[Ads] InterstitialAd loaded');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              _isShowingInterstitial = false;
              ad.dispose();
              _interstitialAd = null;
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              _isShowingInterstitial = false;
              debugPrint('[Ads] Interstitial failed to show: ${error.code} - ${error.message}');
              ad.dispose();
              _interstitialAd = null;
            },
            onAdShowedFullScreenContent: (ad) {
              _isShowingInterstitial = true;
              debugPrint('[Ads] Interstitial showed');
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _interstitialLoadCompleter?.complete();
          debugPrint('[Ads] InterstitialAd failed to load: ${error.code} - ${error.message}');
        },
      ),
    );
  }

  Future<bool> waitForInterstitial({Duration timeout = const Duration(seconds: 6)}) async {
    if (_interstitialAd != null) return true;
    if (_interstitialLoadCompleter == null) {
      loadInterstitial();
    }
    try {
      await (_interstitialLoadCompleter?.future.timeout(timeout) ?? Future.value());
    } catch (_) {}
    return _interstitialAd != null;
  }

  Future<bool> showInterstitialWhenAvailable({Duration timeout = const Duration(seconds: 6)}) async {
    final ok = await waitForInterstitial(timeout: timeout);
    if (ok && !_isShowingInterstitial) {
      _interstitialAd?.show();
      return true;
    }
    return false;
  }

  /// Intenta mostrar App Open; si no hay, cae a Interstitial con el mismo timeout.
  Future<void> showOnLaunch({Duration timeout = const Duration(seconds: 6)}) async {
    final shownAppOpen = await showWhenAvailable(timeout: timeout);
    if (!shownAppOpen) {
      await showInterstitialWhenAvailable(timeout: timeout);
    }
  }
}
