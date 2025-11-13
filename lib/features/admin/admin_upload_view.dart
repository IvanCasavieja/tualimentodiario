// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart'; // userIsAdminProvider
import '../../core/app_state.dart'; // languageProvider
import '../../core/i18n.dart'; // stringsProvider
import '../../core/moods_i18n.dart' show moodLabelI18n;
import '../common/moods.dart' show kMoods; // lista de moods (slug, icon, color)

/// Admin: crear y publicar el "Alimento Diario" (ES/EN/PT/IT)
class AdminUploadView extends ConsumerStatefulWidget {
  const AdminUploadView({super.key});
  @override
  ConsumerState<AdminUploadView> createState() => _AdminUploadViewState();
}

class _AdminUploadViewState extends ConsumerState<AdminUploadView>
    with TickerProviderStateMixin {
  static const langs = ['es', 'en', 'pt', 'it'];
  static const langLabels = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'it': 'Italiano',
  };

  static const Map<String, String> kFarewells = {
    'es': 'Bendecido día',
    'en': 'Blessed day',
    'pt': 'Dia abençoado',
    'it': 'Giorno benedetto',
  };

  static final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');

  late final TabController _tabs = TabController(length: langs.length, vsync: this);

  final bool _isPublished = true;
  final Set<String> _selectedMoods = {};
  final Set<String> _completed = {};

  final Map<String, TextEditingController> _verse = {
    for (final l in langs) l: TextEditingController(),
  };
  final Map<String, List<TextEditingController>> _paragraphs = {
    for (final l in langs) l: [TextEditingController()],
  };
  final Map<String, TextEditingController> _prayer = {
    for (final l in langs) l: TextEditingController(),
  };

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in _verse.values) {
      c.dispose();
    }
    for (final list in _paragraphs.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final c in _prayer.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _addParagraph(String lang) {
    setState(() => _paragraphs[lang]!.add(TextEditingController()));
  }

  void _removeParagraph(String lang, int idx) {
    if (_paragraphs[lang]!.length <= 1) return;
    final c = _paragraphs[lang]!.removeAt(idx);
    c.dispose();
    setState(() => _completed.remove(lang));
  }

  void _markDirty(String lang) {
    if (_completed.contains(lang)) setState(() => _completed.remove(lang));
  }

  bool _isLangValid(String lang) {
    final v = _verse[lang]!.text.trim();
    final ps = _paragraphs[lang]!
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final pr = _prayer[lang]!.text.trim();
    return v.isNotEmpty && ps.isNotEmpty && pr.isNotEmpty;
  }

  void _validateAndComplete(String lang) {
    if (_isLangValid(lang)) {
      setState(() => _completed.add(lang));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paso completado')),
      );
    } else {
      _tabs.index = langs.indexOf(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completá Versículo, al menos 1 párrafo y la Oración en ${langLabels[lang]}',
          ),
        ),
      );
    }
  }

  Future<void> _openMoodSelector() async {
    final temp = Set<String>.from(_selectedMoods);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            final langCode = ref.read(languageProvider).name; // 'es'|'en'|'pt'|'it'
            String labelFor(String slug, String fallback) => moodLabelI18n(
                  slug: slug,
                  langCode: langCode,
                  fallbackLabel: fallback,
                );
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Seleccioná hasta 3 moods',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text('(${temp.length}/3)', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: kMoods.length,
                        itemBuilder: (_, i) {
                          final m = kMoods[i];
                          final sel = temp.contains(m.slug);
                          return ListTile(
                            dense: true,
                            title: Text(labelFor(m.slug, m.label)),
                            trailing: sel
                                ? const Icon(Icons.check_circle, size: 20)
                                : const Icon(Icons.radio_button_unchecked, size: 20, color: Colors.grey),
                            onTap: () {
                              setSheet(() {
                                if (sel) {
                                  temp.remove(m.slug);
                                } else if (temp.length < 3) {
                                  temp.add(m.slug);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                        const Spacer(),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _selectedMoods
                                ..clear()
                                ..addAll(temp);
                            });
                            Navigator.pop(ctx);
                          },
                          child: const Text('Listo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final isAdmin = ref.read(userIsAdminProvider).value ?? false;
    final user = FirebaseAuth.instance.currentUser;
    if (!isAdmin || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenés permisos para publicar.')),
      );
      return;
    }

    for (final l in langs) {
      if (!_isLangValid(l)) {
        _tabs.index = langs.indexOf(l);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falta completar ${langLabels[l]}')),
        );
        return;
      }
    }

    final Map<String, dynamic> translations = {};
    for (final l in langs) {
      final verse = _verse[l]!.text.trim();
      final paragraphs = _paragraphs[l]!
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final description = paragraphs.join('\n\n');
      final prayer = _prayer[l]!.text.trim();
      translations[l] = {
        'verse': verse,
        'description': description,
        'prayer': prayer,
        'farewell': kFarewells[l] ?? '',
        'reflection': '',
      };
    }

    final dateStr = _dateFormatter.format(DateTime.now());
    final dataToSend = {
      'date': dateStr,
      'authorUid': user.uid,
      'authorName': user.displayName ?? (user.email ?? 'Admin'),
      'isPublished': _isPublished,
      if (_selectedMoods.isNotEmpty) 'moods': _selectedMoods.toList(),
      'stats': {'favoritesCount': 0},
      'translations': translations,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('dailyFoods').add(dataToSend);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alimento publicado correctamente')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(userIsAdminProvider);
    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.adminUpload)),
      body: isAdminAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (isAdmin) => isAdmin == true
            ? _buildForm(context)
            : const Center(child: Text('No tenés permisos para publicar.')),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return DefaultTabController(
      length: langs.length,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _openMoodSelector,
                  icon: const Icon(Icons.emoji_emotions_outlined),
                  label: Text('Moods (${_selectedMoods.length}/3)'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Publicar'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabs,
            isScrollable: true,
            tabs: langs.map((l) => Tab(text: langLabels[l])).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: langs.map((l) {
                return _LangForm(
                  lang: l,
                  verse: _verse[l]!,
                  paragraphs: _paragraphs[l]!,
                  prayer: _prayer[l]!,
                  farewellText: kFarewells[l] ?? '',
                  onAddParagraph: () => _addParagraph(l),
                  onRemoveParagraph: (i) => _removeParagraph(l, i),
                  onDirty: () => _markDirty(l),
                  onValidateAndComplete: () => _validateAndComplete(l),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LangForm extends StatelessWidget {
  final String lang;
  final TextEditingController verse;
  final List<TextEditingController> paragraphs;
  final TextEditingController prayer;
  final String farewellText;
  final VoidCallback onAddParagraph;
  final void Function(int idx) onRemoveParagraph;
  final VoidCallback onDirty;
  final VoidCallback onValidateAndComplete;

  const _LangForm({
    required this.lang,
    required this.verse,
    required this.paragraphs,
    required this.prayer,
    required this.farewellText,
    required this.onAddParagraph,
    required this.onRemoveParagraph,
    required this.onDirty,
    required this.onValidateAndComplete,
  });

  @override
  Widget build(BuildContext context) {
    final badge = paragraphs.any((c) => c.text.trim().isNotEmpty) &&
            verse.text.trim().isNotEmpty &&
            prayer.text.trim().isNotEmpty
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 6),
              Icon(Icons.verified, size: 16, color: Colors.green),
            ],
          )
        : const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Row(
          children: [
            Text('Paso: ${_title(lang)}', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(width: 6),
            badge,
          ],
        ),
        const SizedBox(height: 12),

        // Versículo
        TextField(
          controller: verse,
          onChanged: (_) => onDirty(),
          decoration: const InputDecoration(labelText: 'Versículo'),
        ),
        const SizedBox(height: 12),

        const Text('Párrafos (Descripción)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...List.generate(paragraphs.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: paragraphs[i],
                    onChanged: (_) => onDirty(),
                    maxLines: null,
                    decoration: InputDecoration(labelText: 'Párrafo ${i + 1}'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: paragraphs.length > 1 ? 'Eliminar' : 'No se puede eliminar',
                  onPressed: paragraphs.length > 1 ? () => onRemoveParagraph(i) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ],
            ),
          );
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onAddParagraph,
            icon: const Icon(Icons.add),
            label: const Text('Agregar párrafo'),
          ),
        ),
        const SizedBox(height: 8),

        // Oración (obligatoria)
        TextField(
          controller: prayer,
          onChanged: (_) => onDirty(),
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Oración (obligatoria)'),
        ),
        const SizedBox(height: 12),

        // Despedida fija (read-only)
        TextFormField(
          initialValue: farewellText,
          enabled: false,
          decoration: const InputDecoration(labelText: 'Despedida (fija)'),
        ),
        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: onValidateAndComplete,
            icon: const Icon(Icons.check_circle),
            label: const Text('Marcar paso como completado'),
          ),
        ),
      ],
    );
  }

  String _title(String lang) {
    switch (lang) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      case 'pt':
        return 'Português';
      case 'it':
        return 'Italiano';
    }
    return lang;
  }
}
