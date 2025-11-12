// ignore_for_file: use_build_context_synchronously
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers.dart'; // userIsAdminProvider
import '../../core/app_state.dart'; // languageProvider
import '../../core/i18n.dart'; // stringsProvider
import '../../core/moods_i18n.dart'
    show moodLabelI18n; // <-- usar la misma traducciÃ³n que Home
import '../common/moods.dart' show kMoods; // lista de moods (slug, icon, color)

// Vista de administración para crear y publicar el "Alimento Diario".
// - Soporta pestañas por idioma (es, en, pt, it).
// - Permite seleccionar hasta 3 moods y valida campos requeridos.
// - Publica en Firestore (colección `dailyFoods`) con metadatos básicos.

/// Pantalla principal del panel de carga del Alimento Diario.
class AdminUploadView extends ConsumerStatefulWidget {
  const AdminUploadView({super.key});
  @override
  ConsumerState<AdminUploadView> createState() => _AdminUploadViewState();
}

// Estado de la pantalla: controla pestañas, validaciones y envío a Firestore.
class _AdminUploadViewState extends ConsumerState<AdminUploadView>
    with TickerProviderStateMixin {
  // Idiomas / tabs
  static const langs = ['es', 'en', 'pt', 'it'];
  static const langLabels = {
    'es': 'Español',
    'en': 'English',
    'pt': 'Português',
    'it': 'Italiano',
  };

  // Despedidas fijas
  static const Map<String, String> kFarewells = {
    'es': 'Bendecido Día',
    'en': 'Blessed day',
    'pt': 'Dia abençoado',
    'it': 'Giorno benedetto',
  };

  // Controlador de pestañas para alternar entre idiomas.
  late final TabController _tabs = TabController(
    length: langs.length,
    vsync: this,
  );

  /// Publicamos directo (sin switch)
  final bool _isPublished = true;

  /// SelecciÃ³n de Moods (máx. 3) â€“ GUARDAREMOS SLUGS EN Español
  final Set<String> _selectedMoods = {};

  /// Pasos completados (por idioma)
  final Set<String> _completed = {};

  // Campos por idioma
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
    setState(() => _completed.remove(lang)); // si edita, invalidamos el paso
  }

  void _markDirty(String lang) {
    if (_completed.contains(lang)) {
      setState(() => _completed.remove(lang));
    }
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
        SnackBar(content: Text('Paso \\ completado ?')),
      );
    } else {
      _tabs.index = langs.indexOf(lang);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Completá Versículo, al menos 1 párrafo y la Oración en ',
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
            final currentLang = ref
                .read(languageProvider)
                .name; // 'es'|'en'|'pt'|'it'
            String labelFor(String slug, String fallback) => moodLabelI18n(
              slug: slug,
              langCode: currentLang,
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
                          'SeleccionÃ¡ hasta 3 moods',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          '(${temp.length}/3)',
                          style: const TextStyle(color: Colors.grey),
                        ),
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
                                : const Icon(
                                    Icons.radio_button_unchecked,
                                    size: 20,
                                    color: Colors.grey,
                                  ),
                            onTap: () {
                              setSheet(() {
                                if (sel) {
                                  temp.remove(m.slug);
                                } else {
                                  if (temp.length < 3) temp.add(m.slug);
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
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
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

    debugPrint('---------------------------');
    debugPrint('ðŸ” Intentando publicar alimento diario');
    debugPrint('isAdmin (cliente): $isAdmin');
    debugPrint('UID actual: ${user?.uid}');
    debugPrint('Email: ${user?.email}');
    debugPrint('DisplayName: ${user?.displayName}');
    debugPrint('---------------------------');

    if (!isAdmin || user == null) {
      debugPrint('â›” Bloqueado localmente: no tenÃ©s permisos para publicar.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tenÃ©s permisos para publicar.')),
      );
      return;
    }

    // Validar todos los idiomas
    for (final l in langs) {
      if (!_isLangValid(l)) {
        _tabs.index = langs.indexOf(l);
        debugPrint('âš ï¸ Falta completar idioma: $l');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falta completar ${langLabels[l]}')),
        );
        return;
      }
    }

    // Construir traducciones
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

    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
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

    debugPrint('ðŸ“¤ Datos que se enviarÃ¡n a Firestore:');
    debugPrint(dataToSend.toString());
    debugPrint('---------------------------');

    try {
      await FirebaseFirestore.instance.collection('dailyFoods').add(dataToSend);
      debugPrint('âœ… Documento enviado correctamente');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alimento publicado correctamente')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      debugPrint('ðŸ”¥ ERROR al publicar en Firestore: $e');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al publicar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminAsync = ref.watch(userIsAdminProvider);
    final currentLang = ref
        .watch(languageProvider)
        .name; // por si lo necesitÃ¡s en UI

    final t = ref.watch(stringsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(t.adminUpload)),
      body: isAdminAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (isAdmin) {
          if (!isAdmin) {
            return const Center(
              child: Text('No tenés permisos para acceder a este panel.'),
            );
          }
          final completedCount = _completed.length;

          String moodLabel(String slug, String fallback) => moodLabelI18n(
            slug: slug,
            langCode: currentLang,
            fallbackLabel: fallback,
          );

          return Column(
            children: [
              // Selector de moods (select)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openMoodSelector,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Moods (máx. 3)',
                      border: const OutlineInputBorder(),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '(${_selectedMoods.length}/3)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    child: _selectedMoods.isEmpty
                        ? const Text('Toca para seleccionar')
                        : Wrap(
                            spacing: 8,
                            runSpacing: -6,
                            children: _selectedMoods.map((slug) {
                              final base = kMoods.firstWhere(
                                (m) => m.slug == slug,
                              );
                              final label = moodLabel(slug, base.label);
                              return Chip(
                                label: Text(label),
                                onDeleted: () => setState(() {
                                  _selectedMoods.remove(slug);
                                }),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),

              // Tabs alineados a la izquierda
              Align(
                alignment: Alignment.centerLeft,
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                  indicatorPadding: const EdgeInsets.only(left: 8, right: 8),
                  tabs: [for (final l in langs) Tab(text: langLabels[l])],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    for (final l in langs)
                      _LangForm(
                        lang: l,
                        verse: _verse[l]!,
                        paragraphs: _paragraphs[l]!,
                        prayer: _prayer[l]!,
                        farewellText: kFarewells[l] ?? '',
                        isCompleted: _completed.contains(l),
                        onAddParagraph: () => _addParagraph(l),
                        onRemoveParagraph: (i) => _removeParagraph(l, i),
                        onDirty: () => _markDirty(l),
                        onValidateAndComplete: () => _validateAndComplete(l),
                      ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pasos completados $completedCount de ${langs.length}',
                          style: TextStyle(
                            color: completedCount == langs.length
                                ? Colors.green[700]
                                : Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: completedCount == langs.length
                            ? _submit
                            : null,
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text('Publicar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LangForm extends StatelessWidget {
  const _LangForm({
    required this.lang,
    required this.verse,
    required this.paragraphs,
    required this.prayer,
    required this.farewellText,
    required this.isCompleted,
    required this.onAddParagraph,
    required this.onRemoveParagraph,
    required this.onDirty,
    required this.onValidateAndComplete,
  });

  final String lang;
  final TextEditingController verse;
  final List<TextEditingController> paragraphs;
  final TextEditingController prayer;
  final String farewellText;
  final bool isCompleted;
  final VoidCallback onAddParagraph;
  final void Function(int idx) onRemoveParagraph;
  final VoidCallback onDirty;
  final VoidCallback onValidateAndComplete;

  @override
  Widget build(BuildContext context) {
    final badge = isCompleted
        ? Row(
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
            Text(
              'Paso: ${_title(lang)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 6),
            badge,
          ],
        ),
        const SizedBox(height: 12),

        // VersÃ­culo
        TextField(
          controller: verse,
          onChanged: (_) => onDirty(),
          decoration: const InputDecoration(labelText: 'VersÃ­culo'),
        ),
        const SizedBox(height: 12),

        const Text(
          'PÃ¡rrafos (DescripciÃ³n)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                    decoration: InputDecoration(labelText: 'PÃ¡rrafo ${i + 1}'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: paragraphs.length > 1
                      ? 'Eliminar'
                      : 'No se puede eliminar',
                  onPressed: paragraphs.length > 1
                      ? () => onRemoveParagraph(i)
                      : null,
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
            label: const Text('Agregar pÃ¡rrafo'),
          ),
        ),
        const SizedBox(height: 8),

        // OraciÃ³n (obligatoria)
        TextField(
          controller: prayer,
          onChanged: (_) => onDirty(),
          maxLines: null,
          decoration: const InputDecoration(labelText: 'OraciÃ³n (obligatoria)'),
        ),
        const SizedBox(height: 12),

        // Despedida fija (read-only)
        TextField(
          controller: TextEditingController(text: farewellText),
          enabled: false,
          decoration: const InputDecoration(labelText: 'Despedida (fija)'),
        ),
        const SizedBox(height: 16),

        // BotÃ³n completar paso
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
        return 'PortuguÃªs';
      case 'it':
        return 'Italiano';
    }
    return lang;
  }
}












