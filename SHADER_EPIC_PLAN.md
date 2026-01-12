# SHADER EPIC PLAN

> Context: The goal is to build "Mesozoic" neon shaders for the tower defense game - liquid neon, cyber-organic, high-end GPU flair while remaining mobile-friendly (60 FPS baseline, optional 144 Hz headroom). This file tracks shader deliverables from infra to polish.

## Phase 1 - Shader Infrastructure (Foundation)
- [x] 1.1 ShaderManager + cache - `flutter_app/lib/src/game/effects/shaders/shader_manager.dart` compiles/loads fragment programs, exposes descriptors, and caches noise textures.
- [x] 1.2 Noise texture - `noise_texture.dart` procedurally generates a 512x512 noise image for shader sampling without shipping a PNG.
- [x] 1.3 Bit packing - `flag_packer.dart` packs/unpacks up to 32 boolean flags plus Flutter tests for compact uniform bitfields.

## Phase 2 - The World (Grid + Background)
- [x] 2.1 World uber-shader - `assets/shaders/world_uber_shader.sksl` drives scanline gradients and pointer pulses.
- [x] 2.2 World renderer - `WorldUberShaderComponent` feeds `uResolution`, `uTime`, `uPointer`, and `uWaveIntensity` each frame.
- [x] 2.3 Dynamic warp - UV warp, wave intensity, and scanline shimmer are now baked into the SkSL shader.

## Phase 3 - Entities (Towers, Particles, HUD)
- [x] 3.1 Entity uniforms - `ShaderUniformController` records the first 10 tower/enemy positions into Float32Lists for SkSL.
- [x] 3.2 Metaballs + SDF - `world_uber_shader.sksl` blends tower/enemy fields with smooth SDF logic.
- [x] 3.3 Glow pass + chroma - entity glow now adds chromatic tint for plasma highlights.
- [x] 3.4 Particle shader - `particle_trail_shader.sksl` + `ParticleShaderComponent` add GPU-driven ambient trails.

## Phase 4 - Screen Juice + Performance
- [x] 4.1 Post-process pipeline - `ScreenPostProcessComponent` + `post_process_master.sksl` add vignette and chroma pulse overlays.
- [x] 4.2 Trauma system - `ScreenEffects` tracks trauma (decays over time), fed by `VisualDirector` on leaks/kills/mines/pulses.
- [x] 4.3 Performance presets - `assets/config/shader_presets.json` + `shader_presets.dart` loader define Ultra/Balanced/Eco tuning.

## Next Up
1. Validate shader compilation and asset loading on Web and mobile.
2. Profile FPS in Ultra/Balanced/Eco and tune values in `assets/config/shader_presets.json`.
3. Adjust trauma/overlay intensity for readability and reduce overdraw if needed.
