# Comprehensive Phase Guide for a Neon Tron Tower Defense in Flutter + Flame

## Preface
- Use this plan when collaborating across multiple LLMs or developers; each phase lists deliverables, validation criteria, and aesthetic notes.
- Blend Flutter UI (Overlays, Bloc/Riverpod) with Flame's deterministic game loop and sprite handling. Review after each phase, especially when adding neon/Tron features.

## Cross-Phase Validation
- [ ] Required artifacts: Tiled map layers, modular FlameGame + managers, Flutter overlays wired to Bloc/Riverpod, Docker + README for reproducible launches.
- [ ] Success indicators: stable 60 FPS in browser, render/update loops without per-frame allocations, documented DPS vs. wave balance, checklist trace linked to this guide.
- [ ] Neon/Tron aesthetic checklist: gradient grid background, glowing UI, synth sound palette, pulse-based particles, shader-hint overlays in at least one demo scene per phase.
- [ ] CI/automation: add lint/format, static analysis, unit tests, and build; publish web artifacts once a basic scene renders.
- Current progress: **Phase 8 COMPLETE (2026-01-06)**. Full game v1.0.0 released! Features: Menus, Bloc state management, Settings screen, AudioService (stub), ParticleSystem, StorageService. CI/CD via GitHub Actions for automatic deployment to GitHub Pages. README updated with full documentation.
- **Update 2026-01-11**: SharedPreferences persistence implemented. Phantom enemy type added with invisibility mechanics - Phase Mage can detect/reveal phantoms. UI/HUD significantly improved with professional cyberpunk styling. **Deployable Neon Mines** added (Phase 2.6) - 40g cost, 8s cooldown, max 5 active, 150 damage in 60px radius, hotkey [M]. **Procedural Audio SFX** system implemented - synthwave-style sounds generated via waveform synthesis (sine, square, triangle, noise) for all game events.

## Phase 0: Environment Setup and Aesthetic Direction
- [x] Repository/containers: Dockerfile + compose serve at http://localhost:3001; .dockerignore lean; README actualizado con build/run y puerto.
- [x] Dependencies: flame, flame_tiled, flame_audio, flutter_bloc or riverpod, equatable, vector_math, settings_ui; opcional pathfinding/flow_field.
- [ ] Assets/style: definir paleta neon, fuentes, shader hints; documentar torres/enemigos/power-ups; tokens de estilo/UI kit.

## Phase 1: Engine Foundation and Neon Grid
- [x] FlameGame skeleton: BoredGamesGame creado; backgroundColor set; NeonGridComponent como base.
- [x] Managers: World, Enemy, Tower, Bullet, Hud (skeletons creados; logica pendiente).
- [x] Neon grid: NeonGridComponent dibuja grilla tron y se ajusta en resize.
- [x] Tiled pipeline: mapa real (level1.tmx via flame_tiled) parsea waypoints y mascara de buildable.
- [x] Coordinates/snapping: helpers screenToGrid/gridToWorld; ghost con heatmap.
- [x] EnemyManager conectado a waypoints con enemigos dummy spawneando en loop.
- [x] Overlay/heatmap de buildable activo y ghost interactivo (coloca torre dummy; bloqueo de camino validado).
- [x] Incorporar mapa Tiled real (.tmx) con capas visuales y reemplazar el placeholder JSON.
- [x] Implementar ghost tower interactivo con snapping y bloqueo basico (mask de buildable/ocupado; click coloca torre dummy).
- [x] Crear enemigo/tower de prueba y HUD debug simple (FPS/estado) para validar flujo.
- [x] Integrar entrada (mouse/touch) para posicionar ghost tower y probar bloqueos dinamicos (click coloca torre dummy).

## Phase 2: Core Combat Mechanics with Neon Flair
### 2.1 Enemy Health & Combat
- [x] Add health system to Enemy: `health`, `maxHealth`, `takeDamage(amount)`, death event emission.
- [x] Implement HP scaling per wave: HP_n = HP_base * 1.2^n.
- [x] Add visual health bar (neon glow style) above enemies.
- [x] Emit `onEnemyDeath` and `onEnemyReachBase` events for state tracking.

### 2.2 Wave Management
- [x] Create wave orchestration in EnemyManager (startWave, currentWave tracking).
- [x] Define progression constants (baseHealth, baseSpeed, scaling factors).
- [x] Implement wave timing (1s spawn intervals, wave completion callbacks).
- [x] Add wave modifiers: Overload (fast, weak), Juggernaut (slow, tanky), Mixed (alternating types).

### 2.3 Tower Targeting & Shooting
- [x] Add targeting properties to Tower: `detectionRange`, `fireRate`, `damage`, `targetMode`.
- [x] Implement target acquisition (first/last/strongest/weakest/closest in range).
- [x] Create `Projectile` class with movement, damage, and visual glow.
- [x] Implement `BulletManager` with ObjectPool pattern for reuse.
- [x] Wire tower shooting loop: detect → aim → fire → cooldown.

### 2.4 Tower Types (Full Set)
- [x] Define base tower stats structure via TowerType enum (range, damage, fireRate, cost, color, projectileSpeed, slowAmount, slowDuration).
- [x] Implement 4 tower types:
  - Pulse Archer (fast, low damage, cyan, no slow)
  - Circuit Cannon (slow, high damage, magenta, no slow)
  - Phase Mage (medium, long range, purple, 50% slow for 1.5s)
  - Glimmer Field (very fast, short range, yellow, 70% slow for 0.5s)
- [x] Add tower selection buttons to HUD for choosing type before placement.

### 2.5 Game State & Economy
- [x] Track gold, lives, score in BoredGamesGame.
- [x] Deduct gold on tower placement, award gold on enemy kills.
- [x] Reduce lives when enemies reach base; bonus gold on wave complete.
- [x] Display resources in HUD with neon styling.

### 2.6 Special Abilities
- [x] Neon Pulse ability: SPACE key activates, 30g cost, 5s cooldown, 100px radius, 70% slow for 3s, expanding ring VFX.
- [x] Deployable Neon Mines: M key deploys, 40g cost, 8s cooldown, max 5 active mines, 150 damage in 60px radius, arming animation, triggered explosion VFX. (Implemented 2026-01-11)

### 2.7 Enemy Types
- [x] Runner: standard enemy (orange, normal speed/health).
- [x] Overloaded: fast but fragile (magenta, 1.4x speed, 0.8x health, glowing core).
- [x] Juggernaut: slow tank (purple, 0.6x speed, 2.5x health, larger size).

### Phase 2 Legacy Notes (original spec):
- Enemy flow: waypoint movement (normalize dir, advance by speed * dt); WaveManager reads JSON/config, scales HP with HP_n = HP_base * 1.2^n; events on reach-base/death; synthwave SFX.
- Wave spices: periodic "Overload" waves (speed/resistance buffs); optional stealth enemies targetable only by detection-upgraded towers (HUD icon).
- Build/validate: TowerManager handles grid, costs, ghost towers; ensure isBuildable and path not blocked; player-activated Neon Pulse slows nearby enemies with glowing ring; deployable mines/laser tripwires (single-use, cooldown).
- Detection/shooting: CircleHitbox or spatial hash keeps shortlist; targeting modes (first/last/strongest/weakest) with leading prediction; ObjectPool<Projectile> reuse; modular projectile effects (slow/burn/chain) as stackable components.

## Phase 3: Menus and Navigation System
### 3.1 Main Menu
- [x] Create `MainMenuScreen` Flutter widget with neon Tron aesthetic.
- [x] Menu options: Play (Campaign), Level Select, Settings, Credits, Quit.
- [x] Animated neon title with glow pulse effect (`NeonTitle` widget).
- [x] Background: animated neon grid (`AnimatedGridBackground` widget with scan line).
- [x] Button styling: neon borders, hover glow, press feedback (`NeonButton` widget).
- [x] Navigation using Flutter Navigator with `onGenerateRoute`.

### 3.2 Level Select Menu
- [x] Create `LevelSelectScreen` with grid of available levels (4 columns).
- [x] Level cards showing: level number, name, difficulty stars (1-5), locked/unlocked status.
- [x] Visual indicators: completed (checkmark glow), locked (dimmed with lock icon).
- [x] Scrollable grid for 8 predefined levels.
- [x] Back button to return to Main Menu.

### 3.3 Level Data Structure
- [x] Create `LevelConfig` model: id, name, mapFile, waves, difficulty, unlockRequirement, startingGold, startingLives.
- [x] `LevelService` singleton with 8 hardcoded levels (Grid Alpha to Mainframe).
- [x] Level progression logic: unlock next level on completion, star ratings (1-3) based on lives remaining.

### 3.4 Pause Menu (In-Game)
- [x] Pause overlay triggered by ESC key or pause button.
- [x] Options: Resume, Restart Level, Quit to Main Menu.
- [x] Game state frozen via `game.paused = true`.
- [x] Semi-transparent backdrop with blur effect (`BackdropFilter`).

### 3.5 Game Over / Victory Screens
- [x] Victory screen: score summary, animated stars earned, "Next Level" button.
- [x] Game Over screen: waves survived, final score, retry button, quit to menu.
- [x] Scale animation on victory overlay entrance.

### 3.6 Menu State Management
- [x] Basic in-memory progression via `LevelService`.
- [x] Persist unlocked levels and high scores via SharedPreferences (2026-01-07).
- [x] Loading screen with neon spinner - Implemented 2026-01-11.

## Phase 4: Economy, State, and Reactive Neon UI
- State: Bloc/Riverpod tracks gold, lives, currentWave, score, selectedTowerType, neonEnergy; events EnemyKilled, TowerBuilt, TowerUpgraded, PulseActivated; Threat Meter rises with leaks, drops with perfect clears, spawning elites with better rewards.
- HUD/overlays: neon-styled ListViews/buttons with AnimatedContainer + BackdropFilter; pause, win/lose, Neon Feed ticker. Settings (audio sliders, graphics presets, VFX intensity, control sensitivity, colorblind toggle). Leaderboards (local, future online, filters by mode). Replay/Highlights stub (runs, waves cleared, damage, combo). Diagnostics (FPS, memory, entity counts, pool usage) gated by debug flag. Accessibility overlay (subtitles for cues, high-contrast, adjustable text size).
- Store/skills: store overlay with neon icons, cost bars, spark animations; select tower types, deduct gold, highlight buildable cells; skill tree/neon grid of upgrades (fire rate, damage type, pulse recharge).

## Phase 5: Dynamic Content, Balance, and Neon Tech
- [x] Entities/damage: tower types (Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field); enemies (Runner, Juggernaut, Phantom); damage matrix implemented.
- [x] Phantom enemy with invisibility mechanics and Phase Mage detection (implemented 2026-01-11).
- [x] Audio/SFX: Procedural synthwave audio service with waveform generation (sine, square, triangle, noise). Sound effects: shoot, hit, explosion, build, wave_start, pulse, mine_deploy, mine_explode, victory, game_over, button_click, enemy_leak, phantom_reveal, gold_earned. (Implemented 2026-01-11)
- [ ] Future: elites with shield phases, bosses with multipart hitboxes, aerial Data Ghosts, environmental hazards, BGM synthwave tracks.

## Phase 6: Optimization, Persistence, and Production Polish
- Rendering: SpriteBatchComponent for repeated tiles/projectiles; atlases via TexturePacker + flame_texturepacker; SpriteAnimationComponent references.
- Memory/determinism: avoid allocations in render/update; ObjectPool for bullets, explosions, glow pulses, temporary overlays; deterministic seed support for QA and leaderboards.
- Persistence/monetization: progress with hive/shared_preferences; optional rewarded neon boosts via google_mobile_ads behind UX gating.

## Phase 7: Validation, QA, and Neon Showcase
- Gameplay tests: simulate/log DPS vs waves; stress in Docker for 60 FPS with heavy enemy/projectile counts; add automated soak tests with FPS/GC logs.
- Architecture audits: managers have single responsibility; Flutter UI reacts via Bloc/Riverpod only; Flame emits events without manipulating widgets.
- Delivery checklist: log artifacts (scripts, tests, maps, overlays), metrics (FPS, GC pauses); archive neon style references; plan opt-in telemetry hooks (session length, wave reached, FPS floor, crash logs).

## Phase 8: Distribution and Live Ops (optional)
- Build web bundles and host on static hosting (Pages/S3); document cache-busting/versioning.
- Prepare mobile flavors with reduced VFX and texture sizes for low-end devices.
- Plan limited-time events (Season Menu) with rotating modifiers; drive toggles via remote config.

## Creative Feature Backlog
- Neon Combo Meter: kill streak boosts glow/intensity. Trap Field: temporary neon walls re-route enemies. Dynamic Wave Events: glitch waves with alternate colors/speed.
- Co-op Sync Mode: multi-player tower building via WebSockets. Achievement System: feats with neon badge reveal. Boss Rush Mode: curated bosses with rotating shields, homing shots, beam sweeps.
- Hardcore "Sudden Death": one-life mode with higher drops. Roguelite Draft: between waves draft upgrades/curses. Bullet Hell Events: enemies emit radial projectiles towers must soak/dodge.
- Season Menu: time-limited neon events with modifiers and cosmetics. Style Presets Menu: swap neon palettes (cyan/magenta, orange/teal, emerald/lime) and fonts to refresh Tron vibe.

## Appendix: Coordinating Multiple LLMs
- Assign distinct phases per model (e.g., A covers Phases 1-2, B covers Phases 3-4) to avoid conflicts.
- Keep a log of implementations and dates so follow-up models continue from the right checkpoint.
- Treat this guide as source of truth; add notes to the backlog when experimenting with neon features.
