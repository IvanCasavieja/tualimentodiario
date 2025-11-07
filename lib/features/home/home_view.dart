import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';

// Proveedor definido en main.dart para comunicar Home -> Archivo
import '../../main.dart' show selectedFoodIdProvider, bottomTabIndexProvider;

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLang = ref.watch(languageProvider);
    final langCode = _toCode(appLang); // es | en | pt | it

    final query = FirebaseFirestore.instance
        .collection('dailyFoods')
        .where('isPublished', isEqualTo: true)
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true)
        .limit(5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Alimento Diario'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay alimentos aún.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;

              // Fecha (acepta múltiples formatos)
              final dt = _parseDate(data['date']);

              // Traducciones
              final translations =
                  (data['translations'] as Map?)?.cast<String, dynamic>() ?? {};
              final Map<String, dynamic> t = _pickLangMap(
                translations,
                primary: langCode,
                fallback: 'es',
              );

              final verse = (t['verse'] as String?)?.trim() ?? '—';
              final description = (t['description'] as String?)?.trim() ?? '—';

              return _FoodCard(
                id: id,
                verse: verse,
                description: description,
                date: dt,
                onOpen: () {
                  // Guardamos el ID seleccionado y cambiamos a la pestaña "Archivo" (índice 1)
                  ref.read(selectedFoodIdProvider.notifier).state = id;
                  ref.read(bottomTabIndexProvider.notifier).state = 1;
                },
              );
            },
          );
        },
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

class _FoodCard extends StatelessWidget {
  final String id;
  final String verse;
  final String description;
  final DateTime date;
  final VoidCallback onOpen;

  const _FoodCard({
    required this.id,
    required this.verse,
    required this.description,
    required this.date,
    required this.onOpen,
  });

  String _short(String text) =>
      text.length > 120 ? '${text.substring(0, 120)}...' : text;

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(date);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(_short(description)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
