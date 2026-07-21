class Reciter {
  const Reciter({required this.id, required this.name, required this.moshaf});

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      moshaf: ((json['moshaf'] as List?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Moshaf.fromJson)
          .where((moshaf) => moshaf.server.isNotEmpty && moshaf.surahIds.isNotEmpty)
          .toList(),
    );
  }

  final int id;
  final String name;
  final List<Moshaf> moshaf;
}

class Moshaf {
  const Moshaf({
    required this.id,
    required this.name,
    required this.server,
    required this.surahTotal,
    required this.moshafType,
    required this.surahIds,
  });

  factory Moshaf.fromJson(Map<String, dynamic> json) {
    final surahIds = (json['surah_list'] as String? ?? '')
        .split(',')
        .map((value) => int.tryParse(value.trim()) ?? 0)
        .where((value) => value > 0)
        .toList();
    return Moshaf(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      server: (json['server'] as String? ?? '').trim(),
      surahTotal: (json['surah_total'] as num?)?.toInt() ?? 0,
      moshafType: (json['moshaf_type'] as num?)?.toInt() ?? 0,
      surahIds: surahIds,
    );
  }

  final int id;
  final String name;
  final String server;
  final int surahTotal;
  final int moshafType;
  final List<int> surahIds;

  String audioUrlFor(int surahId) {
    final base = server.endsWith('/')
        ? server.substring(0, server.length - 1)
        : server;
    return '$base/${surahId.toString().padLeft(3, '0')}.mp3';
  }

  bool hasSurah(int surahId) {
    return surahIds.contains(surahId);
  }
}

class MoshafSurah {
  const MoshafSurah({
    required this.id,
    required this.name,
    required this.startPage,
    required this.endPage,
    required this.makkia,
    required this.type,
  });

  factory MoshafSurah.fromJson(Map<String, dynamic> json) {
    return MoshafSurah(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      startPage: (json['start_page'] as num?)?.toInt() ?? 0,
      endPage: (json['end_page'] as num?)?.toInt() ?? 0,
      makkia: (json['makkia'] as num?)?.toInt() == 1,
      type: (json['type'] as num?)?.toInt() ?? 0,
    );
  }

  final int id;
  final String name;
  final int startPage;
  final int endPage;
  final bool makkia;
  final int type;
}

class Riwayah {
  const Riwayah({required this.id, required this.name});

  factory Riwayah.fromJson(Map<String, dynamic> json) {
    return Riwayah(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  final int id;
  final String name;
}

class QuranRadio {
  const QuranRadio({
    required this.id,
    required this.name,
    required this.url,
  });

  factory QuranRadio.fromJson(Map<String, dynamic> json) {
    return QuranRadio(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String? ?? '').trim(),
      url: (json['url'] as String? ?? '').trim(),
    );
  }

  final int id;
  final String name;
  final String url;
}
