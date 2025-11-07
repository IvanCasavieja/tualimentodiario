import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/firestore_repository.dart';
import '../../core/models/daily_food.dart';
import '../../core/app_state.dart';
import '../../core/ui_utils.dart';
import '../common/food_detail_dialog.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).asData?.value;
    final langCode = ref.watch(languageProvider).name;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Iniciá sesión para ver favoritos')));
    }

    final favIdsSnap = ref.watch(favoritesIdsProvider(user.uid));
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favIdsSnap.when(
        data: (ids) {
          if (ids.isEmpty) {
            return const Center(child: Text('No tenés favoritos aún'));
          }
          // Cargamos de a 10 por whereIn
          final futures = <Future<QuerySnapshot<Map<String, dynamic>>>>[];
          for (var i = 0; i < ids.length; i += 10) {
            final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);
            futures.add(FS.db.collection('dailyFoods').where(FieldPath.documentId, whereIn: chunk).get());
          }
          return FutureBuilder<List<QuerySnapshot<Map<String, dynamic>>>>(
            future: Future.wait(futures),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.expand((e) => e.docs).toList();
              if (docs.isEmpty) return const Center(child: Text('No se encontraron documentos'));
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final item = DailyFood.fromDoc(docs[i]);
                  final t = Map<String, dynamic>.from(item.translations[langCode] ?? item.translations['es'] ?? {});
                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text((t['verse'] ?? '').toString()),
                      subtitle: Text('${ellipsize((t['description'] ?? '').toString(), 140)}\n${item.authorName} • ${item.date}'),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite),
                        onPressed: () => FS.toggleFavorite(uid: user.uid, foodId: item.id, add: false),
                      ),
                      onTap: () => showDialog(context: context, builder: (_) => FoodDetailDialog(item: item, lang: langCode)),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
