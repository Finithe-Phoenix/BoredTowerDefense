# Architecture Map — Neon Defense → Unreal Engine 5

> Complete subsystem-by-subsystem map of the `flutter_app` codebase, written as the foundation for
> migrating the game from **Flutter + Flame (Dart)** to **Unreal Engine 5 (C++ / Blueprints)**.
> Read alongside [`DEPENDENCY_GRAPH.md`](DEPENDENCY_GRAPH.md) (the import graph) and
> [`FLAME_TO_UNREAL.md`](FLAME_TO_UNREAL.md) (the construct-by-construct migration matrix).

## 0. How this map was produced

This is not a hand-wave. It was built by a multi-tool, multi-engine pass over the real source:

1. **Static import analysis** — `flutter_app/scripts/codegraph.js` parsed all 115 Dart files → nodes,
   edges, fan-in/out, cycles (see the dependency graph).
2. **11 subsystem mapping agents (Claude)** + **1 completeness critic** read every file in their
   slice and produced structured maps + Unreal targets. The critic diffed coverage against the file
   list and flagged gaps.
3. **A dedicated agent** mapped the UI screens/overlays/transitions layer the critic identified as
   missing, closing coverage to **115/115 files**.
4. **Cross-engine validation** — findings were cross-checked with **OpenAI Codex (gpt-5.5)** and
   **Google Gemini** as independent reviewers.

**Test baseline:** the existing suite passes **12,478 / 12,478** tests (run in Docker), so the
behavior we are migrating is well-specified and regression-checkable.

## 1. What the game is

**Neon Defense** ("bored_games") — a Tron-style **tower defense** game.

- **4 tower types** (Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field), **enemy types**
  (Runner, Overloaded, Juggernaut), **10 world bosses** + mini-bosses with mechanics.
- **100 campaign levels across 10 worlds**, progressive unlock + star ratings.
- **Neon Pulse** AoE-slow ability and deployable **Neon Mines**.
- A pseudo-3D **FPS view mode** (first-person per tower with a BOOST/Overdrive).
- Heavy **neon/Tron aesthetic**: animated grids, particle systems, a fragment-shader pipeline, and a
  large amount of hand-drawn `dart:ui` Canvas art.
- Narrative layer: story chapters, a lore **codex**, **chronicles**, and **cinematics**.

## 2. Runtime architecture (the shape you must preserve)

```
main.dart  (MaterialApp + SettingsCubit + string-route table → TronPageRoute transitions)
   │
   ▼
Flutter Navigator screens  (menu, levels, settings, story, codex, upgrades, benchmark, loading…)
   │  (LoadingScreen bootstraps services in order)
   ▼
GameScreen  ──hosts──►  GameWidget ──►  BoredGamesGame  (FlameGame "god object", fan-out 43)
   │  owns lifecycle,                         │  owns gold/lives/score/wave, input, coord transform,
   │  overlay routing,                        │  quality scaling, abilities, focus/FPS mode
   │  settings→game,                          │
   │  progress save                           ├── managers/ (enemy, tower, bullet)
   │                                          ├── entities/ (enemy, tower, boss, projectile)
   ▼                                          ├── effects/  (particles, shaders, visual director)
Flutter overlays (pause/victory/gameOver/     ├── hud/      (Flame-canvas in-game UI)
   briefing/runUpgrade) via overlayBuilderMap ├── fps/      (pseudo-3D view)
                                              └── world/components/ (tilemap grid, neon grid, mines)
   services (singletons): Audio, AmbientSoundscape, ProceduralMusic, Level, Storage, Upgrade, SpriteCache
   state:  SettingsCubit (live)   ·   GameBloc (DORMANT — see §4.3)
```

Two structural facts dominate the migration (both proven by the import graph):

- **`BoredGamesGame` is a 2,441-line god object** that wires together every manager, HUD element,
  effect, shader and service, and is the runtime source of truth for gameplay state.
- **A 37-node `HasGameRef` import cycle** binds nearly all of `src/game/*` together: every Flame
  `Component` reaches the root via `game.<x>` and the root holds references back. There is **no clean
  dependency order** to port these one at a time — see §4.1.

## 3. Subsystem map

Each subsystem below lists its **role**, **key types**, **state owned**, **dependencies**, the
**Flame/Flutter APIs** it leans on, and its **Unreal target** (constructs · strategy · complexity).
Strategy legend: `reuse-port` (translate ~1:1) · `rewrite` (same behavior, new design) · `redesign`
(rethink for Unreal) · `engine-native` (Unreal provides it).

---

### 3.1 `core-world` — game loop, world, balance, on-grid components
*10 files · strategy: **redesign** · complexity: **very-high***

**Role.** The runtime core: app entry/router (`main.dart`), the `BoredGamesGame` FlameGame root, the
Tiled-map `GameWorld` (buildable/path/blocked grids + waypoints + a massive custom-painter renderer),
the pure-math `DifficultyCurve`, grid/path utilities, and self-contained on-grid components (neon
grid backdrop, reflective floor, deployable mine, neon pulse field).

**Key types.**

| Type | Kind | Responsibility |
|---|---|---|
| `BoredGamesGame` | `FlameGame with TapCallbacks, DragCallbacks, KeyboardEvents` | Root loop; owns managers/HUD/effects/services, gold/lives/score, input, coord transform, quality, abilities, focus/FPS mode, event dispatch |
| `PerspectiveWorldRoot` | `PositionComponent, HasGameRef` | Applies a `Matrix4` 3D perspective tilt when focus/FPS mode is active |
| `GameWorld` | `Component` | Loads `.tmx` (flame_tiled), derives waypoints + tile types + buildable mask + start/end cells |
| `_WorldRenderer` | `PositionComponent` | Procedurally paints the whole cyberpunk map each frame (tiles, circuit traces, hex overlay, energy veins, spawn/core), `ui.Picture` cached |
| `DifficultyCurve` | static util | Pure tuning math: HP/speed/count/spawn/gold scaling, tower-cost inflation, wave bonus (`levelsPerWorld=10`) |
| `NeonGridComponent`, `ReflectiveFloorComponent` | `PositionComponent` | Animated Tron backdrop + reflective floor illusion (heavy cached painting) |
| `NeonMine` (`MineState`), `NeonPulse` (`_PulsePhase`) | `PositionComponent` | Proximity mine FSM + AoE; expanding slow-field ability |
| `PendingAbility` | enum | Which ability awaits a target tap |

**State owned.** gold, lives, score, wave, timeScale, quality level, world bounds, pending ability,
focus/FPS flags, the entire scene graph.

**Depends on.** `effects`, `hud`, `components`, `services` (audio/level), `models`. **Depended on by**
basically everything in `src/game/*` (it is the cycle hub).

**Flame/Flutter APIs.** `FlameGame`, `Component`/`PositionComponent`, `HasGameRef`, input mixins,
`Canvas`/`Picture`, `Matrix4`, `flame_tiled`.

**→ Unreal target.** `AGameModeBase` (rules, win/lose, wave orchestration) · `AGameStateBase`+`APlayerState`
(queryable gold/lives/score/wave) · `APlayerController` + **Enhanced Input** (tap/drag/key → place/sell/
ability/focus) · `DifficultyCurve` → `UBlueprintFunctionLibrary`/curve `UDataAsset` · grid →
`UDataAsset` + a `.tmx` importer · path → `USplineComponent` (+ NavMesh optionally) · mine/pulse →
`AActor` + `UNiagaraComponent` · grid/floor/perspective → `UMaterial`/`UMaterialParameterCollection` +
post-process · quality → `UGameUserSettings`/Scalability + `USaveGame`. **This is the central
refactor: decompose the god object instead of porting it 1:1.**

---

### 3.2 `entities-combat` — enemies, towers, bosses, projectiles + managers
*7 files · strategy: **rewrite** · complexity: **very-high***

**Role.** The combat simulation: enemy/tower/boss/projectile entities and the enemy/tower/bullet
managers that spawn, target, move, and apply damage.

**Key types.** `Enemy` (`EnemyType`), `Boss` (`BossType`, `BossMechanicState`), `Tower`
(`TowerType`, `TargetMode`), `Projectile`, `EnemyManager` (`WaveModifier`), `TowerManager`,
`BulletManager`.

**State owned.** Live entity lists, wave composition + modifiers, per-tower cooldowns/targets,
projectile pool, per-enemy HP/status (slow/burn/shield/boost/stun).

**Depends on.** `core-world` (game ref), `effects`, `services`, `models`. `enemy.dart` has fan-in 23,
`tower.dart` 12 — base types touched everywhere.

**Flame/Flutter APIs.** `PositionComponent`, `SpriteComponent`, effects/timers, `Canvas` drawing,
`Vector2` math.

**→ Unreal target.** Entities → `AActor` (or, if enemy counts are large, a **struct-in-array /
`UActorComponent` lightweight simulation** for performance) · managers → `UWorldSubsystem` or
GameMode/GameState · stats → `UDataAsset`/`UDataTable` (per enemy/tower/boss type) · damage & statuses
(slow/burn/shield/boost/stun) and tower fire → **GAS** `UGameplayAbility` + `UGameplayEffect` +
`UAttributeSet` · VFX → Niagara · neon look → `UMaterialInstanceDynamic` (emissive + Fresnel) · fixed
path → `USplineComponent` · **object pooling** for projectiles/enemies.

---

### 3.3 `effects-particles` — particle systems, screen FX, visual director
*22 files · strategy: **redesign** · complexity: **very-high***

**Role.** All non-shader VFX: particle emitters, explosions, impacts, damage numbers, floating text,
auroras, galaxies, pixel-disintegration, reality tears, boss entrances, environmental particles,
energy barriers, plus the `VisualDirector` orchestrator and `ScreenEffects`.

**Key types.** `VisualDirector`, `ScreenEffects`, `GameParticles`, `ParticleEmitter`/`Particle`,
`ExplosionEffect`, `ImpactEffect`, `DamageNumberEffect`, `FloatingText`, `GalaxyEffect`,
`PixelDisintegrationEffect`, `PowerUpCollectEffect`, `GroundCrackEffect`, `TowerDestructionEffect`,
`RealityTearEffect`, `BossEntranceEffect`, `AuroraEffect`, `EnvironmentalParticles`,
`EnergyBarrierEffect`, `ReflectiveFloor`, `FocusModeOverlay`, `GameResultOverlay`, `TutorialGuide`.

**→ Unreal target.** Particle effects → **Niagara** (`UNiagaraSystem`/`UNiagaraComponent`) · procedural
looks (auroras, energy walls, portals) → Niagara scratch / Materials · screen FX (CRT, vignette,
scanlines, chromatic aberration, lens flare) → post-process `UMaterial` · `VisualDirector` →
`UGameInstanceSubsystem`/`AActor` "VFX director" · shake/big-hit → `UCameraShakeBase` + trauma curve ·
damage numbers/floating text/result/tutorial → **UMG** · type→VFX mapping → `UDataAsset`/`UDataTable`.
**Re-author, do not port** — this is immediate-mode Canvas art.

---

### 3.4 `effects-shaders` — the fragment-shader pipeline
*12 files · strategy: **redesign** · complexity: **medium***

**Role.** Manages `.frag` shaders (in `assets/shaders/`): a world "uber" shader, particle-trail
shader, and a master post-process shader, plus uniform control, presets, and noise/flag packing.

**Key types.** `ShaderManager`, `ShaderDescriptor`, `ShaderAsset`, `WorldUberShaderComponent`,
`ParticleShaderComponent`, `ScreenPostProcessComponent`, `ShaderUniformController`, `NoiseTexture`,
`ShaderPresetConfig`, `ShaderPreset`, `FlagPacker`.

**→ Unreal target.** `UMaterial`/`UMaterialInstanceDynamic` · post-process domain material on a
`UPostProcessComponent`/volume · surface material or decal for the world backdrop · Niagara for
particle trails · presets/tunables → `UDataAsset`/curve/`UMaterialParameterCollection` · global
params (time/wave/trauma/pointer) pushed via a `UWorldSubsystem`. The GLSL→HLSL/material-graph port is
mechanical and bounded → only **medium** complexity.

---

### 3.5 `hud` — in-game UI drawn inside Flame
*9 files · strategy: **redesign** · complexity: **very-high***

**Role.** The in-battle HUD rendered as Flame components: resource/wave bar, boss health bar,
countdown timer, battle dialogue, event feed, kill-combo, minimap, ability buttons.

**Key types.** `HudComponent`, `HudButton`, `BossHealthBar`, `CountdownTimerComponent`,
`BattleDialogueComponent`, `GameEventFeed`, `KillComboDisplay`, `MinimapComponent`, `GameEventType`.

**→ Unreal target.** **UMG** `UUserWidget` per element · root assembled on `AHUD`/`APlayerController` ·
minimap via `SceneCapture2D` render-target or projected canvas markers · boss/wave/dialogue data →
`UDataAsset`/`UDataTable` · neon glow/CRT/glitch → UI-domain `UMaterial` + Retainer Box · a UMG
**view-model** (MVVM plugin or a snapshot `UObject`) bound to GameState and pushed on change (replaces
reading the god object directly).

---

### 3.6 `fps` — pseudo-3D first-person tower view
*5 files · strategy: **redesign** · complexity: **high***

**Role.** Simulates a first-person camera per tower inside the 2D engine: a hand-rolled 3D camera,
ray math, billboard reprojection of enemies/towers, a starfield/data background, and a timed BOOST/
Overdrive.

**Key types.** `Vector3`, `Ray`, `Camera3D`, `FpsViewComponent`, `Enemy3D` (`Enemy3DShape`),
`Tower3D`, `FpsBackgroundComponent`, particle/star helpers.

**→ Unreal target.** This is where Unreal **wins for free**: `APlayerCameraManager`/`ACameraActor` (or
a possessed camera Pawn) · `APlayerController` custom input mode + `InputMappingContext` · a
GameState/subsystem flag for FocusMode (replaces the manual 10s timer) · existing tower/enemy
`AActor`s rendered **natively as meshes — no billboard reprojection needed** · UMG cockpit HUD ·
Niagara for boost/muzzle · post-process material for CRT/glitch/vignette · per-tower weapon-viewmodel
mesh (DataTable `TowerType→mesh/FX`) · GAS for the Overdrive ability. **Delete the hand-rolled 3D
math entirely.**

---

### 3.7 `state-bloc` — Bloc/Cubit state management
*5 files · strategy: **rewrite** · complexity: **medium***

**Role.** `SettingsCubit`/`SettingsState` (live: volumes, FPS display, graphics quality, particle
intensity, screen shake) and `GameBloc` with a full event/state set (`GameStarted`, `GoldChanged`,
`LivesChanged`, `WaveStarted`, `EnemyKilled`, `TowerPlaced`, `GameOver`, `Victory`, …).

> ⚠️ **`GameBloc` is dormant.** The runtime source of truth for gameplay state is `BoredGamesGame`
> (imperative `gold`/`lives`/`score`), which `game_screen.dart` reads directly and persists. See §4.3.

**→ Unreal target.** `AGameStateBase` (per-match gold/lives/score/wave/status, replicable) ·
`AGameModeBase` (authoritative rules: wave bonuses, victory/defeat, affordability/spend) ·
`UGameInstanceSubsystem` (settings store across levels) · `USaveGame` via
`UGameplayStatics::SaveGameToSlot` (replaces SharedPreferences) · default tuning → `UPrimaryDataAsset`
· optionally GAS `UAttributeSet` for gold/lives/score · UMG dynamic-multicast delegates replace
`BlocBuilder`. **Use `GameBloc` as a design reference for the event vocabulary, not as code to port.**

---

### 3.8 `services` — audio, persistence, levels, upgrades, sprites
*7 files · strategy: **redesign** · complexity: **very-high***

**Role.** Cross-cutting singletons: `AudioService` (fan-in 12), `AmbientSoundscapeService`,
`ProceduralMusicService` (real-time-ish synthesis with leitmotifs/sections), `LevelService` (fan-in 8,
the 100-level catalog + progress), `StorageService` (shared_preferences), `UpgradeService` (meta + run
upgrades), `SpriteCacheService`.

**Key types.** `AudioService` (`WaveType`, `_SfxLayer`), `AmbientSoundscapeService`,
`ProceduralMusicService` (`WorldSoundTheme`, melody/section types), `LevelService`, `StorageService`,
`UpgradeService` (`UpgradeDefinition`/`RunUpgradeDefinition`/`UpgradeStats`), `LevelConfig`/
`LevelProgress`, `SpriteCacheService`.

**→ Unreal target.** One `UGameInstanceSubsystem` per service (Audio, Level, Upgrade) ·
`USaveGame` replaces StorageService/shared_preferences · catalogs → `UPrimaryDataAsset`/`UDataTable` ·
SFX/music → **MetaSounds** (drop the hand-written DSP, but keep adaptive behavior: battle intensity,
leitmotifs, ducking) · spatialization/throttling → `USoundConcurrency` + attenuation · volume/profile/
ducking mix → Control Bus / SoundMix / Audio Modulation · **drop `SpriteCacheService`** (Niagara +
materials make it unnecessary).

---

### 3.9 `models-data` — data models + static narrative content
*5 files · strategy: **rewrite** · complexity: **medium***

**Role.** Pure data: `LevelConfig`/`LevelProgress`, `QualityLevel`, `UpgradeStats`/`UpgradeDefinition`/
`RunUpgradeDefinition`, and the narrative corpus (`StoryData`, `WorldChronicles`, characters,
briefings, lore entries, cinematic data — ~2,600 lines of prose).

**→ Unreal target.** `UPrimaryDataAsset` (level configs, upgrade defs, chronicles) · `UStruct`
(`FTableRowBase` rows: `FUpgradeStats`, `FLevelProgress`, `FDialogueLine`, `FCinematicLine`) ·
`UDataTable` (level catalog, briefings-by-level, lore, codex, run upgrades) · `UEnum` (quality,
moods, lore categories, cinematic visuals) · `USaveGame` for progress · **`FText` + String Tables**
for every piece of narrative text (localization). Lowest-risk subsystem; do it **first** so towers/
enemies/levels become data-driven early.

---

### 3.10 `ui-widgets-theme` — reusable neon widgets + the central theme
*19 files · strategy: **redesign** · complexity: **very-high***

**Role.** The reusable neon UI library (buttons, titles, dialogs, glitch text, animated Tron grids,
loading spinner, the `UniverseGraphWidget` galaxy graph, a world-art generator) and the central
`neon_theme.dart` — **the single most depended-upon file in the codebase (fan-in 42)**.

**Key types.** `NeonColors`/`NeonTheme`/`NeonTextStyles`/`NeonAnimations`/`NeonEffects`, `NeonButton`,
`TronButton`, `EpicNeonButton`, `EpicNeonTitle`, `NeonTitle`, `GlitchText`, `EpicDialog`, `TronDialog`,
`EpicLoadingSpinner`, `TronCard`, `UniverseGraphWidget`, `AnimatedTronGrid`, `CyberGridBackground`,
`MaterializationOverlay`, `TronMaterializationWidget` (`TronPattern`), `WorldArtGenerator`.

**→ Unreal target.** **UMG** `UUserWidget` per widget + a reusable Widget-Blueprint palette · design
tokens (`neon_theme`) → a `UDataAsset` design-token asset + a `USlateWidgetStyle` set (port this
**first** — fan-in 42) · glow/scanlines/glitch/gradients → UI-domain `UMaterial`/`MID` · animations →
`UWidgetAnimation` · buttons/dialogs/menus → **Common UI** (`UCommonButtonBase`) · galaxy graph →
custom Slate `FPaintContext` widget · transition/theme provider → `UGameInstanceSubsystem`.

---

### 3.11 `ui-screens-overlays` — Navigator screens, overlays, transitions
*18 files · strategy: **redesign** · complexity: **high–very-high***

**Role.** The user-facing flow: 11 screens (`main_menu`, `level_select`, `game_screen`, `settings`,
`story`, `upgrades`, `benchmark`, `codex`, `loading`, `cinematic`, `chronicle_reader`), 6 overlays
(`pause`, `victory`, `game_over`, `briefing`, `run_upgrade`, `game_result`), and `tron_page_route`
transitions. **~18,000 LOC**, ~60 custom painters.

**Load-bearing files (priority-1 for migration):**
- **`game_screen.dart`** — *the game-session host.* Creates/configures/destroys `BoredGamesGame`,
  registers the Flame `overlayBuilderMap` (pause/gameOver/victory/upgrade), routes Esc→pause, applies
  `SettingsCubit` changes to the live game via `BlocListener`, persists progress via
  `LevelService.updateProgress` on victory/gameOver, and drives audio lifecycle. *This is the seam
  between the documented Flame world and the Flutter UI.*
- **`loading_screen.dart`** — *the service bootstrap orchestrator.* Initializes services in order:
  `StorageService → LevelService → AudioService → ProceduralMusicService → SpriteCacheService`.

**→ Unreal target.** **The containment relationship inverts:** in Flutter a screen hosts the game; in
Unreal the **game world is primary** and UI is a HUD over the viewport. Screens → **Common UI**
`UCommonActivatableWidget` stacks · overlays → UMG push/pop driven by GameMode/PlayerController ·
`game_screen`'s responsibilities → split across `AGameMode` (rules/spawn) + `AGameStateBase`
(authoritative state) + `APlayerController` (input/UMG) + a GameInstance-subsystem bootstrap
(replacing `loading_screen._initializeServices`) · `TronPageRoute` materialization → UMG widget
animations + UI material (don't use level transitions) · animated-CustomPainter chrome → UI materials/
Niagara.

## 4. Cross-cutting concerns (the migration traps)

These span subsystems and are where naive ports fail. Surfaced by the completeness critic.

### 4.1 The 37-node `HasGameRef` cycle — break it by design
Nearly all of `src/game/*` + `audio_service` + `level_service` form one strongly-connected component
because Flame components hold `game.<x>` back-references and the root holds child references. **You
cannot port these in dependency order.** In Unreal, replace back-pointers with `GetWorld()`/
`GetGameMode()`/`GetSubsystem<>()` lookups and a `GameplayMessageSubsystem` (events), so actors never
hard-reference a god object. Treat the whole SCC as **one milestone** ("the battle simulation").
The smaller `level_select_screen ⇄ universe_graph_widget` cycle is broken with a delegate.

### 4.2 The game-session lifecycle seam (`game_screen`)
The owner of the entire Flame game is a *screen*. Migration must explicitly assign that ownership:
**who creates/destroys the session, how end-of-level triggers save + overlay + audio change.** Map it
onto `AGameMode` (create/spawn) + `AGameState` (read authoritative gold/lives/score/wave via getters,
**not** by reaching into managers) + `APlayerController` (UMG) + GameInstance bootstrap.

### 4.3 Single source of truth — drop dormant `GameBloc`
`GameBloc` exists but is unwired; `BoredGamesGame` is the imperative authority. **Pick `AGameStateBase`
as the one authority** and do not port `GameBloc` 1:1 (use it only as the event vocabulary reference).

### 4.4 Two `game_result_overlay.dart` (naming collision)
There are **two** files named `game_result_overlay.dart` — one Flame effect
(`src/game/effects/`), one Flutter overlay (`src/ui/overlays/`). Determine which is live and reconcile
before building the UMG end-of-level screen, or you will port dead code.

### 4.5 Service init order & audio lifetime
Bootstrap order (`Storage → Level → Audio → ProceduralMusic → SpriteCache`) and per-level audio
resource management (temp WAVs, pool refresh, `reset()` on dispose, the "refresh every 5 sessions"
hack) are split between `services` and the `loading_screen`/`game_screen`. Map to **GameInstance
subsystem init ordering** + an audio subsystem lifetime; getting it wrong causes silent audio failures
or leaks.

### 4.6 Theme coupling (`neon_theme.dart`, fan-in 42)
Consumed by **both** the Flutter screens **and** in-game Flame render code. The migration must split
it into a **UI design-token DataAsset** (for UMG) **and** in-game **material parameters** (for the
world), serving both consumer sets. Port it early.

### 4.7 Save/load write-site census
`shared_preferences` keys (`level_progress_<id>`, `unlocked_levels`, `meta_currency`,
`upgrade_levels`) are written from services **and** screens/overlays (level unlock, upgrade spend,
progress save). Enumerate **every** write site to design the `USaveGame` schema + importer.

### 4.8 The 152 `.instance` singleton call-sites
Service singletons are reached via `.instance` from ~152 sites across entities, managers, **and**
screens. A mechanical pass must redirect these to `GetGameInstance()->GetSubsystem<>()`.

### 4.9 Narrative / localization
~2,600 lines of hardcoded ES/EN prose in `models-data`, **rendered** by 4 large screens (story, codex,
chronicle, cinematic). Localization migration must cover **both** the data and the presenters →
`FText`/String Tables.

### 4.10 Cost reality: the dominant effort is art, not logic
The biggest line-count subsystems (`effects-particles`, `entities` visuals, `hud`, `ui-widgets`, `fps`)
are bespoke `dart:ui` immediate-mode drawing. **All map to re-authoring in Materials/Niagara/UMG, not
code translation.** LOC overstates logic and understates tech-art effort. Budget accordingly.

## 5. Coverage ledger

| Source files (`lib/`) | Mapped |
|---|---|
| 115 | **115 (100%)** — 10 subsystem maps + the screens/overlays/transitions map |

Module file counts and the full import graph are in [`DEPENDENCY_GRAPH.md`](DEPENDENCY_GRAPH.md).
The machine-readable subsystem digest is at `scripts/.codegraph/graph.json` (graph) and
`docs/migration/.tmp/maps-digest.json` (subsystem maps).

## 6. Suggested milestone order

1. **Skeleton** — UE5 project, modules, `AGameMode`/`AGameState`/`APlayerController`, GameInstance +
   service subsystems, the theme DataAsset, and a `GameplayMessageSubsystem` (so the cycle never forms).
2. **Data-driven content** (`models-data`) — towers/enemies/levels/upgrades as DataAssets/DataTables;
   narrative into String Tables.
3. **Battle simulation** (the whole SCC) — entities + managers + combat via GAS, on a spline path.
4. **VFX & shaders** — Niagara + Materials (the long tail).
5. **HUD & UI** — UMG/Common UI; invert the game-session host into GameMode + HUD.
6. **FPS mode** — native camera/meshes; delete the pseudo-3D math.
7. **Audio** — MetaSounds + adaptive music subsystem.

---

*Cross-checked with Codex (gpt-5.5) and Gemini. Regenerate the graph with
`node flutter_app/scripts/codegraph.js`; re-map with the `code-map` skill.*
