import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_state.dart'; // languageProvider, AppLang
import '../../core/providers.dart'; // authServiceProvider, authStateProvider, userIsAdminProvider
import '../../core/i18n.dart';
import '../admin/admin_upload_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(title: Text(s.profileTitle)), body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null || user.isAnonymous) {
          return const _GuestProfile();
        }
        return _UserProfile(user: user);
      },
    );
  }
}

class _GuestProfile extends ConsumerWidget {
  const _GuestProfile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
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
          Center(child: Text(s.guest, style: const TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(height: 8),
          Center(child: Text(s.guestHint, style: const TextStyle(fontSize: 12, color: Colors.grey))),
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
            label: Text(s.googleSignIn),
          ),

          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showEmailDialog(context, ref, isRegister: false),
            icon: const Icon(Icons.login),
            label: Text(s.emailSignIn),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showEmailDialog(context, ref, isRegister: true),
            child: Text(s.emailRegister),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailDialog(BuildContext context, WidgetRef ref, {required bool isRegister}) async {
    final s = ref.read(stringsProvider);
    final auth = ref.read(authServiceProvider);
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRegister ? s.emailRegister : s.emailSignIn),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: s.email)),
            TextField(controller: passCtrl, obscureText: true, decoration: InputDecoration(labelText: s.password)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(s.cancel)),
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
            child: Text(isRegister ? s.create : s.enter),
          ),
        ],
      ),
    );
  }
}

class _UserProfile extends ConsumerStatefulWidget {
  const _UserProfile({required this.user});
  final User user;
  @override
  ConsumerState<_UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends ConsumerState<_UserProfile> {
  static final Set<String> _ensured = {};

  @override
  void initState() {
    super.initState();
    if (!_ensured.contains(widget.user.uid)) {
      _ensured.add(widget.user.uid);
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final u = widget.user;
        await FirebaseFirestore.instance.doc('users/${u.uid}').set({
          'displayName': u.displayName ?? '',
          'email': u.email ?? '',
          'providerIds': u.providerData.map((p) => p.providerId).toList(),
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final auth = ref.read(authServiceProvider);
    final isAdminAsync = ref.watch(userIsAdminProvider);

    final initial = (widget.user.displayName?.isNotEmpty == true
            ? widget.user.displayName!.trim()[0]
            : (widget.user.email?.isNotEmpty == true ? widget.user.email![0] : 'U'))
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(title: Text(s.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 36,
              child: Text(initial, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.user.displayName?.isNotEmpty == true
                  ? widget.user.displayName!
                  : (widget.user.email ?? 'Usuario'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 6),
          Center(child: Text('UID: ${widget.user.uid}', style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const SizedBox(height: 24),

          Text(s.language, style: const TextStyle(fontWeight: FontWeight.w600)),
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
          isAdminAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (isAdmin) => isAdmin
                ? Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: Text(s.adminUpload),
                      subtitle: Text(s.adminPanel),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminUploadView()),
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          FilledButton.tonal(
            onPressed: () async {
              await auth.signOut();
            },
            child: Text(s.logout),
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
