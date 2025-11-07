import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/app_state.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  void initState() {
    super.initState();
    // Cargar preferencia de idioma al entrar
    LanguagePrefs.load().then((loaded) {
      if (mounted) {
        ref.read(languageProvider.notifier).state = loaded;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 40, backgroundImage: AssetImage('assets/avatars/avatar_01.png')),
          const SizedBox(height: 12),
          Center(child: Text(user?.isAnonymous == true ? 'Invitado' : (user?.uid ?? 'Usuario'))),
          const SizedBox(height: 24),
          const Text('Idioma', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Español'),
                selected: lang == AppLang.es,
                onSelected: (_) {
                  ref.read(languageProvider.notifier).state = AppLang.es;
                  LanguagePrefs.save(AppLang.es);
                },
              ),
              FilterChip(
                label: const Text('English'),
                selected: lang == AppLang.en,
                onSelected: (_) {
                  ref.read(languageProvider.notifier).state = AppLang.en;
                  LanguagePrefs.save(AppLang.en);
                },
              ),
              FilterChip(
                label: const Text('Português'),
                selected: lang == AppLang.pt,
                onSelected: (_) {
                  ref.read(languageProvider.notifier).state = AppLang.pt;
                  LanguagePrefs.save(AppLang.pt);
                },
              ),
              FilterChip(
                label: const Text('Italiano'),
                selected: lang == AppLang.it,
                onSelected: (_) {
                  ref.read(languageProvider.notifier).state = AppLang.it;
                  LanguagePrefs.save(AppLang.it);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await FirebaseAuth.instance.signInAnonymously();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión reiniciada (invitado)')));
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}
