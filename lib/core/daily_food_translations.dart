Map<String, dynamic> pickDailyFoodTranslation(
  Map<String, dynamic> translations, {
  required String primary,
  String fallback = 'es',
}) {
  if (translations[primary] is Map) {
    return (translations[primary] as Map).cast<String, dynamic>();
  }
  if (translations[fallback] is Map) {
    return (translations[fallback] as Map).cast<String, dynamic>();
  }
  for (final value in translations.values) {
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
  }
  return const {};
}
