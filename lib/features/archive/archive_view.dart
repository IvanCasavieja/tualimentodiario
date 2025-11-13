import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart'; // languageProvider, selectedFoodIdProvider
import '../../core/models/daily_food.dart';
import '../../core/ui_utils.dart'; // ellipsize
import '../../core/text_filters.dart'; // normalizeDisplayText
import '../../core/i18n.dart'; // stringsProvider
import '../../core/share_helper.dart';
import '../common/food_detail_dialog.dart';
import '../common/favorite_heart.dart';
import '../common/moods.dart';

class ArchiveView extends ConsumerStatefulWidget {
  final String? initialFoodId;
  const ArchiveView({super.key, this.initialFoodId});

  @override
  ConsumerState<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends ConsumerState<ArchiveView> {
  static const int _pageSize = 10;
  static const int _pagerWindow = 5;

  int _totalCount = 0;
  int _totalPages = 0;
  int _currentPage = 1;

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageCursors = [];
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];

  bool _loading = false;
  String? _error;
  String? _rawError;

  // Serializa aperturas por ID para evitar carreras al spamear "azar".
  bool _openingById = false;
  String? _queuedOpenId;

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  String get _langCode => _toCode(ref.read(languageProvider));

  ProviderSubscription<String?>? _selSub;
  ProviderSubscription<Set<String>>? _moodsSub;

  Query<Map<String, dynamic>> _baseQuery() {
    return FirebaseFirestore.instance
        .collection('dailyFoods')
        .where('isPublished', isEqualTo: true)
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  @override
  void initState() {
    super.initState();

    _selSub = ref.listenManual<String?>(selectedFoodIdProvider, (
      prev,
      next,
    ) async {
      if (next != null) {
        _enqueueOpenById(next);
      }
    });

    _moodsSub = ref.listenManual<Set<String>>(moodsFilterProvider, (
      prev,
      next,
    ) {
      _applyFilter();
    });

    final pending = ref.read(selectedFoodIdProvider);
    if (pending != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _enqueueOpenById(pending);
      });
    }

    _fetchCount().then((_) => _loadPage(1)).then((_) async {
      if (widget.initialFoodId != null) {
        await _openById(widget.initialFoodId!);
      }
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    _selSub?.close();
    _moodsSub?.close();
    super.dispose();
  }

  Query<Map<String, dynamic>> _filteredQuery() {
    var q = _baseQuery();

    final f = _fromCtrl.text.trim();
    final t = _toCtrl.text.trim();
    if (f.isNotEmpty) q = q.where('date', isGreaterThanOrEqualTo: f);
    if (t.isNotEmpty) q = q.where('date', isLessThanOrEqualTo: t);

    final moods = ref.read(moodsFilterProvider);
    if (moods.isNotEmpty) {
      q = q.where('moods', arrayContains: moods.first);
    }
    return q;
  }

  Future<void> _fetchCount() async {
    try {
      _setError(null, null);
      final snap = await _filteredQuery().count().get();
      _totalCount = snap.count ?? 0;
      _totalPages = _totalCount == 0
          ? 1
          : ((_totalCount + _pageSize - 1) ~/ _pageSize);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      _handleFirestoreError(e, context: 'contando documentos');
      if (!mounted) return;
      setState(() {
        _totalCount = 0;
        _totalPages = 1;
      });
    }
  }

  Future<void> _loadPage(int targetPage) async {
    if (_loading) {
      await _waitWhileLoading(maxWait: const Duration(seconds: 8));
    }
    setState(() {
      _loading = true;
      _items.clear();
      _setError(null, null);
    });

    try {
      if (targetPage < 1) targetPage = 1;
      if (targetPage > _totalPages) targetPage = _totalPages;

      while (_pageCursors.length < targetPage - 1) {
        final prevIdx = _pageCursors.length;
        final prevCursor = prevIdx == 0 ? null : _pageCursors[prevIdx - 1];
        var q = _filteredQuery().limit(_pageSize);
        if (prevCursor != null) q = q.startAfterDocument(prevCursor);
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        _pageCursors.add(snap.docs.last);
      }

      final prevCursor = targetPage == 1 ? null : _pageCursors[targetPage - 2];
      var q = _filteredQuery().limit(_pageSize);
      if (prevCursor != null) q = q.startAfterDocument(prevCursor);
      final pageSnap = await q.get();

      _items
        ..clear()
        ..addAll(pageSnap.docs);
      _currentPage = targetPage;

      if (_pageCursors.length < targetPage) {
        if (pageSnap.docs.isNotEmpty) {
          _pageCursors.add(pageSnap.docs.last);
        } else if (prevCursor != null) {
          _pageCursors.add(prevCursor);
        }
      }
    } catch (e) {
      _handleFirestoreError(e, context: 'cargando página');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyFilter() async {
    _pageCursors.clear();
    await _fetchCount();
    await _loadPage(1);
  }

  Future<void> _openById(String id) async {
    final local = _items.indexWhere((d) => d.id == id);
    if (local >= 0) {
      _openDetail(_items[local]);
      return;
    }
    final start = _currentPage;

    for (int p = start; p <= _totalPages; p++) {
      if (p != _currentPage) await _loadPage(p);
      final idx = _items.indexWhere((d) => d.id == id);
      if (idx >= 0) {
        _openDetail(_items[idx]);
        return;
      }
    }

    if (start != 1) {
      for (int p = 1; p < start; p++) {
        await _loadPage(p);
        final idx = _items.indexWhere((d) => d.id == id);
        if (idx >= 0) {
          _openDetail(_items[idx]);
          return;
        }
      }
    }

    // Fallback: intenta obtener el documento directo por ID
    try {
      final doc = await FirebaseFirestore.instance
          .collection('dailyFoods')
          .doc(id)
          .get();
      if (doc.exists) {
        final map = doc.data();
        final data = (map is Map)
            ? Map<String, dynamic>.from(map as Map)
            : <String, dynamic>{};
        if (data.isEmpty || data['isPublished'] == true) {
          final stats = data['stats'];
          final favs = (stats is Map ? stats['favoritesCount'] : 0) ?? 0;
          final item = DailyFood(
            id: id,
            date: data['date'] ?? '',
            authorUid: data['authorUid'] ?? '',
            authorName: data['authorName'] ?? '',
            isPublished: data['isPublished'] ?? false,
            translations: Map<String, dynamic>.from(data['translations'] ?? {}),
            favoritesCount: favs is int ? favs : int.tryParse('$favs') ?? 0,
          );
          final lang = _langCode;
          if (mounted) {
            // ignore: use_build_context_synchronously
            showDialog(
              context: context,
              builder: (_) => FoodDetailDialog(item: item, lang: lang),
            );
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el alimento con los filtros actuales.'),
        ),
      );
    }
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

  String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  DateTime? _tryParseYMD(String s) {
    try {
      return DateFormat('yyyy-MM-dd').parseStrict(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickDateFor(TextEditingController ctrl) async {
    final initial = _tryParseYMD(ctrl.text) ?? DateTime.now();
    final first = DateTime(2000, 1, 1);
    final last = DateTime(2100, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) || initial.isAfter(last)
          ? DateTime.now()
          : initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Seleccioná la fecha',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      useRootNavigator: true,
      builder: (ctx, child) {
        return Localizations.override(
          context: ctx,
          locale: Locale(_langCode),
          child: child,
        );
      },
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void _openDetail(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final item = DailyFood.fromDoc(doc);
    final lang = _langCode;
    showDialog(
      context: context,
      builder: (_) => FoodDetailDialog(item: item, lang: lang),
    );
  }

  // Serializa aperturas por ID provenientes de Random o toques rápidos.
  void _enqueueOpenById(String id) {
    _queuedOpenId = id; // coalesce: quedarse con el último
    if (!_openingById) {
      _processOpenQueue();
    }
  }

  Future<void> _processOpenQueue() async {
    _openingById = true;
    try {
      while (_queuedOpenId != null) {
        final id = _queuedOpenId!;
        _queuedOpenId = null;
        await _waitWhileLoading();
        await _openById(id);
        ref.read(selectedFoodIdProvider.notifier).state = null;
      }
    } finally {
      _openingById = false;
    }
  }

  Future<void> _waitWhileLoading({Duration maxWait = const Duration(seconds: 10)}) async {
    final start = DateTime.now();
    while (_loading) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (DateTime.now().difference(start) > maxWait) {
        if (mounted) {
          setState(() {
            _loading = false; // reseteo defensivo si algo quedó colgado
          });
        }
        break;
      }
    }
  }


  // ============================================

  void _setError(String? userMessage, String? raw) {
    _error = userMessage;
    _rawError = raw;
  }

  void _handleFirestoreError(Object e, {required String context}) {
    final msg = e.toString();
    if (msg.contains('FAILED_PRECONDITION') &&
        (msg.contains('requires an index') ||
            msg.contains('index is currently building'))) {
      _setError(
        'El filtro por estados de ánimo necesita un índice de Firestore y '
        'ese índice todavía se está construyendo. Cuando quede listo, '
        'los resultados aparecerán ordenados por fecha (10 por página).',
        msg,
      );
    } else {
      _setError('Error $context: $e', msg);
    }
  }

  void _clearMood() {
    ref.read(moodsFilterProvider.notifier).state = {};
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final t = ref.watch(stringsProvider);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Rebuild si cambia idioma y/moods
    ref.watch(languageProvider);
    final selected = ref.watch(moodsFilterProvider);
    final activeSlug = selected.isEmpty ? null : selected.first;
    final activeMood = activeSlug == null ? null : moodBySlug(activeSlug);

    final subtleBorder = Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.black12;
    final shadow = Theme.of(context).brightness == Brightness.dark
        ? Colors.black.withValues(alpha: .35)
        : Colors.black12.withValues(alpha: .06);

    return Scaffold(
      appBar: AppBar(title: Text(t.archiveTitle)),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        controller: _fromCtrl,
                        label: t.filterFrom,
                        onPick: () => _pickDateFor(_fromCtrl),
                        onClear: () {
                          _fromCtrl.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateField(
                        controller: _toCtrl,
                        label: t.filterTo,
                        onPick: () => _pickDateFor(_toCtrl),
                        onClear: () {
                          _toCtrl.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _loading ? null : _applyFilter,
                      icon: const Icon(Icons.filter_alt),
                      label: Text(t.filterBtn),
                    ),
                  ],
                ),
                if (activeMood != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      avatar: Icon(
                        activeMood.icon,
                        size: 16,
                        color: activeMood.color,
                      ),
                      label: Text(
                        activeMood.label,
                        style: TextStyle(
                          color: activeMood.color.withValues(alpha: .95),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onDeleted: _clearMood,
                      deleteIconColor: activeMood.color,
                      backgroundColor: activeMood.color.withValues(alpha: .12),
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: activeMood.color.withValues(alpha: .35),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Lista + paginador
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _FriendlyError(
                    message: _error!,
                    raw: _rawError,
                    onClearMood: _clearMood,
                  )
                : _items.isEmpty
                ? Center(child: Text(t.noResults))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    itemCount: _items.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _items.length) {
                        return _Paginator(
                          current: _currentPage,
                          total: _totalPages,
                          window: _pagerWindow,
                          onPrev: _currentPage > 1
                              ? () => _loadPage(_currentPage - 1)
                              : null,
                          onNext: _currentPage < _totalPages
                              ? () => _loadPage(_currentPage + 1)
                              : null,
                          onJump: (p) => _loadPage(p),
                        );
                      }

                      final doc = _items[i];
                      final data = doc.data();
                      final translations =
                          (data['translations'] as Map?)
                              ?.cast<String, dynamic>() ??
                          {};
                      final tmap = _pickLangMap(
                        translations,
                        primary: _langCode,
                        fallback: 'es',
                      );
                      final verse = (tmap['verse'] as String?)?.trim() ?? '—';
                      final description =
                          (tmap['description'] as String?)?.trim() ?? '';
                      final dateStr = (data['date'] as String?) ?? '';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: shadow,
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          border: Border.all(color: subtleBorder),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _openDetail(doc),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        normalizeDisplayText(verse),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ellipsize(normalizeDisplayText(description), 130),
                                        style: textTheme.bodyMedium?.copyWith(
                                          color:
                                              Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white.withValues(
                                                  alpha: .80,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: .75,
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _DateChip(
                                            text: _formatDate(dateStr),
                                            icon: Icons.event,
                                            color: scheme.tertiary,
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              FavoriteHeart(
                                                foodId: doc.id,
                                                iconSize: 22,
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.ios_share,
                                                ),
                                                tooltip: 'Compartir',
                                                onPressed: () {
                                                  ShareHelper.openShareSheet(
                                                    context: context,
                                                    langCode: _langCode,
                                                    verse: verse,
                                                    description: description,
                                                    dateStr: dateStr,
                                                  );
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.open_in_new,
                                                ),
                                                tooltip: 'Abrir',
                                                onPressed: () =>
                                                    _openDetail(doc),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FriendlyError extends StatelessWidget {
  final String message;
  final String? raw;
  final VoidCallback onClearMood;
  const _FriendlyError({
    required this.message,
    this.raw,
    required this.onClearMood,
  });

  @override
  Widget build(BuildContext context) {
    final subtleBg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: .06)
        : Colors.grey.shade100;
    final subtleBorder = Theme.of(context).brightness == Brightness.dark
        ? Colors.white12
        : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: onClearMood,
            icon: const Icon(Icons.clear_all),
            label: const Text('Quitar filtro'),
          ),
          if (raw != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: subtleBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: subtleBorder),
              ),
              child: Text(raw!, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final VoidCallback onPick;
  final VoidCallback onClear;
  const _DateField({
    required this.controller,
    required this.label,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.trim().isNotEmpty;
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasValue)
              IconButton(
                tooltip: 'Limpiar',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              ),
            IconButton(
              tooltip: 'Seleccionar fecha',
              icon: const Icon(Icons.calendar_today),
              onPressed: onPick,
            ),
          ],
        ),
      ),
      onTap: onPick,
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

class _Paginator extends StatelessWidget {
  final int current; // 1-based
  final int total;
  final int window;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final void Function(int page) onJump;

  const _Paginator({
    required this.current,
    required this.total,
    required this.window,
    required this.onPrev,
    required this.onNext,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    final half = window ~/ 2;
    int start = (current - half).clamp(1, (total - window + 1).clamp(1, total));
    int end = (start + window - 1).clamp(1, total);
    if (end - start + 1 < window && start > 1) {
      start = (end - window + 1).clamp(1, total);
    }
    final pages = List<int>.generate(end - start + 1, (i) => start + i);

    final outline = Theme.of(context).brightness == Brightness.dark
        ? Colors.white24
        : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
            ...pages.map((p) {
              final selected = p == current;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : outline,
                    ),
                    backgroundColor: selected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.10)
                        : null,
                  ),
                  onPressed: () => onJump(p),
                  child: Text('$p'),
                ),
              );
            }),
            IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
/*
  void _enqueueOpenById(String id) {
    _queuedOpenId = id; // coalesce: nos quedamos con el último
    if (!_openingById) {
      _processOpenQueue();
    }
  }

  Future<void> _processOpenQueue() async {
    _openingById = true;
    try {
      while (_queuedOpenId != null) {
        final id = _queuedOpenId!;
        _queuedOpenId = null;
        // Evita competir con cargas de página en curso
        await _waitWhileLoading();
        await _openById(id);
        // Limpia la selección para evitar reaperturas
        ref.read(selectedFoodIdProvider.notifier).state = null;
      }
    } finally {
      _openingById = false;
    }
  }

  Future<void> _waitWhileLoading() async {
    while (_loading) {
      await Future.delayed(const Duration(milliseconds: 16));
    }
  }
*/
