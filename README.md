# Rosome — رسوم

**Your anime, remembered.** A dark, premium anime **discovery & tracker** app
built with Flutter. Swipe through anime like a deck of cards, track what you're
watching, and level up as you go.

> **Rosome** is the app's public name (shown under the launcher icon and in the
> stores). The Flutter project / package codename stays `kioku` internally —
> that's not user-visible and changing it isn't required.

> Original app — original name, logo, colours and concept. It surfaces real
> anime data from the public **Jikan / MyAnimeList** API (the same way every
> tracker does), but **all Kioku branding is 100% original** — no third-party
> characters, logos, or artwork are used as the app's own identity.

---

## ✨ Features

- **Discover (signature feature)** — a Tinder-style swipe deck.
  - Swipe **right** → add to *Plan to Watch*
  - Swipe **left** → skip
  - Swipe **up** → *Love* (favourite)
- **Kioku Aura — "taste DNA" (original, one-of-a-kind)** — analyses your
  library and generates a personal *aura*: an archetype (The Dreamweaver, The
  Firebrand, The Kindred, The Trickster…), a unique colour signature, four
  emotional trait scores, and a rarity grade. Nothing like it exists in other
  trackers.
- **Explore** — search any anime, or browse *Trending*, *This Season*,
  *Top Rated*, and 12 genre filters.
- **Library** — your list, filtered by status (Watching / Completed / Planned /
  On Hold / Dropped) with per-episode progress tracking and personal ratings.
- **Stats & gamification** — XP, levels, rank titles, a "your taste" genre
  chart, watch-time totals, and 9 unlockable achievements.
- **Themes** — Dark, Light, or follow the system, with a live toggle.
- **3 languages** — English, Français, and العربية (Arabic) with full
  right-to-left layout.
- **Detail pages** — synopsis, score, members, genres, and "you might also
  like" recommendations.
- **Offline-first** — your whole library lives on-device (Hive). No account,
  no backend, no login.

## 🧱 Tech

| | |
|---|---|
| Framework | Flutter 3.44 / Dart 3.12 |
| Data | Jikan v4 API (free, no key) |
| Local storage | Hive |
| State | Provider |
| UI | Google Fonts (Outfit + Plus Jakarta Sans), custom glass/gradient design system |

## ▶️ Run it (dev)

```bash
flutter pub get

# Android emulator / device
flutter run

# Web (opens a real Chrome window)
flutter run -d chrome
```

## 🍏 Publishing to iOS (from Windows — no Mac)

You wrote the app on Windows, but Apple requires macOS + Xcode to build & submit.
Use the included **`codemagic.yaml`** (cloud macOS build):

1. Push this repo to GitHub / GitLab / Bitbucket.
2. Create a free account at [codemagic.io](https://codemagic.io) and add the repo.
3. **Test build (no Apple account):** run the `ios-test-build` workflow → get an
   unsigned `.app`.
4. **App Store / TestFlight:** you need an **Apple Developer Program** membership
   ($99/yr). In Codemagic, add an *App Store Connect* API key integration, set
   your `bundle_identifier` (currently `com.rosoume.kioku`), then run the
   `ios-appstore` workflow. It builds a signed IPA and uploads to TestFlight.

## 🎨 Branding / App icon

The Kioku mark (violet→magenta tile with a white play spark) is fully original.
It's drawn in-app by `KiokuMark` (`lib/main.dart`) and the launcher icons were
generated from `assets/icon.png`.

- Regenerate the source art: `dart run tool/gen_icon.dart`
- Regenerate platform icons: `dart run flutter_launcher_icons`

## 📁 Structure

```
lib/
  main.dart              app entry, splash, brand mark
  theme/app_theme.dart   colours, gradients, typography
  models/                Anime, TrackedAnime, WatchStatus
  l10n/app_localizations.dart  EN / FR / AR strings + RTL
  services/
    jikan_api.dart       throttled Jikan v4 client
    library_service.dart Hive store + stats/XP/achievements
    aura_engine.dart     Kioku Aura "taste DNA" engine
    settings_controller.dart  theme + language, persisted
  screens/
    home_shell.dart      bottom-nav shell
    discover_screen.dart swipe deck
    explore_screen.dart  search + browse
    library_screen.dart  your list
    stats_screen.dart    gamified profile + Aura/Settings entry
    aura_screen.dart     the Aura reveal
    settings_screen.dart theme + language
    detail_screen.dart   anime detail
  widgets/               shared UI kit
tool/gen_icon.dart       original app-icon generator
codemagic.yaml           cloud iOS build/publish pipeline
```

## ⚖️ Data & attribution

Anime data & cover images are provided by [Jikan](https://jikan.moe) (an
unofficial MyAnimeList API). All artwork remains the property of its respective
rights holders and is shown for informational/tracking purposes. Kioku's own
name, logo, colour system and UI are original.
