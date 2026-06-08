# Flame → Unreal Engine 5 — Migration Matrix

> Construct-by-construct mapping from **Flutter + Flame (Dart)** to **Unreal Engine 5 (C++/Blueprints)**
> for **Neon Defense** ("bored_games"). This is the *how-to-translate* companion to
> [`ARCHITECTURE_MAP.md`](ARCHITECTURE_MAP.md) (the 11-subsystem map + cross-cutting concerns) and
> [`DEPENDENCY_GRAPH.md`](DEPENDENCY_GRAPH.md) (the import graph, the 37-node `HasGameRef` SCC, the
> UI 2-node cycle, and the external-package list). Read those first — this document assumes their
> findings and cites their real type/file names.

## 0. How to read this document

Every row carries a **strategy** tag. The legend is the same as the architecture map:

| Tag | Meaning |
|---|---|
| **reuse-port** | Translate ~1:1. Pure logic/data; Dart → C++ is mechanical. Lowest risk. |
| **rewrite** | Same observable behavior, new design. The Flame code is a *spec*, not a template. |
| **redesign** | Rethink the whole approach for Unreal. Usually immediate-mode art or a god-object seam. |
| **engine-native** | Unreal already provides it; delete the hand-rolled Dart entirely. |

**Complexity** is `low / medium / high / very-high` and tracks effort + regression risk, **not** lines
of code. Per cross-cutting concern §4.10, line count *overstates* logic effort and *understates*
tech-art effort: the largest subsystems (`effects-particles`, `hud`, `ui-widgets`, `fps`, entity
visuals) are bespoke `dart:ui` immediate-mode drawing and become Niagara/Materials/UMG re-authoring,
not code translation.

### How the two independent reviews shaped this doc

Both **Codex (gpt-5.5)** and **Gemini (gemini-3.1-pro-preview)** reviewed the plan. Where they
**agree**, the guidance below is stated as settled. Where they **conflict**, the row flags it
explicitly and gives a decision rule:

- **GAS adoption (the main conflict).** Codex endorses GAS scaffolding for combat (slow/burn/shield/
  boost/stun, tower fire, Overdrive, mines, pulse). Gemini calls full GAS *over-engineering* for a
  single-player TD and prefers plain `UActorComponent` health/status + native `AActor::TakeDamage`.
  **Decision rule in this doc:** GAS is the *recommended default* because the status-effect matrix
  (stacking/duration/periodic) is exactly GAS's sweet spot and keeps tuning data-driven; but every GAS
  row notes the **plain-component fallback** so the team can downgrade if GAS boilerplate outweighs the
  benefit. There is no multiplayer requirement, so prediction/replication features of GAS are not a
  reason on their own.
- **Entity representation (the second conflict, both reviewers raised it).** The architecture map
  already hedges (`AActor` *or* lightweight struct-in-array). Gemini is emphatic that `AActor`-per-
  projectile/enemy will bottleneck the GameThread at TD densities and pushes `InstancedStaticMeshComponent`
  + a `UWorldSubsystem` struct-array sim, escalating to **MassEntity (ECS)** for large counts. Codex
  concurs ("Mass/struct-array simulation when entity counts are high"). **Decision rule:** author
  *gameplay-significant, low-count* actors (towers, bosses) as `AActor`; simulate *high-count, short-lived*
  entities (projectiles, swarm enemies) as structs in a `UWorldSubsystem` rendered via ISMC, with a
  MassEntity escape hatch. Profile before committing to either.
- **Other corrections folded in below** (both reviewers, non-conflicting): screens → Common UI, **not**
  levels; `CustomPainter`/Canvas is **not** Slate 1:1; the floor grid is a world-space material on a
  mesh, **not** post-process; `SpriteCacheService` → `UAssetManager` async streaming, **not** simply
  deleted; native `UCurveFloat`/`UCurveTable` for tuning curves; coordinate-space transform (Flutter
  Y-down top-left vs Unreal Z-up center) needs one central library; save migration needs a Flutter-side
  JSON export + UE deserializer for existing players; `USplineComponent` only if there is **no** tower
  "mazing".

---

## 1. Concept mapping table (Flame/Flutter → Unreal)

One row per recurring construct. "Where it lives today" cites real files/types from the map.

| # | Flame / Flutter construct (where it lives today) | Unreal equivalent | Strategy | Notes / reviewer corrections |
|---|---|---|---|---|
| 1 | `FlameGame` root — `BoredGamesGame` (`bored_games_game.dart`, fan-out 43, 2,441 LOC) | **Split**: `AGameModeBase` (rules/spawn/win-lose) + `AGameStateBase` (gold/lives/score/wave) + `APlayerController` (input/UMG) + `UGameInstanceSubsystem`/`UWorldSubsystem` (services) | redesign | **Do NOT make one mega `AGameModeBase`** (both reviewers). Decompose the god object; see §6. |
| 2 | `Component` / `PositionComponent` (+ `HasGameRef`) | `AActor` (placed/positioned) or `UActorComponent` (behavior on an actor); high-count entities → struct in `UWorldSubsystem` + ISMC | rewrite | `HasGameRef` is the cycle source — see row 4 and §6. |
| 3 | `HasGameRef<BoredGamesGame>` back-reference (`game.<x>`) | `GetWorld()` / `GetWorld()->GetAuthGameMode()` / `GetGameState()` / `GetGameInstance()->GetSubsystem<>()` + **`UGameplayMessageSubsystem`** for events | redesign | **Never a hard root pointer.** This is *the* cycle-breaker (both reviewers, §4.1, §6). |
| 4 | The 37-node `HasGameRef` SCC (`bored_games_game ⇄ entities ⇄ managers ⇄ effects ⇄ hud ⇄ fps ⇄ components ⇄ services{audio,level}`) | One milestone: skeleton (GameMode/State/Subsystems + message bus) **first**, then port the simulation against it | redesign | No clean port order. Treat as **one** milestone "the battle simulation" (§6). |
| 5 | `SpriteComponent` (sprites) | `UStaticMeshComponent` / `UPaperSpriteComponent` / `UPaperFlipbookComponent`; instanced → `UInstancedStaticMeshComponent` | redesign | Gemini: keep the hand-drawn neon look in FPS/3D via `UPaperSpriteComponent` or camera-facing billboard materials — do **not** force native meshes everywhere. |
| 6 | `CustomPainter` / `dart:ui` `Canvas` / `ui.Picture` (~60 painters across UI; `_WorldRenderer`, neon-grid, HUD) | **Re-author**: UMG `UImage` + UI-domain `UMaterial`/`MID`, Niagara, meshes, or post-process | redesign | **NOT Slate 1:1** (both reviewers). The dominant cost (§4.10). Some chrome → custom Slate `FPaintContext` only where genuinely vector (e.g. `UniverseGraphWidget`). |
| 7 | Fragment shaders `.frag` (`assets/shaders/`: world uber, particle-trail, master post-process) | `UMaterial`/`MID` (surface), post-process-domain `UMaterial` on `UPostProcessComponent`/volume, Niagara for trails | redesign (medium) | GLSL→material-graph/HLSL is mechanical → **medium** complexity. Global uniforms → `UMaterialParameterCollection` pushed by a `UWorldSubsystem`. |
| 8 | `flutter_bloc` — `SettingsCubit`/`SettingsState` (live) | `UGameInstanceSubsystem` (settings store) + UMG **MVVM**/dynamic-multicast delegates replace `BlocBuilder`; persist via `USaveGame` | rewrite | See subsystem §3.7. |
| 9 | `flutter_bloc` — `GameBloc` (**DORMANT**, §4.3) | `AGameStateBase` is the single authority; reuse `GameBloc`'s events (`GoldChanged`, `WaveStarted`, `EnemyKilled`, …) **only as event vocabulary** | rewrite | **Do NOT port `GameBloc` as runtime authority** (both reviewers). |
| 10 | `shared_preferences` (`StorageService`; keys `level_progress_<id>`, `unlocked_levels`, `meta_currency`, `upgrade_levels`) | `USaveGame` via `UGameplayStatics::SaveGameToSlot/LoadGameFromSlot` | redesign | **Census every write site first** (§4.7). Add a Flutter→JSON export + UE boot deserializer to migrate existing players (both reviewers). |
| 11 | `audioplayers` / `flame_audio` (`AudioService` fan-in 12) | **MetaSounds** + `UAudioComponent`; mix via Audio Modulation / Control Bus / SoundMix; throttle via `USoundConcurrency` + attenuation | redesign | Drop hand-written DSP; **keep** adaptive behavior (intensity/leitmotif/ducking). §3.8. |
| 12 | `ProceduralMusicService` (real-time synth, leitmotifs, sections, `WorldSoundTheme`) | MetaSounds adaptive stem-mixing + intensity states in a GameInstance audio subsystem | redesign (very-high) | Gemini: prototype adaptive stems/leitmotifs in MetaSounds in **Milestone 1** before committing — it will not port 1:1. |
| 13 | `flame_tiled` `.tmx` load (`GameWorld`: buildable/path/blocked grids, waypoints, start/end cells) | A `.tmx`→`UDataAsset`/`UDataTable` importer (grid masks + waypoints) | rewrite | TMX/grid/path fidelity is gameplay-load-bearing, not visual (Codex). |
| 14 | Fixed enemy path (waypoints in `GameWorld`) | `USplineComponent` (+ `UPathFollowingComponent`) **only if no mazing**; otherwise **grid A\*** over the buildable mask | rewrite | **Gemini conflict flag:** verify whether towers can block/alter the path ("mazing"). If yes, splines fail → A* + grid waypoints required. Confirm before committing. |
| 15 | `Navigator` + `MaterialPageRoute` + string-route table (`main.dart`) | **Common UI** `UCommonActivatableWidget` stacks pushed/popped by GameMode/PlayerController | redesign | **Screens are NOT UE levels** (both reviewers). The whole game runs in one (or few) persistent levels; "screens" are widget stacks. |
| 16 | `TronPageRoute` transitions (`ui/transitions`, materialization) | `UWidgetAnimation` + UI-domain transition `UMaterial` (dissolve/scanline) | redesign | Not level travel; a widget animation. §3.11. |
| 17 | `AnimationController` / implicit animations (UMG widgets, glitch text, spinners) | `UWidgetAnimation` (Sequencer-authored) or UMG `Timeline`/tick-driven `MID` params | redesign | High-frequency tiny UI animations → drive `MID` scalar params, not heavy Sequencer. |
| 18 | `Vector2` (Flame) | `FVector2D` (UI/grid math) / `FVector` (world) | reuse-port | Y is **down** in Flutter; see row 19. |
| 19 | Coordinate transform (god object owns Flutter screen↔grid mapping; FPS `Vector3`) | **One central C++ grid↔world transform library** (`UBlueprintFunctionLibrary` / static), Flutter Y-down top-left → Unreal Z-up center | rewrite | Both reviewers raised this as an underestimated risk. Centralize once; never scatter ad-hoc math. |
| 20 | `Matrix4` perspective tilt (`PerspectiveWorldRoot`) | Real `ACameraActor`/`APlayerCameraManager` perspective; delete the manual matrix | engine-native | §3.6 — Unreal does 3D for free. |
| 21 | `DifficultyCurve` (pure tuning math) | `UBlueprintFunctionLibrary` for formulae **+ native `UCurveFloat`/`UCurveTable`** for tunable curves | reuse-port | **Gemini correction:** use native curve assets (built-in editor + C++ eval), not a bespoke curve `UDataAsset`. |
| 22 | Service singletons reached via `.instance` (~152 call-sites, §4.8) | `GetGameInstance()->GetSubsystem<U…Subsystem>()` (Audio/Level/Upgrade) or `GetWorld()->GetSubsystem<>()` | rewrite | Mechanical redirect pass; do it after subsystems exist. |
| 23 | `SpriteCacheService` | **`UAssetManager`** async streaming + Primary Asset Labels (pre-load boss/world assets per level) | redesign | **Gemini correction:** do NOT just drop it. A 100-level game needs async streaming to avoid hitching. (Map said "drop"; reviewer overrides.) |
| 24 | `equatable` value equality (`models`) | C++ `operator==` on `USTRUCT` | reuse-port | Trivial. |
| 25 | `path_provider` | `FPaths` + SaveGame slots | engine-native | — |
| 26 | Hardcoded ES/EN prose (~2,600 lines in `models-data`, rendered by story/codex/chronicle/cinematic screens, §4.9) | **`FText` + String Tables** (CSV-backed); migrate both data **and** presenters | rewrite | Localization must cover data *and* the 4 large presenter screens. |
| 27 | `neon_theme.dart` (fan-in 42, §4.6 — consumed by UI **and** in-game render) | **Split**: a UI design-token `UDataAsset` + `USlateWidgetStyle` set **AND** world `UMaterialParameterCollection` params | redesign | **Single most depended-upon file. Port FIRST.** One asset cannot serve both consumer sets (both reviewers). |
| 28 | `GameWidget` host inside a Flutter screen (`game_screen.dart`, fan-out 14) | Inverts: world owns the viewport, UMG is a HUD overlay; responsibilities split across GameMode/State/Controller + GameInstance bootstrap | redesign | The lifecycle seam (§4.2, §6). |

---

## 2. Per-subsystem migration matrix

One row per the 11 subsystems from the architecture map. Targets, strategy, complexity and key risks
are pulled from §3 of the map and refined by the reviews.

| # | Subsystem (files · map strategy) | Target Unreal constructs | Strategy | Complexity | Key risks (reviewer-flagged) |
|---|---|---|---|---|---|
| 3.1 | **core-world** (10 · redesign) — `BoredGamesGame`, `GameWorld`, `_WorldRenderer`, `DifficultyCurve`, `NeonGridComponent`, `ReflectiveFloorComponent`, `NeonMine`, `NeonPulse`, `PerspectiveWorldRoot` | `AGameModeBase` (rules/wave orchestration) · `AGameStateBase`+`APlayerState` (gold/lives/score/wave) · `APlayerController`+**Enhanced Input** (place/sell/ability/focus) · `DifficultyCurve`→`UBlueprintFunctionLibrary`+`UCurveFloat`/`UCurveTable` · grid→`UDataAsset`+`.tmx` importer · path→`USplineComponent` **or** grid A\* · mine/pulse→`AActor`+`UNiagaraComponent` · grid/floor→**world-space `UMaterial` on a mesh plane** (+MPC); post-process **only** for screen FX · quality→`UGameUserSettings`/Scalability+`USaveGame` | redesign | very-high | God-object decomposition has no clean port order (§6). **Floor grid via world-space material on a mesh, NOT post-process** (Gemini — post-process breaks depth sort + AA). Confirm mazing before choosing spline vs A* (Gemini). Centralize the coord transform (both). |
| 3.2 | **entities-combat** (7 · rewrite) — `Enemy`/`EnemyType`, `Boss`/`BossType`/`BossMechanicState`, `Tower`/`TowerType`/`TargetMode`, `Projectile`, `EnemyManager`/`WaveModifier`, `TowerManager`, `BulletManager` | Towers/bosses → `AActor` (low count) · projectiles/swarm enemies → **struct in `UWorldSubsystem` + ISMC** (or MassEntity) · managers → `UWorldSubsystem` (spawner/placement/pool) · stats → `UDataAsset`/`UDataTable` per type · damage+statuses+tower-fire → **GAS** (default) *or* plain `UActorComponent`+`TakeDamage` (fallback) · path → spline/A* · object pooling | rewrite | very-high | **Performance: `AActor`-per-entity bottlenecks at TD density** (both reviewers) → ISMC/struct-array/Mass. **GAS-vs-plain-components conflict** (Codex pro-GAS, Gemini anti) — see §4 decision rule. Battle parity is a high-regression rewrite (Codex): build deterministic parity tests from the 12,478-test baseline. `enemy.dart` fan-in 23 / `tower.dart` fan-in 12 — base types touched everywhere. |
| 3.3 | **effects-particles** (22 · redesign) — `VisualDirector`, `ScreenEffects`, `GameParticles`, `ExplosionEffect`, `DamageNumberEffect`, `FloatingText`, `GalaxyEffect`, `PixelDisintegrationEffect`, `BossEntranceEffect`, `AuroraEffect`, `RealityTearEffect`, `EnergyBarrierEffect`, `ReflectiveFloor`, `FocusModeOverlay`, `TutorialGuide`, … | Particles → **Niagara** (`UNiagaraSystem`/`UNiagaraComponent`) · procedural looks (auroras/walls/portals) → Niagara scratch/Materials · screen FX (CRT/vignette/scanlines/chromatic aberration) → post-process `UMaterial` · `VisualDirector` → `UGameInstanceSubsystem`/director `AActor` · shake → `UCameraShakeBase`+trauma curve · damage numbers/floating text/result/tutorial → **lightweight UMG** · type→VFX map → `UDataAsset`/`UDataTable` | redesign | very-high | **Re-author, do not port — immediate-mode Canvas art** (§4.10). Gate the milestone on a **neon vertical slice** proving the look (Gemini "tech-art paralysis"). Damage numbers/health bars → lightweight `UUserWidget`/Canvas, NOT heavy Common UI (Gemini). |
| 3.4 | **effects-shaders** (12 · redesign/medium) — `ShaderManager`, `ShaderDescriptor`, `ShaderAsset`, `WorldUberShaderComponent`, `ParticleShaderComponent`, `ScreenPostProcessComponent`, `ShaderUniformController`, `NoiseTexture`, `ShaderPresetConfig`, `FlagPacker` | `UMaterial`/`MID` (surface) · post-process-domain `UMaterial` on `UPostProcessComponent`/volume · world backdrop → surface material/decal · particle trails → Niagara · presets → `UDataAsset`/`UCurveFloat`/`UMaterialParameterCollection` · global params (time/wave/trauma/pointer) → pushed by a `UWorldSubsystem` | redesign | medium | GLSL→HLSL/material-graph is mechanical & bounded. Keep the floor grid out of post-process (Gemini, see 3.1). The `FlagPacker`/uniform-packing logic is the only non-obvious bit — port as a material function. |
| 3.5 | **hud** (9 · redesign) — `HudComponent`, `HudButton`, `BossHealthBar`, `CountdownTimerComponent`, `BattleDialogueComponent`, `GameEventFeed`, `KillComboDisplay`, `MinimapComponent`, `GameEventType` | **UMG** `UUserWidget` per element · assembled on `AHUD`/`APlayerController` · minimap → `SceneCapture2D` render-target or projected canvas markers · boss/wave/dialogue → `UDataAsset`/`UDataTable` · neon glow/CRT/glitch → UI-domain `UMaterial`+Retainer Box · **view-model (MVVM / snapshot `UObject`) bound to `AGameStateBase`, pushed on change** | redesign | very-high | **HUD must NOT read random actors** (Codex "HUD state-binding drift") — push `GameState` snapshots via delegates/MVVM. High-frequency elements (boss bar, combo, timer) → lightweight `UUserWidget`, reserve Common UI for menus (Gemini). |
| 3.6 | **fps** (5 · redesign/high) — `Vector3`, `Ray`, `Camera3D`, `FpsViewComponent`, `Enemy3D`/`Enemy3DShape`, `Tower3D`, `FpsBackgroundComponent` | `APlayerCameraManager`/`ACameraActor` (or possessed camera Pawn) · `APlayerController` input mode + `InputMappingContext` · FocusMode flag on GameState/subsystem (replaces manual 10s timer) · existing tower/enemy `AActor`s rendered **natively** · UMG cockpit HUD · Niagara boost/muzzle · post-process CRT/glitch · per-tower weapon-viewmodel mesh (`TowerType`→mesh/FX DataTable) · GAS Overdrive | redesign → mostly **engine-native** | high | **Delete the hand-rolled 3D math entirely** (`Vector3`/`Ray`/`Camera3D`/billboard reprojection). Gemini caveat: to preserve the 2D neon art direction in 3D, use `UPaperSpriteComponent`/billboard materials lit by Niagara rather than forcing solid meshes. |
| 3.7 | **state-bloc** (5 · rewrite/medium) — `SettingsCubit`/`SettingsState`, `GameBloc` (DORMANT) + event set | `AGameStateBase` (per-match gold/lives/score/wave/status) · `AGameModeBase` (authoritative rules: wave bonus, victory/defeat, affordability/spend) · `UGameInstanceSubsystem` (settings across levels) · `USaveGame` (replaces shared_preferences) · default tuning → `UPrimaryDataAsset` · optional GAS `UAttributeSet` for gold/lives/score · dynamic-multicast delegates replace `BlocBuilder` | rewrite | medium | **`GameBloc` is dormant — do not port as authority** (§4.3, both reviewers). Use its events only as vocabulary. Pick `AGameStateBase` as the one source of truth. |
| 3.8 | **services** (7 · redesign) — `AudioService`, `AmbientSoundscapeService`, `ProceduralMusicService`, `LevelService` (fan-in 8, 100-level catalog+progress), `StorageService`, `UpgradeService`, `SpriteCacheService` | One `UGameInstanceSubsystem` per service (Audio/Level/Upgrade) · `USaveGame` replaces `StorageService` · catalogs → `UPrimaryDataAsset`/`UDataTable` · SFX/music → **MetaSounds** (keep adaptive behavior) · spatialization/throttle → `USoundConcurrency`+attenuation · mix → Control Bus/SoundMix/Audio Modulation · **`SpriteCacheService` → `UAssetManager` async streaming** | redesign | very-high | **Service init ordering & audio lifetime** (§4.5): replicate `Storage→Level→Audio→ProceduralMusic→SpriteCache` as GameInstance subsystem init order; mishandling → silent audio failure/leaks (Codex). Procedural music needs early MetaSounds prototyping (Gemini). Keep async asset streaming (Gemini, see row 23). |
| 3.9 | **models-data** (5 · rewrite/medium) — `LevelConfig`/`LevelProgress`, `QualityLevel`, `UpgradeStats`/`UpgradeDefinition`/`RunUpgradeDefinition`, `StoryData`/`WorldChronicles`/briefings/lore/cinematics | `UPrimaryDataAsset` (level configs, upgrade defs, chronicles) · `USTRUCT : FTableRowBase` (`FUpgradeStats`, `FLevelProgress`, `FDialogueLine`, `FCinematicLine`) · `UDataTable` (level catalog, briefings, lore, codex, run upgrades) · `UEnum` (quality/moods/lore categories/cinematic visuals) · `USaveGame` (progress) · **`FText` + String Tables** for all prose | rewrite | medium | **Lowest-risk subsystem — do it FIRST** so towers/enemies/levels are data-driven early (map + Codex). Gemini: use hybrid DataAssets with **soft pointers to Blueprint-implementable event classes** for mid-wave boss mechanics/dialogue triggers (pure data lacks scriptable hooks). |
| 3.10 | **ui-widgets-theme** (19 · redesign) — `NeonColors`/`NeonTheme`/`NeonTextStyles`/`NeonAnimations`/`NeonEffects`, `NeonButton`, `TronButton`, `EpicNeonButton`, `EpicNeonTitle`, `GlitchText`, `EpicDialog`, `TronDialog`, `EpicLoadingSpinner`, `TronCard`, `UniverseGraphWidget`, `AnimatedTronGrid`, `CyberGridBackground`, `MaterializationOverlay`, `WorldArtGenerator` | **UMG** `UUserWidget` per widget + reusable WBP palette · `neon_theme` → design-token `UDataAsset` + `USlateWidgetStyle` (+ world MPC) · glow/scanlines/glitch/gradients → UI-domain `UMaterial`/`MID` · animations → `UWidgetAnimation` · buttons/dialogs/menus → **Common UI** (`UCommonButtonBase`) · galaxy graph → custom Slate `FPaintContext` widget · transition/theme provider → `UGameInstanceSubsystem` | redesign | very-high | **Port `neon_theme` FIRST (fan-in 42) and split UI-vs-world params** (§4.6). `level_select_screen ⇄ universe_graph_widget` is the **2-node cycle** — break with a delegate (§6). Most painters → UI materials, not Slate (both reviewers). |
| 3.11 | **ui-screens-overlays** (18 · redesign/high–very-high) — 11 screens (`main_menu`, `level_select`, `game_screen`, `settings`, `story`, `upgrades`, `benchmark`, `codex`, `loading`, `cinematic`, `chronicle_reader`), 6 overlays (`pause`, `victory`, `game_over`, `briefing`, `run_upgrade`, `game_result`), `tron_page_route` | **Common UI** `UCommonActivatableWidget` stacks · overlays → UMG push/pop driven by GameMode/PlayerController · `game_screen` responsibilities → `AGameMode`+`AGameStateBase`+`APlayerController`+GameInstance bootstrap (replaces `loading_screen._initializeServices`) · `TronPageRoute` → `UWidgetAnimation`+UI material · CustomPainter chrome → UI materials/Niagara | redesign | high–very-high | **Containment inverts** — `game_screen.dart` is the lifecycle seam (§4.2, both reviewers). **Two `game_result_overlay.dart` files** (one Flame effect, one Flutter overlay, §4.4) — determine which is live before building the UMG end screen, or you port dead code. UI dismissal must gate on GameInstance/GameMode load state to avoid the "loading dismissed before GameState init" race (Gemini). |

---

## 3. GAS plan (gameplay → GameplayAbility / GameplayEffect / AttributeSet)

> **Default = GAS** (Codex-endorsed); **fallback = plain `UActorComponent` + `TakeDamage`** (Gemini-
> preferred). Both are valid for single-player. Choose GAS if you want the status matrix and tuning to
> stay fully data-driven and composable; choose plain components if GAS boilerplate dominates. The
> mapping below is identical in *intent* either way — the GAS column tells you the construct; the
> fallback column tells you the lightweight equivalent.

### 3.1 Attributes (`UAttributeSet`)

| Quantity (today) | GAS attribute | Plain-component fallback | Owner |
|---|---|---|---|
| Enemy/boss HP, max HP, armor/shield | `UCombatAttributeSet`: `Health`, `MaxHealth`, `Shield`, `Armor` | `UHealthComponent` fields | Per enemy/boss actor (or struct for swarm) |
| Enemy move speed (slow target) | `MoveSpeed`, `MoveSpeedMultiplier` | `UStatusComponent` multiplier | Enemy |
| Tower fire rate / range / damage | `FireRate`, `Range`, `Damage` (+ `DamageMultiplier` for Boost) | `UTowerStatsComponent` | Tower |
| **Gold / lives / score** | `UPlayerResourceAttributeSet`: `Gold`, `Lives`, `Score` on `APlayerState` | Plain replicated/snapshot fields on `AGameStateBase` | GameState/PlayerState |

Gold/lives/score *may* be GAS attributes, but per §3.7 the **single authority is `AGameStateBase`** —
expose them via getters and a change delegate regardless of GAS, so the HUD view-model binds to one
place (see §5 HUD note). Affordability/spend stays an authoritative **GameMode** rule.

### 3.2 Abilities (`UGameplayAbility`)

| Gameplay (today) | Ability | Trigger | Fallback |
|---|---|---|---|
| Tower fire (per `TowerType`, `TargetMode`) | `UGA_TowerFire` → applies a damage `UGameplayEffect` to target(s) | Cooldown/range tick on `ATower` | Timer + `TakeDamage` on target |
| **Neon Pulse** AoE slow (`NeonPulse`/`_PulsePhase`) | `UGA_NeonPulse` → expanding overlap → applies `GE_Slow` to enemies in radius | Player input (`PendingAbility`) | Sphere overlap + apply slow status component |
| **Neon Mine** (`NeonMine`/`MineState`) | `UGA_DeployMine` (place) + proximity-triggered `UGA_MineDetonate` → AoE damage GE | Player input + proximity FSM | `AActor` mine + overlap + `TakeDamage` |
| **Overdrive / BOOST** (FPS focus mode) | `UGA_Overdrive` → grants `GE_Boost` (fire-rate/damage up) for duration | Focus-mode input; replaces manual 10s timer | Buff component + timer |

### 3.3 Effects (`UGameplayEffect`) — the status matrix

The enemy status set (slow / burn / shield / boost / stun) is **exactly** what GAS effects model well
(duration, periodic, stacking, modifiers) — this is the strongest argument for GAS here.

| Status (today, per-enemy in `entities-combat`) | GameplayEffect | Type | Fallback (plain) |
|---|---|---|---|
| **Slow** | `GE_Slow` → multiplies `MoveSpeed` | Duration, stacking policy | `UStatusComponent` speed multiplier + timer |
| **Burn** | `GE_Burn` → periodic `Health` damage | Duration + Period | Periodic-tick damage on status component |
| **Shield** | `GE_Shield` → adds `Shield`, absorbs before `Health` | Duration / infinite | Shield field + damage pre-pass |
| **Boost** (enemy buff or tower buff) | `GE_Boost` → `+Damage`/`+MoveSpeed`/`+FireRate` | Duration | Multiplier field + timer |
| **Stun** | `GE_Stun` → grants a `State.Stunned` tag that blocks abilities/movement | Duration | Bool flag gating tick |
| Instant tower hit | `GE_Damage_Instant` → `-Health` (armor/shield aware) | Instant | `TakeDamage` |

Use **GameplayTags** (`Status.Slow`, `Status.Burn`, `Status.Shield`, `Status.Boost`, `State.Stunned`)
for queries, immunities and HUD icons — equivalent to the per-enemy status flags today. Drive all
magnitudes/durations from `UDataTable`/`UCurveTable` so tuning matches the `DifficultyCurve` data, not
hardcoded GAS values.

---

## 4. Data-driven content plan

Per §3.9 this is the **first** real milestone after the skeleton — everything downstream becomes
data-driven and the 100-level catalog/narrative stops being a code dependency.

| Content (today) | Unreal asset | Type detail | Notes |
|---|---|---|---|
| **Towers** (4 types: Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field; `TowerType`, `TargetMode`) | `UPrimaryDataAsset` per tower + `UDataTable` row | `UEnum ETowerType`, `UEnum ETargetMode`; row holds cost, range, fire-rate, damage, projectile, mesh/FX soft-ptr | Mesh/FX as **soft object pointers** (async load via `UAssetManager`). |
| **Enemies** (Runner, Overloaded, Juggernaut; `EnemyType`) | `UDataTable` (`FEnemyRow : FTableRowBase`) | HP/speed/gold/armor + `EEnemyType`; visual soft-ptr | Stats feed GAS `UAttributeSet` init. |
| **Bosses** (10 world bosses + mini-bosses; `BossType`, `BossMechanicState`) | `UPrimaryDataAsset` per boss | Phases, HP, mechanic timeline; **soft ptr to a Blueprint event class** for mid-wave mechanics | Gemini: pure data lacks scriptable hooks → hybrid DataAsset + BP event class for bespoke boss mechanics/dialogue triggers. |
| **Levels** (100 across 10 worlds; `LevelConfig`, `GameWorld` `.tmx`) | `UDataTable` level catalog + per-level `UPrimaryDataAsset` + imported grid `UDataAsset` | Waves, modifiers (`WaveModifier`), reward, world theme, grid/path | `levelsPerWorld = 10` constant → curve/config. `.tmx` importer produces grid masks + waypoints (row 13). |
| **Difficulty / tuning** (`DifficultyCurve`) | `UCurveFloat`/`UCurveTable` + `UBlueprintFunctionLibrary` | HP/speed/count/spawn/gold scaling, cost inflation, wave bonus | **Native curve assets** (Gemini), not bespoke DataAsset. |
| **Upgrades** (meta + run; `UpgradeDefinition`, `RunUpgradeDefinition`, `UpgradeStats`) | `UDataTable` (`FUpgradeStats`, `FUpgradeDefinition`, `FRunUpgradeDefinition` rows) | Levels, costs, effect deltas | Meta-upgrade levels persist in `USaveGame`. |
| **Lore / narrative** (`StoryData`, `WorldChronicles`, characters, briefings, codex, cinematics; ~2,600 lines ES/EN) | `UDataTable` (`FDialogueLine`, `FCinematicLine`, codex rows) + **String Tables** | `FText` keys → String Table CSV (ES/EN) | §4.9: migrate **data AND the 4 presenter screens** (story/codex/chronicle/cinematic). |
| **Quality levels** (`QualityLevel`) | `UEnum` + `UGameUserSettings`/Scalability | maps to UE Scalability groups | Persist in `USaveGame`. |
| **Player progress** (`level_progress_<id>`, `unlocked_levels`, `meta_currency`, `upgrade_levels`, stars) | `USaveGame` | one schema after the **write-site census** (§4.7) | Add Flutter→JSON export + UE boot deserializer for existing players (both reviewers). |

---

## 5. Cycle-breaking guidance

### 5.1 The 37-node `HasGameRef` SCC ("the battle simulation") — §4.1

The SCC is `bored_games_game ⇄ entities/{enemy,tower,boss,projectile} ⇄ managers/{enemy,tower,bullet}
⇄ effects/* ⇄ hud/* ⇄ fps/* ⇄ components/{neon_mine,neon_pulse} ⇄ services/{audio,level}`. It exists
because every Flame `Component` reaches the root via `HasGameRef<BoredGamesGame>` / `game.<x>` and the
root holds child references back — bidirectional refs = one giant cycle. **There is no clean port
order.** Break it *by design*:

1. **Stand up the skeleton first** (Milestone 1): `AGameModeBase` + `AGameStateBase` +
   `APlayerController` + the service `UGameInstanceSubsystem`s + a **`UGameplayMessageSubsystem`**. This
   exists *before* any entity is ported, so the cycle can never re-form.
2. **Replace `game.<x>` back-pointers with lookups, never hard refs** (row 3): `GetWorld()`,
   `GetWorld()->GetAuthGameMode()`, `GetGameState()`, `GetGameInstance()->GetSubsystem<>()`. Actors
   resolve "the game" on demand instead of caching a god-object pointer.
3. **Replace child→root *notifications* with messages**: instead of `game.onEnemyKilled(...)`, broadcast
   a `GameplayMessage` (e.g. `Combat.EnemyKilled`) on the `UGameplayMessageSubsystem`; GameState/GameMode
   listen. This severs the back-edge entirely.
4. **Drop dormant `GameBloc`** as authority (§4.3); `AGameStateBase` is the single source of truth. Keep
   `GameBloc`'s event names as the message-channel vocabulary.
5. **Decompose the god object, do not port it 1:1** (both reviewers): GameMode = rules/spawn/win-lose;
   GameState/PlayerState = current state; PlayerController = input/UMG; subsystems = services. **No mega
   `AGameModeBase`.**
6. **Treat the entire SCC as ONE milestone** ("the battle simulation"), not many file-by-file ports.

### 5.2 The UI 2-node cycle — §4.2 / DEPENDENCY_GRAPH §4.2

`ui/screens/level_select_screen.dart ⇄ ui/widgets/universe_graph_widget.dart` — a screen and the custom
galaxy-graph widget it hosts reference each other. Break it with a **delegate / dynamic-multicast**:
the `UniverseGraphWidget` (custom Slate `FPaintContext` widget per row 6) exposes an
`OnNodeSelected` delegate; the level-select `UCommonActivatableWidget` binds to it. No mutual hard
refs — one-directional ownership (screen owns widget, widget calls up via delegate).

---

## 6. Milestone-ordered checklist

Ordering follows §6 of the architecture map, with the reviewers' gating advice folded in.

### Milestone 1 — Skeleton (break the cycle before it forms)
- [ ] UE5 project + C++ modules; enable plugins: Enhanced Input, Common UI, Niagara, GAS (if used),
      MetaSounds, GameplayMessageSubsystem; (MassEntity if profiling demands it).
- [ ] `AGameModeBase` (rules) + `AGameStateBase` (gold/lives/score/wave authority) + `APlayerController`
      (Enhanced Input) + `APlayerState`.
- [ ] One `UGameInstanceSubsystem` per service (Audio, Level, Upgrade) + settings subsystem; wire
      **init ordering** `Storage→Level→Audio→ProceduralMusic→Asset-streaming` (§4.5).
- [ ] `UGameplayMessageSubsystem` channels (the `GameBloc` event vocabulary).
- [ ] **Port `neon_theme.dart` FIRST** → split into UI design-token `UDataAsset` + `USlateWidgetStyle`
      AND world `UMaterialParameterCollection` (fan-in 42, §4.6).
- [ ] Central **grid↔world coordinate transform** library (Flutter Y-down → Unreal Z-up) (row 19).
- [ ] **Prototype adaptive MetaSounds** (stems/leitmotifs/intensity) to de-risk procedural music early
      (Gemini).
- [ ] Save: **census every `shared_preferences` write site** (§4.7); draft `USaveGame` schema + a
      Flutter→JSON exporter + UE boot deserializer.

### Milestone 2 — Data-driven content (`models-data` first; lowest risk)
- [ ] `UEnum`s (`ETowerType`, `ETargetMode`, `EEnemyType`, `EBossType`, quality, lore categories).
- [ ] `USTRUCT : FTableRowBase` rows + `UDataTable`s: enemies, towers, upgrades, level catalog, briefings,
      codex, run upgrades.
- [ ] `UPrimaryDataAsset`s: per-tower, per-boss (with soft-ptr to BP event class for mechanics), per-level,
      chronicles.
- [ ] `UCurveFloat`/`UCurveTable` for `DifficultyCurve` + `UBlueprintFunctionLibrary` formulae.
- [ ] **String Tables** (ES/EN) for all ~2,600 lines of prose; rewire the 4 presenter screens to `FText`.
- [ ] `.tmx` → grid/path importer; **confirm whether mazing exists** to choose spline vs A* (row 14).

### Milestone 3 — Battle simulation (the whole 37-node SCC, one milestone)
- [ ] Towers/bosses as `AActor`; **projectiles/swarm enemies as struct-in-`UWorldSubsystem` + ISMC**
      (profile; escalate to MassEntity if needed) — both reviewers.
- [ ] Managers → `UWorldSubsystem` (spawner/placement/pool); object pooling.
- [ ] Combat via **GAS** (attributes/abilities/effects per §3) **or** plain components+`TakeDamage`
      fallback — pick per §4 decision rule.
- [ ] Path following on spline **or** grid A*.
- [ ] **Deterministic parity tests** vs the 12,478-test baseline (wave/difficulty/status math) as a
      headless UE functional-test suite (Gemini — recover lost automated coverage).
- [ ] No `game.<x>` back-pointers anywhere — lookups + messages only (§6.1).

### Milestone 4 — VFX & shaders (the long tail; gate on a vertical slice)
- [ ] **Prove the neon vocabulary** in a vertical slice (Materials/Niagara) before porting more code
      (Gemini "tech-art paralysis").
- [ ] Niagara for particles/explosions/impacts/auroras/portals; `UCameraShakeBase`+trauma for shake.
- [ ] Materials: world uber → surface material; **floor grid → world-space material on a mesh plane**
      (NOT post-process); post-process material for CRT/vignette/scanlines/chromatic aberration only.
- [ ] `UMaterialParameterCollection` global params pushed by a `UWorldSubsystem`; port `FlagPacker` as a
      material function.

### Milestone 5 — HUD & UI (invert the containment seam)
- [ ] Invert ownership: world is primary, UMG is a HUD overlay; split `game_screen.dart` across
      GameMode/GameState/PlayerController/GameInstance bootstrap (§4.2).
- [ ] HUD elements as **lightweight `UUserWidget`** bound to a GameState **view-model/MVVM**, pushed on
      change (no reaching into actors — Codex). Boss bar/combo/timer/damage numbers lightweight; Common
      UI reserved for menus (Gemini).
- [ ] Screens → **Common UI** `UCommonActivatableWidget` stacks (NOT levels); overlays → UMG push/pop.
- [ ] **Resolve the two `game_result_overlay.dart`** (§4.4) before building the end screen.
- [ ] `TronPageRoute` → `UWidgetAnimation` + transition material.
- [ ] Break the `level_select ⇄ universe_graph_widget` cycle with a delegate (§6.2).
- [ ] Gate UMG dismissal on GameInstance/GameMode load state (Gemini race fix).

### Milestone 6 — FPS mode (delete the pseudo-3D math)
- [ ] Replace `Vector3`/`Ray`/`Camera3D` with `APlayerCameraManager`/`ACameraActor` + input mode +
      `InputMappingContext`; FocusMode flag on GameState.
- [ ] Render existing enemy/tower actors natively; preserve neon art via `UPaperSpriteComponent`/
      billboard materials where desired (Gemini).
- [ ] Per-tower weapon viewmodel (DataTable `TowerType→mesh/FX`); Overdrive via GAS `UGA_Overdrive`.
- [ ] UMG cockpit HUD; post-process CRT/glitch.

### Milestone 7 — Audio (MetaSounds + adaptive music subsystem)
- [ ] Audio `UGameInstanceSubsystem` with the init/lifetime rules from §4.5 (no temp-WAV/pool-refresh
      hacks; deterministic dispose).
- [ ] MetaSounds for SFX + adaptive music (intensity/leitmotif/ducking); mix via Audio Modulation /
      Control Bus / SoundMix; `USoundConcurrency` + attenuation for throttling/spatialization.
- [ ] Wire `SpriteCacheService` replacement (`UAssetManager` + Primary Asset Labels) into level
      pre-load (row 23).

---

## 7. Reviewer agreement / conflict ledger

| Topic | Codex (gpt-5.5) | Gemini (3.1-pro) | Resolution in this doc |
|---|---|---|---|
| God object → GameMode/State/Controller/subsystems (no mega GameMode) | Agree | Agree | Adopted (rows 1, 4; §6). |
| `HasGameRef` → lookups + `GameplayMessageSubsystem` | Agree | Agree (query proxies + tests) | Adopted (row 3; §6.1). |
| `GameBloc` not the authority | Agree | Agree | Adopted (row 9; §3.7). |
| Screens → Common UI, not levels | Agree | Agree | Adopted (rows 15–16; §3.11). |
| CustomPainter ≠ Slate 1:1; art is the dominant cost | Agree | Agree (tech-art paralysis; gate on vertical slice) | Adopted (row 6; §3.3; M4). |
| **GAS for combat** | **Pro** (gas-combat-scaffold skill) | **Con** (over-engineering; plain components) | **Conflict flagged.** GAS default + documented plain-component fallback (§3). |
| **`AActor`-per-entity vs ISMC/struct/Mass** | Mass/struct when counts high | ISMC+struct-array `UWorldSubsystem`, MassEntity for large | **Both push away from naive `AActor`.** Adopted: actors for low-count, struct+ISMC/Mass for high-count (rows 2, 5; §3.2). |
| Floor grid rendering | (not specific) | Con post-process → world-space material on mesh | Adopted Gemini (rows 6–7; §3.1; M4). |
| `SpriteCacheService` | (drop, per map) | Don't drop → `UAssetManager` streaming | Adopted Gemini override (row 23; §3.8). |
| Tuning curves | (curve DataAsset, per map) | Native `UCurveFloat`/`UCurveTable` | Adopted Gemini (row 21; §4). |
| Splines vs A* (mazing) | (not specific) | A* if mazing exists | Adopted as a **verify-first** gate (row 14; M2). |
| Coordinate-space transform | (implicit) | Explicit underestimated risk | Adopted (row 19; M1). |
| Save migration for existing players | Census write-sites first | JSON export + UE deserializer | Both adopted (row 10; §4.7; M1). |
| Procedural music | Deliberate subsystem + MetaSounds | Prototype stems early (won't port 1:1) | Both adopted (row 12; §3.8; M1). |

---

*Companion to [`ARCHITECTURE_MAP.md`](ARCHITECTURE_MAP.md) and [`DEPENDENCY_GRAPH.md`](DEPENDENCY_GRAPH.md).
Cross-checked with Codex (gpt-5.5) and Gemini (3.1-pro-preview). Regenerate the import graph with
`node flutter_app/scripts/codegraph.js`.*
