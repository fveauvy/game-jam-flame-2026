# Flame Game Jam 2026 Template

Generic Flutter + Flame 2D starter for fast team game jam builds.

## Stack

- Flutter stable (latest)
- Flame (latest compatible)
- Web-first deployment via GitHub Pages

## Run locally

```bash
flutter pub get
flutter run -d chrome --wasm
```

## Controls

- Move: `A/D` or `Left/Right`
- Jump: `Space`
- Pause: `Esc`
- Touch: on-screen buttons (web/mobile)

## Build web

```bash
flutter build web --wasm --release
```

## Leaderboard admin reset

- Endpoint: `POST /api/reset-leaderboard`
- Auth header: `x-leaderboard-admin-key`
- Required server env var: `LEADERBOARD_ADMIN_KEY`
- This secret is admin-only and must never be shipped in game/client code.

Example:

```bash
curl -X POST "https://game-jam-flame-2026-gamma.vercel.app/api/reset-leaderboard" \
  -H "x-leaderboard-admin-key: <your-admin-secret>"
```

## Optimize images (Mac + Homebrew)

```bash
brew install pngquant oxipng jpegoptim
scripts/optimize_images.sh assets/images build/optimized-assets/images
rsync -a --delete build/optimized-assets/images/ assets/images/
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
