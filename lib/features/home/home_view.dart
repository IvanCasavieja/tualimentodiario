import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart'
    show AppLang, languageProvider, selectedFoodIdProvider, bottomTabIndexProvider;
import '../../core/i18n.dart'; // stringsProvider
import '../common/favorite_heart.dart';
import '../common/moods.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  static const _bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E9FF), Color(0xFFEAF7FF)],
  );
  static const _primary = Color(0xFF6C4DF5);
  static const _accent = Color(0xFF48C1F1);

  ProviderSubscription<Set<String>>? _moodsSub;

  @override
  void initState() {
    super.initState();
    _moodsSub =
        ref.listenManual<Set<String>>(moodsFilterProvider, (prev, next) {
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
    try {
      final snap = await FirebaseFirestore.instance
          .collection('dailyFoods')
          .where('isPublished', isEqualTo: true)
          .orderBy('date', descending: true)
          .orderBy(FieldPath.documentId, descending: true)
          .limit(30)
          .get();
      if (snap.docs.isEmpty) return;
      final doc = snap.docs[Random().nextInt(snap.docs.length)];
      ref.read(selectedFoodIdProvider.notifier).state = doc.id;
      ref.read(bottomTabIndexProvider.notifier).state = 1;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir un contenido al azar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLang = ref.watch(languageProvider);
    final t = ref.watch(stringsProvider);
    final langCode = _toCode(appLang);

    return Container(
      decoration: const BoxDecoration(gradient: _bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
          centerTitle: true,
          title: Text(t.appTitle),
        ),
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
                return const Center(child: Text('No hay alimentos aÃºn.'));
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _HeroHeader(
                    title: t.headerDailyFood,
                    subtitle: t.headerSubtitle,
                    primary: _primary,
                    accent: _accent,
                    onRandom: _openRandom,
                    randomLabel: t.headerSurprise,
                    chips: const MoodChips(),
                  ),
                  const SizedBox(height: 12),
                  ...docs.map((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final id = d.id;
                    final dt = _parseDate(data['date']);
                    final translations =
                        (data['translations'] as Map?)?.cast<String, dynamic>() ??
                            {};
                    final tr = _pickLangMap(
                      translations,
                      primary: langCode,
                      fallback: 'es',
                    );
                    final verse = (tr['verse'] as String?)?.trim() ?? 'â€”';
                    final description =
                        (tr['description'] as String?)?.trim() ?? 'â€”';
                    return _FoodCard(
                      id: id,
                      verse: verse,
                      description: description,
                      date: dt,
                      primary: _primary,
                      accent: _accent,
                      onOpen: () {
                        ref.read(selectedFoodIdProvider.notifier).state = id;
                        ref.read(bottomTabIndexProvider.notifier).state = 1;
                      },
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
  final Color primary, accent;
  final VoidCallback onRandom;
  final Widget chips;

  const _HeroHeader({
    required this.title,
    required this.subtitle,
    required this.randomLabel,
    required this.primary,
    required this.accent,
    required this.onRandom,
    required this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [primary.withValues(alpha: .15), accent.withValues(alpha: .15)]),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
          _PillIconButton(icon: Icons.casino, label: randomLabel, fg: primary, onTap: onRandom),
        ]),
        const SizedBox(height: 10),
        Text(subtitle, style: TextStyle(color: Colors.black.withValues(alpha: .7), height: 1.25)),
        const SizedBox(height: 12),
        chips,
      ]),
    );
  }
}

class _PillIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color fg;
  final VoidCallback onTap;
  const _PillIconButton({required this.icon, required this.label, required this.fg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _FoodCard extends StatelessWidget {
  final String id, verse, description;
  final DateTime date;
  final VoidCallback onOpen;
  final Color primary, accent;

  const _FoodCard({
    required this.id,
    required this.verse,
    required this.description,
    required this.date,
    required this.primary,
    required this.accent,
    required this.onOpen,
  });

  String _short(String t) => t.length > 130 ? '${t.substring(0, 130)}â€¦' : t;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.white, Colors.white.withValues(alpha: .96)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12.withValues(alpha: .06), blurRadius: 14, offset: const Offset(0, 6))
        ],
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 6, height: 72, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(8))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(verse, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(_short(description), style: TextStyle(color: Colors.black.withValues(alpha: .75))),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _DateChip(text: formattedDate, icon: Icons.event, color: accent),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    FavoriteHeart(foodId: id, iconSize: 22),
                    const SizedBox(width: 4),
                    IconButton(icon: const Icon(Icons.open_in_new), onPressed: onOpen, tooltip: 'Abrir'),
                  ]),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _DateChip({required this.text, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: color.withValues(alpha: .9)),
        const SizedBox(width: 6),
        Text(text,
            style: TextStyle(fontSize: 12, color: _darken(color), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  Color _darken(Color c, [double a = .18]) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness - a).clamp(0.0, 1.0)).toColor();
  }
}

