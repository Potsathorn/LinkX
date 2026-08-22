# LinkX Tester

A Flutter tool for building, validating and testing the **CardX deeplinks**
defined in [`deeplink_spec.json`](deeplink_spec.json).

Flutter **3.44.7** (Dart 3.12) · MVVM · Provider · go_router · **Android and iOS only**.

Everything the app shows comes from the spec file — there is no hardcoded
deeplink data anywhere in `lib/`. Replacing `deeplink_spec.json` changes the
whole catalogue with no code change.

---

## What drives the app

The spec keys the app is built on, and what each one produces:

| Spec key | Drives |
|----------|--------|
| `deeplinks` | The whole catalogue — 33 entries loaded at start-up |
| `rank` | Default list order, the rank badge on every card, and the rank shown in history |
| `destination_page` | Entry title, searchable, and the QR / share subject |
| `structure.path_pattern` | The URL template — path tokens and the ` \| ` variants are parsed out of it |
| `valid_user_types.allowed` | Audience chips, the "Any user" filter, and the **Test as** selector that warns when a session type is not allowed |
| `label` | Channel chips and the "All channels" filter (Marketing / Chat / Push / Unreferenced) |
| `query_parameters.name` | One form field per parameter |
| `query_parameters.requirement` | Field grouping and validation — `required`, `conditional`, `optional` |
| `query_parameters.allowed_values_in_code` | Choice chips instead of a text field, plus rejection of any other value |

### The spec is stripped on purpose

The source document this file is derived from also carried `structure.scheme`,
`base_path`, `path_shape`, `match_rule`, `path_parameters`,
`valid_user_types.rule` and `global_precondition`. The app never read any of
them, and they described internal matching and session-check behaviour rather
than anything a deeplink tester needs.

Removing them halved the file — 37.5 KB to 19.8 KB — with no code change and no
failing test. **Keep it that way**: when you refresh this file from its source,
strip it back to the eight keys in the table above before dropping it in. What
remains describes routes an ordinary user could observe; what was removed could
not be observed from outside the app.

---

## Screens

The app is built for one user: a QA tester firing CardX deeplinks at a device.
The UI is tuned for **find → fill → fire**, and everything else is either removed
or moved behind a tap.

**Catalogue** — a ranked list, a search field, and a filter icon. Search covers
page name, path, parameter names and allowed values. Channel and user-type
filters live in a bottom sheet (`/filters`) so they cost no permanent space; a
result count appears only while a search or filter is active. A "Most used"
pill strip appears only once you have run something.

Each card carries four things and nothing else: rank, destination page, path
pattern, and one muted meta line (channel dots + allowed user types, collapsed
to `ALL` when every type is permitted).

**Generator** — the entry header, then parameters grouped Required →
Conditional → Optional, then the live URL preview. Launch, QR and share sit in
the bottom action bar.

**History** — every copy / launch / share / QR-save with its parameter snapshot,
re-launchable, and re-openable in the generator with the exact values restored.

---

## Validation rules

| Rule | Source |
|------|--------|
| A `required` parameter must have a value | `requirement: required` |
| At least one `conditional` parameter must be filled | `requirement: conditional` — matches the spec's own `category or tab is not empty` rule |
| A value must be in `allowed_values_in_code` when the list exists | `allowed_values_in_code` |
| Warn when the tested user type is not allowed | `valid_user_types.allowed` |
| Warn when the deeplink has no channel source | `label: Not referenced by any channel source` |

Values are encoded with `Uri.encodeComponent`, so spaces become `%20` rather
than `+` and a nested path value never leaks `?` or `&` into the outer query.

---

## Architecture (MVVM)

```
lib/
├── main.dart                  Loads the spec, then wires every dependency
├── core/
│   ├── constants/app_config.dart   Asset path, scheme, storage keys
│   ├── router/                     go_router config
│   ├── theme/                      Dark futuristic theme + backdrop
│   └── utils/
├── data/
│   ├── models/                DeeplinkEntry, SpecParameter, UserType,
│   │                          ChannelLabel, ParameterRequirement, …
│   ├── datasources/           DeeplinkSpecSource (asset), LocalStorage
│   └── repositories/          Deeplink (read-only), History, Usage
├── services/                  DeeplinkFormService, LinkBuilderService,
│                              QrService, ShareService, LauncherService
├── viewmodels/                Catalogue, Generator, History
└── views/                     Widgets only
```

Conventions:

* ViewModels never touch `BuildContext` or import widgets.
* Actions return an `ActionResult`; the View turns it into a snackbar.
* History and Usage repositories are `ChangeNotifier`s, so the catalogue
  refreshes itself when a deeplink is used.
* **The Dart sources contain no comments** — naming and structure carry the
  intent, and anything that needs explaining lives in this README.

---

## Splash

`/splash` is the initial route: a 1s boot sequence built entirely in Flutter
with no image assets — [splash_view.dart](lib/views/splash/splash_view.dart).

One `AnimationController` drives every layer through explicit time windows:
a scan line sweeps the screen, the five characters of **LinkX** decode out of
random glyphs staggered left to right, a chromatic split in grey and amber
settles as they lock, a targeting reticle draws around the mark, a trace line
sweeps beneath it, and the whole thing fades out into the catalogue.

Two deliberate choices:

* **Tap anywhere to skip.** A QA tester opens this app many times a day; a
  splash that cannot be dismissed becomes a tax.
* **No repeating animations.** Every window is finite and the controller runs
  once, so `pumpAndSettle` terminates and the widget tests pass straight
  through the splash without special handling.

## App icon

The launcher icon is generated from Dart, not authored in a design tool and not
produced by `flutter_launcher_icons` — there is no image dependency in the
project. [tool/generate_app_icon.dart](tool/generate_app_icon.dart) paints the
mark with the same vocabulary as the splash — **two interlocking chain rings
crossing into an X**, one amber and one light grey on a navy grid, framed by a
targeting reticle. The chain says *link*, the silhouette says *X*. It writes
every required file:

```bash
fvm flutter test tool/generate_app_icon.dart
```

That regenerates all 15 iOS sizes, the 5 legacy Android mipmaps, and the
adaptive-icon background/foreground pairs. Design details that only appear once
you look at the output:

* **Detail scales with size.** Below 120px the grid and reticle are dropped and
  the mark is enlarged, because at 40px they turn into noise.
* **The reticle sits at 15% inset** so it survives the iOS superellipse mask.
* **The adaptive foreground carries the mark only.** The reticle would fall
  outside Android's 66% safe zone and be clipped by launcher masks, so it lives
  in the background layer where cropping does not matter. That foreground also
  doubles as the `monochrome` layer for Android 13 themed icons.

## Navigation

| Route | Screen |
|-------|--------|
| `/splash` | boot animation, 1s (initial location) |
| `/catalogue` | ranked deeplink list |
| `/generator` | builder for the selected entry |
| `/history` | activity log |
| `/filters` | channel and user-type filter sheet |
| `/qr` | QR bottom sheet |

The three tabs are a `StatefulShellRoute.indexedStack`, so a half-filled
generator form survives a trip to the catalogue. `/qr` is pinned to the root
navigator via `parentNavigatorKey`, otherwise the sheet would be clipped inside
the shell branch instead of covering the navigation bar.

---

## Theme — five colours, one accent

Dark only, pinned to `ThemeMode.dark`. The palette lives in the `Palette` class
in [app_theme.dart](lib/core/theme/app_theme.dart) and is exactly five colours
plus tints derived from them:

| Token | Colour | Role |
|-------|--------|------|
| `black` | `#000000` | app ground |
| `navy` | `#14213D` | cards, panels, inputs |
| `amber` | `#FCA311` | the single accent |
| `grey` | `#E4E4E4` | secondary text |
| `white` | `#FFFFFF` | primary text |

Derived tints — `navyRaised`, `navyLine`, `navyEdge`, `amberDeep`, `greyMuted`,
`greyFaint` — are shades of those five, used for borders and text ladders.

**Amber is rationed.** With one accent, meaning comes from *emphasis* rather
than hue, which is what gives the screens a clear primary/secondary read:

| Emphasis | Treatment | Used for |
|----------|-----------|----------|
| Highest | amber fill, black text | Launch button, selected chip, rank 1–3 badge |
| High | amber text or border | errors, focus, usage counts, active tab |
| Normal | white text | the content itself — page names, values, URLs |
| Low | grey | secondary labels, warnings |
| Lowest | `greyMuted` / `greyFaint` | micro-labels, disabled, unreferenced |

Consequences worth knowing:

* **Amber marks what to look at, not what is fine.** A valid link's preview is
  white and quiet; an invalid one turns amber. Success snackbars are grey,
  failures amber.
* **A parameter's switch turns amber only when it actually contributes to the
  URL** — toggled on but empty stays grey, so amber always tracks real effect.
* **Channel and user-type chips carry no hue.** They are secondary facets, so
  they read in grey and the label does the work; only "unreferenced" is dimmed
  further.
* There is no separate red. Amber doubles as the error colour, which is why it
  is kept off everything that is merely "normal".

## The spec is not in this repository

`assets/spec/deeplink_spec.json` is git-ignored. It carries CardX's internal
routing table, so it is distributed out of band rather than committed.

`assets/spec/` is declared as an asset **directory**, which is what makes this
work: the directory always exists because
[example_spec.json](assets/spec/example_spec.json) is committed, so the build
never fails on a missing asset. At start-up
[DeeplinkSpecSource](lib/data/datasources/deeplink_spec_source.dart) tries the
real spec first and falls back to the example when it is absent *or malformed*.

When the fallback is in use the catalogue shows a **DEMO SPEC** badge beside the
title. Without it a tester could fire example links at a device and believe they
were real, which is the failure this badge exists to prevent.

To work with the real spec, drop it at `assets/spec/deeplink_spec.json` and
restart. Nothing else changes, and git will not see the file.

## Updating the spec

Replace `assets/spec/deeplink_spec.json` and restart. The loader tolerates unknown keys and
skips entries without a `path_pattern`. Entry ids are derived from the path
pattern, so history and usage counters survive edits to unrelated fields but
reset for an entry whose pattern changes.

---

## Tests do not carry spec data

Every behavioural test runs against
[test/fixtures/sample_spec.json](test/fixtures/sample_spec.json) — a synthetic
13-entry spec on a `demoapp://` scheme, written to exercise each feature the
loader and builder support: conditional groups, enumerated values, required and
optional parameters, a path token, a token with alternatives, ` | ` variants, a
rank tie, an entry with no parameters, an unreferenced entry, and at least one
entry per channel and user type.

`deeplink_spec.json` is touched by exactly one test file,
[test/data/real_spec_test.dart](test/data/real_spec_test.dart), which asserts
only that the real file parses and conforms — no route, page name or parameter
value is written down. That file skips itself when the spec is absent.

That skip alone would not be enough to drop the file, because `pubspec.yaml`
declares the asset directory and a missing declared asset fails the build. See
*The spec is not in this repository* below for how that is handled.

Two things follow from this. The tests stop breaking when the real spec changes,
because they no longer assert on its contents. And the repository holds no copy
of the spec outside the spec file itself, so ignoring or replacing that one file
is enough to keep the data out.

## Running

```bash
fvm flutter pub get
fvm flutter run
fvm flutter test        # 76 tests
fvm flutter analyze
```

Only `android/` and `ios/` exist — the web, macOS, Windows and Linux runners
were removed.

---

## Platform setup

### Android

* `WRITE_EXTERNAL_STORAGE` (maxSdk 29) + `requestLegacyExternalStorage` for
  gallery saves, and `<queries>` entries for the `cardx` scheme, `https` and the
  share sheet — without those, Android 11+ reports every deeplink as
  unlaunchable.
* The `android/` scaffold was migrated from the original Groovy setup
  (Gradle 7.5 / AGP 7.3 / Kotlin 1.7) to what Flutter 3.44.7 generates:
  **Gradle 9.1.0, AGP 9.0.1, Kotlin 2.3.20, Java 17**, Kotlin DSL build files.
* **`org.gradle.jvmargs` pins `-Duser.language=en -Duser.country=US`. Do not
  remove it.** On a Thai-locale machine the JVM defaults to the Buddhist
  calendar, so `Calendar.YEAR` returns 2569. AGP's `apkzlib` packs that year into
  an MS-DOS ZIP timestamp, which only encodes 1980–2107, and the build dies in
  `:app:mergeDebugJavaResource` with an empty
  `com.google.common.base.VerifyException`.

### iOS

* `NSPhotoLibraryAddUsageDescription`, `NSPhotoLibraryUsageDescription` and
  `LSApplicationQueriesSchemes` in `Info.plist`.
* Deployment target raised **12.0 → 13.0**, required by
  `shared_preferences_foundation` and `url_launcher_ios`.

---

## TODO before shipping

* `applicationId` / bundle id are still `com.example.linkx_tester`.
