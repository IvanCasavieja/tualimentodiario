import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart'
    show
        AppLang,
        languageProvider,
        selectedFoodIdProvider,
        bottomTabIndexProvider;
import '../../core/i18n.dart'; // stringsProvider
import '../../core/tema.dart'; // AppExtras
import '../../core/text_filters.dart'; // normalizeDisplayText
import '../common/favorite_heart.dart';
import '../common/moods.dart';
import '../../core/models/daily_food.dart';
import '../common/food_detail_dialog.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  ProviderSubscription<Set<String>>? _moodsSub;
  bool _randomInFlight = false;

  @override
  void initState() {
    super.initState();
    _moodsSub = ref.listenManual<Set<String>>(moodsFilterProvider, (
      prev,
      next,
    ) {
      final had = (prev ?? {}).isNotEmpty;
      final has = next.isNotEmpty;
      if (has && (!had || (prev!.first != next.first))) {
        ref.read(bottomTabIndexProvider.notifier).state = 1; // Archivo
      }
    });
  }

  @override
  void dispose() {
    _moodsSub?.close();
    super.dispose();
  }

  Query<Map<String, dynamic>> _latest5Query() => FirebaseFirestore.instance
      .collection('dailyFoods')
      .where('isPublished', isEqualTo: true)
      .orderBy('date', descending: true)
      .orderBy(FieldPath.documentId, descending: true)
      .limit(5);

  Future<void> _openRandom() async {
    if (_randomInFlight) return;
    _randomInFlight = true;
    try {
      // Rango fijo: del 1 de agosto al 31 de octubre (año actual)
      final now = DateTime.now();
      final startMonth = DateTime(now.year, 8, 1);
      final endMonth = DateTime(now.year, 10, 31);
      final startStr = DateFormat('yyyy-MM-dd').format(startMonth);
      final endStr = DateFormat('yyyy-MM-dd').format(endMonth);

      final snap = await FirebaseFirestore.instance
          .collection('dailyFoods')
          .where('isPublished', isEqualTo: true)
          .where('date', isGreaterThanOrEqualTo: startStr)
          .where('date', isLessThanOrEqualTo: endStr)
          .orderBy('date', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(100)
          .get();
      if (snap.docs.isEmpty) return;
      final doc = snap.docs[Random().nextInt(snap.docs.length)];
      final item = DailyFood.fromDoc(doc);
      final lang = _toCode(ref.read(languageProvider));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => FoodDetailDialog(item: item, lang: lang),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir un contenido al azar: $e')),
      );
    } finally {
      _randomInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLang = ref.watch(languageProvider);
    final t = ref.watch(stringsProvider);
    final langCode = _toCode(appLang);

    final scheme = Theme.of(context).colorScheme;
    final extras = Theme.of(context).extension<AppExtras>()!;
    final text = Theme.of(context).textTheme; // ignore: unused_local_variable

    return Container(
      // fondo según tema (mantiene tu estilo en claro)
      decoration: BoxDecoration(gradient: extras.homeBackground),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(centerTitle: true, title: Text(t.appTitle)),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: _latest5Query().snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              final docs = snap.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No hay alimentos diarios.'));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroHeader(
                    title: t.headerDailyFood,
                    subtitle: t.headerSubtitle,
                    onRandom: _openRandom,
                    randomLabel: t.headerSurprise,
                    randomEnabled: !_randomInFlight,
                  ),
                  const SizedBox(height: 12),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final id = d.id;
                    final dt = _parseDate(data['date']);
                    final translations =
                        (data['translations'] as Map?)
                            ?.cast<String, dynamic>() ??
                        {};
                    final tr = _pickLangMap(
                      translations,
                      primary: langCode,
                      fallback: 'es',
                    );
                    final verse =
                        (tr['verse'] as String?)?.trim().trimRight() ?? '—';
                    final description =
                        (tr['description'] as String?)?.trim().trimRight() ??
                        '—';

                    return _FoodCard(
                      id: id,
                      verse: verse,
                      description: description,
                      date: dt,
                      onOpen: () {
                        ref.read(selectedFoodIdProvider.notifier).state = id;
                        ref.read(bottomTabIndexProvider.notifier).state = 1;
                      },
                      // colores desde esquema
                      accent: scheme.tertiary,
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _toCode(AppLang l) {
    switch (l) {
      case AppLang.es:
        return 'es';
      case AppLang.en:
        return 'en';
      case AppLang.pt:
        return 'pt';
      case AppLang.it:
        return 'it';
    }
  }

  static Map<String, dynamic> _pickLangMap(
    Map<String, dynamic> translations, {
    required String primary,
    required String fallback,
  }) {
    if (translations[primary] is Map) {
      return (translations[primary] as Map).cast<String, dynamic>();
    }
    if (translations[fallback] is Map) {
      return (translations[fallback] as Map).cast<String, dynamic>();
    }
    for (final v in translations.values) {
      if (v is Map) return v.cast<String, dynamic>();
    }
    return const {};
  }

  static DateTime _parseDate(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) {
      final isSeconds = raw < 2000000000;
      return DateTime.fromMillisecondsSinceEpoch(isSeconds ? raw * 1000 : raw);
    }
    if (raw is String) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
      for (final p in ['dd/MM/yyyy', 'd/M/yyyy']) {
        try {
          return DateFormat(p).parseStrict(raw);
        } catch (_) {}
      }
      try {
        return DateFormat('dd-MM-yyyy').parseStrict(raw);
      } catch (_) {}
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _HeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String randomLabel;
  final VoidCallback onRandom;
  final bool randomEnabled;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.randomLabel,
    required this.onRandom,
    this.randomEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final extras = Theme.of(context).extension<AppExtras>()!;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: extras.heroGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _PillIconButton(
                icon: Icons.casino,
                label: randomLabel,
                fg: scheme.primary,
                onTap: randomEnabled ? onRandom : null,
                bg: extras.pillBg,
                enabled: randomEnabled,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: text.bodySmall?.copyWith(
              color: extras.subtleText,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          const MoodChips(),
        ],
      ),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;
  final bool enabled;
  const _PillIconButton({
    required this.icon,
    required this.label,
    required this.fg,
    required this.bg,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: enabled ? fg : fg.withValues(alpha: .4),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: enabled ? fg : fg.withValues(alpha: .4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final String id, verse, description;
  final DateTime date;
  final VoidCallback onOpen;
  final Color accent;

  const _FoodCard({
    required this.id,
    required this.verse,
    required this.description,
    required this.date,
    required this.onOpen,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: .35)
        : Colors.black12.withValues(alpha: .06);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: shadow, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      normalizeDisplayText(verse),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      normalizeDisplayText(description),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: .80)
                            : Colors.black.withValues(alpha: .75),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DateChip(
                          text: formattedDate,
                          icon: Icons.event,
                          color: accent,
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FavoriteHeart(foodId: id, iconSize: 22),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: onOpen,
                              tooltip: 'Abrir',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _DateChip({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color.withValues(alpha: .9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: _darken(color),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _darken(Color c, [double a = .18]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }
}
