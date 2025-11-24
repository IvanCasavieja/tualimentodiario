import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/auth_service.dart';
import 'date_formats.dart';
import 'firestore_repository.dart'; // FS
import 'models/daily_food.dart';

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

bool isGuestUser(User? user) => user == null || user.isAnonymous;
bool isLoggedIn(User? user) => user != null && !user.isAnonymous;

final guestModeProvider = Provider<bool>(name: 'guestModeProvider', (ref) {
  final auth = ref.watch(authStateProvider);
  return isGuestUser(auth.value);
});

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

final favoriteFoodsProvider =
    FutureProvider.family<List<DailyFood>, List<String>>((ref, ids) async {
      final safeIds = ids.where((id) => id.isNotEmpty).toList();
      if (safeIds.isEmpty) return [];
      final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
      for (var i = 0; i < safeIds.length; i += 10) {
        final chunk = safeIds.sublist(
          i,
          (i + 10 > safeIds.length) ? safeIds.length : i + 10,
        );
        futures.add(
          FirebaseFirestore.instance
              .collection('dailyFoods')
              .where(FieldPath.documentId, whereIn: chunk)
              .get(),
        );
      }

      final snapshots = await Future.wait(futures);
      final todayStr = DateFormats.iso.format(DateTime.now());
      final filteredDocs = snapshots.expand((snapshot) => snapshot.docs).where((
        doc,
      ) {
        final rawDate = (doc.data()['date'] ?? '').toString();
        if (rawDate.isEmpty) return true;
        return rawDate.compareTo(todayStr) <= 0;
      }).toList();
      filteredDocs.sort((a, b) {
        final da = (a.data()['date'] ?? '').toString();
        final db = (b.data()['date'] ?? '').toString();
        return db.compareTo(da);
      });
      return filteredDocs.map(DailyFood.fromDoc).toList();
    }, name: 'favoriteFoodsProvider');

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
