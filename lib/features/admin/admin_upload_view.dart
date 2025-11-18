// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart'; // userIsAdminProvider
import '../../core/app_state.dart'; // languageProvider
import '../../core/i18n.dart'; // stringsProvider
import '../../core/moods_i18n.dart' show moodLabelI18n;
import '../../core/date_formats.dart';
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

  late final TabController _tabs;

  final bool _isPublished = true;
  final Set<String> _selectedMoods = {};
  bool _isSubmitting = false;
  bool _showScheduleStep = false;
  DateTime _scheduledDate = _todayMidnight();

  final Map<String, TextEditingController> _verse = {
    for (final l in langs) l: TextEditingController(),
  };
  final Map<String, TextEditingController> _title = {
    for (final l in langs) l: TextEditingController(),
  };
  final Map<String, List<TextEditingController>> _paragraphs = {
    for (final l in langs) l: [TextEditingController()],
  };
  final Map<String, TextEditingController> _prayer = {
    for (final l in langs) l: TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: langs.length, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    for (final c in _verse.values) {
      c.dispose();
    }
    for (final c in _title.values) {
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
    setState(() {});
  }

  bool _isLangValid(String lang) {
    final v = _verse[lang]!.text.trim();
    final ti = _title[lang]!.text.trim();
    final ps = _paragraphs[lang]!
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final pr = _prayer[lang]!.text.trim();
    return v.isNotEmpty && ti.isNotEmpty && ps.isNotEmpty && pr.isNotEmpty;
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
        final idx = langs.indexOf(l);
        _tabs.animateTo(idx);
        _showIncompleteMessage(l);
        return;
      }
    }

    final Map<String, dynamic> translations = {};
    for (final l in langs) {
      final verse = _verse[l]!.text.trim();
      final title = _title[l]!.text.trim();
      final paragraphs = _paragraphs[l]!
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final description = paragraphs.join('\n\n');
      final prayer = _prayer[l]!.text.trim();
      translations[l] = {
        'verse': verse,
        'title': title,
        'description': description,
        'prayer': prayer,
        'farewell': kFarewells[l] ?? '',
        'reflection': '',
      };
    }

    final dateStr = DateFormats.iso.format(_scheduledDate);
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
    final isFinalStep = _showScheduleStep;

    return Column(
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
                onPressed: _isSubmitting ? null : _handlePrimaryAction,
                icon: Icon(
                  isFinalStep ? Icons.cloud_upload : Icons.arrow_forward,
                ),
                label: Text(isFinalStep ? 'Publicar' : 'Siguiente'),
              ),
            ],
          ),
        ),
        if (!_showScheduleStep) ...[
          TabBar(
            controller: _tabs,
            isScrollable: true,
            onTap: (i) => _tabs.animateTo(i),
            tabs: langs.map((l) => Tab(text: langLabels[l])).toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: langs.map((l) {
                return _LangForm(
                  lang: l,
                  verse: _verse[l]!,
                  title: _title[l]!,
                  paragraphs: _paragraphs[l]!,
                  prayer: _prayer[l]!,
                  farewellText: kFarewells[l] ?? '',
                  onAddParagraph: () => _addParagraph(l),
                  onRemoveParagraph: (i) => _removeParagraph(l, i),
                );
              }).toList(),
            ),
          ),
        ] else ...[
          Expanded(
            child: _ScheduleStep(
              selectedDate: _scheduledDate,
              onPickDate: _pickDate,
            ),
          ),
        ],
      ],
    );
  }

  void _handlePrimaryAction() async {
    if (!_showScheduleStep) {
      final currentLang = langs[_tabs.index];
      if (!_isLangValid(currentLang)) {
        _showIncompleteMessage(currentLang);
        return;
      }
      if (_tabs.index < langs.length - 1) {
        _tabs.animateTo(_tabs.index + 1);
        return;
      }
      setState(() => _showScheduleStep = true);
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    await _submit();
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 3),
    );
    if (picked != null) {
      setState(() => _scheduledDate = _normalizeDate(picked));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Se publicará el ${DateFormats.display.format(_scheduledDate)} a las 00:00.',
          ),
        ),
      );
    }
  }

  static DateTime _todayMidnight() {
    final now = DateTime.now();
    return _normalizeDate(now);
  }

  static DateTime _normalizeDate(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  void _showIncompleteMessage(String lang) {
    final name = langLabels[lang] ?? lang;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Completa versiculo, Titular, al menos 1 parrafo y la Oracion en $name',
        ),
      ),
    );
  }
}

class _LangForm extends StatelessWidget {
  final String lang;
  final TextEditingController verse;
  final TextEditingController title;
  final List<TextEditingController> paragraphs;
  final TextEditingController prayer;
  final String farewellText;
  final VoidCallback onAddParagraph;
  final void Function(int idx) onRemoveParagraph;

  const _LangForm({
    required this.lang,
    required this.verse,
    required this.title,
    required this.paragraphs,
    required this.prayer,
    required this.farewellText,
    required this.onAddParagraph,
    required this.onRemoveParagraph,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      children: [
        Row(
          children: [
            Text('Paso: ${_title(lang)}', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),

        // Versiculo
        TextField(
          controller: verse,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Versiculo'),
        ),
        const SizedBox(height: 16),

        // Titular
        TextField(
          controller: title,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Titular'),
        ),
        const SizedBox(height: 16),

        const Text('Parrafos (Descripcion)', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        ...List.generate(paragraphs.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: paragraphs[i],
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
            label: const Text('Agregar parrafo'),
        ),
        ),
        const SizedBox(height: 16),

        // Oración (obligatoria)
        TextField(
          controller: prayer,
          maxLines: null,
          decoration: const InputDecoration(labelText: 'Oracion (obligatoria)'),
        ),
        const SizedBox(height: 16),

        // Despedida fija (read-only)
        TextFormField(
          initialValue: farewellText,
          enabled: false,
          decoration: const InputDecoration(labelText: 'Despedida (fija)'),
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

class _ScheduleStep extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onPickDate;
  const _ScheduleStep({
    required this.selectedDate,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormats.display.format(selectedDate);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      children: [
        const Text(
          'Programación de fecha',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 8),
        const Text(
          'Elegí la fecha exacta en la que el alimento debe estar disponible. '
          'Podés seleccionar fechas pasadas para cargar contenidos atrasados o fechas futuras para dejarlos programados.',
        ),
        const SizedBox(height: 24),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: const Icon(Icons.event_available),
            title: const Text('Fecha seleccionada'),
            subtitle: Text(formatted),
            trailing: FilledButton.tonalIcon(
              onPressed: onPickDate,
              icon: const Icon(Icons.edit_calendar),
              label: const Text('Cambiar'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Nota: el alimento se publicará automáticamente a las 00:00 (hora local) del día seleccionado y no estará visible antes.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

