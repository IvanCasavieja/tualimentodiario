// Archivo principal: configura Firebase, Riverpod y la navegación base.
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ads/interstitial_manager.dart';
import 'core/app_state.dart';
import 'core/i18n.dart'; // stringsProvider
import 'core/tema.dart'; // ThemeMode, escala de texto y temas Light/Dark
import 'debug/log_observer.dart';
import 'core/push_notifications.dart';
import 'features/archive/archive_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/home/home_view.dart';
import 'features/profile/profile_view.dart';
import 'features/splash/splash_view.dart';
import 'firebase_options.dart';

const bool kEnableRiverpodLogs = false;

/// Observador global: mantiene la suscripción al topic de FCM cuando cambia idioma.
class PushLanguageObserver extends ProviderObserver {
  const PushLanguageObserver(this._push);
  final PushNotifications _push;

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider == languageProvider && newValue is AppLang) {
      _push.onLanguageChanged(newValue);
    }
  }
}

/// Punto de entrada de la app: inicializa Firebase, sesión y preferencias.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await MobileAds.instance.initialize();
  InterstitialAdManager.instance.loadAd();

  // Inicia una sesión anónima si no existe un usuario actual.
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Carga de preferencias persistidas (idioma, tema y escala de texto).
  final savedLang = await LanguagePrefs.load();
  await PushNotifications.instance.init(savedLang);
  final (savedMode, savedScale) = await ThemePrefs.load();
  final observers = <ProviderObserver>[
    if (kEnableRiverpodLogs) LogObserver(),
    PushLanguageObserver(PushNotifications.instance),
  ];

  runApp(
    ProviderScope(
      observers: observers,
      overrides: [
        languageProvider.overrideWith((ref) => savedLang),
        themeModeProvider.overrideWith((ref) => savedMode),
        textScaleProvider.overrideWith((ref) => savedScale),
      ],
      child: const App(),
    ),
  );
}

/// Widget raíz de la app. Escucha providers para i18n y tema.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final t = ref.watch(stringsProvider);
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(textScaleProvider);

    return MaterialApp(
      title: t.appTitle,
      debugShowCheckedModeBanner: false,
      locale: Locale(_toCode(lang)),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('pt'),
        Locale('it'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,
      // Aplica textScale global para accesibilidad y tamaño de texto.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashView(), // Vista raíz con navegación inferior por tabs.
      routes: {'/home': (_) => const NavScaffold()},
    );
  }

  /// Convierte AppLang a su código de idioma (ej: es, en, pt, it).
  String _toCode(AppLang l) {
    switch (l) {
      case AppLang.en:
        return 'en';
      case AppLang.pt:
        return 'pt';
      case AppLang.it:
        return 'it';
      case AppLang.es:
        return 'es';
    }
  }
}

/// Scaffold principal con navegación inferior y conservación de estado.
class NavScaffold extends ConsumerStatefulWidget {
  const NavScaffold({super.key});

  @override
  ConsumerState<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends ConsumerState<NavScaffold> {
  // Lista de páginas en el mismo orden que las pestañas.
  static const pages = [
    HomeView(),
    ArchiveView(),
    FavoritesView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(bottomTabIndexProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      body: IndexedStack(index: idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) =>
            ref.read(bottomTabIndexProvider.notifier).state = i,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: t.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.folder_copy_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: t.navArchive,
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            selectedIcon: const Icon(Icons.favorite),
            label: t.navFavorites,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: t.navProfile,
          ),
        ],
      ),
    );
  }
}
