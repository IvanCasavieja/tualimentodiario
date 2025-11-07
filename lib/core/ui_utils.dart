String ellipsize(String s, [int max = 140]) {
  if (s.length <= max) return s;
  return '${s.substring(0, max).trimRight()}…';
}

String langFarewell(String code) {
  switch (code) {
    case 'en':
      return 'Blessed day';
    case 'pt':
      return 'Dia abençoado';
    case 'it':
      return 'Giorno benedetto';
    case 'es':
    default:
      return 'Bendecido día';
  }
}
