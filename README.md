# 新闻 / News

AI news reader (Flutter). The same codebase can target other desktops and phones; the builds this repo ships are Windows and Android.

Domestic RSS is fetched on the device. Overseas feeds are bundled as `data/snapshot.json` and can be refreshed from jsDelivr after you publish this repo.

## Run

1. Install [Flutter](https://flutter.dev) (stable) and put it on `PATH`.
2. Windows: `install.bat` then `run.bat`. macOS/Linux: `chmod +x install.sh run.sh` then `./install.sh && ./run.sh`.

```bat
install.bat
run.bat
```

Windows release + Android APK (on Mac: `cd app && flutter run -d macos`):

```bat
build.bat
```

Ship **`dist\News-windows\`**, not `app\build\windows\x64\runner\Debug`. A Debug exe needs `MSVCP140D.dll` (Visual Studio debug CRT), which is not installed on user machines and is not redistributable. The Release folder plus the bundled `msvcp140.dll` / `vcruntime140.dll` is what `build.bat` copies into `dist`.

`build.bat` refreshes `data/snapshot.json` before packaging. Phones live-update overseas news from `https://cdn.jsdelivr.net/gh/martjay/AI-News-Reader@main/data/snapshot.json`. That address is written into `snapshot.defaultUrl` by `tools\apply_snapshot_repo.ps1` from `config/snapshot.repo`. You can also set another `owner/repo` under **Me**.

Release APKs require `app/android/key.properties` and an upload keystore. `build.bat` creates them on the first release build if they are missing. Both files are gitignored. Back them up; a lost keystore cannot update an already installed release.

## Overseas snapshot (no VPN on the phone)

1. The public repository is [martjay/AI-News-Reader](https://github.com/martjay/AI-News-Reader). `snapshot.defaultUrl` already points at its jsDelivr snapshot.
2. GitHub Actions (`.github/workflows/aggregate.yml`) fetches snapshot sources every 30 minutes into `data/snapshot.json`. A failed source keeps the previous items instead of publishing an empty list.
3. In the app, open **Me** to override the snapshot repo. The default load is:

`https://cdn.jsdelivr.net/gh/martjay/AI-News-Reader@main/data/snapshot.json`

You can also paste a custom snapshot URL. If remote fetch fails, the last local cache and the bundled snapshot are used.

Refresh snapshot locally:

```bat
cd tools\aggregator
dart pub get
dart run bin\aggregator.dart
```

## Layout

- `config/sources.yaml` — all feeds (shared by the app and the aggregator)
- `packages/news_core` — models, RSS, dedupe, timeline
- `tools/aggregator` — CLI that writes `data/snapshot.json`
- `app` — Flutter client

## Reading

Today opens on a brief of the day’s main stories (cross-source when the same news lands in more than one feed), then the rest grouped by RSS source. Unread and “new since last visit” are the daily spine. Opening a story loads a cleaned article body in-app; if that fails, the excerpt stays and the original site is one tap away.

On Windows/macOS/Linux, overseas feeds are fetched live. On phones they come from the bundled snapshot (and jsDelivr if you set a repo). Default UI language is Chinese; overseas titles, excerpts, and article text are translated via Tencent Transmart (reachable in mainland China). Optional: paste a DeepSeek or Qwen-compatible API key in **Me**.

No account sync.
