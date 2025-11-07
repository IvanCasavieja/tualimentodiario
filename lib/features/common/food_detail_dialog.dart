import 'package:flutter/material.dart';
import '../../core/models/daily_food.dart';
import '../../core/ui_utils.dart';

class FoodDetailDialog extends StatelessWidget {
  final DailyFood item;
  final String lang;
  const FoodDetailDialog({super.key, required this.item, required this.lang});

  @override
  Widget build(BuildContext context) {
    final t = Map<String, dynamic>.from(
      item.translations[lang] ?? item.translations['es'] ?? {},
    );
    return AlertDialog(
      title: Text((t['verse'] ?? '').toString()),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((t['description'] ?? '').toString().isNotEmpty) ...[
              const Text('Descripción', style: TextStyle(fontWeight: FontWeight.bold)),
              Text((t['description'] ?? '').toString()),
              const SizedBox(height: 8),
            ],
            if ((t['reflection'] ?? '').toString().isNotEmpty) ...[
              const Text('Reflexión', style: TextStyle(fontWeight: FontWeight.bold)),
              Text((t['reflection'] ?? '').toString()),
              const SizedBox(height: 8),
            ],
            if ((t['prayer'] ?? '').toString().isNotEmpty) ...[
              const Text('Oración', style: TextStyle(fontWeight: FontWeight.bold)),
              Text((t['prayer'] ?? '').toString()),
              const SizedBox(height: 8),
            ],
            Text((t['farewell'] ?? langFarewell(lang)).toString()),
            const SizedBox(height: 12),
            Text('— ${item.authorName}, ${item.date}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
      ],
    );
  }
}
