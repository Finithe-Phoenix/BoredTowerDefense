# PERF OPT PLAN (ANDROID/IOS PRIORITY)

Goal: keep gameplay smooth on mid-range Android/iOS when enemies cluster and VFX stack.

Targets
- [ ] 60 FPS on mid devices (frame budget ~16.6 ms).
- [ ] 30 FPS minimum on low-end (frame budget ~33.3 ms).
- [ ] No long jank (>120 ms) during peak waves.
- [ ] Memory steady during long sessions (no continuous growth).

Phase 0 - Baseline and profiling (must do first)
- [ ] Run in profile/release, not debug.
- [ ] Capture FPS and frame time during peak wave (>= 30 enemies).
- [ ] Record CPU/GPU hotspots using DevTools or Flame profiling.
- [ ] Note top 3 expensive functions.
- [ ] Define device tiers (low, mid, high) for testing.

Phase 1 - Quick wins (highest ROI)
- [x] Cache the world background to a single image and blit each frame.
  - [x] Pre-render map tiles and static decor in GameWorld on load.
  - [ ] Only rebuild cached image when map changes or on resize.
- [x] HUD caching to avoid per-frame TextPainter work.
  - [x] Cache top bar values and only repaint when values change.
  - [ ] Cache gradients, paints, and static geometry.
- [x] Throttle shader uniform updates (10-15 Hz).
  - [x] Update shader texture only every N frames.
  - [x] Skip updates when no towers/enemies on screen.
- [ ] Pool bullets, particles, floating texts to reduce GC.
  - [x] Reuse bullets via pooling.
  - [x] Reuse floating texts via pooling.
  - [x] Pool particle-heavy effects (impact/explosion).
- [ ] Cap VFX counts (particles, pulses, glows) with a hard limit.
  - [x] Cap impact/explosion effects with max-active limits.
  - [ ] Cap particle bursts and trails at high enemy counts.

Phase 2 - Rendering and VFX
- [ ] Replace per-tile drawing with SpriteBatch or cached atlas.
- [ ] Precompute repeated Path and gradient objects once.
- [ ] Reduce blur and glow usage in hot paths.
  - [ ] Use simpler paints in low quality.
  - [ ] Disable blur when FPS drops below target.
- [x] LOD VFX: fewer particles and effects at higher enemy counts.
  - [x] Reduce enemy trails/particles when alive count is high.
- [ ] Lower shader resolution (half-res and upscale).

Phase 3 - Simulation (CPU)
- [x] Avoid building lists from children every frame.
  - [x] Maintain active enemy/tower lists on add/remove.
- [ ] Spatial partitioning for targeting.
  - [ ] Grid or hash by tile to avoid O(towers * enemies).
- [ ] Fixed time step for heavy updates (e.g., 30 Hz targeting).
- [ ] Offscreen or distant entities update at lower rate.

Phase 4 - Adaptive quality (mobile focus)
- [ ] Quality presets: Low, Medium, High.
- [ ] Auto degrade quality if FPS < target for 2-3 seconds.
- [ ] Persist quality choice per device tier.
- [ ] Disable expensive effects on low-end by default.

Phase 5 - Asset and build hygiene
- [ ] Verify texture sizes and compress where possible.
- [ ] Ensure release build is used for production tests.
- [ ] Remove debug logs in hot loops.

Implementation order for mobile priority
- [ ] Phase 0 baseline
- [ ] Phase 1 (cache world + HUD caching + pooling)
- [ ] Phase 2 (render pipeline simplification)
- [ ] Phase 3 (simulation optimizations)
- [ ] Phase 4 (adaptive quality)
- [ ] Phase 5 (asset cleanup)

Success criteria
- [ ] Stable 60 FPS on mid devices during peak waves.
- [ ] No visible hitching when enemies cluster.
- [ ] Consistent frame time without spikes during VFX bursts.

Notes
- Prefer CanvasKit on web, but Android/iOS is primary target here.
- Avoid per-frame allocations in render/update loops.
