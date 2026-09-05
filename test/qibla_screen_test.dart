import 'package:ckikatowice/core/localization/arb/app_localizations.dart';
import 'package:ckikatowice/data/services/qibla_service.dart';
import 'package:ckikatowice/features/qibla/qibla_screen.dart';
import 'package:ckikatowice/state/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FailedLocation extends QiblaService {
  @override
  Future<bool> ensurePermission() async => true;
  @override
  Future<void> resolveLocation() async =>
      throw StateError('Location services disabled');
}

void main() {
  testWidgets('location failure ends spinner and offers recovery', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<QiblaService>(create: (_) => _FailedLocation()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const QiblaScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        'Location could not be obtained. Enable location services and try again.',
      ),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
