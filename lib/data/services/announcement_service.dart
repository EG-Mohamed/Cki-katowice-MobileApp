import '../api/api_client.dart';
import '../models/content.dart';

abstract class AnnouncementService {
  Future<List<Announcement>> active({String? type});
}

class ApiAnnouncementService implements AnnouncementService {
  const ApiAnnouncementService(this._api);

  final ApiClient _api;

  @override
  Future<List<Announcement>> active({String? type}) async {
    final data = await _api.get('/announcements', query: {'type': type});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Announcement.fromJson)
        .toList();
  }
}
