import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_state.dart';
// (removido import no usado de core/providers.dart)
import 'features/home/home_view.dart';
import 'features/archive/archive_view.dart';
import 'features/favorites/favorites_view.dart';
import 'features/profile/profile_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Sign-in anónimo para poder usar favoritos
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }

  runApp(const ProviderScope(child: App()));
}

class App extends ConsumerWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return MaterialApp(
      title: 'Tu Alimento Diario',
      debugShowCheckedModeBanner: false,
      locale: Locale(lang.name),
      supportedLocales: const [Locale('es'), Locale('en'), Locale('pt'), Locale('it')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const NavScaffold(),
    );
  }
}

class NavScaffold extends StatefulWidget {
  const NavScaffold({super.key});
  @override
  State<NavScaffold> createState() => _NavScaffoldState();
}

class _NavScaffoldState extends State<NavScaffold> {
  int idx = 0;
  final pages = const [HomeView(), ArchiveView(), FavoritesView(), ProfileView()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) => setState(() => idx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.folder_copy_outlined), selectedIcon: Icon(Icons.folder), label: 'Archivo'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favoritos'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
