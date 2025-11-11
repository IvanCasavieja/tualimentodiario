import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/auth_service.dart';
import 'firestore_repository.dart'; // FS

/// ---------------------------------------------------------------------------
/// 🔐 UIDs con rol de administrador (mantener en un solo lugar)
///   ➜ Debe coincidir con la función `isAdmin()` de tus Firestore Rules
/// ---------------------------------------------------------------------------
const Set<String> kAdminUids = {
  "Hw70VMXycgXgLKow2EIAjFU9h8p1", // Iván
  "8Z5t5CqqO9XLqSWhzNI0AnMjkPF2", // Maxi
};

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
final homeStreamProvider = StreamProvider<QuerySnapshot<Map<String, dynamic>>>(
  name: 'homeStreamProvider',
  (ref) => FS.homeQuery().snapshots(),
);

/// ---------------------------------------------------------------------------
/// ✅ FAVORITOS
/// ---------------------------------------------------------------------------
final favoritesIdsProvider = StreamProvider.family<List<String>, String>(
  (ref, uid) => FS
      .favCol(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList()),
  name: 'favoritesIdsProvider',
);

final isFavoriteProvider =
    StreamProvider.family<bool, ({String uid, String foodId})>((ref, key) {
      final docRef = FS.favCol(key.uid).doc(key.foodId);
      return docRef.snapshots().map((doc) => doc.exists);
    }, name: 'isFavoriteProvider');

/// ---------------------------------------------------------------------------
/// ✅ ¿ES ADMIN?
///   ✔️ Nueva lógica: compara el UID actual con `kAdminUids`
///   ❌ Ya no consulta `admins/{uid}` en Firestore
/// ---------------------------------------------------------------------------
final userIsAdminProvider = StreamProvider<bool>(name: 'userIsAdminProvider', (
  ref,
) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    final isAdmin = user != null && kAdminUids.contains(user.uid);
    if (kDebugMode) {
      debugPrint('[admin] uid=${user?.uid} -> isAdmin=$isAdmin');
    }
    return isAdmin;
  });
});
