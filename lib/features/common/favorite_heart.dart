import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart'; // authStateProvider, isFavoriteProvider
import '../../core/firestore_repository.dart'; // FS
import '../../core/app_state.dart'; // bottomTabIndexProvider

class FavoriteHeart extends ConsumerWidget {
  const FavoriteHeart({super.key, required this.foodId, this.iconSize = 24});

  final String foodId;
  final double iconSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.value;
    final isGuest = isGuestUser(user);
    if (isGuest) {
      return IconButton(
        iconSize: iconSize,
        tooltip: 'Agregar a favoritos',
        icon: const Icon(Icons.favorite_border),
        onPressed: () {
          ref.read(bottomTabIndexProvider.notifier).state = 2;
        },
      );
    }

    if (user == null) {
      return IconButton(
        iconSize: iconSize,
        icon: const Icon(Icons.favorite_border),
        onPressed: null,
      );
    }

    final isFavAsync =
        ref.watch(isFavoriteProvider((uid: user.uid, foodId: foodId)));

    return isFavAsync.when(
      loading: () => SizedBox(
        width: iconSize,
        height: iconSize,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (e, _) => IconButton(
        iconSize: iconSize,
        icon: const Icon(Icons.favorite_border),
        onPressed: null,
      ),
      data: (isFav) => IconButton(
        iconSize: iconSize,
        tooltip: isFav ? 'Quitar de favoritos' : 'Agregar a favoritos',
        icon: Icon(isFav ? Icons.favorite : Icons.favorite_border),
        color: isFav ? Theme.of(context).colorScheme.error : null,
        onPressed: () async {
          await FS.toggleFavorite(uid: user.uid, foodId: foodId, add: !isFav);
        },
      ),
    );
  }
}
