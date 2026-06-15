# Install on Linux

There is no native Linux menu bar build of `EnterpriseAIMetrics`.

What is supported on Linux is the bundled CLI, which can be used for:

- usage queries
- cost queries
- local dashboards
- integration with Waybar, GNOME Shell extensions, Quickshell, or custom scripts

## Supported Linux install options

- GitHub Release CLI tarballs
- Arch Linux AUR package
- Build from source

## Option 1: Install the CLI from GitHub Releases

1. Open:
   `https://github.com/miangino/EnterpriseAIMetrics/releases`
2. Download the matching tarball:
   - `EnterpriseAIMetricsCLI-v<tag>-linux-x86_64.tar.gz`
   - `EnterpriseAIMetricsCLI-v<tag>-linux-aarch64.tar.gz`
3. Extract it:

```bash
tar -xzf EnterpriseAIMetricsCLI-v<tag>-linux-x86_64.tar.gz
cd EnterpriseAIMetricsCLI-v<tag>-linux-x86_64
./codexbar --version
```

4. Optionally install it into your path:

```bash
sudo install -m 0755 CodexBarCLI /usr/local/bin/codexbar
codexbar --version
```

## Option 2: Arch Linux AUR

```bash
yay -S codexbar-cli
codexbar --version
```

## Option 3: Build from source

Requirements:

- Swift 6.2 or newer

Build the CLI:

```bash
swift build -c release --product CodexBarCLI --static-swift-stdlib
./.build/release/CodexBarCLI --version
```

## Important limitation

- Web-backed provider modes are not supported on Linux.
- The Linux flow is CLI-only, not a desktop `.app` equivalent.
- For a desktop integration, use one of the Linux community integrations built on top of the CLI.
