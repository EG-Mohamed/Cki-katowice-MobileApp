class HijriDate {
  const HijriDate({required this.year, required this.month, required this.day});

  final int year;
  final int month;
  final int day;

  static const List<String> monthsEn = [
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Ula',
    'Jumada al-Akhira',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const List<String> monthsAr = [
    'محرم',
    'صفر',
    'ربيع الأول',
    'ربيع الآخر',
    'جمادى الأولى',
    'جمادى الآخرة',
    'رجب',
    'شعبان',
    'رمضان',
    'شوال',
    'ذو القعدة',
    'ذو الحجة',
  ];

  factory HijriDate.fromGregorian(DateTime date) {
    final jd = _gregorianToJd(date.year, date.month, date.day);
    final l0 = jd - 1948440 + 10632;
    final n = ((l0 - 1) / 10631).floor();
    final l1 = l0 - 10631 * n + 354;
    final j = (((10985 - l1) / 5316).floor()) * (((50 * l1) / 17719).floor()) +
        ((l1 / 5670).floor()) * (((43 * l1) / 15238).floor());
    final l2 = l1 -
        (((30 - j) / 15).floor()) * (((17719 * j) / 50).floor()) -
        ((j / 16).floor()) * (((15238 * j) / 43).floor()) +
        29;
    final month = ((24 * l2) / 709).floor();
    final day = l2 - ((709 * month) / 24).floor();
    final year = 30 * n + j - 30;
    return HijriDate(year: year, month: month, day: day);
  }

  String format(String locale) {
    final names = locale == 'ar' ? monthsAr : monthsEn;
    final index = (month - 1).clamp(0, 11);
    return '$day ${names[index]} $year';
  }

  static int _gregorianToJd(int year, int month, int day) {
    final a = ((14 - month) / 12).floor();
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        ((153 * m + 2) / 5).floor() +
        365 * y +
        (y / 4).floor() -
        (y / 100).floor() +
        (y / 400).floor() -
        32045;
  }
}
