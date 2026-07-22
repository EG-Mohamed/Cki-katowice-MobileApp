import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/localization/arb/app_localizations.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/models/content.dart';
import '../../data/services/news_service.dart';
import '../../shared/widgets/app_background.dart';
import '../../state/theme_controller.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final ScrollController _controller = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<NewsItem> _items = [];
  final List<ContentCategory> _categories = [];

  String? _locale;
  Timer? _searchDebounce;
  int? _categoryId;
  int _page = 1;
  int _lastPage = 1;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isLoadingCategories = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context).languageCode;
    if (_locale != locale) {
      _locale = locale;
      _loadCategories();
      _loadFirstPage();
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categories.clear();
      _categoryId = null;
      _isLoadingCategories = true;
    });
    try {
      final categories = await context.read<NewsService>().categories();
      if (!mounted) return;
      setState(() {
        _categories.addAll(categories);
        _isLoadingCategories = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _items.clear();
      _page = 1;
      _lastPage = 1;
      _isLoading = true;
      _hasError = false;
    });
    await _loadPage(1, replace: true);
  }

  Future<void> _refresh() async {
    await _loadCategories();
    await _loadFirstPage();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || _page >= _lastPage) return;
    setState(() => _isLoadingMore = true);
    await _loadPage(_page + 1);
  }

  Future<void> _loadPage(int page, {bool replace = false}) async {
    try {
      final result = await context.read<NewsService>().page(
        page: page,
        search: _searchController.text,
        categoryId: _categoryId,
      );
      if (!mounted) return;
      setState(() {
        if (replace) _items.clear();
        _items.addAll(result.items);
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    if (_controller.position.extentAfter < 360) {
      _loadMore();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), _loadFirstPage);
  }

  void _selectCategory(int? id) {
    if (_categoryId == id) return;
    setState(() => _categoryId = id);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return AppBackground(
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.transparent,
                title: Text(l10n.newsAnnouncements),
              ),
              SliverToBoxAdapter(
                child: _NewsFilters(
                  controller: _searchController,
                  categories: _categories,
                  selectedCategoryId: _categoryId,
                  loadingCategories: _isLoadingCategories,
                  onSearchChanged: _onSearchChanged,
                  onCategorySelected: _selectCategory,
                ),
              ),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_hasError && _items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.emptyNews,
                      style: TextStyle(color: BrandColors.textMuted),
                    ),
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      l10n.emptyNews,
                      style: TextStyle(color: BrandColors.textMuted),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => _NewsCard(
                      item: _items[i],
                      onTap: () => context.go(
                        '/news/${Uri.encodeComponent(_items[i].slug)}',
                      ),
                    ),
                  ),
                ),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.paddingOf(context).bottom + 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsFilters extends StatelessWidget {
  const _NewsFilters({
    required this.controller,
    required this.categories,
    required this.selectedCategoryId,
    required this.loadingCategories,
    required this.onSearchChanged,
    required this.onCategorySelected,
  });

  final TextEditingController controller;
  final List<ContentCategory> categories;
  final int? selectedCategoryId;
  final bool loadingCategories;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<int?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            autocorrect: false,
            enableSuggestions: false,
            spellCheckConfiguration: SpellCheckConfiguration.disabled(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchNews,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        controller.clear();
                        onSearchChanged('');
                      },
                      icon: const Icon(Icons.close),
                    ),
              filled: true,
              fillColor: BrandColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: BrandColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: BrandColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: BrandColors.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 38,
            child: loadingCategories
                ? Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final category = isAll ? null : categories[index - 1];
                      final selected = isAll
                          ? selectedCategoryId == null
                          : selectedCategoryId == category!.id;
                      return ChoiceChip(
                        label: Text(
                          isAll ? l10n.allCategories : category!.name,
                        ),
                        selected: selected,
                        onSelected: (_) => onCategorySelected(category?.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.onTap});
  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.yMMMMd(locale).format(item.date);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: BrandColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: BrandColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (item.featuredImageUrl != null)
                        Image.network(
                          item.featuredImageUrl!,
                          cacheWidth: 720,
                          cacheHeight: 440,
                          fit: BoxFit.cover,
                          headers: const {
                            'Accept': 'image/*',
                            'User-Agent': 'CKI-Katowice-App',
                          },
                          errorBuilder: (_, _, _) => const _ImageFallback(),
                        )
                      else
                        const _ImageFallback(),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.46),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.bottomStart,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: item.category == null
                              ? null
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: BrandColors.accent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    item.category!,
                                    style: TextStyle(
                                      color: BrandColors.onAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: BrandColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: BrandColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.excerpt,
                      style: TextStyle(
                        color: BrandColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.readMore,
                      style: TextStyle(
                        color: BrandColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeController>();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrandColors.primaryLight, BrandColors.primaryDark],
        ),
      ),
    );
  }
}
