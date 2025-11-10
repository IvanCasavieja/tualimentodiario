import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
import 'core/i18n.dart'; // stringsProvider
import 'features/home/home_view.dart';
import 'features/archive/archive_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/profile/profile_view.dart';
import 'debug/log_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  final savedLang = await LanguagePrefs.load();

  runApp(
    ProviderScope(
      observers: [LogObserver()],
      overrides: [
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
    final t = ref.watch(stringsProvider);

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
  final pages = const [
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
              label: t.navHome),
          NavigationDestination(
              icon: const Icon(Icons.folder_copy_outlined),
              selectedIcon: const Icon(Icons.folder),
              label: t.navArchive),
          NavigationDestination(
              icon: const Icon(Icons.favorite_border),
              selectedIcon: const Icon(Icons.favorite),
              label: t.navFavorites),
          NavigationDestination(
              icon: const Icon(Icons.person_outline),
              selectedIcon: const Icon(Icons.person),
              label: t.navProfile),
        ],
      ),
    );
  }
}
