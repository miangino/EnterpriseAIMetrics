# Install on macOS

`EnterpriseAIMetrics` is a native macOS menu bar app. The supported install paths are:

- Download a packaged `.zip` or `.app` from GitHub Releases
- Build the app locally from source

## Requirements

- macOS 14 or newer
- Apple Silicon (`arm64`) or Intel (`x86_64`)

## Option 1: Install from GitHub Releases

1. Open the releases page:
   `https://github.com/miangino/EnterpriseAIMetrics/releases`
2. Download the latest macOS DMG.
3. Open the DMG and drag `EnterpriseAIMetrics.app` to `Applications`.

If you prefer a zip archive, the release page also includes one:

```bash
ditto -x -k EnterpriseAIMetrics-macos-arm64-<version>.zip .
```

4. Move the app into `/Applications` if you used the zip:

```bash
mv EnterpriseAIMetrics.app /Applications/
```

5. Launch it:

```bash
open /Applications/EnterpriseAIMetrics.app
```

## First launch trust prompt

If macOS says the app cannot be opened because it is from an unidentified developer, or the first launch is blocked by Gatekeeper:

1. Close the warning window.
2. Open **System Settings**.
3. Go to **Privacy & Security**.
4. Scroll to the Security section.
5. Click **Open Anyway** for `EnterpriseAIMetrics`.
6. Open the app again and confirm the launch dialog.

## Option 2: Build from source

Requirements:

- Xcode 26 or newer
- Swift 6.2 or newer

Build the app bundle in-place:

```bash
./Scripts/package_app.sh
open EnterpriseAIMetrics.app
```

If you do not have Apple Developer signing configured, build an ad-hoc signed app:

```bash
CODEXBAR_SIGNING=adhoc ./Scripts/package_app.sh
open EnterpriseAIMetrics.app
```

## Optional: install the bundled CLI

After the app is installed in `/Applications`, install the CLI symlink:

```bash
./bin/install-codexbar-cli.sh
codexbar --version
```

## Notes

- The app is a macOS-only menu bar application.
- Sparkle auto-update only works for signed release builds. Ad-hoc local builds disable Sparkle.
- If Gatekeeper complains about a downloaded archive, re-extract with `ditto` instead of `unzip`.
