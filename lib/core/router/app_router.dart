import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/khutba/khutba_detail_screen.dart';
import '../../features/khutba/khutba_list_screen.dart';
import '../../features/news/news_detail_screen.dart';
import '../../features/news/news_list_screen.dart';
import '../../features/qibla/qibla_screen.dart';
import '../../features/radio/radio_screen.dart';
import '../../features/quran/now_playing_screen.dart';
import '../../features/quran/reader_screen.dart';
import '../../features/quran/reciter_picker_screen.dart';
import '../../features/quran/surah_list_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../shared/widgets/app_shell.dart';

final GlobalKey<NavigatorState> _rootKey = GlobalKey<NavigatorState>();

GoRouter buildRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/radio',
                builder: (context, state) => const RadioScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/quran',
                builder: (context, state) => const SurahListScreen(),
                routes: [
                  GoRoute(
                    path: 'reciters',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => const ReciterPickerScreen(),
                  ),
                  GoRoute(
                    path: ':number',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) => ReaderScreen(
                      surahNumber: int.parse(state.pathParameters['number']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const NewsListScreen(),
                routes: [
                  GoRoute(
                    path: ':slug',
                    parentNavigatorKey: _rootKey,
                    builder: (context, state) =>
                        NewsDetailScreen(slug: state.pathParameters['slug']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/qibla',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const QiblaScreen(),
      ),
      GoRoute(
        path: '/now-playing',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const NowPlayingScreen(),
      ),
      GoRoute(
        path: '/khutba',
        parentNavigatorKey: _rootKey,
        builder: (context, state) => const KhutbaListScreen(),
        routes: [
          GoRoute(
            path: ':slug',
            builder: (context, state) =>
                KhutbaDetailScreen(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
    ],
  );
}
