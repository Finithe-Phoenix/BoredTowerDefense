# Neon Defense — Unreal Migration Roadmap (to Flutter parity & beyond)

Status snapshot (2026-06-08). The Unreal port already **meets or exceeds** the Flutter game on
core gameplay; this roadmap closes the remaining feature gaps in priority order. Effort: S < M < L < XL.

## ✅ Done (parity or better than Flutter)
- Core TD loop: 9 towers (vs Flutter's 4) with 1→4 upgrades; ~13 enemies + 3 world bosses (minions,
  phantom, slow); gold economy; multi-wave levels; Victory/Defeat; 100 imported maps + auto-advance.
- In-battle HUD (resources, wave, boss bar, selected-tower panel) + click place/select/sell/upgrade.
- Progress save/persistence (level / highest / best score).
- **Real 3D meshes** (Kenney CC0 — Flutter is 2D): 10 distinct towers + UFO enemies, neon materials.
- **Epic visual pass**: Tron floor, colored stage lights, bloom/exposure grade, volumetric fog, crystals.
- **Combat FX (mesh-based)**: neon projectiles + mesh trail + impact/death bursts (render in packaged build).
- Tooling: two live MCP servers (`unreal` Python + `mcp-unreal` Go w/ MCPUnreal plugin, 38 routes),
  reliable `capture_viewport`, CC0 import pipeline.

## 🎯 Milestones (priority order)

### M1 — Niagara / Material VFX  ·  effort S–M  ·  *in progress*
Real particle FX (sparks, explosions, projectile trails, muzzle flashes) via `niagara_ops` now that the
MCPUnreal plugin is online. Replace/augment the mesh-burst stopgaps. Also: rewire showcase materials to
`MPC_NeonPalette` for global neon control (behind a before/after check).
**Done when:** combat shows Niagara particle impacts + trails, captured cleanly via `capture_viewport`.

### M2 — Audio / MetaSounds  ·  effort XL  ·  *highest "feel" impact — game is currently silent*
Flutter has `AudioService` (SFX), `AmbientSoundscapeService`, and `ProceduralMusicService` (adaptive
music). Unreal `UBTDAudioSubsystem` is an empty stub.
- SFX: fire / impact / death / place / upgrade / boss / victory / defeat via MetaSounds + `USoundConcurrency`.
- Adaptive music: intensity-driven MetaSound (calm → wave → boss), per-world themes.
- Mixing: Control Bus / SoundMix; init order Storage→Level→Audio→Music.
**Done when:** towers/enemies/UI emit SFX and an adaptive music bed plays through waves.

### M3 — UMG / Common UI menus & overlays  ·  effort XL  ·  *unblocked by the new plugin*
Flutter has 11 navigator screens + overlays; Unreal only has the in-battle HUD (game drops straight into
battle). With MCPUnreal's blueprint/UMG routes, WBP authoring is now feasible.
- Common UI `UCommonActivatableWidget` stack: Main Menu → Level Select → Settings → (battle) → Pause →
  Victory/Defeat → Upgrades.
- Reparent `WBP_BTDHud` to the full neon layout; author menu widgets.
- A "player mode" toggle disabling the director's auto-place/auto-wave so a human drives from the menu.
**Done when:** boot → main menu → pick level → play → pause/restart/next, all via UMG.

### M4 — Settings application + persistence  ·  effort M  ·  *couples to M2 + M3*
Flutter `SettingsCubit`: volumes, graphics quality, particle intensity, screen shake, FPS display.
- `UBTDSettingsSubsystem` (flesh out the stub) + `USaveGame` + `UGameUserSettings`/Scalability mapping.
- Live-apply to the running game; wired to the Settings screen (M3) and audio buses (M2).
**Done when:** settings screen changes volume/quality/shake and they persist + apply live.

### M5 — Player abilities  ·  effort M
Flutter: **Neon Pulse** (AoE slow), **Neon Mines** (deployable FSM), **Overdrive/BOOST**.
- Enhanced Input bindings + ability cooldown UI; mine actor + overlap; expanding-overlap pulse.
- Decide GAS vs plain components (GameplayAbilities plugin is enabled).
**Done when:** player can trigger Pulse + place Mines; cooldowns show on the HUD.

### M6 — Status-effect matrix  ·  effort M
Slow ✅. Add **Burn** (periodic dmg), **Shield** (absorb), **Stun** (block move/abilities), data-driven via
DataTable/CurveTable (or GAS GameplayEffects).
**Done when:** towers/enemies apply burn/shield/stun with correct stacking/durations.

### M7 — Full 100-level campaign content  ·  effort L (authoring volume)
Maps imported ✅, but per-level wave sets, buildable cells, world themes, rewards/stars, and the full
**DifficultyCurve** (count/speed/spawn/gold/cost inflation as UCurveTable) are not authored — the demo reuses
one wave set for all levels.
**Done when:** levels 1–100 each have distinct waves + difficulty scaling + rewards across 10 worlds.

### M8 — Meta / run-upgrade economy  ·  effort M
Flutter `UpgradeService`: persisted meta-upgrades + in-run run-upgrades (run_upgrade overlay).
**Done when:** meta-upgrade screen spends meta-currency (persisted) + run-upgrade choices appear mid-run.

### M9 — Narrative + localization  ·  effort L  ·  *couples to M3*
StoryData, WorldChronicles, codex, briefings, cinematics; FText + String Tables (ES/EN). Plus the 4 presenter
screens (story/codex/chronicle/cinematic).
**Done when:** story/codex/briefings render in ES + EN through the UI.

### M10 — FPS / pseudo-3D view mode  ·  effort L
Flutter's BOOST/Overdrive first-person mode. Native `APlayerCameraManager`/camera + Enhanced Input context;
per-tower weapon viewmodel; CRT/glitch post-process; the Overdrive buff.
**Done when:** a key toggles a first-person mode rendering the live board with a cockpit HUD.

### M11 — High-density performance  ·  effort L  ·  *latent until big waves ship*
AActor-per-entity saturates PIE at ~80 enemies. Move high-count short-lived entities to a struct sim in a
`UWorldSubsystem` rendered via ISMC (MassEntity escape hatch); pool projectiles/bursts.
**Done when:** a 100+ enemy wave runs without hitching.

### M12 — Save migration for existing Flutter players  ·  effort M
Flutter→JSON export of `shared_preferences` (level_progress, unlocked_levels, meta_currency, upgrade_levels,
stars) + a UE boot deserializer; do the write-site census first.
**Done when:** an exported Flutter save loads into the UE game with progress intact.

## Suggested execution order
**M1 → M2 → M3 → M4** (the "feels like a real game" wrapper) → **M5, M6, M7** (depth) →
**M8, M9** (meta + story) → **M10, M11, M12** (FPS, scale, migration).

## Cross-cutting / ongoing
- Shader pipeline: showcase materials exist; port the `.frag` uber/post-process pipeline as Materials +
  global uniforms via `MPC_NeonPalette` (a `UWorldSubsystem` pushes time/wave/trauma).
- Keep both MCP servers + the CC0 import pipeline as the production workflow; capture via `capture_viewport`.
