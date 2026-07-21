# CKI Katowice

The official mobile app for the **Islamic Cultural Centre Katowice** (Centrum Kultury Islamu Katowice) — prayer times, Qibla compass, the Holy Quran with a full audio player, news, the Friday Khutba, events, and community announcements.

Built with Flutter for Android and iOS. Fully localized in **English, Polish, and Arabic** (with right‑to‑left support).

---

## Features

- **Prayer times** — daily schedule with a live next‑prayer countdown, date navigation, and local Adhan notifications per prayer.
- **Qibla compass** — device compass + GPS bearing to the Kaaba, with alignment feedback.
- **Holy Quran** — a comprehensive media player:
  - Ayah‑by‑ayah reader with translation (English / Polish / Arabic) and adjustable font size.
  - Multiple reciters and narrations (riwayat) via the mp3quran provider, with a searchable reciter picker.
  - Full‑surah audio, a persistent sticky mini‑player, and a now‑playing screen.
  - **Background playback** with lock‑screen / notification media controls.
  - Live **Quran radio** stations (searchable).
- **News & announcements** — published news with search and categories; active announcements shown app‑wide as a banner.
- **Friday Khutba** — published khutbas with details.
- **Hijri date**, dark mode, and the mosque's contact details, social links, and map location.

---

## Tech stack

- **Flutter** (Dart SDK `^3.12.2`), Material 3
- **State / DI**: `provider` (`ChangeNotifier` controllers + interface‑based services)
- **Routing**: `go_router` (`StatefulShellRoute` bottom navigation)
- **Audio**: `just_audio` + `audio_service` (background playback & media notification) + `audio_session`
- **Networking**: `http`
- **Localization**: `flutter_localizations` + gen‑l10n (ARB files)
- **Other**: `shared_preferences`, `flutter_local_notifications`, `timezone`, `flutter_compass`, `geolocator`, `permission_handler`, `google_fonts`, `url_launcher`, `intl`

---

## Project structure

```
lib/
├── app.dart                     # MaterialApp.router, global banner + mini-player overlay
├── main.dart                    # DI wiring (MultiProvider), startup, AudioService.init
├── core/
│   ├── localization/arb/        # app_en.arb, app_pl.arb, app_ar.arb (+ generated)
│   ├── router/app_router.dart   # go_router config
│   ├── theme/                   # BrandColors, AppTheme, AppGradients (light + dark)
│   └── utils/                   # hijri_date, prayer_labels
├── data/
│   ├── api/api_client.dart      # backend client (sends Accept-locale header globally)
│   ├── audio/audio_handler.dart # just_audio + audio_service handler
│   ├── models/                  # content, prayer, mp3quran
│   └── services/                # one interface + Api* impl per domain
├── features/                    # announcements, home, khutba, news, qibla, quran, settings
├── shared/widgets/              # app_shell (bottom nav), app_background, mini_player, …
└── state/                       # *_controller.dart (ChangeNotifier)
```

---

## Backend & data sources

- **Mosque backend** — `https://ckikatowice.pl/api` (prayer times, news, khutbas, announcements, events, gallery, staff, site settings). The active locale is sent globally as an **`Accept-locale`** HTTP header, not per‑request query params.
- **Quran text** — `api.alquran.cloud` (surahs, translations, per‑ayah audio).
- **Quran audio / reciters / radios** — `mp3quran.net/api/v3` (reciters, narrations, full‑surah audio, radio streams).

---

## Getting started

Requires the [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel).

```bash
flutter pub get
flutter gen-l10n        # regenerate localizations if ARB files changed
flutter run
```

### Localization

Edit the three ARB files in `lib/core/localization/arb/` (`app_en.arb`, `app_pl.arb`, `app_ar.arb`), then run `flutter gen-l10n`. Do not hand‑edit the generated `app_localizations*.dart` files.

---

## Building for release

### App size

A default `flutter build apk` produces a **universal APK (~57 MB)** because it bundles native libraries for all CPU architectures. Ship per‑architecture instead — a real device downloads only its own slice (~22 MB):

```bash
# Google Play (recommended) — Play splits per device automatically
flutter build appbundle --release

# Direct distribution — separate APK per architecture
flutter build apk --release --split-per-abi
```

Release builds have R8 code + resource shrinking enabled (`android/app/build.gradle.kts`).

### Signing (Android)

Release signing reads `android/key.properties` (git‑ignored). If it's absent, the build falls back to debug keys.

1. Create a keystore:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy the template and fill it in:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
   ```properties
   storePassword=…
   keyPassword=…
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```
3. Build the App Bundle and upload the resulting `.aab` to the Play Store.

### App identity

- **Application ID**: `pl.ckikatowice.app`
- **Display name**: "CKI Katowice"

---

## Conventions

- Services are exposed by their abstract interface type and injected via `MultiProvider` in `main.dart`; swap an `Api*` implementation in one place.
- The active locale is a single global (`ApiClient.locale` → `Accept-locale` header), driven by `LocaleController`.
- Brand colors are brightness‑aware (`BrandColors.isDark`); the two brand colors are `primary` (green) and `accent` (gold).
- User‑facing text goes through `AppLocalizations` — no hardcoded strings.

---

*Built with ♥ by [Mohamed Said](https://msaied.com/).*
