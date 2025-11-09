import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_state.dart'; // languageProvider
import '../../core/providers.dart';  // authServiceProvider, authStateProvider

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (user) {
        if (user == null || user.isAnonymous) {
          return _GuestProfile(lang: lang);
        }
        return _UserProfile(user: user, lang: lang);
      },
    );
  }
}

class _GuestProfile extends ConsumerWidget {
  const _GuestProfile({required this.lang});
  final AppLang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 36,
              child: Icon(Icons.person, size: 36, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text('Invitado', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                await auth.signInWithGoogle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sesión iniciada con Google')),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Error al iniciar con Google')),
                  );
                }
              }
            },
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: const Text('Continuar con Google'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showEmailDialog(context, ref, isRegister: false),
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión con email'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showEmailDialog(context, ref, isRegister: true),
            child: const Text('Crear cuenta con email'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailDialog(BuildContext context, WidgetRef ref, {required bool isRegister}) async {
    final auth = ref.read(authServiceProvider);
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRegister ? 'Crear cuenta' : 'Iniciar sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              try {
                if (isRegister) {
                  await auth.registerWithEmail(emailCtrl.text, passCtrl.text);
                } else {
                  await auth.signInWithEmail(emailCtrl.text, passCtrl.text);
                }
                if (context.mounted) Navigator.pop(ctx);
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.message ?? 'Error de autenticación')),
                  );
                }
              }
            },
            child: Text(isRegister ? 'Crear' : 'Entrar'),
          ),
        ],
      ),
    );
  }
}

class _UserProfile extends ConsumerStatefulWidget {
  const _UserProfile({required this.user, required this.lang});
  final User user;
  final AppLang lang;

  @override
  ConsumerState<_UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<_UserProfile> {
  static final Set<String> _ensured = {};

  @override
  void initState() {
    super.initState();
    // Creamos/actualizamos doc mínimo en /users/{uid} sin depender de Storage ni foto.
    if (!_ensured.contains(widget.user.uid)) {
      _ensured.add(widget.user.uid);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final u = widget.user;
        await FirebaseFirestore.instance.doc('users/${u.uid}').set({
          'displayName': u.displayName ?? '',
          'email': u.email ?? '',
          'providerIds': u.providerData.map((p) => p.providerId).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(), // merge no lo pisa si ya existe
        }, SetOptions(merge: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    // Avatar SIEMPRE local por inicial (no usamos photoURL para evitar dependencias/costos)
    final initial = (widget.user.displayName?.isNotEmpty == true
            ? widget.user.displayName!.trim()[0]
            : (widget.user.email?.isNotEmpty == true ? widget.user.email![0] : 'U'))
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 36,
              child: Text(
                initial,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.user.displayName?.isNotEmpty == true ? widget.user.displayName! : (widget.user.email ?? 'Usuario'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('UID: ${widget.user.uid}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
          const SizedBox(height: 24),

          const Text('Idioma', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: const [
              _LangChip(label: 'Español', value: AppLang.es),
              _LangChip(label: 'English', value: AppLang.en),
              _LangChip(label: 'Português', value: AppLang.pt),
              _LangChip(label: 'Italiano', value: AppLang.it),
            ],
          ),

          const SizedBox(height: 24),

          FilledButton.tonal(
            onPressed: () async {
              await auth.signOut();
            },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends ConsumerWidget {
  const _LangChip({required this.label, required this.value});
  final String label;
  final AppLang value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(languageProvider) == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => ref.read(languageProvider.notifier).state = value,
    );
  }
}
