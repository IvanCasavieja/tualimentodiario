// lib/core/moods_i18n.dart
/// i18n centralizado para los labels de moods.
/// Claves: slug -> { 'es'|'en'|'pt'|'it' : labelTraducido }
const Map<String, Map<String, String>> kMoodI18n = {
  'esperanza': {
    'es': 'Esperanza',
    'en': 'Hope',
    'pt': 'Esperança',
    'it': 'Speranza',
  },
  'gratitud': {
    'es': 'Gratitud',
    'en': 'Gratitude',
    'pt': 'GratidÃ£o',
    'it': 'Gratitudine',
  },
  'fortaleza': {
    'es': 'Fortaleza',
    'en': 'Strength',
    'pt': 'Força',
    'it': 'Fortezza',
  },
  'paz': {'es': 'Paz', 'en': 'Peace', 'pt': 'Paz', 'it': 'Pace'},
  'alegria': {'es': 'Alegría', 'en': 'Joy', 'pt': 'Alegria', 'it': 'Gioia'},
  'consuelo': {
    'es': 'Consuelo',
    'en': 'Comfort',
    'pt': 'Consolo',
    'it': 'Conforto',
  },
  'sabiduria': {
    'es': 'Sabiduría',
    'en': 'Wisdom',
    'pt': 'Sabedoria',
    'it': 'Saggezza',
  },
  'fe': {'es': 'Fe', 'en': 'Faith', 'pt': 'FÃ©', 'it': 'Fede'},
  'perdon': {
    'es': 'Perdón',
    'en': 'Forgiveness',
    'pt': 'PerdÃ£o',
    'it': 'Perdono',
  },
  'paciencia': {
    'es': 'Paciencia',
    'en': 'Patience',
    'pt': 'PaciÃªncia',
    'it': 'Pazienza',
  },
};

/// Devuelve el label traducido para el slug dado.
/// - [fallbackLabel] se usa si no hay traducciÃ³n para ese idioma.
/// - [langCode] debe ser 'es'|'en'|'pt'|'it'.
String moodLabelI18n({
  required String slug,
  required String langCode,
  required String fallbackLabel,
}) {
  final bySlug = kMoodI18n[slug];
  if (bySlug != null) {
    final t = bySlug[langCode];
    if (t != null && t.isNotEmpty) return t;
  }
  return fallbackLabel;
}


