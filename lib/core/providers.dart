import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/auth_service.dart';
import 'firestore_repository.dart'; // FS

/// ---------------------------------------------------------------------------
/// ✅ AUTH STATE (anónimo o logueado)
/// ---------------------------------------------------------------------------
final authStateProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

// Alias opcional para compatibilidad con código viejo
@Deprecated('Usá authStateProvider')
final authProvider = authStateProvider;

/// Servicio de autenticación (email, google, guest, logout)
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// 🔹 Acción rápida: entrar en modo invitado (anon)
final signInAnonProvider = Provider<Future<User?> Function()>((ref) {
  return () async {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user;
  };
});

/// ---------------------------------------------------------------------------
/// ✅ HOME STREAM (inicio)
/// ---------------------------------------------------------------------------
/// Usa FS.homeQuery() de tu repositorio (últimos 5 publicados)
final homeStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FS.homeQuery().snapshots();
});

/// ---------------------------------------------------------------------------
/// ✅ FAVORITOS DEL USUARIO (lista de IDs para la pantalla Favoritos)
/// ---------------------------------------------------------------------------
/// Se mantiene igual: escucha la colección /users/{uid}/favorites
final favoritesIdsProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  return FS
      .favCol(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());
});

/// ---------------------------------------------------------------------------
/// ✅ ¿Es favorito? (stream del DOCUMENTO puntual /users/{uid}/favorites/{foodId})
/// ---------------------------------------------------------------------------
/// No dependemos de listar la colección; con get del doc alcanza.
/// Si el doc existe -> true; si no -> false.
final isFavoriteProvider =
    StreamProvider.family<bool, ({String uid, String foodId})>((ref, key) {
  final docRef = FS.favCol(key.uid).doc(key.foodId);
  return docRef.snapshots().map((doc) => doc.exists);
});
