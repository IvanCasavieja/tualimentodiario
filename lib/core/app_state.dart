import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Idiomas soportados
enum AppLang { es, en, pt, it }

/// Proveedor simple del idioma actual
final languageProvider = StateProvider<AppLang>((ref) => AppLang.es);

/// Navegación bottom (0: Inicio, 1: Archivo, 2: Favoritos, 3: Perfil)
final bottomTabIndexProvider = StateProvider<int>((ref) => 0);

/// Cuando el usuario toca una tarjeta en Inicio, guardamos el ID para que
/// Archivo abra el detalle de ese documento.
final selectedFoodIdProvider = StateProvider<String?>((ref) => null);

/// Preferencias locales del idioma
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
      default:
        return AppLang.es;
    }
  }
}
