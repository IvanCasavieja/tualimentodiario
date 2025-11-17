// Archivo principal: configura Firebase, Riverpod y navegaciÃ³n base.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/app_state.dart';
import 'core/i18n.dart'; // stringsProvider
import 'core/tema.dart'; // themeModeProvider, textScaleProvider, ThemePrefs, buildLightTheme, buildDarkTheme
import 'features/home/home_view.dart';
import 'features/archive/archive_view.dart';
import 'features/favorites/favorites_view.dart';
import 'package:tu_alimento_diario/features/profile/profile_view.dart';
import 'debug/log_observer.dart';
import 'features/splash/splash_view.dart';
import 'ads/ad_manager.dart';

/// Punto de entrada de la app: inicializa Firebase, sesiÃ³n y preferencias.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Inicializa los servicios de Firebase
  // Inicializa el SDK de Google Mobile Ads (AdMob) y precarga App Open Ad
  await MobileAds.instance.initialize();
  AppOpenAdManager.instance.loadAd();

  // SesiÃ³n anÃ³nima si no hay usuario
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Carga de preferencias persistidas (idioma, tema y escala de texto)
  final savedLang = await LanguagePrefs.load();
  final (savedMode, savedScale) = await ThemePrefs.load(); // ThemeMode + double

  runApp(
    ProviderScope(
      observers: [LogObserver()], // Observa cambios de estado para debug
      overrides: [
        // Inyecta estados iniciales desde preferencias persistidas
        languageProvider.overrideWith((ref) => savedLang),
        themeModeProvider.overrideWith((ref) => savedMode),
        textScaleProvider.overrideWith((ref) => savedScale),
      ],
      child: const App(),
    ),
  );
}

/// Widget raÃ­z de la app. Escucha providers para i18n y tema.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Estados reactivos leÃ­dos de Riverpod
    final lang = ref.watch(languageProvider);
    final t = ref.watch(stringsProvider);
    final mode = ref.watch(themeModeProvider);
    final scale = ref.watch(textScaleProvider);

    // ConfiguraciÃ³n principal del MaterialApp
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

      // â¬‡â¬‡ IMPORTANTE: temas que incluyen AppExtras
      // Temas claro/oscuro de la app (con AppExtras)
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: mode,

      // Aplica textScale globalmente para accesibilidad/tamaÃ±o de texto
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
      // Vista raÃ­z con navegaciÃ³n inferior por pestaÃ±as
      home: const SplashView(),
      routes: {
        '/home': (_) => const NavScaffold(),
      },
    );
  }

  /// Convierte AppLang a su cÃ³digo de idioma (ej: es, en, pt, it)
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

/// Scaffold principal con navegaciÃ³n inferior y conservaciÃ³n de estado.
class NavScaffold extends ConsumerStatefulWidget {
  const NavScaffold({super.key});
  @override
  ConsumerState<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends ConsumerState<NavScaffold> {
  // Lista de pÃ¡ginas en el mismo orden que las pestaÃ±as.
  static const pages = [
    HomeView(),
    ArchiveView(),
    FavoritesView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ãndice actual de la pestaÃ±a activa (estado global)
    final idx = ref.watch(bottomTabIndexProvider);
    final t = ref.watch(stringsProvider);

    return Scaffold(
      // Mantiene el estado de las pÃ¡ginas no visibles
      body: IndexedStack(index: idx, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        // Cambia la pestaÃ±a seleccionada actualizando el provider
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(bottomTabIndexProvider);
      if (current == 0) {
        AppOpenAdManager.instance
            .showOnLaunch(timeout: const Duration(seconds: 4));
      }
    });
  }

}







