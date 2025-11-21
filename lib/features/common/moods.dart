// lib/features/common/moods.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../core/app_state.dart' show languageProvider;
import '../../core/moods_i18n.dart' show moodLabelI18n;

class MoodDef {
  final String slug, label;
  final IconData icon;
  final Color color;
  const MoodDef(this.slug, this.label, this.icon, this.color);
}

/// Labels base en ES (fallback)
const kMoods = <MoodDef>[
  MoodDef('esperanza', 'Esperanza', Icons.wb_sunny_outlined, Color(0xFF48C1F1)),
  MoodDef('gratitud', 'Gratitud', Icons.favorite_outline, Color(0xFF6C4DF5)),
  MoodDef(
    'fortaleza',
    'Fortaleza',
    Icons.fitness_center_outlined,
    Color(0xFF48C1F1),
  ),
  MoodDef('paz', 'Paz', Icons.self_improvement_outlined, Color(0xFF6C4DF5)),
  MoodDef(
    'alegria',
    'Alegría',
    Icons.emoji_emotions_outlined,
    Color(0xFF48C1F1),
  ),
  MoodDef(
    'consuelo',
    'Consuelo',
    Icons.volunteer_activism_outlined,
    Color(0xFF6C4DF5),
  ),
  MoodDef(
    'sabiduria',
    'Sabiduría',
    Icons.psychology_outlined,
    Color(0xFF48C1F1),
  ),
  MoodDef('fe', 'Fe', FontAwesomeIcons.handsPraying, Color(0xFF6C4DF5)),
  MoodDef('perdon', 'Perdón', Icons.handshake_outlined, Color(0xFF48C1F1)),
  MoodDef('paciencia', 'Paciencia', Icons.hourglass_empty, Color(0xFF6C4DF5)),
];

final moodsFilterProvider = StateProvider<Set<String>>((_) => {});

MoodDef? moodBySlug(String slug) {
  try {
    return kMoods.firstWhere((m) => m.slug == slug);
  } catch (_) {
    return null;
  }
}

/// Chips SOLO para Home (ahora traducidos con la misma fuente que Admin).
class MoodChips extends ConsumerWidget {
  const MoodChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(moodsFilterProvider);
    final active = selected.isEmpty ? null : selected.first;
    final langCode = ref.watch(languageProvider).name; // 'es'|'en'|'pt'|'it'

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kMoods.map((m) {
          final isSel = m.slug == active;
          final bg = isSel ? m.color.withValues(alpha: .18) : Colors.white;
          final border = isSel ? m.color.withValues(alpha: .5) : Colors.black12;

          final label = moodLabelI18n(
            slug: m.slug,
            langCode: langCode,
            fallbackLabel: m.label, // ES por defecto
          );

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              child: InkWell(
                onTap: () {
                  final next = <String>{};
                  if (!isSel) next.add(m.slug);
                  ref.read(moodsFilterProvider.notifier).state = next;
                },
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: border),
                  ),
                  child: Row(
                    children: [
                      Icon(m.icon, size: 16, color: m.color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: m.color.withValues(alpha: .9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSel) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.close,
                          size: 14,
                          color: m.color.withValues(alpha: .9),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
