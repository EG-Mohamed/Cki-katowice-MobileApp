# Releasing CKI Katowice to the App Store

A start-to-finish runbook for shipping this app to the App Store. Follow it in order.

## 0. Prerequisites you must provide

- **A privacy policy URL.** App Store Connect requires one before submission.
- **An active Apple Developer Program membership** ($99/year), enrolled under team id
  `8RXNJ4FF8V` (already configured in the Xcode project).

## 1. Identity & signing

- Bundle id: **`pl.ckikatowice.app`** (already set for Debug/Release/Profile in
  `ios/Runner.xcodeproj/project.pbxproj`).
- Test target bundle id: `pl.ckikatowice.app.RunnerTests`.
- Team: `8RXNJ4FF8V`, already set as `DEVELOPMENT_TEAM` for all three build configurations.
- **Register the App ID** `pl.ckikatowice.app` in the Apple Developer portal if it isn't
  already (Certificates, Identifiers & Profiles → Identifiers → +).
- Use **automatic signing** in Xcode (Signing & Capabilities tab on the Runner target) —
  Xcode will provision and manage certificates/profiles for you as long as your Apple ID is
  logged in and has access to team `8RXNJ4FF8V`.

## 2. Build the release IPA

```bash
flutter build ipa --release
```

Output: `build/ios/ipa/*.ipa`, plus an Xcode archive you can also drive manually via
**Product → Archive** in Xcode if you need to inspect it before upload.

Upload with either:
- **Xcode Organizer** (Window → Organizer → Archives → Distribute App), or
- **Transporter** app (drag the `.ipa` in) if you built headlessly via the CLI.

## 3. App Store Connect: create the app record

1. App Store Connect → **My Apps → +** → New App.
2. Platform: iOS. Bundle ID: `pl.ckikatowice.app` (select the registered identifier, don't
   retype it). SKU: any internal identifier (e.g. `ckikatowice-ios`).
3. **Screenshots** — required per device class actually supported. At minimum:
   - 6.9" (iPhone 16 Pro Max / 15 Pro Max class)
   - 6.5" (iPhone 11 Pro Max / XS Max class, still required by some older baseline)
   - 12.9" iPad Pro — `TARGETED_DEVICE_FAMILY` is set to `"1,2"` (iPhone + iPad), so the
     project is built to run on iPad and this screenshot set is required. If the UI hasn't
     actually been tested on an iPad, do that before submission (see step 9) or change
     `TARGETED_DEVICE_FAMILY` to `"1"` (iPhone only) to avoid shipping an untested iPad
     experience.
4. **Description, keywords, promotional text** — provide both **English and Polish**
   localizations in App Store Connect (App Information → Localizable Information), matching
   the in-app locale support (`en`, `pl`, `ar`).
5. **Age rating** questionnaire — no objectionable content, no user-generated content, no
   ads; should rate 4+.

## 4. Export compliance

`Info.plist` already sets:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This skips the export compliance questionnaire on every upload. It is correct here because
the app only uses HTTPS (standard, exempt encryption) and implements no custom cryptography.
If you ever add anything that does its own crypto beyond TLS, this must be revisited before
the next upload — a `false` value paired with actual non-exempt encryption is treated as a
compliance misstatement, not just a wrong label.

## 5. Privacy nutrition labels

App Store Connect → App Privacy. Declare:

- **Location** — collected, used for **App Functionality** (Qibla direction), processed
  **on-device**, **not linked** to the user's identity, **not used for tracking**.
- **No other data types.** No analytics, no advertising identifiers, no user accounts.
- Answer "No" to "Do you or your third-party partners use data to track users" — nothing in
  this app does cross-app/cross-site tracking.

## 6. ATS exception justification

`Info.plist` replaces the previous blanket `NSAllowsArbitraryLoads` with narrow exceptions:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSExceptionDomains</key>
  <dict>
    <key>radiojar.com</key>
    <dict>
      <key>NSIncludesSubdomains</key><true/>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
    </dict>
    <key>radiojar.net</key>
    <dict>
      <key>NSIncludesSubdomains</key><true/>
      <key>NSExceptionAllowsInsecureHTTPLoads</key><true/>
    </dict>
  </dict>
</dict>
```

If App Review asks about this (they sometimes flag any ATS exception), the justification is:
*"The app streams internet radio (Quran recitation) from third-party stations hosted on
Radiojar (`radiojar.com`/`radiojar.net`), which serve some streams over plain HTTP without a
TLS option we control. All other network traffic, including the mosque's own prayer-times
API, uses HTTPS. This exception is scoped to exactly those two ad hosting domains and does
not disable ATS app-wide."*

## 7. Background modes justification

`Info.plist` declares:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
  <string>fetch</string>
</array>
```

- **`audio`** — Quran and radio playback continues when the app is backgrounded or the
  screen is locked. Standard, low-scrutiny justification for a media-playback app.
- **`fetch`** — periodic background refresh of the prayer-times schedule, so notification
  coverage doesn't run out on a device the user hasn't opened in a while. If Review asks,
  the justification is: *"The app's core purpose is timely prayer notifications; background
  fetch keeps the local notification schedule extended so a user who hasn't opened the app
  in several days still receives correctly-timed Adhan notifications."*

## 8. BGTaskScheduler note

`AppDelegate.swift` registers the background task id `pl.ckikatowice.app.prayerRefresh`,
also declared in `Info.plist` under `BGTaskSchedulerPermittedIdentifiers`. **This id must
stay prefixed by the app's actual bundle id at all times.** iOS silently fails to register
a BGTaskScheduler task (or throws) if the prefix doesn't match the running app's bundle id —
this exact mismatch was a live bug during earlier development (bundle id was
`com.example.ckikatowice` while the task id already said `pl.ckikatowice.app.prayerRefresh`),
and background prayer-schedule refresh did not run at all until the bundle id was corrected.
If the bundle id is ever changed again, this task id and the `Info.plist` entry must change
with it in the same commit.

## 9. TestFlight

1. Upload a build via step 2, then App Store Connect → TestFlight tab.
2. **Internal testing** — up to 100 users on your team, no Beta App Review needed, available
   almost immediately after processing.
3. **External testing** — requires **Beta App Review** (similar to full review, usually
   faster). Use this for a wider pre-release group, e.g. mosque committee members.
4. Test on a physical device with the screen locked and the app force-quit — this is the
   condition that matters most for Adhan delivery, and simulators cannot reliably simulate
   backgrounded BGTaskScheduler behavior.

## 10. Review notes template

Paste something like this into the "Notes for Review" field on submission:

> This app provides Islamic prayer times and a call-to-prayer (Adhan) notification for
> Centrum Kultury Islamu Katowice, a mosque in Katowice, Poland. Prayer times are fetched
> from the mosque's own API (ckikatowice.pl). Location permission is used only for the
> Qibla (prayer direction) compass feature and is never transmitted anywhere — all
> processing is on-device. There is no login, no user accounts, and no user-generated
> content. If a demo account or specific test steps are needed, none are required — all
> features are available without sign-in.

No test account is needed since there's no authentication in the app.

## Pre-flight checklist

- [ ] Bundle id `pl.ckikatowice.app` confirmed in the Xcode project and the Developer portal
- [ ] Automatic signing resolves cleanly for team `8RXNJ4FF8V`
- [ ] `flutter build ipa --release` succeeds
- [ ] Privacy policy URL live and entered in App Store Connect
- [ ] Screenshots provided for every required device class
- [ ] EN + PL localized description/keywords entered
- [ ] Export compliance: `ITSAppUsesNonExemptEncryption = false` still accurate
- [ ] App Privacy nutrition labels filled in (location, on-device, not tracking)
- [ ] ATS exception still scoped to only the radio domains, not blanket
- [ ] Background modes (`audio`, `fetch`) justified in review notes if asked
- [ ] BGTaskScheduler id still prefixed by the current bundle id
- [ ] TestFlight internal build tested with the app force-quit and screen locked
