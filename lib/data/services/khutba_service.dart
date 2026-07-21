import '../api/api_client.dart';
import '../models/content.dart';

abstract class KhutbaService {
  Future<List<Khutba>> all();
  Future<Khutba> find(String slug);
}

class ApiKhutbaService implements KhutbaService {
  const ApiKhutbaService(this._api);

  final ApiClient _api;

  @override
  Future<List<Khutba>> all() async {
    final data = await _api.get('/khutbas', query: {'per_page': 20});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Khutba.fromJson)
        .toList();
  }

  @override
  Future<Khutba> find(String slug) async {
    final data = await _api.get('/khutbas/${Uri.encodeComponent(slug)}');
    return Khutba.fromJson(data as Map<String, dynamic>);
  }
}
