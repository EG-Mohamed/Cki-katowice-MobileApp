import '../api/api_client.dart';
import '../models/content.dart';

abstract class SettingsService {
  Future<SiteSettings> fetch();
}

class ApiSettingsService implements SettingsService {
  const ApiSettingsService(this._api);

  final ApiClient _api;

  @override
  Future<SiteSettings> fetch() async {
    final data = await _api.getEnvelope('/settings');
    final payload = data is Map<String, dynamic> && data['data'] is Map
        ? data['data'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    return SiteSettings.fromJson(payload);
  }
}
