import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/daily_food.dart';
import '../../core/ui_utils.dart';
import '../../core/text_filters.dart'; // normalizeDisplayText
import '../../core/i18n.dart'; // stringsProvider
import '../common/favorite_heart.dart';

class FoodDetailDialog extends ConsumerStatefulWidget {
  const FoodDetailDialog({super.key, required this.item, required this.lang});

  final DailyFood item;
  final String lang;

  @override
  ConsumerState<FoodDetailDialog> createState() => _FoodDetailDialogState();
}

class _FoodDetailDialogState extends ConsumerState<FoodDetailDialog>
    with SingleTickerProviderStateMixin {
  final _scrollCtrl = ScrollController();
  bool _canScroll = false;
  bool _atEnd = false;

  late final AnimationController _hintAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _hintOffset = Tween<double>(
    begin: 0,
    end: 6,
  ).animate(CurvedAnimation(parent: _hintAnim, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      final canScroll = _scrollCtrl.position.maxScrollExtent > 0;
      setState(() {
        _canScroll = canScroll;
        _atEnd =
            _scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 2;
      });
    });
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final atEnd =
        _scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 2;
    if (atEnd != _atEnd) setState(() => _atEnd = atEnd);
  }

  @override
  void dispose() {
    _hintAnim.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _pickLang(Map<String, dynamic> translations) {
    if (translations[widget.lang] is Map) {
      return (translations[widget.lang] as Map).cast<String, dynamic>();
    }
    if (translations['es'] is Map) {
      return (translations['es'] as Map).cast<String, dynamic>();
    }
    for (final v in translations.values) {
      if (v is Map) return v.cast<String, dynamic>();
    }
    return const {};
  }

  String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);

    final item = widget.item;
    final tr = _pickLang(Map<String, dynamic>.from(item.translations));
    final verse = normalizeDisplayText((tr['verse'] ?? '').toString().trim());
    final description =
        normalizeDisplayText((tr['description'] ?? '').toString().trim());
    final prayer = normalizeDisplayText((tr['prayer'] ?? '').toString().trim());
    final reflection =
        normalizeDisplayText((tr['reflection'] ?? '').toString().trim());
    final farewell = langFarewell(widget.lang);

    final meta = (item.date.isNotEmpty) ? _formatDate(item.date) : '';

    final mq = MediaQuery.of(context);
    final maxWidth = mq.size.width.clamp(320.0, 560.0);
    final maxHeight = mq.size.height * 0.82;
    final contentScrollMaxHeight = (maxHeight - 140).clamp(140.0, 800.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      verse.isEmpty ? 'â€”' : verse,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FavoriteHeart(foodId: item.id, iconSize: 24),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: t.close,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    meta,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Content with scroll
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: contentScrollMaxHeight),
                child: Stack(
                  children: [
                    Scrollbar(
                      controller: _scrollCtrl,
                      thumbVisibility: false,
                      child: SingleChildScrollView(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.only(right: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (description.isNotEmpty) ...[
                              Text(
                                normalizeDisplayText(description),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (reflection.isNotEmpty) ...[
                              Text(
                                normalizeDisplayText(reflection),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (prayer.isNotEmpty) ...[
                              Text(
                                t.prayerTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                normalizeDisplayText(prayer),
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(
                              '$farewell.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).colorScheme.primary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),

                    // Scroll hint
                    if (_canScroll && !_atEnd) ...[
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  (Theme.of(
                                            context,
                                          ).dialogTheme.backgroundColor ??
                                          Colors.white)
                                      .withValues(alpha: 0.0),
                                  (Theme.of(
                                            context,
                                          ).dialogTheme.backgroundColor ??
                                          Colors.white)
                                      .withValues(alpha: 0.9),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _hintAnim,
                            builder: (context, _) {
                              return Transform.translate(
                                offset: Offset(0, _hintOffset.value),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      t.scrollHint,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
