# Prayer reminder reliability

## Architecture

- `PrayerScheduler` is shared by the foreground coordinator and the Workmanager entry point. OS local notifications deliver each alert; Flutter timers only update the visible countdown.
- Android schedules `exactAllowWhileIdle` with user-granted Alarms & reminders access. Without it, reminders use `inexactAllowWhileIdle`, and Settings explicitly warns that delivery may be delayed. App notification permission and the prayer channel are checked separately.
- Android schedules 30 days ahead. iOS schedules up to 60 prayer alerts over 12 calendar days, accounting for unrelated pending requests and reserving slots for a coverage reminder and test.
- The unique Workmanager task is `pl.ckikatowice.app.prayerRefresh`. Android requests a 12-hour interval; iOS receives a 12-hour earliest-start hint. OS scheduling is opportunistic. Registering work is separate from delivering prayer alerts.
- SQLite provides a cross-isolate scheduling lock via the sqflite plugin. Contention retries in Dart, rather than blocking the native database executor. Preference changes use the same lock; the scheduler reloads preferences after acquisition.
- Stable IDs preserve upgrades. Payloads encode prayer/date/UTC time/precision/language for reconciliation. Android pending requests are plugin metadata, not an OS alarm audit: launch, resume and worker runs reapply Android alarms. iOS retains unchanged requests.
- Offline caching is per date and reads the old cache on upgrades. Corrupt rows do not discard valid dates. Gaps/partial failures are visible, and failures preserve existing reminders. User-requested muting still cancels alerts offline.
- The iOS coverage reminder asks the user to open the app 24 hours before the last completely scheduled day's coverage expires. The existing 13-second adhan asset remains within iOS's custom notification sound limit.

## Automated checks

```sh
flutter analyze --no-pub
flutter test --no-pub
flutter test integration_test/notification_plugins_test.dart -d <mobile-device-or-ios-simulator>
```

The integration checks exercise real plugin scheduling/cancellation, cross-isolate SQLite locking, Workmanager registration/cancellation, and a native Workmanager callback invoking the shared scheduler. They do **not** prove lock-screen delivery, Android Doze behavior, or automatic background execution on a physical device.

## Builds

```sh
# Production: requires the actual release keystore referenced by android/key.properties.
flutter build apk --release --split-per-abi
flutter build appbundle --release

# Local QA only: optimized release binaries signed with the local debug key.
ORG_GRADLE_PROJECT_localTestSigning=true flutter build apk --release --split-per-abi

# iOS compile/package validation; installation still requires signing.
flutter build ios --release --no-codesign
```

After switching between integration tests and production builds, run the build commands without `--no-pub`: Flutter must regenerate registrants to exclude development-only native plugins.

A locally test-signed APK cannot replace an installation signed with another key. Do not uninstall a user's existing app merely to bypass that mismatch; use a spare test device or the correct production signing key. iOS minimum deployment is 14.0. No custom native alarm or worker implementation is included; AppDelegate only wires the plugins.

## Physical-device acceptance checklist

Record device model, OS version, build, scheduled and observed times, notification permission, exact-alarm access (Android), Background App Refresh (iOS), and battery restrictions.

1. Fresh install: enable reminders, accept notifications and Android exact alarms. Settings must show upcoming reminders and coverage.
2. Select **Test with screen locked**, immediately lock the screen, and confirm a single alert roughly 15 seconds later. Repeat without reopening the app. When exact permission is denied, the test can be late and the UI must show that limitation.
3. Check actual prayer notifications with the screen locked, app backgrounded and app process normally terminated. Confirm one alert and one adhan, without a duplicate when reopening.
4. Android: test Doze using a dedicated test device and `adb shell dumpsys deviceidle force-idle`; restore normal operation with `adb shell dumpsys deviceidle unforce`. Verify delivery independently of the 15-second test because idle alarms are rate-limited.
5. Android: reboot after scheduling, unlock once and verify subsequent delivery. Revoke/restore exact access and return to the app; verify schedule repair and honest precision status.
6. Enable airplane mode after scheduling. Scheduled prayers must continue within cached coverage. Disable one prayer offline and confirm its pending reminders are removed.
7. iOS: disable Background App Refresh and verify already scheduled notifications still arrive. Verify the coverage reminder is present; local coverage cannot extend indefinitely if iOS never grants background time.
8. Test Friday Jumuah, Warsaw DST changes, travel/device timezone changes, midnight rollover and language changes.
9. Exercise rapid date/filter/track changes, playback stop during loading, Qibla with location disabled, and navigation away during requests. Check for stuck loaders, wrong content and uncaught errors.

Android force-stop and manufacturer restrictions, and iOS Focus/notification settings/background scheduling decisions, can prevent or defer delivery. Do not describe simulator tests or a stored pending list as proof these conditions work. Production phone acceptance remains required.

## Validation recorded on 2026-09-05

- Flutter analysis: clean.
- Unit/widget suite: 25 passed.
- iPhone 17 Pro simulator, iOS 26.5: four native plugin integration tests passed.
- Android optimized per-ABI APKs: built and signature-verified with the local debug key. ARM64 APK is approximately 24.3 MB.
- Android resource audit: adhan bytes match the source asset; notification icon, scheduled/boot receivers, Workmanager initializer and job service remain packaged.
- iOS release application: built without signing; iOS 14 minimum, background refresh identifier and bundled adhan verified.
- Live prayer API: returned the expected 30-day timetable with application request headers.
- Physical-phone screen-off delivery, Android Doze/OEM restrictions, and production signing remain unverified/unavailable in this checkout.
- Toolchain notices: the installed Workmanager Android plugin still uses Kotlin Gradle Plugin; flutter_compass still uses CocoaPods on iOS. Current builds succeed; check plugin compatibility before a future Flutter toolchain upgrade.
