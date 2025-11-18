import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import 'ad_support_view.dart';

/// Navega a la pantalla con la explicación y el banner contenido.
class WatchAdButton extends ConsumerWidget {
  const WatchAdButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final foreground = theme.appBarTheme.foregroundColor ??
        theme.colorScheme.onPrimary;
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        visualDensity: VisualDensity.compact,
      ),
      icon: const Icon(Icons.volunteer_activism),
      label: Text(t.adCollaborationLabel),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AdSupportView()),
      ),
    );
  }
}
