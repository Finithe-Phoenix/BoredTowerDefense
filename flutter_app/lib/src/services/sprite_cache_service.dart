import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// SPRITE CACHE SERVICE
/// Pre-renders complex visual elements to images for faster rendering
/// This eliminates per-frame Paint allocations and expensive blur operations
/// ═══════════════════════════════════════════════════════════════════════════

class SpriteCacheService {
  SpriteCacheService._();
  static final SpriteCacheService instance = SpriteCacheService._();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  // LRU cache limit - max colors to cache before eviction
  static const int _maxCacheSize = 20;

  // LRU tracking - LinkedHashSet for O(1) remove + add (insertion order preserved)
  final Set<int> _accessOrder = <int>{};

  // Cached projectile sprites by color hash
  final Map<int, ui.Image> _projectileSprites = {};
  final Map<int, ui.Image> _projectileGlowSprites = {};

  // Cached impact effect sprites
  final Map<int, ui.Image> _impactSprites = {};
  final Map<int, ui.Image> _impactRingSprites = {};

  // Cached enemy glow sprites
  final Map<int, ui.Image> _enemyGlowSprites = {};

  // Common colors used in the game
  static const List<Color> _commonColors = [
    Color(0xFF00FFFF), // Cyan - Pulse Archer
    Color(0xFFFF6600), // Orange - Circuit Cannon
    Color(0xFF9933FF), // Purple - Phase Mage
    Color(0xFFFFFF00), // Yellow - Glimmer Field
    Color(0xFF00FF00), // Green - Ion Sniper
    Color(0xFFFF0066), // Magenta - Overloaded enemy
    Color(0xFF9C27B0), // Purple - Juggernaut
    Color(0xFFFF7043), // Orange - Runner
    Color(0xFF00FFAA), // Teal - Phantom
    Color(0xFFFF3344), // Red - Threat
    Color(0xFFFFFFFF), // White - Generic
  ];

  /// Initialize the sprite cache - call during loading screen
  Future<void> initialize() async {
    if (_initialized) return;

    // Pre-render sprites for all common colors
    for (final color in _commonColors) {
      await _prerenderProjectileSprites(color);
      await _prerenderImpactSprites(color);
      await _prerenderEnemyGlowSprite(color);
    }

    _initialized = true;
  }

  /// Get cached projectile sprite or create on-demand
  ui.Image? getProjectileSprite(Color color) {
    final key = color.value;
    return _projectileSprites[key];
  }

  /// Get cached projectile glow sprite
  ui.Image? getProjectileGlowSprite(Color color) {
    final key = color.value;
    return _projectileGlowSprites[key];
  }

  /// Get cached impact sprite
  ui.Image? getImpactSprite(Color color) {
    final key = color.value;
    return _impactSprites[key];
  }

  /// Get cached impact ring sprite
  ui.Image? getImpactRingSprite(Color color) {
    final key = color.value;
    return _impactRingSprites[key];
  }

  /// Get cached enemy glow sprite
  ui.Image? getEnemyGlowSprite(Color color) {
    final key = color.value;
    return _enemyGlowSprites[key];
  }

  /// Pre-render a sprite for a new color (on-demand) with LRU eviction
  Future<void> ensureColorCached(Color color) async {
    final key = color.value;

    // If already cached, move to end (most recently used)
    if (_projectileSprites.containsKey(key)) {
      _accessOrder.remove(key);
      _accessOrder.add(key);
      return;
    }

    // Evict oldest entries if cache is full - O(1) with LinkedHashSet
    while (_accessOrder.length >= _maxCacheSize) {
      final oldestKey = _accessOrder.first;
      _accessOrder.remove(oldestKey);
      _evictColorFromAllCaches(oldestKey);
    }

    // Cache the new color
    await _prerenderProjectileSprites(color);
    await _prerenderImpactSprites(color);
    await _prerenderEnemyGlowSprite(color);

    _accessOrder.add(key);
  }

  /// Evict a color from all sprite caches to free GPU memory
  void _evictColorFromAllCaches(int key) {
    _projectileSprites[key]?.dispose();
    _projectileSprites.remove(key);

    _projectileGlowSprites[key]?.dispose();
    _projectileGlowSprites.remove(key);

    _impactSprites[key]?.dispose();
    _impactSprites.remove(key);

    _impactRingSprites[key]?.dispose();
    _impactRingSprites.remove(key);

    _enemyGlowSprites[key]?.dispose();
    _enemyGlowSprites.remove(key);
  }

  Future<void> _prerenderProjectileSprites(Color color) async {
    final key = color.value;

    // Projectile core sprite (16x16)
    const coreSize = 16.0;
    final coreRecorder = ui.PictureRecorder();
    final coreCanvas = Canvas(coreRecorder);

    // Draw arrow shape
    final arrowPath = Path()
      ..moveTo(coreSize * 0.9, coreSize / 2)
      ..lineTo(coreSize * 0.2, coreSize * 0.2)
      ..lineTo(coreSize * 0.35, coreSize / 2)
      ..lineTo(coreSize * 0.2, coreSize * 0.8)
      ..close();

    coreCanvas.drawPath(
      arrowPath,
      Paint()..color = color.withOpacity(0.9),
    );

    // Bright center
    coreCanvas.drawCircle(
      Offset(coreSize * 0.7, coreSize / 2),
      coreSize * 0.15,
      Paint()..color = Colors.white,
    );

    final corePicture = coreRecorder.endRecording();
    _projectileSprites[key] = await corePicture.toImage(
      coreSize.toInt(),
      coreSize.toInt(),
    );

    // Projectile glow sprite (32x32) - with blur pre-baked
    const glowSize = 32.0;
    final glowRecorder = ui.PictureRecorder();
    final glowCanvas = Canvas(glowRecorder);

    // Multiple layers of glow for soft effect
    for (int i = 4; i >= 0; i--) {
      final radius = glowSize * 0.15 + i * 2;
      final opacity = 0.15 - i * 0.025;
      glowCanvas.drawCircle(
        Offset(glowSize / 2, glowSize / 2),
        radius,
        Paint()..color = color.withOpacity(opacity.clamp(0.02, 0.15)),
      );
    }

    // Core glow
    glowCanvas.drawCircle(
      Offset(glowSize / 2, glowSize / 2),
      glowSize * 0.12,
      Paint()..color = color.withOpacity(0.6),
    );

    final glowPicture = glowRecorder.endRecording();
    _projectileGlowSprites[key] = await glowPicture.toImage(
      glowSize.toInt(),
      glowSize.toInt(),
    );
  }

  Future<void> _prerenderImpactSprites(Color color) async {
    final key = color.value;

    // Impact burst sprite (48x48)
    const burstSize = 48.0;
    final burstRecorder = ui.PictureRecorder();
    final burstCanvas = Canvas(burstRecorder);
    final center = Offset(burstSize / 2, burstSize / 2);

    // Outer glow layers
    for (int i = 5; i >= 0; i--) {
      final radius = burstSize * 0.1 + i * 3;
      final opacity = 0.2 - i * 0.03;
      burstCanvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withOpacity(opacity.clamp(0.02, 0.2)),
      );
    }

    // Core
    burstCanvas.drawCircle(
      center,
      burstSize * 0.08,
      Paint()..color = color.withOpacity(0.8),
    );

    // Bright center
    burstCanvas.drawCircle(
      center,
      burstSize * 0.04,
      Paint()..color = Colors.white.withOpacity(0.9),
    );

    final burstPicture = burstRecorder.endRecording();
    _impactSprites[key] = await burstPicture.toImage(
      burstSize.toInt(),
      burstSize.toInt(),
    );

    // Impact ring sprite (64x64)
    const ringSize = 64.0;
    final ringRecorder = ui.PictureRecorder();
    final ringCanvas = Canvas(ringRecorder);
    final ringCenter = Offset(ringSize / 2, ringSize / 2);

    // Multiple ring layers
    for (int i = 3; i >= 0; i--) {
      final radius = ringSize * 0.2 + i * 4;
      final strokeWidth = 3.0 - i * 0.5;
      final opacity = 0.4 - i * 0.1;
      ringCanvas.drawCircle(
        ringCenter,
        radius,
        Paint()
          ..color = color.withOpacity(opacity.clamp(0.1, 0.4))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }

    final ringPicture = ringRecorder.endRecording();
    _impactRingSprites[key] = await ringPicture.toImage(
      ringSize.toInt(),
      ringSize.toInt(),
    );
  }

  Future<void> _prerenderEnemyGlowSprite(Color color) async {
    final key = color.value;

    // Enemy glow sprite (64x64)
    const glowSize = 64.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(glowSize / 2, glowSize / 2);

    // Outer glow layers (simulates blur)
    for (int i = 8; i >= 0; i--) {
      final radius = glowSize * 0.15 + i * 2.5;
      final opacity = 0.12 - i * 0.012;
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withOpacity(opacity.clamp(0.01, 0.12)),
      );
    }

    // Inner glow
    canvas.drawCircle(
      center,
      glowSize * 0.18,
      Paint()..color = color.withOpacity(0.3),
    );

    final picture = recorder.endRecording();
    _enemyGlowSprites[key] = await picture.toImage(
      glowSize.toInt(),
      glowSize.toInt(),
    );
  }

  /// Clear all cached sprites (for memory management)
  void dispose() {
    for (final sprite in _projectileSprites.values) {
      sprite.dispose();
    }
    for (final sprite in _projectileGlowSprites.values) {
      sprite.dispose();
    }
    for (final sprite in _impactSprites.values) {
      sprite.dispose();
    }
    for (final sprite in _impactRingSprites.values) {
      sprite.dispose();
    }
    for (final sprite in _enemyGlowSprites.values) {
      sprite.dispose();
    }

    _projectileSprites.clear();
    _projectileGlowSprites.clear();
    _impactSprites.clear();
    _impactRingSprites.clear();
    _enemyGlowSprites.clear();
    _accessOrder.clear();

    _initialized = false;
  }
}

/// Extension to draw cached sprites easily
extension CachedSpriteCanvas on Canvas {
  /// Draw a cached sprite centered at position with optional rotation and scale
  void drawCachedSprite(
    ui.Image sprite,
    Offset center, {
    double rotation = 0,
    double scale = 1.0,
    double opacity = 1.0,
  }) {
    save();
    translate(center.dx, center.dy);
    if (rotation != 0) {
      rotate(rotation);
    }
    if (scale != 1.0) {
      this.scale(scale, scale);
    }

    final paint = Paint();
    if (opacity < 1.0) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }

    drawImage(
      sprite,
      Offset(-sprite.width / 2, -sprite.height / 2),
      paint,
    );
    restore();
  }
}
