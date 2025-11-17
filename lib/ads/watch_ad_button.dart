import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/i18n.dart';
import 'interstitial_manager.dart';

class WatchAdButton extends ConsumerStatefulWidget {
  const WatchAdButton({super.key});

  @override
  ConsumerState<WatchAdButton> createState() => _WatchAdButtonState();
}

class _WatchAdButtonState extends ConsumerState<WatchAdButton> {
  bool _loading = false;

  Future<void> _handleTap() async {
    if (_loading) return;
    setState(() => _loading = true);
    bool shown = false;
    try {
      shown = await InterstitialAdManager.instance.showAdIfAvailable();
    } catch (_) {
      shown = false;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    if (!mounted) return;
    if (!shown) {
      final t = ref.read(stringsProvider);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(t.adHelpUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    return IconButton(
      icon: _loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ondemand_video_outlined),
      onPressed: _loading ? null : _handleTap,
      tooltip: t.adHelpLabel,
    );
  }
}
