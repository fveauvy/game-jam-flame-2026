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

## Leaderboard config (GitHub Pages + Vercel KV)

- Frontend stays on GitHub Pages.
- Backend runs as Vercel Function: `api/submit-score.js`.
- Required Vercel env vars:
  - `LEADERBOARD_SERVER_KEY`
  - `LEADERBOARD_ALLOWED_ORIGIN` (example `https://gronouy.fr`)
  - `KV_REST_API_URL`
  - `KV_REST_API_TOKEN`
- Required GitHub Actions secrets (for web build `--dart-define`):
  - `LEADERBOARD_SUBMIT_URL` (example `https://<your-vercel-project>.vercel.app/api/submit-score`)
  - `LEADERBOARD_KEY_PART_A`
  - `LEADERBOARD_KEY_PART_B`

Generate key parts from your plain key:

```bash
node -e "const s=process.argv[1];const b=Buffer.from(s).toString('base64').replace(/\+/g,'-').replace(/\//g,'_');const m=Math.floor(b.length/2);console.log('LEADERBOARD_KEY_PART_B='+b.slice(0,m));console.log('LEADERBOARD_KEY_PART_A='+b.slice(m));" "your-secret"
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
