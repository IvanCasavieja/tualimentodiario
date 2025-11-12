import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/app_state.dart'; // languageProvider, AppLang
import '../../core/i18n.dart'; // stringsProvider
import '../../core/providers.dart'; // authServiceProvider, authStateProvider, userIsAdminProvider
import '../../core/tema.dart'; // themeModeProvider, textScaleProvider, ThemePrefs
import '../../core/prefs_i18n.dart';
import '../admin/admin_upload_view.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: Text(t.profileTitle)),
        body: Center(child: Text('Error: $e')),
      ),
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
    final t = ref.watch(stringsProvider);
    final auth = ref.read(authServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _ProfileHeader(
            displayName: 'Invitado',
            email: 'Invitado',
            photoUrl: null,
          ),
          const SizedBox(height: 16),

          const _LanguageDropdown(),

          const SizedBox(height: 16),

          const _PreferencesCard(),

          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              try {
                await auth.signInWithGoogle();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(prefsTextsOf(ref.read(languageProvider)).googleSignedIn)),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message ?? 'Error al iniciar con Google'),
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.g_mobiledata, size: 28),
            label: Text(t.googleSignIn),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _showEmailDialog(context, ref, isRegister: false),
            icon: const Icon(Icons.login),
            label: Text(t.emailSignIn),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _showEmailDialog(context, ref, isRegister: true),
            child: Text(t.emailRegister),
          ),
        ],
      ),
    );
  }

  Future<void> _showEmailDialog(
    BuildContext context,
    WidgetRef ref, {
    required bool isRegister,
  }) async {
    final t = ref.read(stringsProvider);
    final auth = ref.read(authServiceProvider);
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRegister ? t.emailRegister : t.emailSignIn),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: t.email),
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: t.password),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
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
                    SnackBar(
                      content: Text(e.message ?? 'Error de autenticaciÃ³n'),
                    ),
                  );
                }
              }
            },
            child: Text(isRegister ? t.create : t.enter),
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
    final t = ref.watch(stringsProvider);
    final auth = ref.read(authServiceProvider);
    final isAdminAsync = ref.watch(userIsAdminProvider);

    final name = widget.user.displayName?.trim();
    final email = widget.user.email?.trim();
    final photo = widget.user.photoURL;

    return Scaffold(
      appBar: AppBar(title: Text(t.profileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            displayName: (name?.isNotEmpty ?? false) ? name! : 'Usuario',
            email: (email?.isNotEmpty ?? false) ? email! : 'Invitado',
            photoUrl: photo,
          ),
          const SizedBox(height: 16),

          const _LanguageDropdown(),

          const SizedBox(height: 16),

          const _PreferencesCard(),

          const SizedBox(height: 24),

          isAdminAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (isAdmin) => isAdmin
                ? Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.verified_user),
                      title: Text(t.adminUpload),
                      subtitle: Text(t.adminPanel),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminUploadView(),
                          ),
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
            child: Text(t.logout),
          ),
        ],
      ),
    );
  }
}

/// Header compacto: avatar a la izquierda, nombre a la derecha y email debajo.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  final String displayName;
  final String email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
              ? NetworkImage(photoUrl!)
              : null,
          child: (photoUrl == null || photoUrl!.isEmpty)
              ? const Icon(Icons.person, size: 30)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                email.isEmpty ? 'Invitado' : email,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withValues(alpha: .8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dropdown de idioma (reemplaza los chips).
class _LanguageDropdown extends ConsumerWidget {
  const _LanguageDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final lang = ref.watch(languageProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.language, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        DropdownButtonFormField<AppLang>(
          initialValue: lang,
          onChanged: (v) {
            if (v != null) ref.read(languageProvider.notifier).state = v;
          },
          borderRadius: BorderRadius.circular(12),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: AppLang.es, child: Text('Español')),
            DropdownMenuItem(value: AppLang.en, child: Text('English')),
            DropdownMenuItem(value: AppLang.pt, child: Text('Português')),
            DropdownMenuItem(value: AppLang.it, child: Text('Italiano')),
          ],
        ),
      ],
    );
  }
}

/// Preferencias globales: modo oscuro + Tamaño de texto.
/// Se conecta a los providers globales de tema.
class _PreferencesCard extends ConsumerWidget {
  const _PreferencesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final scale = ref.watch(textScaleProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.settings),
              title: Text(prefsTextsOf(ref.watch(languageProvider)).title),
              subtitle: Text(prefsTextsOf(ref.watch(languageProvider)).subtitle),
            ),
            const Divider(height: 0),

            // Modo oscuro
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(prefsTextsOf(ref.watch(languageProvider)).darkMode),
              value: isDark,
              onChanged: (v) async {
                final newMode = v ? ThemeMode.dark : ThemeMode.light;
                ref.read(themeModeProvider.notifier).state = newMode;
                await ThemePrefs.saveMode(newMode);
              },
              secondary: const Icon(Icons.dark_mode),
            ),

            // Tamaño de texto
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.text_fields),
              title: Text(prefsTextsOf(ref.watch(languageProvider)).textSize),
              subtitle: Slider(
                min: 0.9,
                max: 1.4,
                divisions: 5, // 90%,100%,110%,120%,130%,140%
                label: '${(scale * 100).round()}%',
                value: scale,
                onChanged: (v) {
                  ref.read(textScaleProvider.notifier).state = v;
                },
                onChangeEnd: (v) async {
                  await ThemePrefs.saveTextScale(v);
                },
              ),
              trailing: Text(
                '${(scale * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}






