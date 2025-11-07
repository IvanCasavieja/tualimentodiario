import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/firestore_repository.dart';
import '../../core/models/daily_food.dart';
import '../../core/app_state.dart';
import '../../core/ui_utils.dart';
import '../common/food_detail_dialog.dart';

class ArchiveView extends ConsumerStatefulWidget {
  const ArchiveView({super.key});
  @override
  ConsumerState<ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends ConsumerState<ArchiveView> {
  Query<Map<String, dynamic>> _query = FS.archiveBase();
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _isLoading = false;
  bool _end = false;
  final _items = <QueryDocumentSnapshot<Map<String, dynamic>>>[];

  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFirst();
  }

  Future<void> _loadFirst() async {
    setState(() {
      _isLoading = true;
      _items.clear();
      _end = false;
      _lastDoc = null;
    });
    final first = await _query.get();
    _items.addAll(first.docs);
    if (first.docs.isNotEmpty) _lastDoc = first.docs.last;
    if (first.docs.length < 10) _end = true;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_isLoading || _end) return;
    setState(() {
      _isLoading = true;
    });
    var q = _query;
    if (_lastDoc != null) q = q.startAfterDocument(_lastDoc!);
    final next = await q.get();
    _items.addAll(next.docs);
    if (next.docs.isNotEmpty) _lastDoc = next.docs.last;
    if (next.docs.length < 10) _end = true;
    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final from = _fromCtrl.text.trim();
    final to = _toCtrl.text.trim();
    if (from.isNotEmpty && to.isNotEmpty) {
      _query = FS.archiveRange(from, to);
    } else {
      _query = FS.archiveBase();
    }
    _loadFirst();
  }

  @override
  Widget build(BuildContext context) {
    final langCode = ref.watch(languageProvider).name;

    return Scaffold(
      appBar: AppBar(title: const Text('Archivo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _fromCtrl,
                    decoration: const InputDecoration(labelText: 'Desde (yyyy-MM-dd)'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _toCtrl,
                    decoration: const InputDecoration(labelText: 'Hasta (yyyy-MM-dd)'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _applyFilter, child: const Text('Filtrar')),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length + 1,
              itemBuilder: (ctx, i) {
                if (i == _items.length) {
                  if (_end) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('Fin del archivo')),
                    );
                  }
                  _loadMore();
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final doc = _items[i];
                final item = DailyFood.fromDoc(doc);
                final t = Map<String, dynamic>.from(item.translations[langCode] ?? item.translations['es'] ?? {});
                return ListTile(
                  title: Text((t['verse'] ?? '').toString()),
                  subtitle: Text('${ellipsize((t['description'] ?? '').toString(), 120)}\n${item.authorName} • ${item.date}'),
                  isThreeLine: true,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => FoodDetailDialog(item: item, lang: langCode),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
