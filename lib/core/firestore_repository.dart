import 'package:cloud_firestore/cloud_firestore.dart';

class FS {
  static final db = FirebaseFirestore.instance;

  // HOME – últimos 5 publicados (por fecha DESC)
  static Query<Map<String, dynamic>> homeQuery() => db
      .collection('dailyFoods')
      .where('isPublished', isEqualTo: true)
      .orderBy('date', descending: true)
      .limit(5);

  // ARCHIVO – base ASC
  static Query<Map<String, dynamic>> archiveBase() => db
      .collection('dailyFoods')
      .where('isPublished', isEqualTo: true)
      .orderBy('date', descending: false)
      .limit(10);

  // ARCHIVO con rango
  static Query<Map<String, dynamic>> archiveRange(String from, String to) => db
      .collection('dailyFoods')
      .where('isPublished', isEqualTo: true)
      .where('date', isGreaterThanOrEqualTo: from)
      .where('date', isLessThanOrEqualTo: to)
      .orderBy('date', descending: false)
      .limit(10);

  // Favoritos
  static CollectionReference<Map<String, dynamic>> favCol(String uid) =>
      db.collection('users').doc(uid).collection('favorites');

  static DocumentReference<Map<String, dynamic>> foodRef(String id) =>
      db.collection('dailyFoods').doc(id);

  static Future<void> toggleFavorite({
    required String uid,
    required String foodId,
    required bool add,
  }) async {
    final favRef = favCol(uid).doc(foodId);
    final food = foodRef(foodId);

    await db.runTransaction((tx) async {
      final favDoc = await tx.get(favRef);
      if (add && !favDoc.exists) {
        tx.set(favRef, {'createdAt': FieldValue.serverTimestamp()});
        tx.update(food, {'stats.favoritesCount': FieldValue.increment(1)});
      } else if (!add && favDoc.exists) {
        tx.delete(favRef);
        tx.update(food, {'stats.favoritesCount': FieldValue.increment(-1)});
      }
    });
  }
}
