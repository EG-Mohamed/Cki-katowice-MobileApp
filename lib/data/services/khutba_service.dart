import '../api/api_client.dart';
import '../models/content.dart';

abstract class KhutbaService {
  Future<List<Khutba>> all();
  Future<Khutba> find(String slug);
}

class ApiKhutbaService implements KhutbaService {
  ApiKhutbaService(this._api);

  final ApiClient _api;
  final Map<String, ({DateTime storedAt, Future<Khutba> value})> _detailCache =
      {};

  @override
  Future<List<Khutba>> all() async {
    final data = await _api.get('/khutbas', query: {'per_page': 20});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Khutba.fromJson)
        .toList();
  }

  @override
  Future<Khutba> find(String slug) {
    final cached = _detailCache[slug];
    if (cached != null &&
        DateTime.now().difference(cached.storedAt) <
            const Duration(minutes: 5)) {
      return cached.value;
    }
    final future = _find(slug);
    _detailCache[slug] = (storedAt: DateTime.now(), value: future);
    // A failed fetch must not be replayed for 5 minutes: evict it so the
    // next call (e.g. pull-to-refresh) actually retries the network.
    future.catchError((Object error) {
      if (identical(_detailCache[slug]?.value, future)) {
        _detailCache.remove(slug);
      }
      throw error;
    });
    return future;
  }

  Future<Khutba> _find(String slug) async {
    final data = await _api.get('/khutbas/${Uri.encodeComponent(slug)}');
    return Khutba.fromJson(data as Map<String, dynamic>);
  }
}
