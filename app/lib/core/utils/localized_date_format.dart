class LocalizedDateFormat {
  LocalizedDateFormat._();

  static String numeric(DateTime date, {String? locale}) {
    final normalized = _normalize(locale);
    final day = date.day.toString();
    final month = date.month.toString();
    final year = date.year.toString();

    return switch (normalized) {
      'de_DE' || 'fr_FR' => '$day.$month.$year',
      'en_IN' => '$day/$month/$year',
      _ => '${date.month}/${date.day}/${date.year}',
    };
  }

  static String _normalize(String? locale) =>
      (locale ?? '').trim().replaceAll('-', '_');
}
