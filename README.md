# 学 Story Writer — Haksaeng HS story notebook 🖊️📱

A tiny Android app for writing visual-novel style stories, wrapped from the
`mockup/story_writer.html` prototype in a minimal WebView shell.

**Line types:** MC · Hina · Hina says · Hina thinks · Kenji · Kenji says · Note

## Download
Grab the latest APK from [Releases](../../releases) — sideload it
(Settings → allow install from unknown sources for your browser/files app).

## Features
- Styled story feed matching the Haksaeng "prestige acrylic" UI (navy & gold, dark mode aware)
- Lines autosave locally (browser localStorage) — no permissions, no internet
- Make Doc / Copy / Save .txt export with script formatting
- Reorder (↑↓) and delete lines

## Build
No Gradle needed:
```powershell
cd storywriter_app
powershell -ExecutionPolicy Bypass -File build.ps1
```
Requires: Android SDK build-tools 36, any android platform jar, a JDK (17+) for javac/d8.

## Project layout
```
AndroidManifest.xml                  app manifest
java/.../MainActivity.java           WebView shell (DOM storage on)
assets/story_writer.html             the entire app UI (synced from ../mockup)
res/                                 launcher icon (adaptive, vector)
build.ps1                            aapt2 → javac → d8 → zipalign → apksigner
```
