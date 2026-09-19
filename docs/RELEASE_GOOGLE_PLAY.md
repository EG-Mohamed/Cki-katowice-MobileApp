# Releasing CKI Katowice to Google Play

A start-to-finish runbook for shipping this app to the Play Store. Follow it in order.

## 0. Prerequisites you must provide

These block submission and are not something code can fix:

- **A privacy policy URL.** Play Console requires one before you can publish. Host it
  anywhere reachable (the mosque website is fine) and keep the link stable.
- **A Google Play Developer account** (one-time $25 fee) with access to create apps.

## 1. Generate the upload keystore

`android/key.properties` already exists and points at `android/app/upload-keystore.jks`,
which **does not exist yet** — this is the only remaining release blocker. The build's
signing guard (`android/app/build.gradle.kts`) will fail any `assembleRelease*`,
`bundleRelease*`, or `packageRelease*` task until this file is created; it deliberately
cannot fall back to debug signing for a real release build.

```bash
keytool -genkey -v \
  -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

- When prompted for the keystore password and key password, use **exactly** the values
  already in `android/key.properties` (`storePassword`, `keyPassword`), or edit that file
  to match whatever you actually enter. The alias must be `upload` to match
  `keyAlias=upload` in that file.
- **Back this file up outside the repository** (password manager, encrypted drive). If you
  lose it, you can never update the app under the same listing again — Play Console cannot
  reset it for you.
- `android/key.properties` and `*.jks` are already gitignored — verify with
  `git check-ignore android/key.properties android/app/upload-keystore.jks` before your
  first commit that touches this directory.
- **Enroll in Play App Signing** when you create the app in Play Console (it's the default
  path now). You still keep and use this upload key for every build you submit; Google
  re-signs it with the app signing key behind the scenes.

## 2. Build the release bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`.

**Confirm it is not debug-signed** before uploading anything:

```bash
unzip -p build/app/outputs/bundle/release/app-release.aab META-INF/*.RSA | keytool -printcert
```

The certificate owner should be whatever you entered as your name/organization when
generating the keystore in step 1 — not "Android Debug".

If you need a local QA build signed with the debug key instead (for testing on a device
without touching the release signing path), pass:

```bash
flutter build appbundle -PlocalTestSigning=true
```

## 3. Versioning

`pubspec.yaml` controls both Play values via the `version:` line, currently `1.0.0+1`:

```
version: <versionName>+<versionCode>
```

- `versionName` (`1.0.0`) is the human-facing version shown to users.
- `versionCode` (`1`) is the internal build number Play uses to order releases — it **must
  strictly increase** on every upload, even for the same `versionName`. Bump only the
  number after `+` for a patch (`1.0.0+2`), and the part before `+` for a user-facing
  version bump (`1.1.0+3`).

## 4. Play Console: create the app

1. Play Console → **Create app** → fill in name (`CKI Katowice`), default language (Polish),
   app type (Application), free/paid.
2. **Store listing**: short + full description (Polish primary, English if you want wider
   reach), category (likely "Lifestyle" or "Education"), contact details, privacy policy URL
   from step 0.
3. **Graphics assets** you'll need:
   - App icon: 512×512 PNG (already generated via `flutter_launcher_icons` for the app
     itself; export a matching 512×512 separately for the listing).
   - Feature graphic: 1024×500 PNG/JPG.
   - Phone screenshots: at least 2, PNG/JPG, 16:9 or 9:16.
   - 7" and 10" tablet screenshots if you want tablet listing (optional — check whether the
     UI is tablet-tested first).

## 5. Content rating & target audience

- Complete the **Content rating questionnaire** — this is a mosque/prayer-times app with no
  user-generated content, ads, or in-app purchases, so it should rate as "Everyone".
- **Target audience**: select the actual audience (general, not specifically children) —
  this affects which Play policies apply (e.g. Families policy does not apply here).

## 6. Data Safety declaration

This app is specifically low-risk here — declare accurately:

- **Location**: collected — used for the Qibla direction feature
  (`ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`). Processed **on-device only**, **not
  collected or shared** with the developer or third parties, **not** linked to identity.
- **No other data types** are collected: no analytics SDK, no ads SDK, no account/auth data,
  no user-generated content leaves the device.
- No data is shared with third parties.

## 7. Exact-alarm and battery-optimization declarations

`AndroidManifest.xml` declares:

```xml
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS"/>
```

- **`USE_EXACT_ALARM`** requires a declaration in Play Console (App content → Permissions
  declaration → Alarms & reminders). Google restricts this permission to apps whose core
  function is a user-facing alarm/reminder at a specific time — a prayer-times app whose
  entire purpose is a precisely-timed Adhan notification is a strong, defensible fit.
  Justification text to use: *"This app's sole purpose is notifying users of Islamic prayer
  times at their exact scheduled moment. A prayer notification delivered even a few minutes
  late has failed its purpose, so exact alarm scheduling is core functionality, not an
  optimization."*
- **`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`** also draws review scrutiny. Justification: the
  in-app "Reliable Adhan" settings card (`lib/features/settings/widgets/reliable_adhan_card.dart`)
  surfaces this as an optional, user-initiated action with a clear one-tap toggle — it is
  never requested silently or on first launch, satisfying Play's requirement that this
  permission be user-initiated and clearly explained.

## 8. Foreground service declaration

`AndroidManifest.xml` declares `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
for Quran/radio audio playback, correctly paired with
`foregroundServiceType="mediaPlayback"` (an Android 14 hard requirement, already done).

Play Console → App content → Permissions declaration → Foreground service:
select **Media playback**, and be ready to attach a short screencast showing audio
continuing to play with the app backgrounded, if Google's review asks for one (they
increasingly do for this category).

## 9. Notification permission rationale

`POST_NOTIFICATIONS` is declared and requested at runtime (Android 13+). No separate Play
declaration is needed for this one, but make sure your store listing or in-app onboarding
makes clear *why* the app asks for notification permission (Adhan delivery) — this reduces
uninstalls from a permission prompt with no visible reason.

## 10. Target API level compliance

Check `flutter.targetSdkVersion` (set via the Flutter SDK's Android embedding, read from
`android/app/build.gradle.kts:37`) meets Play's current minimum target API level.
Play enforces a **new minimum target SDK every year** (usually around August) for existing
apps — check the current requirement at submission time, since this document will go stale.

## 11. Release rollout

1. **Internal testing** track first — invite yourself and a couple of others, install from
   the internal link, and run through the physical-device verification checklist below.
2. **Closed testing** (optional but recommended) — a small group of real users, ideally on
   varied OEM devices (Xiaomi, Samsung, Huawei are common in Poland and have the most
   aggressive battery managers).
3. **Production**, with a **staged rollout** (start at 10-20%) rather than 100% on day one.
   You can **halt a rollout** from Play Console → Production → the running release → "Halt
   rollout" if a crash rate or bad review spike appears; this pauses further installs
   without pulling the app from users who already have it.

## Pre-flight checklist

- [ ] `android/app/upload-keystore.jks` generated and backed up outside the repo
- [ ] `flutter build appbundle --release` succeeds and the printed cert is not the debug cert
- [ ] `pubspec.yaml` version bumped, `versionCode` higher than any previous upload
- [ ] Privacy policy URL live and entered in Play Console
- [ ] Data Safety form filled in accurately (location, on-device, not shared)
- [ ] `USE_EXACT_ALARM` permission declaration submitted with justification
- [ ] `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` declaration submitted
- [ ] Foreground service (media playback) declaration submitted
- [ ] Store listing assets uploaded (icon, feature graphic, screenshots)
- [ ] Content rating questionnaire completed
- [ ] Internal testing track passed the on-device notification checklist below

## On-device verification (do this before every production rollout)

Physical Android device, ideally Xiaomi or Samsung (most aggressive battery management):

```bash
adb shell dumpsys alarm | grep pl.ckikatowice.app   # confirm exact alarms registered
adb shell cmd deviceidle force-idle                  # simulate Doze
```

1. Enable all prayers in Settings — should show ~29 days of coverage.
2. Force-stop the app, lock the screen, confirm the next Adhan still fires.
3. Reboot the device, re-check `dumpsys alarm` to confirm the boot receiver restored alarms.
4. Confirm the Adhan sound plays (5s, `res/raw/adhan.m4a`) at full volume even with the
   device on silent/Do Not Disturb is *not* expected — verify it respects DND as any alarm
   channel should.
