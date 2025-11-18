import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart'; // authStateProvider, favoritesIdsProvider
import '../../core/firestore_repository.dart';
import '../../core/app_state.dart';
import '../../core/daily_food_translations.dart';
import '../../core/ui_utils.dart';
import '../../core/i18n.dart'; // stringsProvider
import '../common/food_detail_dialog.dart';
import '../../ads/watch_ad_button.dart';

class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);

    final user = ref.watch(authStateProvider).value;
    final langCode = ref.watch(languageProvider).name;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(t.favoritesTitle),
          actions: const [WatchAdButton()],
        ),
        body: Center(child: Text(t.favoritesNeedLogin)),
      );
    }

    final favIds = ref.watch(favoritesIdsProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.favoritesTitle),
        actions: const [WatchAdButton()],
      ),
      body: favIds.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (ids) {
          if (ids.isEmpty) return Center(child: Text(t.favoritesEmpty));
          final foodsAsync = ref.watch(favoriteFoodsProvider(ids));
          return foodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (foods) {
              if (foods.isEmpty) {
                return Center(child: Text(t.favoritesEmpty));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: foods.length,
                itemBuilder: (ctx, i) {
                  final item = foods[i];
                  final tr = Map<String, dynamic>.from(
                    pickDailyFoodTranslation(
                      item.translations,
                      primary: langCode,
                    ),
                  );
                  final verse = (tr['verse'] ?? '').toString().trim();
                  final title = (tr['title'] ?? '').toString().trim();
                  final headline = title.isNotEmpty ? title : verse;
                  final description = ellipsize(
                    (tr['description'] ?? '').toString(),
                    140,
                  );
                  final subtitleBuffer = StringBuffer();
                  if (verse.isNotEmpty && verse != headline) {
                    subtitleBuffer.writeln(verse);
                    subtitleBuffer.writeln();
                  }
                  subtitleBuffer
                    ..writeln(description)
                    ..write('${item.authorName} - ${item.date}');
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(headline),
                      subtitle: Text(subtitleBuffer.toString()),
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
