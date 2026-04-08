# PartyPour Branding Design Spec

## Overview

Create app icon, splash screen, and update application identity for PartyPour (formerly RaksiChaiyo). The branding follows the existing Premium Gold theme.

## Design Decisions

- **Logo style:** Icon + Wordmark — clinking glasses icon standalone for app icon, paired with "PartyPour" text for splash screen
- **Icon symbol:** Two clinking glasses with sparkle rays — represents celebration + social (the "Party" in PartyPour)
- **Background:** Dark-to-gold gradient (`#1C1917` → `#292524` → `#3d2a06`) with subtle gold border glow
- **Icon colors:** Gold gradient stroke (`#CA8A04` → `#EAB308`) on dark gradient background
- **Splash layout:** Large icon + "PartyPour" name centered, tagline "RIGHT PRICE · GENUINE · RETURNABLE" anchored at bottom, radial gold glow behind icon

## Color Palette (existing theme)

| Token | Hex | Usage |
|-------|-----|-------|
| Primary Dark | `#1C1917` | Background base |
| Surface Dark | `#292524` | Gradient mid |
| Gold Warm | `#3d2a06` | Gradient end |
| Gold Primary | `#CA8A04` | Icon stroke start, text |
| Gold Bright | `#EAB308` | Icon stroke end, sparkles |
| Muted | `#78716C` | Tagline text |

## Deliverables

### 1. App Icon (1024x1024 PNG)

- Clinking glasses SVG rendered to 1024x1024 PNG
- Background: linear gradient 160deg from `#1C1917` → `#292524` → `#3d2a06`
- Gold gradient strokes for glasses, bright gold sparkle rays at clink point
- Generated into Android mipmap sizes via `flutter_launcher_icons` package
- Adaptive icon support (foreground + background layers)

### 2. Splash Screen

- Configured via `flutter_native_splash` package
- Background color: `#1C1917` (native splash limitation — gradient via app)
- Centered icon image (clinking glasses, 200px rendered)
- App loads into full branded splash with "PartyPour" text + tagline at bottom before transitioning to home

### 3. Application Identity Update

- `applicationId`: change from `com.raksichaiyo.customer_app` to `com.partypour.app`
- `namespace`: update to match new applicationId
- Android label already updated to "PartyPour" (done previously)

## Implementation Approach

### Icon Generation
1. Create 1024x1024 icon PNG using HTML canvas → export (or SVG → PNG conversion)
2. Add `flutter_launcher_icons` to dev_dependencies
3. Configure in `pubspec.yaml` with icon path
4. Run `dart run flutter_launcher_icons` to generate all mipmap sizes

### Splash Screen
1. Add `flutter_native_splash` to dev_dependencies
2. Configure in `pubspec.yaml` — background color `#1C1917`, centered icon image
3. Run `dart run flutter_native_splash:create` to generate native splash
4. Optionally add a Dart-side branded splash widget for the full gradient + text + tagline experience before transitioning to home

### Identity
1. Update `applicationId` and `namespace` in `android/app/build.gradle.kts`
2. Verify build succeeds with new ID

## Files Modified

- `pubspec.yaml` — add flutter_launcher_icons, flutter_native_splash configs
- `android/app/build.gradle.kts` — update applicationId and namespace
- `android/app/src/main/res/mipmap-*` — generated icon files
- `assets/` — new icon PNG and splash icon PNG

## Out of Scope

- iOS icon/splash (no iOS target currently)
- Animated splash screen
- Custom font integration (Playfair Display / Inter — separate task)
