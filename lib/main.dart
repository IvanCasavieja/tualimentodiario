import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'features/home/home_view.dart';
import 'features/archive/archive_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/profile/profile_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign-in anónimo para poder usar favoritos y lecturas con reglas
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  // Idioma guardado en SharedPreferences (por defecto 'es')
  final savedLang = await LanguagePrefs.load();

  runApp(
    ProviderScope(
      overrides: [
        // Sobrescribimos el valor inicial del StateProvider
        languageProvider.overrideWith((ref) => savedLang),
      ],
      child: const App(),
    ),
  );
}

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Tu Alimento Diario',
      debugShowCheckedModeBanner: false,
      locale: Locale(_toCode(lang)),
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
        Locale('pt'),
        Locale('it'),
      ],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const NavScaffold(),
    );
  }

  String _toCode(AppLang l) {
    switch (l) {
      case AppLang.en:
        return 'en';
      case AppLang.pt:
        return 'pt';
      case AppLang.it:
        return 'it';
      case AppLang.es:
      default:
        return 'es';
    }
  }
}

class NavScaffold extends ConsumerStatefulWidget {
  const NavScaffold({super.key});
  @override
  ConsumerState<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends ConsumerState<NavScaffold> {
  // Suscripción para escuchar el “tocar tarjeta en Inicio”
  ProviderSubscription<String?>? _sub;

  final pages = const [
    HomeView(),
    ArchiveView(),
    FavoritesView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    // Usamos listenManual en initState (apto fuera de build)
    _sub = ref.listenManual<String?>(
      selectedFoodIdProvider,
      (prev, next) {
        if (next != null) {
          // cambiate a Archivo
          ref.read(bottomTabIndexProvider.notifier).state = 1;
          // (ArchiveView abrirá el detalle al detectar selectedFoodId)
        }
      },
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(bottomTabIndexProvider);
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) =>
            ref.read(bottomTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio'),
          NavigationDestination(
              icon: Icon(Icons.folder_copy_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Archivo'),
          NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favoritos'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}
