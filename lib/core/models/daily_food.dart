import 'package:cloud_firestore/cloud_firestore.dart';

class DailyFood {
  final String id;
  final String date; // yyyy-MM-dd
  final String authorUid;
  final String authorName;
  final bool isPublished;
  final Map<String, dynamic> translations; // es/en/pt/it
  final int favoritesCount;

  DailyFood({
    required this.id,
    required this.date,
    required this.authorUid,
    required this.authorName,
    required this.isPublished,
    required this.translations,
    required this.favoritesCount,
  });

  factory DailyFood.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DailyFood(
      id: doc.id,
      date: d['date'] ?? '',
      authorUid: d['authorUid'] ?? '',
      authorName: d['authorName'] ?? '',
      isPublished: d['isPublished'] ?? false,
      translations: Map<String, dynamic>.from(d['translations'] ?? {}),
      favoritesCount: (d['stats']?['favoritesCount'] ?? 0) as int,
    );
  }
}
