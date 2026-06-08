# CLAUDE.md — Neon Defense / BoredTowerDefense

Guidance for Claude Code (and humans) working in this repository.

## What this is

**Neon Defense** ("bored_games") — a Tron-style **tower defense** game built with **Flutter + Flame**
(Dart). The playable project lives in **`flutter_app/`**. There are 100 campaign levels across 10
worlds, 4 tower types, multiple enemy/boss types, a Neon Pulse ability, deployable mines, a pseudo-3D
"FPS view" mode, a fragment-shader pipeline, and a large neon/Tron UI.

> **Active goal: migrate the game from Flutter/Flame to Unreal Engine 5 (C++ / Blueprints).**
> The migration knowledge base lives in **`docs/migration/`** — read it before doing migration work.

## Repository layout

```
flutter_app/                  # THE GAME (Flutter + Flame). Almost all real code is under lib/src/.
  lib/src/{game,bloc,services,models,data,ui}/   # see docs/migration/ARCHITECTURE_MAP.md
  test/                       # 220 test files, 12,478 tests
  scripts/codegraph.js        # static dependency-graph generator ("graphcode") — Node, no deps
  Dockerfile / docker-compose.yml / scripts/run_tests.sh
docs/migration/               # Migration knowledge base (see below)
  ARCHITECTURE_MAP.md         #   subsystem-by-subsystem map + cross-cutting concerns
  DEPENDENCY_GRAPH.md         #   import graph: Mermaid, hubs, cycles, externals, 73-edge matrix
  FLAME_TO_UNREAL.md          #   construct-by-construct Flame/Flutter -> Unreal matrix
  .tmp/                       #   scratch (codegraph json, agent digests, codex/gemini prompts)
unreal-mcp/                   # MCP server to drive Unreal Engine 5 from Claude Code (Python)
```

## Build / run / test

All commands run from **`flutter_app/`**. Docker is the supported path (no local Flutter SDK needed).

```bash
# Run the full test suite in Docker (pulls ghcr.io/cirruslabs/flutter:stable on first run)
docker compose --profile test up --abort-on-container-exit flutter-test

# Serve the web build
docker compose up --build              # nginx on http://localhost:8080
docker compose --profile dev up        # hot-reload dev server on http://localhost:3000

# Build the Android APK without a local toolchain
docker build -f Dockerfile.apk --output build-output .
```

Local (if a Flutter SDK is installed): `flutter pub get && flutter test` / `flutter run -d chrome`.

**Test baseline:** the suite passes **12,478 / 12,478**. Keep it green.

### ⚠️ CRLF gotcha (important on Windows)
The `*.sh` scripts must use **LF** line endings. On a Windows/OneDrive checkout they can become CRLF,
which makes the Linux container fail with errors like `flutter pub: Could not find a subcommand named
"get"` and `run_tests.sh: Syntax error: end of file unexpected`. Fix: normalize to LF
(`tr -d '\r' < f > f.tmp && mv f.tmp f`). A `.gitattributes` enforcing `*.sh text eol=lf` is advisable.

## Architecture (essentials — full detail in `docs/migration/`)

- **`BoredGamesGame`** (`lib/src/game/bored_games_game.dart`, ~2,440 LOC) is a **`FlameGame` god object**
  (fan-out 43) and the **runtime source of truth** for gameplay state (gold/lives/score/wave). It owns
  managers, HUD, effects, shaders, input, the coordinate transform, dynamic quality, and abilities.
- A **37-node `HasGameRef` import cycle** binds nearly all of `lib/src/game/*`. There is no clean
  dependency order — treat `src/game/*` as one tightly-coupled unit.
- **`game_screen.dart`** is the **game-session host**: it creates/destroys the `FlameGame`, wires the
  overlay map, applies settings to the live game, and persists progress. The screen layer
  (`lib/src/ui/`) hosts the game; remember this inverts in Unreal (game world is primary).
- **`SettingsCubit`** is the live state store. **`GameBloc` is DORMANT** (defined but unwired) — do not
  treat it as the runtime authority.
- **Services are singletons** reached via `.instance` (Audio, AmbientSoundscape, ProceduralMusic,
  Level, Storage, Upgrade, SpriteCache), bootstrapped in `loading_screen.dart` in this order:
  `Storage → Level → Audio → ProceduralMusic → SpriteCache`.
- **`neon_theme.dart`** is the single most depended-upon file (fan-in 42) — central design tokens.
- ⚠️ There are **two files named `game_result_overlay.dart`** (one Flame effect under
  `lib/src/game/effects/`, one Flutter overlay under `lib/src/ui/overlays/`). Don't confuse them.

Regenerate the dependency graph after structural changes:
```bash
cd flutter_app && node scripts/codegraph.js   # writes scripts/.codegraph/graph.json + prints a summary
```

## Conventions

- State management: **Bloc/Cubit** (`flutter_bloc`). Gameplay logic lives in **Flame components**
  (`Component`/`PositionComponent`, `HasGameRef`). UI is Flutter widgets + heavy `CustomPainter` art.
- Lint: `flutter_lints` via `analysis_options.yaml`.
- Match surrounding neon/Tron styling; reuse `NeonColors`/`NeonTextStyles` from `neon_theme.dart`.

## Tooling available in this environment

- **Node** (v22 LTS) and **Python** (3.12) are installed. Note: after a fresh install they may not be
  on the inherited `PATH` until the terminal restarts — Python is at
  `C:\Users\daedg\AppData\Local\Programs\Python\Python312\python.exe`.
- **Docker Desktop** for the Flutter toolchain.
- **Auxiliary AI engines for cross-checking** (used during the migration analysis):
  - Codex CLI: `codex exec --skip-git-repo-check --sandbox read-only < prompt.txt` (read-only; its
    Windows sandbox cannot *spawn* commands, so feed content via stdin rather than asking it to read
    files). Do **not** use `--dangerously-bypass-approvals-and-sandbox`.
  - Gemini CLI: `gemini --skip-trust -p "..."`.

## Unreal MCP server (`unreal-mcp/`)

A Python MCP server that lets Claude Code drive a running **Unreal Engine 5 Editor** via UE's
**Remote Control API** (HTTP `:30010`) + the **Python Editor Script Plugin**. Tools include
`unreal_health`, `unreal_run_python`, `unreal_call_function`, `unreal_get/set_property`,
`unreal_console_command`, `unreal_list_actors`, `unreal_spawn_actor`, `unreal_destroy_actor`,
`unreal_list_assets`, `unreal_take_screenshot`, `unreal_save_all`, `unreal_play_in_editor`,
`unreal_stop_pie`. Setup + registration (`claude mcp add unreal -- unreal-mcp`) are in
`unreal-mcp/README.md`. Requires Python and a UE5 editor with Remote Control + Python plugins enabled.

## Migration workflow notes

- Start from `docs/migration/ARCHITECTURE_MAP.md` and `FLAME_TO_UNREAL.md`.
- Suggested order: skeleton (GameMode/GameState/PlayerController + subsystems) → data-driven content →
  battle simulation (entities/managers via GAS on a spline path) → VFX/shaders (Niagara/Materials) →
  HUD/UI (UMG/Common UI) → FPS mode (native camera/meshes) → audio (MetaSounds).
- The dominant cost is **re-authoring bespoke `dart:ui` Canvas art** as Materials/Niagara/UMG, not
  translating logic. Budget for tech-art, not just code.
