# Zzan

A minimal menu-bar utility for vibe coding: press a global shortcut, type a
prompt in your own language (usually Korean), hit Enter, and the English
translation lands on your clipboard — ready to paste. Translation runs through
the built-in macOS **Translation framework**, so there is no API key and no
per-call cost.

## How it works

1. Press the shortcut (default `⌃⌥⌘T`) anywhere.
2. A small input panel appears, focused and ready.
3. Type your text.
   - **Enter** → translate to English, copy to clipboard, close.
   - **Shift+Enter** → newline.
   - **Esc** → close without translating.
4. Focus returns to your previous app — just paste.

## Features

- Menu bar only (no Dock icon).
- Global shortcut, rebindable in Settings with basic conflict validation.
- Launch at login (via `SMAppService`).
- Source language: auto-detect (default) or a fixed language. Target is always English.
- Recent 10 translations in the menu; click one to re-copy.

## Requirements

- macOS 15 or later (the Translation framework's programmatic API).
- The first translation for a language may prompt macOS to download the
  on-device language model.

## Build & run

```bash
./build.sh
open build/Zzan.app
```

`build.sh` compiles the SwiftPM target, assembles `build/Zzan.app`, and ad-hoc
signs it.

For day-to-day development without bundling:

```bash
swift run
```

(Some features — Launch at login in particular — only behave correctly from the
signed `.app` bundle.)

## Notes on shortcut conflicts

macOS provides no public API to enumerate every globally-registered shortcut, so
conflict detection is best-effort: combinations without a `⌘`/`⌥`/`⌃` modifier
are rejected, and a blocklist guards the well-known system shortcuts
(Spotlight, app switcher, Quit, Copy/Paste, etc.). Two apps can still legally
register the same hotkey — both simply receive it.
