import '../api/api_client.dart';
import '../models/content.dart';

abstract class NewsService {
  Future<PaginatedNews> page({int page = 1, String? search, int? categoryId});
  Future<NewsItem> find(String slug);
  Future<List<ContentCategory>> categories();
}

class ApiNewsService implements NewsService {
  ApiNewsService(this._api);

  final ApiClient _api;
  final Map<String, ({DateTime storedAt, Future<NewsItem> value})>
  _detailCache = {};

  @override
  Future<PaginatedNews> page({
    int page = 1,
    String? search,
    int? categoryId,
  }) async {
    final data = await _api.getEnvelope(
      '/news',
      query: {
        'per_page': 10,
        'page': page,
        'search': search?.trim().isEmpty == true ? null : search?.trim(),
        'category_id': categoryId,
      },
    );
    return PaginatedNews.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<NewsItem> find(String slug) {
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

  Future<NewsItem> _find(String slug) async {
    final data = await _api.get('/news/${Uri.encodeComponent(slug)}');
    return NewsItem.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<List<ContentCategory>> categories() async {
    final data = await _api.get('/news-categories', query: {'per_page': 100});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(ContentCategory.fromJson)
        .toList();
  }
}
