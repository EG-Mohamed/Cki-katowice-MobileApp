import '../api/api_client.dart';
import '../models/content.dart';

abstract class NewsService {
  Future<PaginatedNews> page({int page = 1, String? search, int? categoryId});
  Future<NewsItem> find(String slug);
  Future<List<ContentCategory>> categories();
}

class ApiNewsService implements NewsService {
  const ApiNewsService(this._api);

  final ApiClient _api;

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
  Future<NewsItem> find(String slug) async {
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
