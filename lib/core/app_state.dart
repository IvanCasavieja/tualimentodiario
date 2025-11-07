import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas soportados
enum AppLang { es, en, pt, it }

/// Proveedor simple del idioma actual
final languageProvider = StateProvider<AppLang>((ref) => AppLang.es);

/// Helper para cargar/guardar preferencia de idioma en SharedPreferences
class LanguagePrefs {
  static const _key = 'lang';

  static Future<void> save(AppLang lang) async {
    final sp = await SharedPreferences.getInstance();
    sp.setString(_key, _toCode(lang));
  }

  static Future<AppLang> load() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_key) ?? 'es';
    return _fromCode(code);
  }

  static String _toCode(AppLang l) {
    switch (l) {
      case AppLang.en:
        return 'en';
      case AppLang.pt:
        return 'pt';
      case AppLang.it:
        return 'it';
      case AppLang.es:
        return 'es';
    }
  }

  static AppLang _fromCode(String c) {
    switch (c) {
      case 'en':
        return AppLang.en;
      case 'pt':
        return AppLang.pt;
      case 'it':
        return AppLang.it;
      case 'es':
        return AppLang.es;
      default:
        return AppLang.es;
    }
  }
}
