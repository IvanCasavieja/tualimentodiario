import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'date_formats.dart';
import 'daily_food_translations.dart';
import 'models/daily_food.dart';
import 'text_filters.dart';
import 'ui_utils.dart';

class ShareHelper {
  const ShareHelper._();

  static const String kInstallUrl = 'https://example.com/tu_alimento_diario';

  static String _formatDate(String raw) {
    try {
      final dt = DateFormats.iso.parseStrict(raw);
      return DateFormats.display.format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String _buildDetailShareText({
    required DailyFood item,
    required String langCode,
    required String prayerLabel,
  }) {
    final tr = pickDailyFoodTranslation(
      item.translations,
      primary: langCode,
    );

    final verse =
        normalizeDisplayText((tr['verse'] ?? '').toString().trim());
    final title =
        normalizeDisplayText((tr['title'] ?? '').toString().trim());
    final headerText = verse.isNotEmpty ? verse : title;
    final descriptionRaw = (tr['description'] ?? '').toString().trim();
    final descriptionParagraphs = descriptionRaw
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final reflection =
        normalizeDisplayText((tr['reflection'] ?? '').toString().trim());
    final prayerText =
        normalizeDisplayText((tr['prayer'] ?? '').toString().trim());
    final prayerDisplay =
        prayerText.isNotEmpty ? 'Ora así: $prayerText' : '';
    final farewell = langFarewell(langCode);
    final sections = <String>[];

    if (headerText.isNotEmpty) sections.add(headerText);
    final formattedDate = _formatDate(item.date);
    if (formattedDate.isNotEmpty) sections.add(formattedDate);
    if (title.isNotEmpty && title != headerText) {
      sections.add(title);
    }
    if (descriptionParagraphs.isNotEmpty) {
      sections.addAll(descriptionParagraphs);
    }
    if (reflection.isNotEmpty) sections.add(reflection);
    if (prayerDisplay.isNotEmpty) {
      sections.add('$prayerLabel\n$prayerDisplay');
    }
    if (farewell.isNotEmpty) sections.add(farewell);
    sections.add('Descarga la app: $kInstallUrl');

    return sections.where((s) => s.trim().isNotEmpty).join('\n\n');
  }

  static Future<void> _shareToWhatsApp(String text) async {
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
    try {
      final ok = await canLaunchUrl(uri);
      if (ok) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await SharePlus.instance.share(ShareParams(text: text)); // fallback
      }
    } catch (_) {
      await SharePlus.instance.share(ShareParams(text: text)); // fallback
    }
  }

  static Future<void> _shareGeneric(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }

  static void openShareSheet({
    required BuildContext context,
    required String langCode,
    required DailyFood item,
    required String prayerLabel,
  }) {
    final text = _buildDetailShareText(
      item: item,
      langCode: langCode,
      prayerLabel: prayerLabel,
    );

    final messenger = ScaffoldMessenger.maybeOf(context);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                ),
                title: const Text('Compartir por WhatsApp'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareToWhatsApp(text);
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.instagram,
                  color: Color(0xFFE1306C),
                ),
                title: const Text('Compartir en Instagram'),
                subtitle: const Text('Usá el menú del sistema (texto)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareGeneric(text);
                },
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.facebook,
                  color: Color(0xFF1877F2),
                ),
                title: const Text('Compartir en Facebook'),
                subtitle: const Text('Usá el menú del sistema (texto)'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareGeneric(text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.ios_share),
                title: const Text('Más opciones'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _shareGeneric(text);
                },
              ),
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  messenger?.showSnackBar(
                    const SnackBar(
                      content: Text('Texto copiado al portapapeles'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar texto'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }
}
