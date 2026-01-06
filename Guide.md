# Comprehensive Phase Guide for a Neon Tron Tower Defense in Flutter + Flame

## Preface
- Use this plan when collaborating across multiple LLMs or developers; each phase lists deliverables, validation criteria, and aesthetic notes.
- Blend Flutter UI (Overlays, Bloc/Riverpod) with Flame's deterministic game loop and sprite handling. Review after each phase, especially when adding neon/Tron features.

## Cross-Phase Validation
- [ ] Required artifacts: Tiled map layers, modular FlameGame + managers, Flutter overlays wired to Bloc/Riverpod, Docker + README for reproducible launches.
- [ ] Success indicators: stable 60 FPS in browser, render/update loops without per-frame allocations, documented DPS vs. wave balance, checklist trace linked to this guide.
- [ ] Neon/Tron aesthetic checklist: gradient grid background, glowing UI, synth sound palette, pulse-based particles, shader-hint overlays in at least one demo scene per phase.
- [ ] CI/automation: add lint/format, static analysis, unit tests, and build; publish web artifacts once a basic scene renders.
- Current progress: Docker image with Flutter 3.22.1 builds and serves the web app; NeonGridComponent renders as base layer; main.dart wired to GameWidget; managers skeletons and coord helpers added; placeholder map (level1.json) loaded, waypoints and buildable mask parsed.

## Phase 0: Environment Setup and Aesthetic Direction
- [x] Repository/containers: Dockerfile + compose serve at http://localhost:3001; .dockerignore lean; README actualizado con build/run y puerto.
- [x] Dependencies: flame, flame_tiled, flame_audio, flutter_bloc or riverpod, equatable, vector_math, settings_ui; opcional pathfinding/flow_field.
- [ ] Assets/style: definir paleta neon, fuentes, shader hints; documentar torres/enemigos/power-ups; tokens de estilo/UI kit.

## Phase 1: Engine Foundation and Neon Grid
- [x] FlameGame skeleton: BoredGamesGame creado; backgroundColor set; NeonGridComponent como base.
- [x] Managers: World, Enemy, Tower, Bullet, Hud (skeletons creados; lógica pendiente).
- [x] Neon grid: NeonGridComponent dibuja grilla tron y se ajusta en resize.
- [x] Tiled pipeline: placeholder map (level1.json) cargado; se parsean waypoints y máscara de buildable.
- [x] Coordinates/snapping: helpers screenToGrid/gridToWorld; heatmap/ghost pendientes para UI.

## Phase 2: Core Combat Mechanics with Neon Flair
- Enemy flow: waypoint movement (normalize dir, advance by speed * dt); WaveManager reads JSON/config, scales HP with HP_n = HP_base * 1.2^n; events on reach-base/death; synthwave SFX.
- Wave spices: periodic "Overload" waves (speed/resistance buffs); optional stealth enemies targetable only by detection-upgraded towers (HUD icon).
- Build/validate: TowerManager handles grid, costs, ghost towers; ensure isBuildable and path not blocked; player-activated Neon Pulse slows nearby enemies with glowing ring; deployable mines/laser tripwires (single-use, cooldown).
- Detection/shooting: CircleHitbox or spatial hash keeps shortlist; targeting modes (first/last/strongest/weakest) with leading prediction; ObjectPool<Projectile> reuse; modular projectile effects (slow/burn/chain) as stackable components.

## Phase 3: Economy, State, and Reactive Neon UI
- State: Bloc/Riverpod tracks gold, lives, currentWave, score, selectedTowerType, neonEnergy; events EnemyKilled, TowerBuilt, TowerUpgraded, PulseActivated; Threat Meter rises with leaks, drops with perfect clears, spawning elites with better rewards.
- HUD/overlays: neon-styled ListViews/buttons with AnimatedContainer + BackdropFilter; pause, win/lose, Neon Feed ticker. Main Menu (Play, Boss Rush, Sudden Death, Settings, Credits). Settings (audio sliders, graphics presets, VFX intensity, control sensitivity, colorblind toggle). Leaderboards (local, future online, filters by mode). Replay/Highlights stub (runs, waves cleared, damage, combo). Diagnostics (FPS, memory, entity counts, pool usage) gated by debug flag. Accessibility overlay (subtitles for cues, high-contrast, adjustable text size).
- Store/skills: store overlay with neon icons, cost bars, spark animations; select tower types, deduct gold, highlight buildable cells; skill tree/neon grid of upgrades (fire rate, damage type, pulse recharge).

## Phase 4: Dynamic Content, Balance, and Neon Tech
- Entities/damage: tower types (Pulse Archer, Circuit Cannon, Phase Mage, Glimmer Field); enemies (Runner, Juggernaut, Phantom); damage matrix finalDamage = (baseDamage * typeMultiplier) - armorReduction. Add elites with shield phases and bosses with multipart hitboxes/rotating resistances; aerial Data Ghosts immune to ground traps; environmental hazards (energy storms, lane blockers) in specific waves.
- Audio/FX: flame_audio for synthwave BGM and neon SFX; health bars with glow, pulse particles, trails, build flicker animations; dynamic lighting cues on power-ups.

## Phase 5: Optimization, Persistence, and Production Polish
- Rendering: SpriteBatchComponent for repeated tiles/projectiles; atlases via TexturePacker + flame_texturepacker; SpriteAnimationComponent references.
- Memory/determinism: avoid allocations in render/update; ObjectPool for bullets, explosions, glow pulses, temporary overlays; deterministic seed support for QA and leaderboards.
- Persistence/monetization: progress with hive/shared_preferences; optional rewarded neon boosts via google_mobile_ads behind UX gating.

## Phase 6: Validation, QA, and Neon Showcase
- Gameplay tests: simulate/log DPS vs waves; stress in Docker for 60 FPS with heavy enemy/projectile counts; add automated soak tests with FPS/GC logs.
- Architecture audits: managers have single responsibility; Flutter UI reacts via Bloc/Riverpod only; Flame emits events without manipulating widgets.
- Delivery checklist: log artifacts (scripts, tests, maps, overlays), metrics (FPS, GC pauses); archive neon style references; plan opt-in telemetry hooks (session length, wave reached, FPS floor, crash logs).

## Phase 7: Distribution and Live Ops (optional)
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
