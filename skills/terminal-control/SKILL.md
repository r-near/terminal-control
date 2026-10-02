---
name: terminal-control
description: Drive and verify terminal applications with the termctrl CLI in a real PTY - read visible screens, run named live sessions, send typed keyboard input, wait for text, save evidence, record timelines, and export edited videos. Use when an agent must operate or test a TUI, REPL, interactive CLI, shell process, or OpenTUI application.
---

# Terminal Control

Use `termctrl` to observe the actual visible terminal state and drive interaction deterministically.

## Start With The Smallest Workflow

Read a disposable terminal application's settled visible screen when no further interaction is required:

```bash
termctrl show -- my-terminal-app
```

Keep an application alive when interaction or repeated inspection is required:

```bash
termctrl start app -- my-terminal-app
termctrl wait app "Ready"
termctrl show app
termctrl send app text:help enter
termctrl wait app "Commands"
termctrl show app
termctrl stop app
```

Always stop named sessions after use unless the user explicitly wants the live process retained.

Keep an application visible and human-controlled in the current terminal pane while exposing the
same session controls to agents:

```bash
termctrl run -- /usr/bin/nvim
termctrl run editor -- nvim
```

The form without `NAME` uses the executable basename (`nvim`) and fails on a name collision; it
never chooses a suffixed name. Pass an explicit name when running multiple copies.

## Choose The Correct Observation

- Use `show` for current visible screen text. Prefer it for reasoning about full-screen TUIs.
- Use `logs` for readable retained output from normal-screen tools and log-like commands.
- Use `save --format ... --out ...` only when a persisted artifact is required.
- Use `video` only after explicitly recording a timeline with `--record`.

Do not treat logs as the visible state of an alternate-screen TUI.

Named-session reads return immediately by default. Add settling only when intentionally waiting for
quiet output. `wait` defaults to five seconds; set `--timeout` only when choosing another limit.

For fast demos, keep the session alive, omit `--pace-ms` unless slow typing is intentional, and
combine a known transition into one shell call:

```bash
termctrl send app text:help enter && termctrl wait app "Commands" && termctrl show app
```

The wait ends as soon as the text appears; its timeout is a maximum, not a fixed delay. Do not
insert sleeps between these commands. Inspect text during interaction, save PNGs only for visual
checks or requested evidence, and export video after driving the app. With MCP, prefer `interact`
with `waitFor` to combine keyboard input, readiness, and a screen read in one tool call.

## Drive Input Precisely

Send plain text with `text:<value>` and named keys as separate input atoms:

```bash
termctrl send app text:/connect enter
termctrl send app down enter
termctrl send app ctrl-c
printf '%s' 'multiline prompt' | termctrl send app --stdin
```

Use `wait` after sending input instead of sleeping or assuming that the interface has updated.

For mouse-enabled applications, use typed mouse commands with zero-based cell coordinates:

```bash
termctrl mouse app move 12 4
termctrl mouse app click 12 4
termctrl mouse app down 12 4
termctrl mouse app move 20 4
termctrl mouse app up 20 4
```

`move` hovers when no button is held; down/move/up drags. `--button right` or `middle`, `--shift`,
`--alt`, and `--ctrl` are optional. The app must enable mouse reporting; hover requires any-event
tracking. Coordinates outside the resized viewport fail. Do not work around disabled reporting
by injecting raw escape sequences. Restart older named sessions if the command requests it.

For recorded demos, opt into `video --pointer-overlay` to show mouse input with smooth travel,
subtle press compression, and fades. This defaults to 60 fps and does not delay actual input.
Use `--pointer-reduced-motion` to keep fades only. Trim/speed/hold edits stay on the same source
clock. Only typed mouse commands provide overlay evidence; raw bytes and forwarded human input
do not. `show`/`save` remain plain terminal evidence, separate from the video overlay.

## Operate OpenTUI Applications

Use the OpenTUI host handshake for applications such as OpenCode:

```bash
termctrl start app --host opentui --cols 112 --rows 34 -- opencode
termctrl wait app "/connect"
termctrl show app
termctrl show app --format semantic
```

Use `resize` when the application requires more visible area. Use `restart app` to reuse stored launch settings after a deliberate application restart.

## Retain Evidence Deliberately

Save only requested formats:

```bash
termctrl save app --format txt --format png --out artifacts/current
```

Record demos only when the user wants a retained timeline or video. Add markers while the session is running, inspect them after stopping, then export with an explicit edit plan:

```bash
termctrl start app --record artifacts/run.termctrl -- my-terminal-app
termctrl wait app "Ready"
termctrl mark app ready
termctrl send app text:demo enter
termctrl wait app "Done" --timeout 60000
termctrl mark app done
termctrl stop app
termctrl markers artifacts/run.termctrl
termctrl show --recording artifacts/run.termctrl --at-marker done
termctrl video artifacts/run.termctrl --edit artifacts/run-edit.json --footer --out artifacts/run.mp4
```

Use edit-plan `speed` values conservatively when terminal text should remain readable. Use `hold_ms` or `--tail-ms` when the final frame is the payoff. Pass `--footer` when a polished demo should show the clip caption, elapsed timecode, and `TERMINAL CONTROL` branding in a bottom footer; omit it for ordinary videos.

Treat `.termctrl` recordings, ANSI transcripts, screen artifacts, command arguments, and terminal input as potentially sensitive. Do not retain them unless needed, and do not expose their contents unnecessarily.

## Render Polished Screenshots And Videos

PNG, SVG, and video output draw box-drawing, block, braille, Powerline, and ◆◇●○ glyphs as
geometry and render all other text with system fonts and per-glyph fallback, so the result looks
only as good as the font covering the application's glyphs.

Use a Nerd Font. The default family (JetBrains Mono) lacks common spinner and arrow glyphs such as
◐◓◑◒ and ↳, and the fallback font renders them oversized and misaligned. Nerd Fonts also carry the
icon glyphs that prompt themes and TUIs use. Check with `fc-list | grep -i "nerd font"`; if none is
installed, ask before installing one, for example FiraCode Nerd Font:

```bash
# Linux
mkdir -p ~/.local/share/fonts/FiraCodeNerdFont
curl -fsSL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz | tar -xJ -C ~/.local/share/fonts/FiraCodeNerdFont
fc-cache -f
# macOS
brew install --cask font-fira-code-nerd-font
```

Set rendering defaults once per machine instead of repeating flags; explicit flags still win:

```bash
export TERMCTRL_FONT_FAMILY="FiraCode Nerd Font" TERMCTRL_CELL_WIDTH=10 TERMCTRL_CELL_HEIGHT=20
```

`TERMCTRL_FONT_FAMILY`, `TERMCTRL_PADDING`, and `TERMCTRL_PIXEL_RATIO` apply to `save` and `video`;
`TERMCTRL_CELL_WIDTH` and `TERMCTRL_CELL_HEIGHT` also apply to `start` and `run`. The default pixel
ratio of 2 is already sharp on HiDPI screens; use 3 only for print or zoomed crops. Add
`--hide-cursor` to stills.

There is no palette flag, but the renderer reads colours back from the terminal core, so OSC 10, 11,
and 4 sequences printed before the application starts set the foreground, background, and 16 ANSI
colours. `catppuccin-mocha.osc` in this skill's directory is a ready-made Catppuccin Mocha prefix.
Replace `SKILL_DIR` with that directory:

```bash
termctrl save --cols 120 --rows 30 --hide-cursor --format png --out artifacts/out.png -- \
  bash -c 'cat SKILL_DIR/catppuccin-mocha.osc; my-cli --flag'
```

For an application that prompts before the screen worth capturing, keep the shell alive in a named
session, answer the prompt, then save:

```bash
termctrl start app --cols 120 --rows 30 -- bash -c 'cat SKILL_DIR/catppuccin-mocha.osc; my-cli; sleep 300'
termctrl wait app "Proceed?" && termctrl send app enter && termctrl wait app "Done" --timeout 90000
termctrl save app --hide-cursor --format png --out artifacts/out.png
termctrl stop app
```

- Set `--rows` to the number of output lines plus one so the image has no empty band at the bottom.
- `save --input transcript.ansi` replays the bytes through the emulator, so the file needs CRLF line
  endings (`perl -pe 's/\r?\n/\r\n/'`). Bare LF only moves down a row and produces a staircase.
- `├` is drawn with a deliberately short right arm and reads as a small tick beside text.

## Recover From Problems

- Run `termctrl status app` to inspect state and launch settings.
- Run `termctrl list` to discover running named sessions. Add `--state`, `--command`, or `--cwd` when narrowing discovery; use `--all` only when retained exited or unavailable entries are relevant.
- MCP agents can pass `state`, `command`, or `cwd` to `list_sessions` and use `get_session_status({ name })` for complete structured status without parsing CLI output.
- If a session socket path is too long, set `TERMCTRL_RUNTIME_DIR` to a short private directory under `/tmp` before starting sessions.
- If `termctrl` is unavailable, install this fork's prebuilt binary with `curl -fsSL https://raw.githubusercontent.com/r-near/terminal-control/main/install.sh | sh`, build it with `cargo install --locked --git https://github.com/r-near/terminal-control terminal-control`, or ask the user which installed binary to use. Upstream `cargo install terminal-control` lacks the `TERMCTRL_*` rendering defaults.
