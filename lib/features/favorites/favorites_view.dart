import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart'; // authStateProvider, favoritesIdsProvider
import '../../core/firestore_repository.dart';
import '../../core/models/daily_food.dart';
import '../../core/app_state.dart';
import '../../core/ui_utils.dart';
import '../../core/i18n.dart'; // stringsProvider
import '../common/food_detail_dialog.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);

    final user = ref.watch(authStateProvider).value;
    final langCode = ref.watch(languageProvider).name;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(t.favoritesTitle)),
        body: Center(child: Text(t.favoritesNeedLogin)),
      );
    }

    final favIds = ref.watch(favoritesIdsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: Text(t.favoritesTitle)),
      body: favIds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ids) {
          if (ids.isEmpty) {
            return Center(child: Text(t.favoritesEmpty));
          }

          final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
          for (var i = 0; i < ids.length; i += 10) {
            final chunk = ids.sublist(
              i,
              (i + 10 > ids.length) ? ids.length : i + 10,
            );
            futures.add(
              FirebaseFirestore.instance
                  .collection('dailyFoods')
                  .where(FieldPath.documentId, whereIn: chunk)
                  .get(),
            );
          }

          return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
            future: Future.wait(futures),
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final docs = (snap.data ?? []).expand((e) => e.docs).toList();
              if (docs.isEmpty) {
                return Center(child: Text(t.favoritesEmpty));
              }

              docs.sort((a, b) {
                final da = (a.data()['date'] ?? '').toString();
                final db = (b.data()['date'] ?? '').toString();
                return db.compareTo(da);
              });

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final item = DailyFood.fromDoc(docs[i]);
                  final tr = Map<String, dynamic>.from(
                    item.translations[langCode] ??
                        item.translations['es'] ??
                        {},
                  );
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text((tr['verse'] ?? '').toString()),
                      subtitle: Text(
                        '${ellipsize((tr['description'] ?? '').toString(), 140)}\n${item.authorName} • ${item.date}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () => FS.toggleFavorite(
                          uid: user.uid,
                          foodId: item.id,
                          add: false,
                        ),
                      ),
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) =>
                            FoodDetailDialog(item: item, lang: langCode),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

