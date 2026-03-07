# Flame Game Jam 2026 Template

Generic Flutter + Flame 2D starter for fast team game jam builds.

## Stack

- Flutter stable (latest)
- Flame (latest compatible)
- Web-first deployment via GitHub Pages

## Run locally

```bash
flutter pub get
flutter run -d chrome
```

## Controls

- Move: `A/D` or `Left/Right`
- Jump: `Space`
- Pause: `Esc`
- Touch: on-screen buttons (web/mobile)

## Build web

```bash
flutter build web --release
```

## Project layout

- `lib/core`: config/constants/utils
- `lib/game`: Flame runtime (`world`, `components`, `systems`, `input`, `camera`)
- `lib/screens`: Flutter overlays (menu, pause, game over)
- `assets`: game assets (`images`, `audio`, `fonts`, `data`)
- `docs`: jam checklists and disclosure templates

## Play link

- GitHub Pages URL: `https://gronouy.fr/`

## Jam docs

- Submission checklist: `docs/JAM_SUBMISSION_CHECKLIST.md`
- Asset attribution: `docs/ASSET_ATTRIBUTION.md`
- AI disclosure: `docs/AI_DISCLOSURE.md`
- Screenshot notes: `docs/SCREENSHOT_GUIDE.md`
