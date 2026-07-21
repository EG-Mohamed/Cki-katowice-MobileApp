// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'المركز الثقافي الإسلامي';

  @override
  String get mosqueName => 'المركز الثقافي الإسلامي - كاتوفيتسه';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navQibla => 'القبلة';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navNews => 'الأخبار';

  @override
  String get navMore => 'المزيد';

  @override
  String get greeting => 'السلام عليكم';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String timeRemaining(Object time) {
    return 'بعد $time';
  }

  @override
  String get prayerNow => 'حان الوقت';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get jumuah => 'الجمعة';

  @override
  String get todaySchedule => 'مواقيت اليوم';

  @override
  String get previousDay => 'اليوم السابق';

  @override
  String get nextDay => 'اليوم التالي';

  @override
  String get quickActions => 'استكشف';

  @override
  String get qiblaDirection => 'اتجاه القبلة';

  @override
  String get quranReader => 'القرآن الكريم';

  @override
  String get newsAnnouncements => 'الأخبار';

  @override
  String get khutbaTitle => 'خطبة الجمعة';

  @override
  String get qiblaHeading => 'استقبل القبلة';

  @override
  String get qiblaInstruction =>
      'أمسك هاتفك أفقيًا واستدر حتى يتوافق المؤشر مع الكعبة.';

  @override
  String get qiblaAligned => 'أنت تواجه القبلة';

  @override
  String qiblaDistance(Object km) {
    return '$km كم إلى الكعبة';
  }

  @override
  String get qiblaPermission =>
      'نحتاج إلى إذن الموقع والمستشعرات لتحديد القبلة.';

  @override
  String get grantAccess => 'السماح بالوصول';

  @override
  String get calibrateHint => 'حرّك هاتفك على شكل رقم 8 لمعايرة البوصلة.';

  @override
  String get surahs => 'السور';

  @override
  String verses(Object count) {
    return '$count آية';
  }

  @override
  String get translation => 'الترجمة';

  @override
  String get fontSize => 'حجم الخط';

  @override
  String get listenQuran => 'استمع إلى السورة';

  @override
  String get stopListening => 'إيقاف الاستماع';

  @override
  String get readMore => 'اقرأ المزيد';

  @override
  String get searchNews => 'ابحث في الأخبار';

  @override
  String get allCategories => 'الكل';

  @override
  String get upcoming => 'القادمة';

  @override
  String get past => 'السابقة';

  @override
  String khatib(Object name) {
    return 'ألقاها $name';
  }

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get prayerNotifications => 'تنبيهات الصلاة';

  @override
  String get prayerNotificationsDesc => 'احصل على تنبيه عند كل وقت صلاة.';

  @override
  String get enableAll => 'كل الصلوات';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutBody =>
      'تطبيق لمجتمع مركز كاتوفيتشه — مواقيت الصلاة، القبلة، القرآن الكريم، الأخبار وخطبة الجمعة.';

  @override
  String get english => 'English';

  @override
  String get polish => 'Polski';

  @override
  String get arabic => 'العربية';

  @override
  String get loading => 'جارٍ التحميل…';

  @override
  String get prayerTimesUnavailable => 'أوقات الصلاة غير متاحة.';

  @override
  String get emptyNews => 'لا توجد إعلانات بعد.';

  @override
  String get emptyKhutba => 'لم تُنشر خطبة بعد.';

  @override
  String get quranUnavailable => 'محتوى القرآن غير متاح.';

  @override
  String notificationBody(Object prayer) {
    return 'حان وقت صلاة $prayer.';
  }

  @override
  String get notificationTitle => 'حان وقت الصلاة';

  @override
  String get adhanOn => 'الأذان مفعّل';

  @override
  String get adhanOff => 'الأذان متوقف';

  @override
  String get reciters => 'القرّاء';

  @override
  String get reciter => 'القارئ';

  @override
  String get selectReciter => 'اختر قارئًا';

  @override
  String get changeReciter => 'تغيير القارئ';

  @override
  String get riwayah => 'الرواية';

  @override
  String get nowPlaying => 'يُشغَّل الآن';

  @override
  String get radios => 'محطات الإذاعة';

  @override
  String get playSurah => 'تشغيل السورة';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get resume => 'متابعة';

  @override
  String get nextSurah => 'التالية';

  @override
  String get previousSurah => 'السابقة';

  @override
  String get readText => 'قراءة النص';

  @override
  String get autoplayNext => 'تشغيل السورة التالية تلقائيًا';

  @override
  String get recitersUnavailable => 'القرّاء غير متاحين.';

  @override
  String get noReciterSelected => 'اختر قارئًا لبدء الاستماع.';

  @override
  String get searchReciters => 'ابحث عن القرّاء';

  @override
  String get announcementDismiss => 'إخفاء';

  @override
  String get announcementDetails => 'التفاصيل';

  @override
  String get announcementUrgent => 'عاجل';

  @override
  String get announcementMaintenance => 'صيانة';

  @override
  String get announcementGeneral => 'إعلان';

  @override
  String get appearance => 'المظهر';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get darkModeDesc => 'استخدم مظهرًا داكنًا في التطبيق.';

  @override
  String get openInMaps => 'افتح في الخرائط';

  @override
  String get searchSurah => 'ابحث عن سورة';

  @override
  String get noResults => 'لا توجد نتائج.';

  @override
  String get radioLive => 'إذاعات القرآن المباشرة';

  @override
  String get searchRadios => 'ابحث عن محطة';

  @override
  String get testNotification => 'إرسال إشعار تجريبي';

  @override
  String get testNotificationBody => 'هكذا ستظهر تذكيرات الصلاة.';

  @override
  String get notificationPermissionDenied =>
      'إذن الإشعارات مطلوب. فعّله من إعدادات النظام.';

  @override
  String get exactAlarmHint =>
      'لتذكيرات دقيقة في وقتها، اسمح لهذا التطبيق بـ \'التنبيهات والتذكيرات\' في إعدادات النظام.';
}
