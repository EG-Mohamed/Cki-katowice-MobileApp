class NewsItem {
  const NewsItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.body,
    required this.date,
    this.featuredImageUrl,
    this.category,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: (json['id'] as Object).toString(),
      slug: json['slug'] as String,
      title: json['title'] as String? ?? '',
      excerpt: _plainText(json['excerpt'] as String? ?? ''),
      body: _plainText(json['content'] as String? ?? ''),
      date: DateTime.parse(json['published_at'] as String),
      featuredImageUrl: json['featured_image_url'] as String?,
      category: _firstCategoryName(json['categories']),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String excerpt;
  final String body;
  final DateTime date;
  final String? featuredImageUrl;
  final String? category;
}

class PaginatedNews {
  const PaginatedNews({
    required this.items,
    required this.currentPage,
    required this.lastPage,
  });

  factory PaginatedNews.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};
    return PaginatedNews(
      items: ((json['data'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(NewsItem.fromJson)
          .toList(),
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
    );
  }

  final List<NewsItem> items;
  final int currentPage;
  final int lastPage;
}

class ContentCategory {
  const ContentCategory({required this.id, required this.name});

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
    );
  }

  final int id;
  final String name;
}

class Khutba {
  const Khutba({
    required this.id,
    required this.slug,
    required this.title,
    required this.khatib,
    required this.date,
    required this.summary,
    required this.body,
    this.isUpcoming = false,
  });

  factory Khutba.fromJson(Map<String, dynamic> json) {
    final date = DateTime.parse(json['date'] as String);
    return Khutba(
      id: (json['id'] as Object).toString(),
      slug: json['slug'] as String,
      title: json['title'] as String? ?? '',
      khatib: json['speaker'] as String? ?? '',
      date: date,
      summary: _plainText(json['summary'] as String? ?? ''),
      body: _plainText(json['content'] as String? ?? ''),
      isUpcoming: !date.isBefore(_today()),
    );
  }

  final String id;
  final String slug;
  final String title;
  final String khatib;
  final DateTime date;
  final String summary;
  final String body;
  final bool isUpcoming;
}

class Ayah {
  const Ayah({
    required this.number,
    required this.arabic,
    required this.translation,
    this.audioUrl,
  });

  final int number;
  final String arabic;
  final String translation;
  final String? audioUrl;
}

class Surah {
  const Surah({
    required this.number,
    required this.nameArabic,
    required this.nameLatin,
    required this.meaning,
    required this.versesCount,
    required this.revelation,
    this.ayat = const [],
  });

  final int number;
  final String nameArabic;
  final String nameLatin;
  final String meaning;
  final int versesCount;
  final String revelation;
  final List<Ayah> ayat;
}

class SiteSettings {
  const SiteSettings({
    required this.name,
    required this.description,
    required this.url,
    required this.logo,
    required this.email,
    required this.address,
    required this.primaryPhone,
    required this.secondaryPhone,
    required this.social,
    required this.latitude,
    required this.longitude,
  });

  factory SiteSettings.fromJson(Map<String, dynamic> json) {
    final social = json['social'] as Map<String, dynamic>? ?? const {};
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    return SiteSettings(
      name: (json['name'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
      logo: (json['logo'] as String? ?? '').trim(),
      email: (json['email'] as String? ?? '').trim(),
      address: (json['address'] as String? ?? '').trim(),
      primaryPhone: (json['primary_phone'] as String? ?? '').trim(),
      secondaryPhone: (json['secondary_phone'] as String? ?? '').trim(),
      social: {
        for (final entry in social.entries)
          if (entry.value is String && (entry.value as String).trim().isNotEmpty)
            entry.key: (entry.value as String).trim(),
      },
      latitude: (location['latitude'] as num?)?.toDouble(),
      longitude: (location['longitude'] as num?)?.toDouble(),
    );
  }

  final String name;
  final String description;
  final String url;
  final String logo;
  final String email;
  final String address;
  final String primaryPhone;
  final String secondaryPhone;
  final Map<String, String> social;
  final double? latitude;
  final double? longitude;

  bool get hasLocation => latitude != null && longitude != null;
}

enum AnnouncementType { general, urgent, maintenance }

class Announcement {
  const Announcement({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] as Object).toString(),
      type: _typeFrom(json['type'] as String?),
      title: (json['title'] as String? ?? '').trim(),
      body: _plainText(json['content'] as String? ?? json['body'] as String? ?? ''),
    );
  }

  final String id;
  final AnnouncementType type;
  final String title;
  final String body;

  static AnnouncementType _typeFrom(String? raw) {
    switch (raw) {
      case 'urgent':
        return AnnouncementType.urgent;
      case 'maintenance':
        return AnnouncementType.maintenance;
      default:
        return AnnouncementType.general;
    }
  }
}

String? _firstCategoryName(Object? value) {
  if (value is List && value.isNotEmpty) {
    final first = value.first;
    if (first is Map<String, dynamic>) {
      return first['name'] as String?;
    }
  }
  return null;
}

String _plainText(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#039;', "'")
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}
