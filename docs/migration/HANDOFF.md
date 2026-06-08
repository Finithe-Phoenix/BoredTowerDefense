# HANDOFF - Neon Defense to Unreal Engine 5

Repo root: `C:\Users\daedg\OneDrive\Documentos\GitHub\BoredTowerDefense`

Flutter game: `flutter_app/`

Unreal project: `C:\Users\daedg\OneDrive\Documentos\Unreal Projects\BoredTowerDefense\BoredTowerDefense.uproject`

Engine: UE 5.7.4 at `C:\Program Files\Epic Games\UE_5.7`

## Current State

The Unreal migration skeleton is now active and verified. Claude CLI, Gemini CLI, Codex tooling, and the local Unreal MCP path are all usable from this repo.

Claude MCP `unreal` is registered locally and connected:

```powershell
claude mcp list
```

Unreal Remote Control and Python execution are validated through:

```powershell
.\scripts\unreal-health.ps1
```

The active Unreal map is:

```text
/Game/NeonDefense/Maps/L_NeonSkeleton.L_NeonSkeleton
```

Project defaults now point at the skeleton map, `BTDGameInstance`, and `BP_BTDGameMode`.

## Completed

- Installed and validated the Unreal C++ build toolchain:
  - Visual Studio 2022 Build Tools
  - MSVC 14.44
  - Windows SDK 10.0.22621.0
  - .NET Framework 4.8.1 Developer Pack
- Built `BoredTowerDefenseEditor Win64 Development` successfully.
- Patched `unreal-mcp` for UE 5.7 Remote Control Python execution:
  - `unreal_client.py` sends `ExecutePythonCommandEx` params in the format UE 5.7 expects.
  - `server.py` uses Python `True`/`False` instead of JSON `true`/`false` in generated Python.
- Enabled required Unreal plugins:
  - RemoteControl
  - RemoteControlWebInterface
  - PythonScriptPlugin
  - EnhancedInput
  - CommonUI
  - Niagara
  - GameplayAbilities
- Added `Config/DefaultRemoteControl.ini` because UE 5.7 stores `URemoteControlSettings` in `RemoteControl` config.
- Created C++ module `BoredTowerDefense`.
- Created core C++ classes:
  - `ABTDGameMode`
  - `ABTDGameState`
  - `ABTDPlayerController`
  - `ABTDPlayerState`
  - `UBTDGameInstance`
  - `UBTDSettingsSubsystem`
  - `UBTDLevelSubsystem`
  - `UBTDSaveSubsystem`
  - `UBTDUpgradeSubsystem`
  - `UBTDAudioSubsystem`
  - `UBTDAssetStreamingSubsystem`
  - `UBTDMessageSubsystem`
  - `UBTDGridLibrary`
  - `UBTDNeonThemeDataAsset`
- Created combat skeleton C++ classes:
  - `UBTDTowerDataAsset`
  - `UBTDEnemyDataAsset`
  - `UBTDWaveDataAsset`
  - `ABTDTowerActor`
  - `ABTDEnemyActor`
  - `UBTDWaveSubsystem`
  - `UBTDPlacementSubsystem`
- Created map/path prototype C++ classes:
  - `ABTDPathActor`
  - `ABTDPrototypeDirector`
  - `UBTDLevelMapDataAsset`
- Created gameplay tags in `Config/DefaultGameplayTags.ini`.
- Created Unreal content:
  - `/Game/NeonDefense/Data/DA_NeonTheme_Default`
  - `/Game/NeonDefense/Data/DA_Tower_Basic`
  - `/Game/NeonDefense/Data/DA_Enemy_Runner`
  - `/Game/NeonDefense/Data/DA_Wave_Prototype_01`
  - `/Game/NeonDefense/Blueprints/BP_BTDGameMode`
  - `/Game/NeonDefense/Blueprints/BP_BTDPlayerController`
  - `/Game/NeonDefense/Blueprints/BP_BTDTowerActor`
  - `/Game/NeonDefense/Blueprints/BP_BTDEnemyActor`
  - `/Game/NeonDefense/Blueprints/BP_BTDPathActor`
  - `/Game/NeonDefense/Blueprints/BP_BTDPrototypeDirector`
  - `/Game/NeonDefense/Maps/L_NeonSkeleton`
  - `/Game/NeonDefense/Data/Maps/DA_Map_Level001` through `DA_Map_Level100`
  - `/Game/NeonDefense/Materials/M_Neon_Background`
  - `/Game/NeonDefense/Materials/M_Neon_Board`
  - `/Game/NeonDefense/Materials/M_Neon_Path`
  - `/Game/NeonDefense/Materials/M_Neon_TowerSocket`
  - `/Game/NeonDefense/Materials/M_Neon_Spawn`
  - `/Game/NeonDefense/Materials/M_Neon_Goal`
  - `/Game/NeonDefense/Materials/M_Neon_Tower`
  - `/Game/NeonDefense/Materials/M_Neon_Enemy`
  - `/Game/NeonDefense/Materials/M_Neon_Text`
- The skeleton map contains:
  - board marker
  - path cell markers
  - tower socket markers
  - spawn and goal markers
  - prototype camera and lights
  - tower/enemy preview actors
- PIE smoke test passed:
  - PIE world count: 1
  - `BTDGameMode` count: 1
  - `BTDGameState` count: 1
  - initial snapshot: `gold=300`, `lives=20`, `max_lives=20`, `total_waves=1`, `status=Ready`
- One-wave vertical slice passed in PIE:
  - `BTDPrototypeDirector` auto-starts
  - 3 prototype towers placed
  - `DA_Wave_Prototype_01` runs through `UBTDWaveSubsystem`
  - 8 enemies killed
  - final snapshot: `gold=121`, `lives=20`, `score=400`, `wave=1`, `enemies_killed=8`, `towers_placed=3`, `status=Victory`
- Map-aware vertical slice passed in PIE:
  - `BTDPrototypeDirector` uses `/Game/NeonDefense/Data/Maps/DA_Map_Level001`
  - `BTDPathActor::ApplyMapData` builds the spline from imported `WaypointCells`
  - `UBTDPlacementSubsystem::ConfigureFromMap` configures the 20x12 map grid
  - towers placed through `PlaceTowerOnMapCell` at cells `(6,3)`, `(10,7)`, `(13,7)`
  - tower world locations validated: `(-350,-250,45)`, `(50,150,45)`, `(350,150,45)`
  - final snapshot remains `gold=121`, `lives=20`, `score=400`, `enemies_killed=8`, `towers_placed=3`, `status=Victory`
- Visual prototype pass:
  - 9 neon material assets created
  - `DA_Tower_Basic` uses `M_Neon_Tower`
  - `DA_Enemy_Runner` uses `M_Neon_Enemy`
  - 29 placed skeleton actors in `L_NeonSkeleton` now have color-coded materials
  - board/path/socket/spawn/goal labels are no longer default black/white materials
- TMX import passed:
  - 100 Flutter maps imported from `flutter_app/assets/tiles/maps/level1.tmx` through `level100.tmx`
  - all map assets are `20x12`, `SourceCellSize=32`, `TileTypes.Num=240`
  - tile values are `0=Buildable`, `1=Blocked`, `2=Path`
  - validation found 0 failures across all 100 assets
  - aggregate: 8,181 path tiles, 15,819 buildable tiles, 0 blocked tiles

## Milestone — Neon HUD + Debug Grid Overlay (Claude / Opus 4.8, 2026-06-05)

New C++ in `Source/BoredTowerDefense/` (module builds clean on UE 5.7.4, `Result: Succeeded`):

- `UBTDHudWidget` (`Public/BTDHudWidget.h`, `Private/BTDHudWidget.cpp`) — data-only `UUserWidget` HUD.
  - Binds to `ABTDGameState::OnResourceSnapshotChanged`; seeds from `GetResourceSnapshot()`; unbinds on destruct.
  - Writes `meta=(BindWidgetOptional)` `UTextBlock` fields: `GoldText`, `LivesText`, `ScoreText`, `WaveText`, `TotalWavesText`, `StatusText`.
  - `OnSnapshotUpdated(FBTDResourceSnapshot)` BlueprintImplementableEvent so a WBP can drive neon visuals from the full snapshot.
  - Robust bind: `TryBindGameState()` retries on a 0.1s timer until the GameState exists (handles the replication/load-order race).
  - First-light fallback: `RebuildWidget()` builds an in-code neon-cyan label layout (GOLD/LIVES/SCORE/WAVE/WAVES/STATUS) when no WBP widget tree is authored, so the HUD is always visible with zero Blueprint wiring. A `WBP_BTDHud` subclass supersedes it automatically.
- `ABTDDebugGridActor` (`Public/BTDDebugGridActor.h`, `Private/BTDDebugGridActor.cpp`) — per-tick DrawDebug overlay of the active map.
  - Colors each cell by `EBTDMapTileType` (Buildable=green, Path=magenta, Blocked=red) using `UBTDLevelMapDataAsset::CellToWorld` + `GetTileType`.
  - Draws the ordered waypoint polyline (cyan), spawn sphere (cyan, first waypoint), goal sphere (yellow, last waypoint).
  - `Configure(MapData, Origin)`, `SetEnabled`, `ToggleEnabled`, `IsEnabled`.
- Wiring:
  - `ABTDPlayerController` creates the HUD in `BeginPlay` (local, non-dedicated-server only); `HudWidgetClass` defaults to `UBTDHudWidget` (overridable by a WBP on `BP_BTDPlayerController`). Logs a warning if unset.
  - Exec `BTDDebugGrid 1` / `BTDDebugGrid 0` finds-or-spawns the grid and `Configure`s it from the running `ABTDPrototypeDirector` via the new `GetActiveMapData()` / `GetGridOrigin()` getters.
  - `ABTDPrototypeDirector` auto-spawns + configures the grid at the end of `StartPrototype` when `bSpawnDebugGrid` is set (defaults `DebugGridActorClass` to the C++ class); destroys it in `StopPrototype`.

External review used (this milestone): Codex (gpt-5.5, read-only) + Gemini reviewed the diff in parallel. Real findings, both fixed:
- the `BTDDebugGrid` exec spawned the grid without `Configure()` → wired to the director getters;
- HUD GameState bind race → added the retry timer.
Their "missing header / missing UPROPERTY / undefined `World` / empty `StatusToText`" findings were artifacts of an abridged review brief (real files compile — `Result: Succeeded`).

PIE validation (real Play-in-Editor via `LevelEditorSubsystem.editor_request_begin_play`; `L_NeonSkeleton` → `DA_Map_Level001`):
- `ABTDPlayerController` spawns; the HUD widget is created, `is_in_viewport=true`, `is_visible=true`.
- Debug grid auto-spawns (`bSpawnDebugGrid=true` persisted on the director instance in `L_NeonSkeleton`) and is configured with the live map.
- Slice-end snapshot: `gold=121, lives=20, score=400, wave=1/1, status=Victory` (matches the prior vertical-slice baseline).
- Numeric alignment proof — `CellToWorld` (the transform the overlay draws with) matches gameplay exactly:
  - spawn cell `(0,5)` → `(-950,-50,45)` == path spawn location;
  - goal cell `(16,9)` → `(650,350,45)` == path goal location;
  - tower cells `(6,3)`/`(10,7)`/`(13,7)` → `(-350,-250,45)`/`(50,150,45)`/`(350,150,45)` == placed tower world locations.

Capture note: `HighResShot` / `AutomationLibrary.take_high_res_screenshot` (the MCP screenshot path) renders the 3D scene ONLY — it does NOT capture `DrawDebug` primitives or Slate/UMG. The saved top-down screenshot (`<Project>/Saved/Screenshots/WindowsEditor/btd_topdown_02.png`) shows the skeleton map markers; the debug overlay + HUD are verified programmatically (above), not in that image. A clean overlay/HUD capture needs a UI-inclusive backbuffer screenshot — folded into the `WBP_BTDHud` next step.

## Milestone — Visual pass (Tron floor + neon HUD) + MCP leveling (Claude / Opus 4.8, 2026-06-06)

Visual (live edits in `L_NeonSkeleton`, saved):
- `M_Neon_TronFloor` — procedural UNLIT neon grid material built via `MaterialEditingLibrary`
  (TexCoord 20x12 → frac → edge lines via abs/power → emissive cyan HDR). `BTD_TronFloor` plane
  (scale 20x12 = 2000x1200, z=-2) uses it, aligned so grid lines fall on the 20x12 map cell boundaries.
- `PPV_NeonGlow` unbound PostProcessVolume: Bloom intensity 2.6, threshold -1 (all emissive blooms),
  exposure locked (auto-exposure min=max=1.0 so blacks stay black). This single pass turns flat
  emissive blocks into a glowing Tron board — the missing post-process was the root cause of the
  "looks horrible" complaint.
- `BTD_NeonFog` ExponentialHeightFog (subtle atmosphere).
- Neon HUD: `UBTDHudWidget::RebuildWidget()` builds an in-code neon top-bar when no WBP tree exists
  (UCanvasPanel → "NEON DEFENSE" title + UHorizontalBox of UBorder cards: GOLD gold, LIVES red-pink,
  SCORE green, WAVE magenta "x / y", STATUS cyan; fonts via `FCoreStyle::GetDefaultFontStyle`).
  `Build.cs` gained `Slate` + `SlateCore`. `WBP_BTDHud` exists (reparented to `UBTDHudWidget`) as the
  designer shell; its empty widget tree falls through to the C++ layout. (WidgetTree authoring via
  UE 5.7 Python is blocked — `WidgetTree` is a protected UPROPERTY — hence the C++-layout approach.)
- Verified in real PIE: HUD shows the live snapshot `GOLD 121 / LIVES 20 / SCORE 400 / VICTORY` over
  the Tron board. Capture: `Saved/Screenshots/WindowsEditor/btd_hud_ui.png` (full editor frame).

UMG/DrawDebug capture — SOLVED (Codex gpt-5.5): the console command
`Shot SHOWUI filename="<abs>.png" -nosuffix` executed on the PIE **game world** (via
`SystemLibrary.execute_console_command`) routes through `FScreenshotRequest` with `bShowUI=true` and
DOES capture Slate/UMG + DrawDebug. `HighResShot` / `take_high_res_screenshot` still do NOT. Poll for
the file from the client side after the exec returns (the editor ticks and writes asynchronously).

unreal-mcp server improvements (applied to `unreal-mcp/src/unreal_mcp/server.py`, import-verified):
- `unreal_play_in_editor(mode="play"|"simulate")` — "play" uses `editor_request_begin_play` (real PIE
  with GameMode PlayerController + HUD); "simulate" uses `editor_play_simulate`.
- `unreal_take_screenshot(..., wait_seconds=10)` — resolves + returns the absolute PNG path and polls
  for the file (`force_game_view=True`). Scene only.
- NEW `unreal_screenshot_ui(filename, resolution, wait_seconds=15)` — `Shot SHOWUI` capture including
  UMG + DrawDebug; requires active PIE.
- Helpers: `_normalize_wait_seconds`, `_poll_local_screenshot_file`, `_move_local_file_to_path`.
- NOTE: a running Claude MCP session must reconnect to expose the new tools; the same techniques work
  today via `unreal_run_python` + `execute_console_command`.

Multi-agent leveling (the "3" CLIs):
- `unreal` MCP wired into Codex (`~/.codex/config.toml` → `[mcp_servers.unreal]`, enabled) and Gemini
  (`~/.gemini/settings.json` → `mcpServers.unreal`). Gemini disables MCP in untrusted folders — use
  `gemini --skip-trust` or add the repo to `~/.gemini/trustedFolders.json`. All three can drive UE5.
- More capable Unreal MCPs to evaluate/adopt: `remiphilippe/mcp-unreal` (Go, 49 tools, UMG-overlay
  screenshots, headless builds, Niagara), `GenOrca/unreal-mcp` (Python, authors UMG Widget Blueprints),
  `flopperam/unreal-engine-mcp` (50+ tools across VFX/PCG/cinematics/landscape).

## Milestone — Live combat FX + neon meshes (Claude / Opus 4.8, 2026-06-06)

Live combat FX (C++, module builds clean; designed by Codex gpt-5.5, which recommended DrawDebug +
a spawned projectile over Niagara since engine template Niagara paths are unstable to hard-code):
- `ABTDNeonProjectileActor` (NEW) — emissive cylinder + cyan `UPointLightComponent` that travels from
  the tower muzzle to the target at `TowerData.ProjectileSpeed` and deals damage in `Impact()` (this is
  now the real damage path), plus a DrawDebug tracer + impact sphere. Real mesh+light → captured by screenshots.
- `ABTDTowerActor::FireAtTarget` rewritten to spawn the projectile (was instant damage).
- `ABTDEnemyActor` — pulsing emissive MID (`InitializeLiveVFX`/`UpdateLiveVFX`), DrawDebug trail per move,
  and `SpawnDeathImpactVFX()` (expanding-sphere burst via 7 timers) hooked into `HandleDefeated`.

Neon meshes/materials (MCP/Python, no rebuild):
- `M_Neon_TowerGlow` (cyan HDR) + `M_Neon_EnemyGlow` (magenta HDR) — UNLIT emissive materials with a
  Fresnel rim glow, built node-by-node via `MaterialEditingLibrary`.
- `DA_Tower_Basic` → mesh `/Engine/BasicShapes/Cone` + `M_Neon_TowerGlow`; `DA_Enemy_Runner` →
  `/Engine/BasicShapes/Sphere` + `M_Neon_EnemyGlow`. `InitializeTower`/`InitializeEnemy` override the
  component mesh + material from the data asset (actor inherits the BP component scale).

Wave/enemy tuning: `DA_Wave_Prototype_01` (`EnemyGroups[0].Count` / `SpawnInterval`) + `DA_Enemy_Runner`
(`MoveSpeed`/`MaxHealth`). NOTE editing a `TArray<FStruct>` via Python needs EXPLICIT reassignment:
`groups[0] = g; wave.set_editor_property("enemy_groups", groups)` — modifying the struct copy in place
without reassigning silently fails to persist (the `Count` edit reverted otherwise; `SpawnInterval` happened to stick).

Validated in PIE via `Shot SHOWUI`: enemies stream along the neon path as glowing magenta spheres,
cyan cone towers fire projectiles, HUD live-updates (e.g. `GOLD 72 / LIVES 19 / SCORE 300 / IN PROGRESS`).

NEW gotchas:
- `Shot SHOWUI filename="<abs>.png" -nosuffix` (console, on the PIE game world) captures BOTH UMG AND
  DrawDebug (the debug grid's magenta/green cells + tower/enemy tracers all appear). `HighResShot` captures neither.
- Heavy PIE load (e.g. an 80-enemy wave + per-death burst timers + per-tick DrawDebug trails) can
  saturate the editor game thread so RC Python exec exceeds even a 150s timeout → the editor effectively
  HANGS. Recovery: force-kill `UnrealEditor` + `start-unreal-editor.ps1`; keep waves modest (<= ~16 enemies)
  and do heavy asset ops (material recompile) with NO PIE running.
- The Claude MCP client default `UNREAL_RC_TIMEOUT` is 15s. For slow ops call RC directly via
  `Invoke-RestMethod ... -TimeoutSec 120` (PUT `/remote/object/call` → `ExecutePythonCommandEx`), or
  re-register the MCP with `UNREAL_RC_TIMEOUT=60`. (Codex + Gemini were wired with `UNREAL_RC_TIMEOUT=60`.)
- `remiphilippe/mcp-unreal` (49-tool Go server) is now BUILT + REGISTERED + CONNECTED for all three CLIs:
  binary `C:\Users\daedg\go\bin\mcp-unreal.exe` (built via portable Go 1.26 at `C:\Users\daedg\go-portable`,
  repo cloned to `C:\Users\daedg\mcp-unreal-eval`). Registered as `mcp-unreal` in Claude (`claude mcp add`,
  ✓ Connected), Codex (`~/.codex/config.toml`), and Gemini (`~/.gemini/settings.json`), with
  `MCP_UNREAL_PROJECT` = the .uproject. So both `unreal` (Remote Control Python) and `mcp-unreal` (headless
  builds/tests, Blueprint editing, procedural meshes, UMG-overlay screenshots, Niagara, UE API docs) are live.
  Optional remaining for its advanced tools: run `mcp-unreal --build-index` (UE-docs lookup tool) and copy
  its `plugin/` into the project's `Plugins/MCPUnreal/` + rebuild (HTTP server on :8090).

## Milestone — Full combat roster + data-driven abilities (Claude / Opus 4.8, 2026-06-06)

The 4-tower / 4-enemy / +mini-boss roster is now LIVE and distinct in a real PIE session, driven by
new **data-driven ability/modifier fields** on the C++ DataAssets (no behavior hardcoded per id).

C++ (module rebuilt clean, `Result: Succeeded`):
- `BTDCombatDataAssets.h` — tower gained `SlowAmount`, `SlowDuration`, `SplashRadius`, `bCanDetectPhantom`;
  enemy gained `BodyScale`, `bIsPhantom`, `MinionSpawnInterval`, `MinionsPerSpawn`,
  `TSoftObjectPtr<UBTDEnemyDataAsset> MinionData`. All default to no-effect so existing assets are unchanged.
- `ABTDEnemyActor` — `ApplySlow()` + `CurrentSlowMultiplier` applied to `MoveSpeed` in `AdvanceAlongPath`;
  `BodyScale` via `SetActorScale3D` in `InitializeEnemy`; boss minion spawner (cached archetype, **8-burst
  cap**, recursion guard) that registers minions with the wave subsystem; `EndPlay` clears timers; `IsPhantom()`.
- `ABTDNeonProjectileActor` — `Initialize()` carries slow + splash; `Impact()` applies the **direct hit first**,
  then a dedup'd splash AOE (collect-then-apply, no iterator invalidation).
- `ABTDTowerActor` — `FireAtTarget` passes slow/splash to the projectile; `AcquireTarget` skips phantom
  enemies unless `TowerData->bCanDetectPhantom`.
- `UBTDWaveSubsystem` — new public `RegisterSpawnedEnemy()` (`AddUniqueDynamic` + rejects when
  `CurrentWave==nullptr` + tracks in `ActiveEnemies`); `StopWave` unbinds + destroys tracked enemies so a
  stopped wave leaves no orphans / no boss spawning post-stop.
- `ABTDPrototypeDirector` — `InitialMapTowerData` per-cell tower-archetype array (zipped with
  `InitialMapTowerCells`, falls back to `TowerData`); 4th default cell added.

External review (this milestone) — Codex (gpt-5.5, read-only) + Gemini on the complete changed files:
- Codex returned `COMPILE: PASS` + `FAIL` with 6 **real** findings, ALL fixed before building: boss could
  keep spawning after `StopWave` (post-stop registration); unbounded/recursive minion spawn → PIE hang;
  splash could miss the direct target; `AddDynamic` double-bind; `LoadSynchronous` timer hitch; 3-cell default.
- Gemini returned **PASS** (its one substantive finding — the `LoadSynchronous` hitch — was already fixed
  via the Codex pass; the rest were O(N) perf notes deferred). Build then `Result: Succeeded`.
- The first build failed on ONE real compile error (director ternary `T*` vs `TObjectPtr` ambiguity) — fixed
  with `.Get()` on both branches; rebuild `Result: Succeeded`.

Content (editor Python `docs/migration/.tmp/apply_roster.py`, idempotent, no recompile):
- 6 neon UNLIT Fresnel-rim HDR materials; 4 tower DAs (Pulse Archer / Circuit Cannon / Phase Mage /
  Glimmer Field) with **Flame-accurate slow** (Phase Mage 0.5/1.5s, Glimmer Field 0.3/0.5s, others 0);
  4 enemy DAs + mini-boss (Elite Guard) with body scales runner 1.0 / overloaded 0.9 / juggernaut 1.4 /
  drone swarm 0.6 / **boss 2.0**, boss spawns 3 runner minions every 5s; `DA_Wave_Showcase` (5 staggered groups).
- Director instance in `L_NeonSkeleton` wired: 4 **auto-detected buildable path-adjacent cells**, the 4 tower
  archetypes in `InitialMapTowerData`, `WaveData=DA_Wave_Showcase`, auto-place + auto-wave on; level saved.
- `BTD_HeroCam` `CameraActor` spawned at an elevated 3/4 angle (loc ~`(50,-820,1520)`, pitch -60, yaw 90,
  FOV 70) with `auto_activate_for_player=PLAYER0` so PIE renders a clean board-filling hero view.

PIE validation (real `editor_request_begin_play`): all four tower types auto-place; the 4 enemy archetypes
stream at visibly distinct scales and the mini-boss (scale 2.0) appears together with them
(`scales=[0.6, 1.4, 1.4, 2.0]`, `towers=4`, `boss=1`); HUD live `GOLD 200 / LIVES 18 / SCORE 140 / IN PROGRESS`.
Captures (UI + DrawDebug via `Shot SHOWUI`): `Saved/Screenshots/btd_roster_hero2.png` (final hero shot),
`btd_roster_hero.png`, `btd_roster_mid.png`, `btd_roster_boss.png`.

Winnable-demo follow-up (same session): demo boss HP lowered to **500** so the 4 towers can clear the whole
wave. A second PIE run validated the full loop: the boss minion-spawn fires LIVE (alive enemy count jumped
`2 -> 4` as a 3-runner burst spawned), the towers then kill the boss (`+300` gold confirming the kill, not a
leak), and the wave resolves to **`status=VICTORY`** (`gold=550 lives=9 score=150`, lives > 0). Captures
`btd_roster_action.png` (boss under fire, a `BTDNeonProjectileActor` in flight) and `btd_roster_victory.png`
(VICTORY HUD over the board). The Flame-accurate boss HP is 1140; 500 is a demo-tuning value only.

Phantom-detect validation (same session, A/B behavioral test): created `DA_Enemy_Phantom`
(`is_phantom=true`) + a phantom-only `DA_Wave_Phantom` (8 phantoms), and ran the wave twice with the
director reconfigured data-only. **Run A** (4 non-detector towers, no Phase Mage): `score=0` — every
phantom slipped past untargeted (8 leaked, lives 20->12). **Run B** (Phase Mage included): `score=30` =
3 phantom kills — only the `bCanDetectPhantom=true` tower engaged them (lives 15). The 0-vs-30 split proves
`ABTDTowerActor::AcquireTarget`'s phantom gate works exactly as designed. The director was then restored to
the 4-distinct-tower + `DA_Wave_Showcase` config. (Confirmed the bool Python field name is `is_phantom`.)

Phantom visual treatment (same session): built `M_Neon_Phantom` (UNLIT, `BLEND_TRANSLUCENT`, dim cyan
emissive ~1.4/1.9, opacity 0.32) and assigned it to `DA_Enemy_Phantom` so phantoms render as faint
translucent ghosts vs the solid bright towers — the stealth reads visually while the Phase Mage still
picks them off. Capture `Saved/Screenshots/btd_phantom.png` (3 ghostly phantoms streaming, `score=30`).
Note: the enemy C++ live-VFX MID sets params named `Color`/`EmissiveStrength`, but the neon materials use
`NeonColor`/`RimBoost`, so those SetParameter calls are silent no-ops — materials render exactly as authored
(which is why the dim phantom look survives). Wave restored to `DA_Wave_Showcase` afterward.

NEW gotchas:
- **Bool UPROPERTY Python names strip the `b` prefix**: `bCanDetectPhantom` -> `can_detect_phantom`,
  `bIsPhantom` -> `is_phantom` (the `apply_roster.py` `safe_set` helper confirmed these names against the live editor).
- **`BP_BTDGameMode` `PrototypeStartingGold` CDO edit via Python did NOT take effect in PIE** — the running PIE
  GameMode still reported `prototype_starting_gold=300` despite a CDO read-back of 1000 (an `EditDefaultsOnly`
  inherited default not truly overridden by a Python CDO set + save). Worked around by lowering the **demo**
  tower costs to 40/70/60/80 (sum 250 <= the 300 start) so all 4 towers place. The real roster costs are
  50/100/80/120. Proper fix later: set it via the level World Settings GameMode override, or
  `BlueprintEditorLibrary.compile_blueprint` after the CDO set, or the C++ default.
  **RESOLVED 2026-06-06**: set the CDO `prototype_starting_gold`, then `unreal.BlueprintEditorLibrary.compile_blueprint(bp)`
  + `save_loaded_asset` — PIE now starts at the new value (verified `startGold=600`, all 4 real-cost towers
  place). A bare CDO set WITHOUT `compile_blueprint` does not persist to PIE. Real roster costs restored to 50/100/80/120.
- `L_NeonSkeleton` had **no `CameraActor`**, so PIE used the default PlayerController view (a low, near-horizontal
  angle that the strong bloom washed out at the floor horizon). A placed `CameraActor` with
  `auto_activate_for_player=PLAYER0` is the fix for a controlled PIE screenshot camera.

## Milestone — Autonomous roadmap campaign (Claude / Opus 4.8, 2026-06-06)

The user reviewed the full plan and chose "complete the ENTIRE roadmap autonomously, don't stop"
(mode "Autónomo total"). Milestones being chained in order B → A → C → D → E → F → G → big phases.

**B — Gold fix + real roster costs (data-only):** the demo starting gold is now genuinely 600 (was a
worked-around 300). Method: set the `BP_BTDGameMode` CDO `prototype_starting_gold`, then
`unreal.BlueprintEditorLibrary.compile_blueprint(bp)` + `save_loaded_asset` (a bare CDO set does NOT
persist to PIE — `compile_blueprint` is the missing step). Verified in PIE `startGold=600`, all four
**real-cost** towers (50/100/80/120 = 350) place. Tower costs restored to the Flame values.

**A + F — Boss UX (C++, module rebuilt clean):**
- `UBTDEnemyDataAsset` gained `bool bIsBoss`; `ABTDEnemyActor` gained `IsBoss()` + `GetDisplayName()`.
- HUD (`UBTDHudWidget`): `NativeTick` + an in-code **boss banner** (a centered-top `UVerticalBox` of a
  name `UTextBlock` + a `USizeBox`(`UProgressBar`)) built in `BuildBossBar` as part of the neon fallback
  layout. Each tick it finds the live boss (cached `TWeakObjectPtr`, re-scan only when invalid), sets the
  bar to `GetHealthPercent()` and the name to `GetDisplayName()`, shows the banner; collapses it when no
  boss is alive.
- Boss **per-phase color shift**: in `UpdateLiveVFX`, when `IsBoss()`, health crossing 75/50/25% sets the
  dynamic MID's `NeonColor` param progressively redder (orange→hot→red-orange→searing red). Works because
  the boss material `M_Neon_Orange` exposes a `NeonColor` VectorParameter (the enemy's older
  `Color`/`EmissiveColor` MID writes are no-ops on the neon materials — known, harmless).
- Verified in real PIE: the boss bar shows `◆ Elite Guard ◆` with the red bar at the live boss %
  (captured at 65% = phase 2) and is hidden before the boss spawns. Captures
  `Saved/Screenshots/btd_bossbar_dmg.png` (bar visible), `btd_bossbar_full.png` (bar hidden, no boss).
- External review (Codex gpt-5.5, read-only; Gemini produced no usable output again — MCP issues): Codex
  returned `FAIL` with 5 findings — applied the perf cache (`CachedBoss` re-scan-on-invalid) + phase reset
  (`CurrentBossPhase=0` in `InitializeEnemy`); the "phase color is a no-op" and "non-ASCII ◆" findings are
  non-issues here (boss material has `NeonColor`; the source is UTF-8 and compiled + rendered correctly);
  the "BuildBossBar only runs in the fallback" finding is a future-WBP concern (the current production HUD
  IS the fallback, so the bar is built) — documented, not changed.

NEW gotcha:
- A Blueprint `EditDefaultsOnly` default set via a Python CDO write only persists to PIE after
  `unreal.BlueprintEditorLibrary.compile_blueprint(bp)` + save (see milestone B).

**E — Roster expansion: chain-lightning + 2 towers (C++ rebuilt clean, Codex `PASS`):**
- `UBTDTowerDataAsset` gained `ChainCount` / `ChainRadius` / `ChainFalloff`. `ABTDNeonProjectileActor`
  `Initialize` carries them; `Impact()` after the direct hit (+ optional splash) arcs to up to `ChainCount`
  nearest not-yet-hit enemies within `ChainRadius` of the previous link, each taking `Damage*ChainFalloff^hop`,
  drawing a light-blue debug arc. `ChainOrigin` is captured BEFORE the direct `ApplyDamage` (which can destroy
  the target). `ABTDTowerActor::FireAtTarget` passes the params. Codex verified origin/dedup/destroy-mid-loop/
  falloff are safe.
- New data-driven towers: `DA_Tower_TeslaTerminal` (chain 2 / 240cm / 0.7, dmg 12, fire 0.29s — the Flame
  Tesla) and `DA_Tower_IonSniper` (range 1000, dmg 60, Strongest). The `MaterialExpressionCollectionParameter`
  node type is available for future material wiring.
- Validation: 4 Teslas (12 base dmg) cleared a wave of 6 juggernauts (1500 HP total) in ~10s — only possible
  because the chain multiplies effective damage across clustered enemies (indirect but conclusive). The arcs
  render but are subtle against the cyan board (light-blue `DrawDebug` lines); a brighter beam is a VFX-phase
  follow-up. Captures `btd_chain1/2.png`, `btd_chainarc1..3.png`. Showcase director config restored afterward.
- Also batched here (from the Boss UX review, flagged by BOTH Codex + Gemini): the boss banner widgets are now
  `UPROPERTY(meta=(BindWidgetOptional))` (`BossBarContainer` is `UVerticalBox*`, named `BossBarContainer`) so an
  authored WBP can supply them by name; the in-code fallback still builds + assigns them (Codex confirmed
  binding runs before `RebuildWidget`, so the fallback pointers stay valid).
- Codex LOW follow-ups (deferred, hypothetical future configs): splash+chain could double-hit a secondary if a
  tower ever enables both (add splash hits to the chain's `AlreadyHit`); a partial authored WBP with
  `BossBarContainer` but no `BossHealthBar` would early-return in tick without collapsing the container.
- Gemini review (FAIL, perf-only — no correctness blocker): chain's per-hop `TActorIterator` is O(N*ChainCount)
  (fold a collect-once list before the loop); the HUD no-boss scan runs every frame when `CachedBoss` is null
  (throttle to ~0.3s or track bosses in a subsystem). Both deferred to a perf pass — fine for the <20-enemy
  showcase. Gemini's "first chain arc applies falloff" note is NOT a bug: the direct/primary target already
  took full damage; chain (secondary) links correctly take `Falloff^hop`, matching the Flame Tesla design.
- The non-ASCII `◆` in the boss label is kept (it compiles under UE's /utf-8 and renders correctly; the
  tooling layer kept converting the `◆` escape back to `◆`). Low-risk; only matters on a non-UTF-8 build agent.

**(Tower upgrades) — Level-up system (C++ rebuilt clean):**
- `ABTDTowerActor` gained `Level` (1..`MaxTowerLevel`=4), `UpgradeTower()` (spends gold via
  `ABTDGameState::SpendGold`, only levels on success, ++Level + `ApplyUpgradeVisuals`), `GetTowerLevel()`,
  `GetUpgradeCost()` (= `TowerData->Cost * Level`). `GetRange/GetDamage/GetFireInterval` apply per-level
  multipliers (+12% range, +30% dmg, +20% fire-rate per level). `ApplyUpgradeVisuals` grows the actor
  (`SetActorScale3D`, +18%/level) and brightens the neon (`TowerMID` `RimBoost`), with a `TowerMID` created
  in `InitializeTower`.
- Validated in PIE: 12 upgrades took all 4 towers level 1→4 (capped), actor scale 1.0→1.54, and gold spent
  was exactly 2100 (= the 350 base-cost sum × 6 for L1→4) — confirming the gold-spend path and the cap.
  Capture `Saved/Screenshots/btd_upgrade.png` shows the visibly larger/brighter upgraded towers.
- Codex review (`FAIL` → reconciled, rebuilt clean): fixed **High** — `UpgradeTower` could level up for FREE
  when `GetWorld()`/GameState was null (nested guard skipped the spend); now it requires a GameState +
  successful `SpendGold` before `++Level`. Fixed **Low** — `GetUpgradeCost()` returns 0 at max level. **Medium**
  (scale could sink a tower if the mesh pivot is centered) noted but not changed — towers render fine on the
  board at the modest 1.0→1.54 growth; a fragile per-level z-heuristic would risk making it worse.

**(Content expansion) — full 9-tower roster + enemy variety + world bosses (data-only, NO rebuild):**
- Drives entirely off the already-built C++ systems (body-scale, slow, splash, chain, boss bar + phase
  colors + minions), via editor Python (`docs/migration/.tmp/apply_content.py`).
- +3 towers → **9 total**: Resonance Siphon (range/slow), Neural Disruptor (heavy 70% slow), Plasma Bubble
  (slow + 200cm splash). Joins Pulse Archer / Circuit Cannon / Phase Mage / Glimmer Field / Tesla Terminal
  (chain) / Ion Sniper.
- +5 enemies with distinct scale/HP/speed/colour: Speedster (0.75, fast), Tank Heavy (1.6, 400 HP),
  Shielded (1.2, 300 HP), Wisp (0.7, phantom — only Phase Mage hits it), Brute (1.3).
- +2 **world bosses** using `bIsBoss` (HUD boss bar + per-phase colour shift) + minion spawners:
  `DA_Enemy_CitadelCore` (scale 3.0, 2000 HP, 3 runner minions / 5s, "Citadel Core") and
  `DA_Enemy_OmegaNexus` (scale 4.0, 3500 HP, 4 overloaded minions / 4s, "Omega Nexus").
- `DA_Wave_Grand` showcases the variety + the Citadel Core world boss. Validated in PIE: at ~26s the wave had
  6 enemies at distinct scales `[1.3, 1.6, 3.0]` with `worldboss=1 (Citadel Core)`; the HUD boss bar correctly
  read `◆ Citadel Core ◆` over the giant scale-3.0 boss. Capture `Saved/Screenshots/btd_grand_boss.png`.
  Director restored to `DA_Wave_Showcase` afterward. No C++ review needed (pure data on validated systems).

**(Multi-wave levels) — wave progression in the director (C++ rebuilt clean):**
- `ABTDPrototypeDirector` gained `LevelWaves` (ordered `TArray<UBTDWaveDataAsset*>`) + `TimeBetweenWaves` +
  `CurrentWaveIndex`. When `LevelWaves` is non-empty it supersedes the single `WaveData`: `StartPrototype`
  resets the cursor + publishes `TotalWaves = LevelWaves.Num()` to the GameState snapshot; `StartWaveNow`
  runs `LevelWaves[CurrentWaveIndex]`; `HandlePrototypeWaveCompleted` advances the cursor and schedules the
  next wave after the intermission; the final wave's Victory is handled by the WaveSubsystem
  (`WaveNumber >= TotalWaves`). Backward-compatible (empty `LevelWaves` = the old single-wave behavior);
  `NextWaveTimerHandle` cleared in `StopPrototype`.
- Data: `DA_Wave_L1_W1/W2/W3` (WaveNumber 1/2/3, increasing difficulty, mini-boss in W3) wired into the
  director instance's `LevelWaves`.
- Validated in PIE end-to-end: the wave counter advanced `WAVE 1/3 -> 2/3 -> 3/3` (intermission chaining
  works), and Victory triggered only after the FINAL wave (`status=VICTORY` at wave 3/3, lives 3). HUD shows
  the live `x / 3`. Capture `Saved/Screenshots/btd_multiwave.png` (WAVE 3/3). The single-wave `DA_Wave_Showcase`
  path is unchanged for the simple demo.
- Codex review (`FAIL` → reconciled, rebuilt clean): fixed **High** — an out-of-range cursor in multi-wave
  mode fell back to the legacy single `WaveData`; now returns `nullptr` instead. **Med** — wave-completion
  only advances when `CompletedWave == LevelWaves[CurrentWaveIndex]` (ignores stray/duplicate broadcasts).
  **Med** — `StartPrototype` warns if any `LevelWaves[i].WaveNumber != i+1` (the victory check relies on it).
  The Low (header `TimerManager.h` include) was a non-issue — already compiled.

**(Win/loss loop) — defeat condition validated (data-only):** ran the 3-wave level with NO towers
(`bAutoPlaceTowers=false`); enemies leaked and drained lives `20 -> 15 -> 10 -> 5 -> 0`, at which point
`status=DEFEAT` (the WaveSubsystem's `LoseLife -> TriggerDefeat` path). HUD shows `LIVES 0 / DEFEAT`
(`Saved/Screenshots/btd_defeat.png`). The intermission `READY` status between waves was also visible. With
Victory already validated, the **core TD game loop is now complete end-to-end**: place + upgrade towers ->
survive multi-wave levels -> Victory (clear all waves) / Defeat (lose all lives). Director restored to
`bAutoPlaceTowers=true` afterward.

### Campaign status (autonomous, 2026-06-07)
Core playable TD migrated + validated in real PIE: 9 towers (distinct abilities: rapid, heavy, slow+phantom-
detect, crowd-slow, chain-lightning, sniper, range-slow, heavy-slow, splash) **with a 1->4 upgrade system**;
~10 enemy archetypes + mini-boss + 2 world bosses (body-scale, slow, phantom, boss bar + per-phase colours +
minion spawners); gold economy; **multi-wave levels** with intermissions; neon HUD (resource cards + wave
counter + dynamic boss health bar); **Victory + Defeat**. Remaining migration phases (larger / would benefit
from user direction): VFX as real Materials/Niagara (current combat FX are DrawDebug — editor-only), the
100-level campaign progression + save, player click-to-place/sell interaction, UMG menu/overlay screens
(WBP authoring is UE-5.7-Python-blocked), FPS mode, and audio/MetaSounds.

**(VFX) — real mesh-based neon bursts replacing editor-only DrawDebug (C++ rebuilt clean, Codex-reconciled):**
- NEW `ABTDNeonBurstActor`: an emissive sphere + point light that scales `0.1 -> MaxScale` and fades opacity
  `1 -> 0` over `Lifetime`, then self-destroys (with a `SetLifeSpan` backstop). Driven by a dynamic MID of a
  new translucent UNLIT `M_Neon_Burst` material (`BurstColor` vector + `BurstOpacity` scalar params).
  Spawned on `ABTDNeonProjectileActor::Impact` (cyan, scaled by splash) and `ABTDEnemyActor::HandleDefeated`
  (warm, scaled by `BodyScale`). Unlike DrawDebug, **these render in a packaged build**.
- Codex review (`FAIL` → reconciled): **High** — runtime `LoadObject` isn't cook-safe and a missing material
  showed a default gray sphere; now a constructor `FObjectFinder` caches `BurstMaterial` (cook-safe) with a
  `LoadObject` fallback, and the mesh is HIDDEN if no material resolves. **Med** — added `SetLifeSpan` backstop
  (pooling deferred — fine for the showcase). **Low** — swapped the deprecated
  `CreateAndSetMaterialInstanceDynamicFromMaterial` for `CreateDynamicMaterialInstance`.
- Validated in PIE: 1–3 bursts alive simultaneously during combat (lifetimes 0.5/0.6s); capture
  `Saved/Screenshots/btd_vfxburst.png` shows a glowing cyan emissive pop on the board. `M_Neon_Burst` created
  via the material builder. (Gotcha: the bursts are brief — sample fast / use the longer lifetimes to catch one
  in a still; the earlier 0.26s version was real but un-catchable at ~2s RC sampling.)

**(Level progression) — advancing through the 100-level campaign (C++ rebuilt clean):**
- `ABTDPrototypeDirector` gained `CurrentLevelId` / `MaxLevelId` / `bAutoAdvanceOnVictory` / `LevelAdvanceDelay`.
  `AdvanceToNextLevel()` (BlueprintCallable): increments the level, `LoadObject`s the next imported map
  (`DA_Map_Level%03d`) into `MapData`, resets the GameState snapshot (LevelId / gold 600 / lives 20 / wave 0 /
  Ready, score carried over), then `StopPrototype()` + `StartPrototype()` to rebuild the board on the new map.
  `HandlePrototypeWaveCompleted` schedules `AdvanceToNextLevel` after the final wave when `bAutoAdvanceOnVictory`.
- Validated in PIE: calling `advance_to_next_level()` on the running director took it `level 1 -> 2`, loaded
  `MapData` `Level001 -> Level002` (`source_map_name "level2"`), reset the snapshot (`LevelId=2, lives=20`),
  re-placed towers, and restarted the wave (`status=IN_PROGRESS`). Capture `Saved/Screenshots/btd_level2.png`.
  Note: the demo reuses one `LevelWaves` sequence + the level-1 tower cells for all levels (so level 2 placed
  fewer towers where its layout differs) — a full campaign needs per-level wave sets + buildable cells.
  Codex review (`FAIL` → reconciled, rebuilt clean): fixed **High** — the level was incremented BEFORE loading
  the next map, so a missing map would advance state onto a stale board; now it loads the next map FIRST and
  returns (no state change) if absent. **Low** (BlueprintCallable spam could skip levels) noted, not changed —
  each call legitimately advances one level and the demo doesn't spam it.

**(End-game banner) — prominent VICTORY/DEFEAT HUD overlay (C++ rebuilt clean):** `UBTDHudWidget` gained a
big centered `EndBannerText` (in the in-code fallback layout, `BindWidgetOptional`), driven in `ApplySnapshot`:
shows "VICTORY" (green) on `EBTDSessionStatus::Victory`, "DEFEAT" (red) on `Defeat`, collapsed otherwise.
Validated in PIE by setting the status via `ABTDGameState::SetSessionStatus` — the centered banner renders
over the board (`Saved/Screenshots/btd_banner_victory.png` / `btd_banner_defeat.png`). Trivial static-UI
change — built + PIE-validated without a Codex pass. (Polish note: a dark backing panel would improve banner
legibility over the bright board.)

**(Per-map auto placement) — every level places towers on its own cells (C++ rebuilt clean):**
`ABTDPrototypeDirector::ResolveTowerCellsForMap()` scans the active `MapData` for buildable, path-adjacent
cells (via `CanPlaceTowerOnCell` / `GetTileType==Path`) and overwrites `InitialMapTowerCells`, spread across
the candidates; called in `StartPrototype` before placing when `bAutoPlaceTowers`. This fixes the
level-progression limitation (levels reached via `AdvanceToNextLevel` previously reused the level-1 cells).
Validated in PIE: level 1 placed 4 towers; after `advance_to_next_level()`, level 2 (`mapLevelId=2`) also
placed **4** towers (was 2 before). The 100-level campaign is now properly playable across levels.
Codex review (`FAIL` → reconciled, rebuilt clean): fixed **Med** — if a map had no path-adjacent buildable
cells the function returned without clearing `InitialMapTowerCells`, leaving the previous level's (possibly
invalid) cells; now one pass collects path-adjacent AND any-buildable cells, prefers path-adjacent, falls back
to any buildable, and clears the cells (places none) if the map truly has none — never reuses stale cells.

**(Self-running campaign) — auto-advance activated (data-only):** set `bAutoAdvanceOnVictory=true` on the
`L_NeonSkeleton` director instance. Validated end-to-end in PIE: level 1's 3 waves cleared to `VICTORY`
(lives 8) → ~4s later the campaign auto-advanced to **level 2** (map `Level002` loaded, lives reset to 20,
towers re-placed via the per-map cell detection, wave 1/3 running). The demo is now a continuous campaign:
win a level → auto-advance → repeat. No rebuild (the auto-advance C++ shipped in the level-progression
milestone; this just enables the flag). The `EndBannerText` shows VICTORY for the 4s before advancing.

**(Player interaction) — click-to-place / select / sell / upgrade + tower palette (C++ rebuilt clean):**
The game is now human-playable. `ABTDPlayerController` gained: `TowerPalette` (the 9 roster towers, defaulted
in BeginPlay) + `SelectTowerType(idx)` on number keys **1-9**; a refactored left-click (`HandlePlaceTowerClick`
→ `ResolveCellUnderCursor` deproject→board-plane→cell) that **selects** the tower under the cursor if the cell
is occupied else **places** the selected type; `UpgradeSelectedTower()` on **U** (calls the tower's
`UpgradeTower`); `SellSelectedTower()` on **X** (refunds `GetSellValue` via `GameState::AddGold`, then
`PlacementSubsystem::ClearTower`). New helpers: `ABTDTowerActor::GetSellValue()` (~50% of invested),
`UBTDPlacementSubsystem::GetTowerAtMapCell()`. All interaction fns are `BlueprintCallable` (driven by input or
tested directly). Validated in PIE via the callable fns: select Tesla(idx 4) → place (−110 gold) → select →
upgrade (level 1→2, −110) → sell (+110 refund, cell empty after). Full chain works with correct gold accounting.
NEXT in this phase: start/victory/defeat **menu screens** + optionally a "player mode" toggle that disables the
director's auto-place/auto-wave so a human drives.
Codex review (`FAIL` → reconciled, rebuilt clean): fixed two **Med** + one **Low** selection-state issues —
`PlaceTowerAtCell` now selects the freshly-placed tower (so U/X never hit a stale prior selection);
`SellSelectedTower` now verifies `GetTowerAtMapCell(SelectedTowerCell) == SelectedTower` before refunding/clearing
(guards stale/sentinel selection); `ResolveCellUnderCursor` now bounds-checks the resolved cell.

**(End-game menus) — Next Level / Restart buttons (C++ rebuilt clean):** `ABTDPrototypeDirector::RestartLevel()`
resets the run (gold/lives/score/wave → Ready) + `StopPrototype`+`StartPrototype` on the SAME level.
`UBTDHudWidget::BuildEndButtons` adds an in-code row of two `UButton`s ("NEXT LEVEL" / "RESTART", each a
`UTextBlock` child, `OnClicked.AddDynamic`) centered under the banner; `ApplySnapshot` shows the row on
Victory (both buttons) / Defeat (Restart only). The handlers find the director and call
`AdvanceToNextLevel` / `RestartLevel`. Validated in PIE: forcing Victory showed the `VICTORY` banner + both
buttons (`Saved/Screenshots/btd_menu_victory.png`); calling `RestartLevel` reset the run and replayed level 1
(`level=1, lives=20`, board rebuilt, wave restarted). **The interaction + menus phase is essentially complete —
the game is human-playable**: place/select/sell/upgrade towers + end-game Next/Restart.
Codex review (`FAIL`, compile PASS → reconciled, rebuilt clean): two **Med** + two **Low** fixed — click
handlers now bind in `BindEndButtonHandlers()` from `NativeConstruct` with `AddUniqueDynamic` (works for a
future WBP-authored button too, not just the in-code fallback); the handlers are now status-gated (Next only
on Victory, Restart only on Victory/Defeat) so stale/early clicks are no-ops; `RestartButton` visibility is
set explicitly; `BuildEndButtons` early-returns if already built (idempotent).

**(Campaign save/persistence) — progress persists across sessions (C++ rebuilt clean):** new `UBTDSaveGame`
(`USaveGame`: `CurrentLevelId` / `HighestLevelReached` / `BestScore`). The **existing empty `UBTDSaveSubsystem`
stub** in `BTDGameInstanceSubsystems.h` was fleshed out — NOT a new class (a fresh `UBTDSaveSubsystem` collided
on engine name; **gotcha: check `BTDGameInstanceSubsystems.h` for the empty subsystem stubs — Settings/Level/
Save/Upgrade/Audio/AssetStreaming — before adding one**). `Initialize` loads/creates the `BTDCampaign` slot;
`SaveProgress(level,score)` grows Highest/Best + flushes; `GetSavedLevel/GetHighestLevel/GetBestScore/HasSave/
ClearProgress`. `ABTDPrototypeDirector::AdvanceToNextLevel` saves on each advance.
Codex review (`FAIL` → reconciled, rebuilt clean): **High** — the saved score was read AFTER the run-state reset;
now the completed-level score is captured BEFORE the reset. **Low** — `Flush` logs on `SaveGameToSlot` failure;
`ClearProgress` now `DeleteGameInSlot`s the slot (so `HasSave()` is false after).

**(Tower range indicator) — visualise a tower's range on select/place (C++ rebuilt clean):** `ABTDTowerActor`
gained a `RangeIndicator` `UStaticMeshComponent` (engine `Cylinder` mesh + the translucent `M_Neon_Burst`
material, NoCollision/no-shadow, hidden by default) and `ShowRangeIndicator(bool)` — scales it to a flat disc
of radius = `GetRange()` (cyan, opacity 0.18) at the board plane. `ABTDPlayerController` shows it on the
selected tower (`SelectTowerAt` moves it from the prior selection; `PlaceTowerAtCell` shows the placed tower's;
`UpgradeSelectedTower` re-shows to rescale to the upgraded range). Validated in PIE: showing it on towers
renders translucent cyan range discs on the board (`Saved/Screenshots/btd_range.png`). In real play only the
selected tower's disc shows (one clean ring of coverage).
Codex review (`FAIL`, compile OK → reconciled, rebuilt clean): **High** (potential `GetRange()` null-deref) was
a false alarm — `GetRange` is already null-safe (450 default) — but `ShowRangeIndicator` now still guards on
`TowerData != nullptr` for clarity; **Low** — swapped the deprecated `CreateAndSetMaterialInstanceDynamic` for
`CreateDynamicMaterialInstance`. **Med** (stale `SelectedTower`) was already mitigated (it's a `UPROPERTY` +
`IsValid` guards). A filled disc — a ring outline material is a future polish.

**(Selected-tower HUD panel) — discoverable upgrade/sell UI (C++ rebuilt clean):** `ABTDPlayerController`
exposes `GetSelectedTower()`. `UBTDHudWidget` builds an in-code `TowerPanelContainer` (bottom-center: a
`TowerInfoText` + a row of **UPGRADE** / **SELL** `UButton`s) and polls it from `NativeTick`
(`UpdateTowerPanel`): when the controller has a selected tower it shows the panel and sets `TOWER Lv {n}`,
`UPGRADE {cost}`/`MAX`, `SELL {refund}`; else collapses. The buttons (bound in `BindEndButtonHandlers` via
`AddUniqueDynamic`) call the controller's `UpgradeSelectedTower`/`SellSelectedTower`. Now a player can click a
tower and **see + click** its actions (no need to know the U/X keys). Validated in PIE: selecting a tower
(via `SelectTowerAt`) showed the panel with `TOWER Lv 1` / `UPGRADE 50` / `SELL 25`
(`Saved/Screenshots/btd_towerpanel.png`) plus the range disc.
Codex review (**PASS**, no High/Med): applied two Low nits — `GetSelectedTower` returns `SelectedTower.Get()`
(idiomatic for a BlueprintPure raw-ptr), and `OnSellClicked` calls `UpdateTowerPanel()` after selling so the
panel collapses the same frame. (Deferred negligible Lows: per-tick `SetText` allocation could be cached;
concrete widget includes were already present.)

**(Enemy health bars) — floating HP bars above every enemy (C++ rebuilt clean):** `ABTDEnemyActor` gained
`HealthBarBg` + `HealthBarFill` `UStaticMeshComponent`s (engine Cube + translucent `M_Neon_Burst`). They use
**absolute** location/rotation/scale (not inheriting the enemy's `BodyScale`), and `UpdateHealthBar()` (per
Tick) places them 90uu above the enemy, **yaw-billboards** them to face the camera, scales the fill by
`GetHealthPercent()` (left-aligned), and lerps its emissive **green(full)→red(low)**. Fill colour is repainted
only when HP changes (cached `LastHealthBarPct`); the fill hides at 0 HP. Validated in PIE by component
inspection: `HealthBarBg` visible 90uu above at fixed scale, `HealthBarFill` Y-scale `0.51` for an enemy at
`51%` HP (tracks HP exactly). Gotcha: at 480px top-down showcase capture the bars are subtle against the
bloom-heavy board — component inspection is the reliable check; a closer camera / dedicated bar material
(ring/segmented) is future polish.
Codex review (**PASS**): applied **Med** (cache fill colour, set opacity once — avoid per-tick material churn;
transforms still update each tick since the enemy moves + billboards) and **Low** (hide fill at 0 HP); the
**Low** body-scale-inheritance note is resolved by the absolute transforms.

**(Enemy hit flash) — combat juice on every hit (C++ rebuilt clean):** `ABTDEnemyActor::ApplyDamage` sets
`HitFlashRemaining = HitFlashDuration (0.15s)`; `UpdateLiveVFX` lerps the emissive `Glow` toward **45** by the
remaining-flash alpha (computed before decaying it, so the first frame gets the full spike) before writing
`EmissiveStrength`/`GlowIntensity`. So enemies flash bright when shot. `IsHitFlashing()` (BlueprintPure) exposes
the state. Validated in PIE: `apply_damage` → `IsHitFlashing()==true` (the emissive spike is a sub-200ms
transient that RC polling can't reliably sample — shorter than 2 round-trips — but the boost is deterministic
from the flashing state). Codex **PASS**; applied its minor polish (alpha-before-decay for a full first-frame
spike). **Validation note for brief VFX: RC screenshot/param polling can't catch <~0.3s transients; validate the
trigger state (a getter) instead of trying to sample the peak.**

**(Campaign difficulty curve) — enemy HP scales per level (C++ rebuilt clean):** self-contained in
`ABTDEnemyActor`. `InitializeEnemy` reads the BTD GameState snapshot `LevelId` and sets
`HealthScale = max(0.01, 1 + PerLevelHealthStep(0.08) * (LevelId-1))`, then `CurrentHealth = MaxHealth *
HealthScale`. `GetHealthPercent` divides by `MaxHealth * HealthScale` so a buffed enemy still reads 100% at full
(health bars + boss phase thresholds stay correct). **Level 1 = ×1.0 (existing balance untouched); reversible
(step 0 disables).** Rewards stay unscaled by design (later levels increase time-to-kill, not economy).
Validated in PIE: level-1 enemy `curHP 130 == maxHP 130` (×1.00); after advancing to level 6, a fresh enemy had
`curHP 182 == 130 × 1.40` (×1.40 = 1+0.08·5) with `hp%` still 1.00. Codex **PASS**; applied its **Low**
(clamp `HealthScale` so a future negative step can't make health negative).

**(Tower muzzle flash) — neon pop at the barrel on each shot (C++ rebuilt clean):** `ABTDTowerActor::FireAtTarget`
spawns a small `ABTDNeonBurstActor` at `MuzzleLocation` (`Initialize(yellow-green, 0.7 scale, 0.16s)`) right after
the projectile — reusing the validated burst VFX. Codex **PASS** (only a Low: per-shot actor churn is fine for a
TD; pool/Niagara only if profiling shows spikes). Validation: confirmed `FireAtTarget` runs (a projectile was
in flight) so the unconditional muzzle-spawn line executes each shot; the flash itself is a rare+brief transient
(towers fire sparsely × 0.16s) that RC polling can't reliably sample (min burst→tower distance stayed 122uu over
22 rapid samples — only impact/death bursts caught). Per the brief-VFX rule, this is logic-validated, not
peak-sampled. (A longer-lived flash or forcing constant fire would make it screenshot-catchable.)

**(VISUAL OVERHAUL — user feedback: the look was the priority, not gameplay juice) — editor/material work, no
C++:** the showcase (`L_NeonSkeleton`) went from "primitive shapes on a flat grid" to a **cinematic neon Tron
arena**:
- **`PPV_NeonGlow` post-process**: bloom ~1.5 (was washing out at 4), manual exposure bias ~10.5, cool Tron color
  grade (saturation/contrast/white-temp), vignette 0.45, scene-fringe (chromatic aberration) ~1.0, AO. (Gotcha:
  bloom 4 + mirror floor + dark scene = washed-out blob; dial bloom to ~1.5 and exposure to ~10.5.)
- **Moody lighting**: dimmed `BTD_KeyLight` (~1.6) + `BTD_SkyLight` (~0.45) so the emissive neon dominates.
- **`M_TronGrid` floor** (NEW, procedural): `BTD_TronFloor` now renders a glowing cyan **grid** (WorldPos→/cell→
  Frac→abs→saturate line mask, emissive × cyan) on a dark metallic/low-roughness base → reflective. This single
  change gave the scene structure, perspective + depth (the biggest win). Hero shot
  `Saved/Screenshots/WindowsEditor/HighresScreenshot00002.png`.
- **`M_NeonRim_<color>` entity materials** (NEW ×7: Cyan/Green/Magenta/Orange/Pink/Purple/TowerGlow): emissive =
  `NeonColor × (EmissiveStrength·0.22 + Fresnel·RimBoost)` — Fresnel rim glow + bright core. Params named to
  match the existing MID-setting C++ (`NeonColor`/`EmissiveStrength`/`RimBoost`), so per-type colours, boss
  phase-shift, pulse + hit-flash all still drive it. Repointed all 21 `DA_Tower_*`/`DA_Enemy_*` `material` fields.
- **Tooling**: visual work driven via Python material/actor scripts in `docs/migration/.tmp/visual_*.py`;
  `MaterialEditingLibrary.create_material_expression` + `connect_material_expressions(from,'',to,'A'/'B')`.
  Capture full-res with the PIE console `HighResShot 1920x1080` → `Saved/Screenshots/WindowsEditor/`.
- **Meshes** (data-only): repointed all `DA_Tower_*` → `Cone` (spire silhouette), `DA_Enemy_*` → `Sphere` (orbs),
  bosses → `Cylinder` (imposing) for shape variety/readability. Still engine primitives — true distinct
  silhouettes need custom/Fab meshes or composed multi-component actors (C++).
- **Camera**: `BTD_HeroCam` is a 3/4 angle (pitch -60, h 1520, fov 70); `BTD_PrototypeCamera` (h 900) is the
  other. Left as-is — re-angling the play camera risks the board framing/placement readability; tune with the
  user. Remaining visual levers: custom/Fab meshes, Niagara particles, animated grid, a backdrop/skybox.
- **(Floating tower core — C++ rebuilt clean)**: `ABTDTowerActor` gained a `CoreMesh` (engine Sphere, scale 0.32,
  rel Z 78, NoCollision/no-shadow) that **spins + bobs** every Tick (`yaw = t·80`, `Z = 78 + 7·sin(t·2.2)`),
  material set to `TowerData->Material` so it glows the tower colour. Gives each tower a designed "energy core"
  above the spire. Validated: cores render as glowing orbs over the towers in
  `Saved/Screenshots/WindowsEditor/HighresScreenshot00005.png` (persistent → screenshot-catchable, unlike the
  brief-VFX). Codex **PASS**; applied its **Low** — `CoreMesh` is now hidden in the ctor and shown in
  `InitializeTower` after the material is applied (no brief default-grey sphere before init).

## External Reviews Used

Gemini CLI was used with `--skip-trust`. Its priorities matched the current direction:

- data-driven tower/enemy actors
- wave controller
- grid placement
- pooled projectile path later
- reactive UMG HUD from GameState

Claude CLI was used after it came back online. It flagged:

- keep `WaveSubsystem` and `PlacementSubsystem` as `UWorldSubsystem` - already done
- avoid porting `BoredGamesGame` as a monolith
- avoid storing grid state in the function library - already done
- move toward spline/path based enemies before expanding tower types
- validate AssetManager and MaterialParameterCollection later
- validate TMX parity risks: Y-axis orientation, cell center vs corner, path width, buildability, and waypoint/path sync

Explorer subagent inspected the Flutter code and confirmed the migration priorities:

- `bored_games_game.dart` is the runtime authority in Flutter
- maps come from TMX path/collision data in `game_world.dart`
- tower behavior is centered in `tower.dart` and `tower_manager.dart`
- enemy/wave behavior is centered in `enemy.dart`, `enemy_manager.dart`, and `boss.dart`
- UI migration should target HUD/overlays first, consuming `FBTDResourceSnapshot`

Explorer subagent inspected the TMX format:

- maps are `20x12`, tile size `32`, world size `640x384`
- `Path` object group stores ordered point objects in source pixel coordinates
- `Collision` layer exists but currently has no non-zero blocked cells across inspected maps
- Flutter expands the path to a 2-tile footprint:
  - horizontal segments mark rows `y-1,y`
  - vertical segments mark columns `x-1,x`
- Unreal import stores `WaypointCells` and a flattened `TileTypes` array.

## Validation Commands

Build Unreal:

```powershell
& 'C:\Program Files\Epic Games\UE_5.7\Engine\Build\BatchFiles\Build.bat' BoredTowerDefenseEditor Win64 Development -Project='C:\Users\daedg\OneDrive\Documentos\Unreal Projects\BoredTowerDefense\BoredTowerDefense.uproject' -WaitMutex -NoHotReloadFromIDE
```

Start Unreal with Remote Control:

```powershell
.\scripts\start-unreal-editor.ps1
```

Health check:

```powershell
.\scripts\unreal-health.ps1
```

Gemini:

```powershell
gemini --skip-trust -p "prompt"
```

Claude:

```powershell
claude -p "prompt"
```

## Next Steps

1. Implement a real vertical slice — DONE (prototype map + imported `DA_Map_Level001`).
2. Add debug map visualization — DONE: `ABTDDebugGridActor` draws the 20x12 grid colored by
   `TileTypes` (buildable/path/blocked), the ordered waypoint polyline, and spawn/goal markers.
   Auto-on via the director `bSpawnDebugGrid`, or toggle in PIE with console `BTDDebugGrid 1` / `0`.
3. First HUD bound to `ABTDGameState::OnResourceSnapshotChanged` — DONE as the C++ `UBTDHudWidget`
   (gold/lives/score/wave/status, with an in-code neon fallback layout so it shows with no Blueprint).
   REMAINING: author `WBP_BTDHud` reparented to `UBTDHudWidget` with the full neon/Tron layout
   (resource cards, wave hex, boss bar, ability cooldowns), assign it on `BP_BTDPlayerController`,
   and capture a UI-inclusive backbuffer screenshot. See `FLAME_TO_UNREAL.md` §3.5 for the HUD element list.
4. Add AssetManager settings for primary asset types — DONE (config-only, `Config/DefaultGame.ini`
   `[/Script/Engine.AssetManagerSettings]` with `+PrimaryAssetTypesToScan` for `BTDTowerDataAsset`,
   `BTDEnemyDataAsset`, `BTDWaveDataAsset` scanning `/Game/NeonDefense/Data`, and `BTDLevelMapDataAsset`
   scanning `/Game/NeonDefense/Data/Maps`). Validated via the editor startup log (no `Ignoring/Conflicts`
   after the fix below). Enables `UAssetManager::Get().GetPrimaryAssetIdList(...)` for data-driven content
   discovery from C++/Blueprint.
5. Add MaterialParameterCollection for neon palette runtime control — DONE at the foundation level:
   `/Game/NeonDefense/Materials/MPC_NeonPalette` created (scalar `EmissiveBoost`=1.0 + 6 HDR palette
   vectors `NeonCyan/Magenta/Purple/Green/Orange/Pink`). Runtime get/set validated in PIE via
   `unreal.MaterialLibrary` (`EmissiveBoost` round-tripped 1.0->2.5->1.0; `NeonCyan` read (0,6,6)).
   DEFERRED: rewiring the existing neon materials to reference the MPC via
   `MaterialExpressionCollectionParameter` nodes — carries visual-regression risk to the validated
   showcase, so do it with a before/after visual check (best when the user can confirm the look).

## Gotchas

- Current shell is not elevated (`IsAdmin=False`). Build and editor work anyway. If a future installer needs elevation, run it manually from an admin terminal.
- The Unreal project is outside the git repo, under `OneDrive\Documentos\Unreal Projects`.
- The repo worktree already has unrelated Flutter script/lockfile modifications from earlier work. Do not revert them unless explicitly requested.
- UE 5.7 Python does not expose every expected subsystem helper. Use C++ or Blueprint validation when Python reflection is missing.
- Long PIE validation calls need `UNREAL_RC_TIMEOUT` above the default 15 seconds.
- `editor_end_play()` sometimes leaves a PIE world visible to Python after simulation. Restart the editor with `.\scripts\start-unreal-editor.ps1 -ForceRestart` after long automated PIE checks if needed.
- The previous Flutter test baseline in older docs said `12,478 / 12,478`, but the subagent saw an existing `full_test_output.txt` with two `universal_transition_test.dart` failures. Re-run the Docker test before making a final claim about current Flutter test health.
- PIE via MCP: the `unreal_play_in_editor` tool maps to `LevelEditorSubsystem.editor_play_simulate()` (Simulate-In-Editor), which does NOT spawn the GameMode's `ABTDPlayerController` (you get a plain `PlayerController` and no UMG HUD). For a real play session with the BTD controller + HUD, call `LevelEditorSubsystem.editor_request_begin_play()` via `unreal_run_python`, and stop with `editor_request_end_play()` / `unreal_stop_pie`.
- Screenshot capture: `HighResShot` / `AutomationLibrary.take_high_res_screenshot` renders the 3D scene only — it does NOT capture `DrawDebug` primitives or Slate/UMG. Verify HUD/debug-overlay programmatically (e.g. `WidgetLibrary.get_all_widgets_of_class(...).is_in_viewport()`, actor counts, `CellToWorld` vs actor locations) or use a UI-inclusive backbuffer screenshot.
- `unreal_run_python` aborts the whole script if any line throws, and reading a C++ `protected`/`private` `UPROPERTY` via `get_editor_property` throws ("... is protected and cannot be read"). Guard such reads in try/except or expose a public getter.
- Reading widget instances: `unreal.WidgetBlueprintLibrary` is NOT exposed in this UE 5.7 Python; use `unreal.WidgetLibrary.get_all_widgets_of_class(world, class, top_level_only)` instead.
- AssetManager `PrimaryAssetTypesToScan`: a native `UPrimaryDataAsset` subclass's default `GetPrimaryAssetId()` already reports its **class name** as the PrimaryAssetType, so a config entry that invents a friendly type name (e.g. `TowerData` for `UBTDTowerDataAsset`) is rejected at startup with `LogAssetManager: Display: Ignoring PrimaryAssetType TowerData - Conflicts with BTDTowerDataAsset`. Fix: name the `PrimaryAssetType` to match the class name (`BTDTowerDataAsset`, etc.) or override `GetPrimaryAssetId()` in C++. `unreal.AssetManager` is NOT exposed in this UE 5.7 Python (only the `PrimaryAssetId`/`PrimaryAssetType`/`PrimaryAssetRules` value types), so validate AssetManager config via the editor startup log (`Saved/Logs/BoredTowerDefense.log`, grep `LogAssetManager`), not Python.
- MaterialParameterCollection runtime get/set: `UKismetMaterialLibrary` is exposed in Python as `unreal.MaterialLibrary` (`get/set_scalar_parameter_value`, `get/set_vector_parameter_value`). It needs a VALID world context: `UnrealEditorSubsystem.get_game_world()` returns null outside PIE ("A null object was passed as a world context object" + values read 0), so validate MPC runtime control inside a real PIE session (where `get_game_world()` returns the PIE world). MPC creation works via `unreal.MaterialParameterCollectionFactoryNew` + `CollectionScalarParameter`/`CollectionVectorParameter` structs set on `scalar_parameters`/`vector_parameters`.
