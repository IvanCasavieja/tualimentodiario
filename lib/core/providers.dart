import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/auth_service.dart';
import 'firestore_repository.dart'; // FS

/// ---------------------------------------------------------------------------
/// ✅ AUTH STATE (anónimo o logueado)
/// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<User?>(
  name: 'authStateProvider',
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// Alias opcional
@Deprecated('Usá authStateProvider')
final authProvider = authStateProvider;

/// Servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 🔹 Acción rápida: entrar en modo invitado (anon)
final signInAnonProvider = Provider<Future<User?> Function()>((ref) {
  return () async {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user;
  };
});

/// ---------------------------------------------------------------------------
/// ✅ HOME STREAM
/// ---------------------------------------------------------------------------
final homeStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  name: 'homeStreamProvider',
  (ref) => FS.homeQuery().snapshots(),
);

/// ---------------------------------------------------------------------------
/// ✅ FAVORITOS
/// ---------------------------------------------------------------------------
final favoritesIdsProvider =
    StreamProvider.family<List<String>, String>(
  (ref, uid) => FS
      .favCol(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList()),
  name: 'favoritesIdsProvider',
);

final isFavoriteProvider =
    StreamProvider.family<bool, ({String uid, String foodId})>(
  (ref, key) {
    final docRef = FS.favCol(key.uid).doc(key.foodId);
    return docRef.snapshots().map((doc) => doc.exists);
  },
  name: 'isFavoriteProvider',
);

/// ---------------------------------------------------------------------------
/// ✅ ¿ES ADMIN? -> existe admins/{uid}
///   Requiere en rules: match /admins/{uid} { allow get: if request.auth.uid == uid; }
/// ---------------------------------------------------------------------------
final userIsAdminProvider = StreamProvider<bool>(
  name: 'userIsAdminProvider',
  (ref) async* {
    await for (final user in FirebaseAuth.instance.authStateChanges()) {
      if (user == null) {
        if (kDebugMode) debugPrint('[admin] user=null -> false');
        yield false;
      } else {
        final path = 'admins/${user.uid}';
        if (kDebugMode) debugPrint('[admin] listening $path');
        yield* FirebaseFirestore.instance
            .doc(path)
            .snapshots()
            .map((d) {
              final ok = d.exists;
              if (kDebugMode) debugPrint('[admin] $path exists=${d.exists} data=${d.data()}');
              return ok;
            })
            .handleError((e) {
              if (kDebugMode) debugPrint('[admin] ERROR leyendo $path -> $e');
            });
      }
    }
  },
);
