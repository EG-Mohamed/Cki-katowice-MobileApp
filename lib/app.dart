import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/localization/arb/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/brand_colors.dart';
import 'features/announcements/announcement_banner.dart';
import 'features/quran/widgets/mini_player.dart';
import 'shared/shell_scope.dart';
import 'state/locale_controller.dart';
import 'state/theme_controller.dart';

class CkiApp extends StatefulWidget {
  const CkiApp({super.key});

  @override
  State<CkiApp> createState() => _CkiAppState();
}

class _CkiAppState extends State<CkiApp> {
  final _router = buildRouter();

  static const List<String> _fullScreenPrefixes = [
    '/quran/reciters',
    '/now-playing',
    '/khutba',
  ];

  @override
  void initState() {
    super.initState();
    _router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  void _onRouteChanged() {
    final location = _router.routerDelegate.currentConfiguration.uri.path;
    ShellScope.isShellRoute.value = !_isFullScreen(location);
    ShellScope.location.value = location;
  }

  bool _isFullScreen(String location) {
    for (final prefix in _fullScreenPrefixes) {
      if (location.startsWith(prefix)) return true;
    }
    if (RegExp(r'^/quran/\d+$').hasMatch(location)) return true;
    if (RegExp(r'^/news/[^/]+$').hasMatch(location)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>().locale;
    final isDark = context.watch<ThemeController>().isDark;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(locale, isDark: isDark),
      routerConfig: _router,
      builder: (context, child) {
        return Scaffold(
          // color: BrandColors.scaffold,
          body: Column(
            children: [
              SafeArea(bottom: false, child: const AnnouncementBanner()),
              Expanded(
                child: Stack(
                  children: [
                    child ?? const SizedBox.shrink(),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: MiniPlayer(
                        onOpenSurah: (id) => _router.go('/quran/$id'),
                        onOpenRadio: () => _router.push('/now-playing'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
