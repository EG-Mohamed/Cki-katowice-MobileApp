import 'dart:async';
import 'package:ckikatowice/core/localization/arb/app_localizations.dart';
import 'package:ckikatowice/data/models/content.dart';
import 'package:ckikatowice/data/services/news_service.dart';
import 'package:ckikatowice/features/news/news_list_screen.dart';
import 'package:ckikatowice/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _News extends NewsService {
  final requests = <String, Completer<PaginatedNews>>{};
  @override
  Future<PaginatedNews> page({int page = 1, String? search, int? categoryId}) =>
      requests.putIfAbsent(search ?? '', Completer.new).future;
  @override
  Future<List<ContentCategory>> categories() async => [];
  @override
  Future<NewsItem> find(String slug) => throw UnimplementedError();
}

PaginatedNews _page(String title) => PaginatedNews(
  items: [
    NewsItem(
      id: title,
      slug: title,
      title: title,
      excerpt: '',
      body: '',
      date: DateTime(2026, 9, 5),
    ),
  ],
  currentPage: 1,
  lastPage: 1,
);
void main() {
  testWidgets('stale search response cannot replace current results', (
    tester,
  ) async {
    final service = _News();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<NewsService>.value(value: service),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const NewsListScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'new');
    await tester.pump(const Duration(milliseconds: 500));
    service.requests['new']!.complete(_page('New result'));
    await tester.pumpAndSettle();
    expect(find.text('New result'), findsOneWidget);
    service.requests['']!.complete(_page('Stale result'));
    await tester.pumpAndSettle();
    expect(find.text('Stale result'), findsNothing);
    expect(find.text('New result'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
