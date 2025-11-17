import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareHelper {
  const ShareHelper._();

  static const String kInstallUrl = 'https://example.com/tu_alimento_diario';

  static String _formatDate(String raw) {
    try {
      final dt = DateFormat('yyyy-MM-dd').parseStrict(raw);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  static String buildShareText({
    required String langCode,
    required String title,
    required String verse,
    required String description,
    required String dateStr,
  }) {
    final datePretty = _formatDate(dateStr);
    final headerByLang = {
      'es': 'Alimento Diario $datePretty',
      'en': 'Daily Food $datePretty',
      'pt': 'Alimento Diario $datePretty',
      'it': 'Cibo Quotidiano $datePretty',
    };
    final header = headerByLang[langCode] ?? 'Alimento Diario $datePretty';
    final trimmedTitle = title.trim();
    final trimmedVerse = verse.trim();
    final trimmedDescription = description.trim();

    final parts = <String>[
      header,
      if (trimmedTitle.isNotEmpty) trimmedTitle,
      if (trimmedVerse.isNotEmpty && trimmedVerse != trimmedTitle)
        trimmedVerse,
      if (trimmedDescription.isNotEmpty) trimmedDescription,
      'Descarga la app: $kInstallUrl',
    ];
    return parts.join('\n\n');
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
    required String title,
    required String verse,
    required String description,
    required String dateStr,
  }) {
    final text = buildShareText(
      langCode: langCode,
      title: title,
      verse: verse,
      description: description,
      dateStr: dateStr,
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
