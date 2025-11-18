import 'package:intl/intl.dart';

/// Centraliza los formatos de fecha para evitar recrearlos constantemente.
class DateFormats {
  DateFormats._();

  static final DateFormat iso = DateFormat('yyyy-MM-dd');
  static final DateFormat display = DateFormat('dd/MM/yyyy');
  static final DateFormat displayDash = DateFormat('dd-MM-yyyy');
  static final DateFormat feedback = DateFormat('dd/MM/yyyy HH:mm');

  static const List<String> _flexiblePatterns = [
    'dd/MM/yyyy',
    'd/M/yyyy',
    'dd-MM-yyyy',
  ];

  /// Intenta parsear formatos comunes sin volver a instanciar el DateFormat manualmente.
  static DateTime? tryParseFlexible(String raw) {
    for (final pattern in _flexiblePatterns) {
      try {
        return DateFormat(pattern).parseStrict(raw);
      } catch (_) {
        // ignora y prueba el siguiente patrón
      }
    }
    return null;
  }
}
