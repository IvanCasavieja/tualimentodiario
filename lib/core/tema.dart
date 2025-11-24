import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ===== Persistencia =====
const _kThemeModeKey = 'pref_theme_mode'; // 'light' | 'dark' (null => follow system)
const _kTextScaleKey = 'pref_text_scale'; // double (0.9 .. 1.4)

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
final textScaleProvider = StateProvider<double>((ref) => 1.0);

class ThemePrefs {
  static Future<(ThemeMode, double)> load() async {
    final sp = await SharedPreferences.getInstance();
    final modeStr = sp.getString(_kThemeModeKey);
    final scale = (sp.getDouble(_kTextScaleKey) ?? 1.0).clamp(0.9, 1.4);
    final mode = switch (modeStr) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system, // no pref saved -> sigue al sistema
    };
    return (mode, scale);
  }

  static Future<ThemeMode> loadMode() async {
    final sp = await SharedPreferences.getInstance();
    final modeStr = sp.getString(_kThemeModeKey);
    return switch (modeStr) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      _ => ThemeMode.system,
    };
  }

  static Future<double> loadTextScale() async {
    final sp = await SharedPreferences.getInstance();
    return (sp.getDouble(_kTextScaleKey) ?? 1.0).clamp(0.9, 1.4);
  }

  static Future<void> saveMode(ThemeMode mode) async {
    final sp = await SharedPreferences.getInstance();
    final value = switch (mode) {
      ThemeMode.dark => 'dark',
      _ => 'light', // la UI solo expone claro/oscuro
    };
    await sp.setString(_kThemeModeKey, value);
  }

  static Future<void> saveTextScale(double scale) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kTextScaleKey, scale.clamp(0.9, 1.4));
  }
}

/// ===== Extensión del tema para fondos/gradientes de Home =====
class AppExtras extends ThemeExtension<AppExtras> {
  final LinearGradient homeBackground; // fondo detrás del Scaffold de Home
  final LinearGradient heroGradient; // tarjeta hero de Home
  final Color pillBg; // fondo de pill-botón "Sorpresa"
  final Color subtleText; // texto secundario sutil

  const AppExtras({
    required this.homeBackground,
    required this.heroGradient,
    required this.pillBg,
    required this.subtleText,
  });

  @override
  AppExtras copyWith({
    LinearGradient? homeBackground,
    LinearGradient? heroGradient,
    Color? pillBg,
    Color? subtleText,
  }) {
    return AppExtras(
      homeBackground: homeBackground ?? this.homeBackground,
      heroGradient: heroGradient ?? this.heroGradient,
      pillBg: pillBg ?? this.pillBg,
      subtleText: subtleText ?? this.subtleText,
    );
  }

  @override
  AppExtras lerp(ThemeExtension<AppExtras>? other, double t) {
    if (other is! AppExtras) return this;
    // No interpolamos gradientes; devolvemos el final.
    return other;
  }
}

/// ===== Paleta base (respetando tu look actual en claro) =====
final _seed = const Color(0xFF6C4DF5); // primary que ya usabas
final _accent = const Color(0xFF48C1F1);

final _lightScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.light,
).copyWith(surface: Colors.white);

final _darkScheme = ColorScheme.fromSeed(
  seedColor: _seed,
  brightness: Brightness.dark,
).copyWith(surface: const Color(0xFF1C1F27));

final _lightExtras = AppExtras(
  // Tu fondo anterior: F6E9FF -> EAF7FF
  homeBackground: const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6E9FF), Color(0xFFEAF7FF)],
  ),
  // Hero en claro (mismo concepto: primary/accent con alfa 0.15)
  heroGradient: LinearGradient(
    colors: [_seed.withValues(alpha: .15), _accent.withValues(alpha: .15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  pillBg: Colors.white,
  subtleText: Colors.black.withValues(alpha: .70),
);

final _darkExtras = AppExtras(
  // Fondo agradable para oscuro (no todo negro, con leve tinte)
  homeBackground: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [const Color(0xFF191C24), const Color(0xFF12141A)],
  ),
  // Hero en oscuro (mismo esquema pero con menos opacidad)
  heroGradient: LinearGradient(
    colors: [_seed.withValues(alpha: .10), _accent.withValues(alpha: .10)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  pillBg: const Color(0xFF2A2E3A),
  subtleText: Colors.white.withValues(alpha: .75),
);

ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: _lightScheme.surface,
    cardColor: _lightScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
    extensions: <ThemeExtension<dynamic>>[_lightExtras],
  );
}

ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: _darkScheme.surface,
    cardColor: _darkScheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
    ),
    extensions: <ThemeExtension<dynamic>>[_darkExtras],
  );
}
