# zzan

<img width="2814" height="1536" alt="image" src="https://github.com/user-attachments/assets/2e087871-5a8f-4995-a810-1016321e1d79" />

A macOS menu-bar utility for **translating text to English in one keystroke**.

Press the shortcut, type in any language, hit **Enter** — the English translation lands on your clipboard.

Built on the native macOS Translation framework. No API key, no cost, no round-trip.

![macOS 15+](https://img.shields.io/badge/macOS-15%2B-black) ![Swift](https://img.shields.io/badge/Swift-6-orange)

## Usage

| Key | Action |
|-----|--------|
| Global shortcut (default `⌃⌥⌘T`) | Open the input panel |
| **Enter** | Translate → copy to clipboard → close |
| **Shift+Enter** | Insert a newline |
| **Esc** | Close without translating |

After closing, focus returns to your previous app — just paste.

## Install

Download the latest `zzan-<version>.dmg` from [Releases](https://github.com/parkjangwon/zzan/releases), open it, and drag **zzan.app** to `/Applications`.

On first launch macOS may ask to download the on-device language model for your language. After that, translation works offline.

## Build from source

Requires Xcode 16+ / macOS 15+.

```bash
git clone https://github.com/parkjangwon/zzan
cd zzan
./build.sh
open build/zzan.app
```

## Release

Releases are published by GitHub Actions when a version tag is pushed:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Settings

- **Shortcut** — rebind the global hotkey (conflict-checked)
- **Source language** — auto-detect (default) or pin to a specific language
- **Launch at login** — start zzan automatically on login
- **History** — recent 10 translations in the menu bar, click to re-copy
