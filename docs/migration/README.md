# Neon Defense Unreal Migration

This folder is the migration knowledge base for porting Neon Defense from
Flutter + Flame to Unreal Engine 5.

## Read Order

1. `HANDOFF.md` - current state, completed work, in-flight work, and next steps.
2. `ARCHITECTURE_MAP.md` - subsystem-by-subsystem map of the Flutter codebase.
3. `DEPENDENCY_GRAPH.md` - import graph, coupling hubs, cycles, and external package targets.
4. `FLAME_TO_UNREAL.md` - construct-by-construct migration matrix.

## Current Direction

The first Unreal milestone skeleton is now implemented and validated:

- C++ project/module structure.
- `AGameModeBase`, `AGameStateBase`, `APlayerController`, and `APlayerState`.
- `UGameInstanceSubsystem` services for settings, level/progress, upgrades, audio, and asset streaming.
- Message channels to replace Flame `HasGameRef` back-references.
- Neon theme split into UI design tokens and world material parameters.
- One central grid-to-world coordinate transform.
- Data-driven tower, enemy, and wave skeleton assets.
- Prototype map `/Game/NeonDefense/Maps/L_NeonSkeleton`.
- Prototype one-wave vertical slice validated in PIE.
- Flutter TMX map data imported to `/Game/NeonDefense/Data/Maps/DA_Map_Level001` through `DA_Map_Level100`.
- Neon prototype material pass applied to board/path/socket/spawn/goal/tower/enemy assets.

Do not port `BoredGamesGame` one-to-one. The Flutter/Flame runtime is a tightly coupled 37-node cycle;
the Unreal version should break that cycle with GameMode/GameState/Controller ownership, subsystems,
and message-based events.

The active next milestone is map-aware gameplay and HUD:

- add debug grid overlay for imported map validation — DONE (`ABTDDebugGridActor`).
- first UMG HUD bound to `FBTDResourceSnapshot` — DONE (C++ `UBTDHudWidget`, neon in-code fallback).
- expand map-aware gameplay beyond `DA_Map_Level001`.
- author `WBP_BTDHud` (neon/Tron layout) reparented to `UBTDHudWidget`; add AssetManager + MaterialParameterCollection.

## Validation Baseline

The documented Flutter baseline is `12,478 / 12,478` tests passing in Docker:

```bash
cd flutter_app
docker compose --profile test up --abort-on-container-exit flutter-test
```

Regenerate the Dart dependency graph after structural source changes:

```bash
cd flutter_app
node scripts/codegraph.js
```

## Unreal MCP

The `unreal-mcp/` directory contains a Python MCP server for controlling a running UE5 editor through
Remote Control API and the Python Editor Script Plugin. From the repo root, read
`unreal-mcp/README.md`.

Operational scripts:

- `scripts/unreal-health.ps1` - verifies package import, Claude MCP registration, and UE Remote Control reachability.
- `scripts/register-unreal-mcp.ps1` - registers the local `unreal` MCP server for Claude using the repo venv.
- `scripts/start-unreal-editor.ps1` - starts the UE5 project with Remote Control launch flags.

UE 5.7 project config note: `URemoteControlSettings` uses `config = RemoteControl`, so MCP-related
Remote Control permissions belong in the Unreal project file
`Config/DefaultRemoteControl.ini`, not only `DefaultEngine.ini`.

## Local Claude Skills

Local Claude skills are under `.claude/skills/` when present. They are intentionally ignored by git:

- `neon-unreal-skeleton`
- `neon-flutter-map`
- `neon-unreal-mcp`

Codex also has a local user skill at `C:\Users\daedg\.codex\skills\unreal-engine-mcp`.

## Current Unreal Validation

- `BoredTowerDefenseEditor Win64 Development` builds successfully with UE 5.7.4.
- `scripts/unreal-health.ps1` confirms Remote Control and Python execution.
- PIE smoke test creates one `BTDGameMode` and one `BTDGameState`.
- Initial PIE snapshot is `gold=300`, `lives=20`, `max_lives=20`, `total_waves=1`, `status=Ready`.
- Vertical slice PIE result: 3 towers placed, 8 enemies killed, final snapshot `gold=121`, `lives=20`, `score=400`, `status=Victory`.
- TMX import validation: 100/100 map assets pass tile count, tile value, waypoint-on-path, and path connectivity checks.
- Map-aware PIE result: `DA_Map_Level001` drives path and placement; final snapshot remains `gold=121`, `lives=20`, `score=400`, `status=Victory`.
- Visual pass validation: 9 material assets exist under `/Game/NeonDefense/Materials`, and map actors/data assets reference them.
- HUD + debug grid milestone: `UBTDHudWidget` (bound to `OnResourceSnapshotChanged`) and `ABTDDebugGridActor` build clean; in real PIE the HUD widget is created + on-viewport and the debug grid auto-spawns aligned to the live map (`CellToWorld` spawn/goal/tower positions match gameplay exactly). See `HANDOFF.md` → "Milestone — Neon HUD + Debug Grid Overlay".
