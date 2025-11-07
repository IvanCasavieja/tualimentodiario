import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_state.dart';                       // languageProvider
import '../../core/models/daily_food.dart';               // DailyFood.fromDoc
import '../../core/ui_utils.dart';                        // ellipsize
import '../common/food_detail_dialog.dart';               // FoodDetailDialog

/// Vista de Archivo con paginación por páginas y filtro de fechas.
/// Si [initialFoodId] viene, intenta abrir ese alimento tras la primera carga.
class ArchiveView extends ConsumerStatefulWidget {
  final String? initialFoodId;
  const ArchiveView({super.key, this.initialFoodId});

  @override
  ConsumerState<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends ConsumerState<ArchiveView> {
  // ---- Config
  static const int _pageSize = 10;
  static const int _pagerWindow = 5;

  // ---- Estado de datos
  Query<Map<String, dynamic>> _baseQuery() {
    // Orden estable: date DESC, luego __name__ DESC (para cursor)
    return FirebaseFirestore.instance
        .collection('dailyFoods')
        .where('isPublished', isEqualTo: true)
        .orderBy('date', descending: true)
        .orderBy(FieldPath.documentId, descending: true);
  }

  // Contadores / paginación
  int _totalCount = 0;
  int _totalPages = 0;
  int _currentPage = 1; // 1-based

  // Para paginar por número de página guardamos el último doc de cada página ya visitada.
  // _pageCursors[i] = último doc de la página i+1 (0-based index => página 1 = index 0)
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pageCursors = [];

  // Items visibles (página actual)
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _items = [];

  // UI / carga
  bool _loading = false;
  String? _error;

  // Filtros por fecha (string 'yyyy-MM-dd', porque en tu base date es String)
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  // Lang
  String get _langCode => _toCode(ref.read(languageProvider));

  @override
  void initState() {
    super.initState();
    _fetchCount().then((_) => _loadPage(1)).then((_) async {
      // Si nos pasaron un ID para abrir en detalle, probamos abrirlo si está en la primera página.
      if (widget.initialFoodId != null) {
        final idx = _items.indexWhere((d) => d.id == widget.initialFoodId);
        if (idx >= 0) {
          _openDetail(_items[idx]);
        }
      }
    });
  }

  @override
  void dispose() {
    _fromCtrl.dispose();
    _toCtrl.dispose();
    super.dispose();
  }

  // ----------------------- Data & Paginación -----------------------

  Query<Map<String, dynamic>> _filteredQuery() {
    var q = _baseQuery();
    final f = _fromCtrl.text.trim();
    final t = _toCtrl.text.trim();
    // Como 'date' es String con formato yyyy-MM-dd, comparar por rango funciona lexicográficamente.
    if (f.isNotEmpty) {
      q = q.where('date', isGreaterThanOrEqualTo: f);
    }
    if (t.isNotEmpty) {
      q = q.where('date', isLessThanOrEqualTo: t);
    }
    return q;
  }

  Future<void> _fetchCount() async {
    // Usamos "aggregation count" para saber total con los filtros vigentes.
    try {
      final snap = await _filteredQuery().count().get();
      _totalCount = snap.count ?? 0; // SDKs viejos devuelven null-safe; usamos 0 por si acaso
      _totalPages = _totalCount == 0 ? 1 : ((_totalCount + _pageSize - 1) ~/ _pageSize);
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _totalCount = 0;
        _totalPages = 1;
        _error = 'Error contando documentos: $e';
      });
    }
  }

  Future<void> _loadPage(int targetPage) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _items.clear();
    });

    try {
      // Aseguramos límites
      if (targetPage < 1) targetPage = 1;
      if (targetPage > _totalPages) targetPage = _totalPages;

      // Si necesitamos llegar a una página cuya posición aún no conocemos,
      // vamos construyendo cursores secuencialmente (startAfterDocument).
      while (_pageCursors.length < targetPage - 1) {
        final prevIdx = _pageCursors.length; // cursor de la página prevIdx+1
        final prevCursor = prevIdx == 0 ? null : _pageCursors[prevIdx - 1];
        var q = _filteredQuery().limit(_pageSize);
        if (prevCursor != null) q = q.startAfterDocument(prevCursor);
        final snap = await q.get();
        if (snap.docs.isEmpty) break;
        _pageCursors.add(snap.docs.last);
      }

      // Ahora obtenemos la página deseada
      final prevCursor = targetPage == 1 ? null : _pageCursors[targetPage - 2];
      var q = _filteredQuery().limit(_pageSize);
      if (prevCursor != null) q = q.startAfterDocument(prevCursor);
      final pageSnap = await q.get();

      _items.clear();
      _items.addAll(pageSnap.docs);
      _currentPage = targetPage;

      // Guardamos el cursor (último doc) de esta página si aún no lo tenemos
      if (_pageCursors.length < targetPage) {
        if (pageSnap.docs.isNotEmpty) {
          _pageCursors.add(pageSnap.docs.last);
        } else {
          _pageCursors.add(prevCursor!); // fallback
        }
      }
    } catch (e) {
      _error = 'Error cargando página: $e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() async {
    // Reiniciamos estado de paginación y recargamos
    _pageCursors.clear();
    await _fetchCount();
    await _loadPage(1);
  }

  // -------------------------- UI helpers --------------------------

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
    // Base tiene 'yyyy-MM-dd' (string). Mostramos 'dd/MM/yyyy'.
    try {
      final dt = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
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

  // ------------------------------ BUILD ------------------------------

  @override
  Widget build(BuildContext context) {
    // Rebuild si cambia idioma
    ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Archivo')),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Desde (yyyy-MM-dd)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _toCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Hasta (yyyy-MM-dd)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _applyFilter,
                  child: const Text('Filtrar'),
                ),
              ],
            ),
          ),

          // Lista + paginador
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : _items.isEmpty
                        ? const Center(child: Text('No hay resultados'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: _items.length + 1,
                            itemBuilder: (ctx, i) {
                              if (i == _items.length) {
                                // Paginador al final
                                return _Paginator(
                                  current: _currentPage,
                                  total: _totalPages,
                                  window: _pagerWindow,
                                  onPrev: _currentPage > 1 ? () => _loadPage(_currentPage - 1) : null,
                                  onNext: _currentPage < _totalPages
                                      ? () => _loadPage(_currentPage + 1)
                                      : null,
                                  onJump: (p) => _loadPage(p),
                                );
                              }

                              final doc = _items[i];
                              final data = doc.data();
                              final translations =
                                  (data['translations'] as Map?)?.cast<String, dynamic>() ?? {};
                              final t = _pickLangMap(translations, primary: _langCode, fallback: 'es');
                              final verse = (t['verse'] as String?)?.trim() ?? '—';
                              final description = (t['description'] as String?)?.trim() ?? '';
                              final dateStr = (data['date'] as String?) ?? '';

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () => _openDetail(doc),
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          verse,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(ellipsize(description, 160)),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatDate(dateStr),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.open_in_new),
                                              onPressed: () => _openDetail(doc),
                                            ),
                                          ],
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

// ===================== Paginador responsivo (ventana de 5) =====================

class _Paginator extends StatelessWidget {
  final int current; // 1-based
  final int total;
  final int window; // cantidad de botones visibles (p. ej., 5)
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    side: BorderSide(
                      color: selected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                    backgroundColor: selected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
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
