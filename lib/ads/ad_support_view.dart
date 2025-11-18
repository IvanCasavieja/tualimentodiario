import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import 'interstitial_manager.dart';

/// Muestra una explicación del impacto de los anuncios con botón al intersticial.
class AdSupportView extends ConsumerStatefulWidget {
  const AdSupportView({super.key});

  @override
  ConsumerState<AdSupportView> createState() => _AdSupportViewState();
}

class _AdSupportViewState extends ConsumerState<AdSupportView> {
  bool _loading = false;

  Future<void> _handleShowAd() async {
    if (_loading) return;
    setState(() => _loading = true);
    var shown = false;
    try {
      shown = await InterstitialAdManager.instance.showAdIfAvailable();
    } catch (_) {
      shown = false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    if (!shown) {
      final t = ref.read(stringsProvider);
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(t.adHelpUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final theme = Theme.of(context);
    final paragraphStyle = theme.textTheme.bodyMedium;
    final cardTitleStyle = theme.textTheme.bodyLarge
        ?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary);
    final cardSubtitleStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: .7));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.adSupportTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.adSupportParagraph,
              style: paragraphStyle,
            ),
            const SizedBox(height: 26),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: .6)),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: .15),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.adSupportCardTitle, style: cardTitleStyle),
                  const SizedBox(height: 6),
                  Text(t.adSupportCardSubtitle, style: cardSubtitleStyle),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleShowAd,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t.adSupportButtonLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
