// Utilities to normalize text coming from backend before display.

/// Replaces hyphens and underscores with spaces, collapses repeated spaces,
/// and trims the result. Intended for titles/descriptions on cards.
String normalizeDisplayText(String s) {
  if (s.isEmpty) return s;
  final replaced = s.replaceAll(RegExp(r'[-_]+'), ' ');
  return replaced.replaceAll(RegExp(r'\s+'), ' ').trim();
}
