import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_repository.dart';

/// Auth simple (anon)
final authProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final signInAnonProvider = Provider<Future<User?> Function()>((ref) {
  return () async {
    final cred = await FirebaseAuth.instance.signInAnonymously();
    return cred.user;
  };
});

/// Home stream
final homeStreamProvider =
    StreamProvider<QuerySnapshot<Map<String, dynamic>>>((ref) {
  return FS.homeQuery().snapshots();
});

/// Favoritos IDs del usuario actual
final favoritesIdsProvider =
    StreamProvider.family<List<String>, String>((ref, uid) {
  return FS
      .favCol(uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.id).toList());
});
