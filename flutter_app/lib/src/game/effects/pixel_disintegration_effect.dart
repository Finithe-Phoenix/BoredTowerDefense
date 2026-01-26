import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Pixel disintegration effect for enemy deaths - breaks enemy into digital pixels
/// that scatter and fade with a cyberpunk aesthetic.
class PixelDisintegrationEffect extends PositionComponent {
  PixelDisintegrationEffect._internal({
    required Vector2 position,
    required Color color,
    required double effectSize,
    required double duration,
  }) : _random = math.Random() {
    _reset(
      position: position,
      color: color,
      effectSize: effectSize,
      duration: duration,
    );
  }

  static const int maxPool = 20;
  static const int maxActive = 15;
  static final List<PixelDisintegrationEffect> _pool = [];
  static int _activeCount = 0;
  static double fxScale = 1.0;
  static bool reduceFx = false;
  static bool lowFx = false;
  static int get activeCount => _activeCount;
  static final Map<int, MaskFilter> _blurCache = {};

  static MaskFilter _blur(double sigma) {
    var key = sigma.round();
    if (key < 1) key = 1;
    if (key > 40) key = 40;
    return _blurCache.putIfAbsent(
      key,
      () => MaskFilter.blur(BlurStyle.normal, key.toDouble()),
    );
  }

  /// Clear the static pool to prevent memory accumulation between games
  static void clearPool() {
    _pool.clear();
    _activeCount = 0;
  }

  static PixelDisintegrationEffect? spawn({
    required Vector2 position,
    required Color color,
    double effectSize = 30.0,
    double duration = 0.8,
  }) {
    if (_activeCount >= maxActive) return null;
    PixelDisintegrationEffect effect;
    if (_pool.isNotEmpty) {
      effect = _pool.removeLast();
      effect._reset(
        position: position,
        color: color,
        effectSize: effectSize,
        duration: duration,
      );
    } else {
      effect = PixelDisintegrationEffect._internal(
        position: position,
        color: color,
        effectSize: effectSize,
        duration: duration,
      );
    }
    effect._markActive();
    return effect;
  }

  Color color = Colors.cyan;
  double effectSize = 30.0;
  double duration = 0.8;

  final List<_DisintegrationPixel> _pixels = [];
  final List<_DataParticle> _dataParticles = [];
  final List<_ScanlineSegment> _scanlines = [];
  double _time = 0;
  final math.Random _random;
  bool _counted = false;
  bool _inPool = false;

  // Flash intensity for final flash
  double _flashIntensity = 0;

  // ═══════════════════════════════════════════════════════════════════════════
  // CACHED PAINT OBJECTS - Avoid per-frame allocations
  // ═══════════════════════════════════════════════════════════════════════════

  // Layer 1: Pixel grid paints
  final Paint _pixelFillPaint = Paint();
  final Paint _pixelGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

  // Layer 2: Pixel fade paints
  final Paint _pixelFadePaint = Paint();

  // Layer 3: Glow effect paints
  final Paint _pixelBrightGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  // Layer 4: Scanline paints
  final Paint _scanlinePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _scanlineCorePaint = Paint();

  // Layer 5: Digital noise paints
  final Paint _noisePaint = Paint();
  final Paint _noiseGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  // Layer 6: Final flash paints
  final Paint _flashOuterPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
  final Paint _flashMidPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
  final Paint _flashCorePaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

  // Layer 7: Residual data particle paints
  final Paint _dataParticlePaint = Paint();
  final Paint _dataParticleGlowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
  final Paint _dataTrailPaint = Paint()
    ..strokeCap = StrokeCap.round
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

  // Reusable path for custom shapes
  final Path _reusablePath = Path();

  void _markActive() {
    if (_counted) return;
    _counted = true;
    _inPool = false;
    _activeCount++;
  }

  void _reset({
    required Vector2 position,
    required Color color,
    required double effectSize,
    required double duration,
  }) {
    this.position.setFrom(position);
    anchor = Anchor.center;
    this.color = color;
    this.effectSize = effectSize;
    this.duration = duration;
    _time = 0;
    _flashIntensity = 0;
    _pixels.clear();
    _dataParticles.clear();
    _scanlines.clear();
    _initializePixels();
    _initializeDataParticles();
    _initializeScanlines();
  }

  void _initializePixels() {
    // Create a grid of pixels that will scatter
    final gridSize = lowFx ? 4 : (reduceFx ? 6 : 8);
    final pixelSize = effectSize / gridSize;
    final pixelCount = _scaledCount(gridSize * gridSize, allowZero: true);

    if (pixelCount == 0) return;

    // Calculate actual grid dimensions based on scaled count
    final actualGrid = math.sqrt(pixelCount).ceil();
    final startOffset = -effectSize / 2;

    int created = 0;
    for (int row = 0; row < actualGrid && created < pixelCount; row++) {
      for (int col = 0; col < actualGrid && created < pixelCount; col++) {
        final gridX = startOffset + col * (effectSize / actualGrid) + pixelSize / 2;
        final gridY = startOffset + row * (effectSize / actualGrid) + pixelSize / 2;

        // Calculate scatter angle from center
        final distFromCenter = math.sqrt(gridX * gridX + gridY * gridY);
        final angleFromCenter = math.atan2(gridY, gridX);

        // Add some randomness to scatter direction
        final scatterAngle = angleFromCenter + (_random.nextDouble() - 0.5) * 0.8;
        final scatterSpeed = 40 + _random.nextDouble() * 80 + distFromCenter * 2;

        // Determine if this pixel should have glow (outer pixels more likely)
        final hasGlow = _random.nextDouble() < (distFromCenter / effectSize) * 0.7;

        // Stagger the start time based on distance from center
        final delay = distFromCenter / effectSize * 0.15 * _random.nextDouble();

        _pixels.add(_DisintegrationPixel(
          startX: gridX,
          startY: gridY,
          angle: scatterAngle,
          speed: scatterSpeed,
          size: pixelSize * (0.8 + _random.nextDouble() * 0.4),
          lifetime: 0.4 + _random.nextDouble() * 0.3,
          delay: delay,
          hasGlow: hasGlow,
          rotationSpeed: (_random.nextDouble() - 0.5) * 15,
          gravity: 30 + _random.nextDouble() * 40,
        ));
        created++;
      }
    }
  }

  void _initializeDataParticles() {
    // These are residual floating particles that linger after disintegration
    final particleCount = _scaledCount(12, allowZero: true);
    if (particleCount == 0) return;

    for (int i = 0; i < particleCount; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final startDist = _random.nextDouble() * effectSize * 0.5;

      _dataParticles.add(_DataParticle(
        startX: math.cos(angle) * startDist,
        startY: math.sin(angle) * startDist,
        driftAngle: angle + (_random.nextDouble() - 0.5) * math.pi,
        driftSpeed: 10 + _random.nextDouble() * 20,
        size: 1.5 + _random.nextDouble() * 2,
        lifetime: 0.5 + _random.nextDouble() * 0.3,
        delay: 0.2 + _random.nextDouble() * 0.2, // Start after main disintegration
        oscillationSpeed: 5 + _random.nextDouble() * 5,
        oscillationAmplitude: 3 + _random.nextDouble() * 4,
      ));
    }
  }

  void _initializeScanlines() {
    // Horizontal scanlines that sweep through the disintegrating form
    final scanlineCount = _scaledCount(4, allowZero: true);
    if (scanlineCount == 0) return;

    for (int i = 0; i < scanlineCount; i++) {
      _scanlines.add(_ScanlineSegment(
        startY: -effectSize / 2 + (i / scanlineCount) * effectSize,
        width: effectSize * (0.6 + _random.nextDouble() * 0.4),
        speed: 80 + _random.nextDouble() * 40,
        thickness: 1.5 + _random.nextDouble() * 1,
        lifetime: 0.2 + _random.nextDouble() * 0.1,
        delay: i * 0.05,
      ));
    }
  }

  int _scaledCount(int base, {bool allowZero = false}) {
    final scaled = (base * fxScale).round();
    if (scaled <= 0 && !allowZero) {
      return 1;
    }
    return scaled;
  }

  /// Get HSL-shifted color for visual variety
  Color _getSecondaryColor(double hueShift) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withHue((hsl.hue + hueShift) % 360).toColor();
  }

  Color _getTertiaryColor(double saturationMult, double lightnessMult) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * saturationMult).clamp(0.0, 1.0))
        .withLightness((hsl.lightness * lightnessMult).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  void update(double dt) {
    super.update(dt);

    _time += dt;
    final progress = _time / duration;

    if (progress >= 1.0) {
      _recycle();
      return;
    }

    // Update flash intensity - peaks at the end
    if (progress > 0.85) {
      final flashProgress = (progress - 0.85) / 0.15;
      _flashIntensity = math.sin(flashProgress * math.pi);
    } else {
      _flashIntensity = 0;
    }

    // Update pixels
    for (final pixel in _pixels) {
      pixel.update(dt);
    }

    // Update data particles
    for (final particle in _dataParticles) {
      particle.update(dt);
    }

    // Update scanlines
    for (final scanline in _scanlines) {
      scanline.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (lowFx) {
      _renderLowFx(canvas);
      return;
    }

    final progress = _time / duration;

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 5: Digital noise/static (behind pixels)
    // ═══════════════════════════════════════════════════════════════════════
    if (!reduceFx) {
      _drawDigitalNoise(canvas, progress);
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 4: Scanline effect
    // ═══════════════════════════════════════════════════════════════════════
    _drawScanlines(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 1 & 2 & 3: Pixel grid with scatter, fade, and glow
    // ═══════════════════════════════════════════════════════════════════════
    _drawPixels(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 7: Residual floating data particles
    // ═══════════════════════════════════════════════════════════════════════
    _drawDataParticles(canvas, progress);

    // ═══════════════════════════════════════════════════════════════════════
    // Layer 6: Final bright flash
    // ═══════════════════════════════════════════════════════════════════════
    if (_flashIntensity > 0) {
      _drawFinalFlash(canvas);
    }
  }

  void _renderLowFx(Canvas canvas) {
    // Simplified rendering for low-end devices
    final progress = _time / duration;
    final fadeOut = 1.0 - progress;

    // Just draw a simple fading circle
    _pixelFillPaint.color = color.withOpacity(fadeOut * 0.5);
    canvas.drawCircle(Offset.zero, effectSize * (1 - progress * 0.5), _pixelFillPaint);

    // Draw a few simple squares scattering
    for (int i = 0; i < _pixels.length && i < 8; i++) {
      final pixel = _pixels[i];
      if (!pixel.isActive) continue;

      final alpha = pixel.alphaValue * fadeOut;
      if (alpha <= 0) continue;

      _pixelFillPaint.color = color.withOpacity(alpha);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(pixel.currentX, pixel.currentY),
          width: pixel.size,
          height: pixel.size,
        ),
        _pixelFillPaint,
      );
    }
  }

  void _drawPixels(Canvas canvas, double progress) {
    final secondaryColor = _getSecondaryColor(30);
    final fadeOut = 1.0 - progress;

    for (final pixel in _pixels) {
      if (!pixel.isActive) continue;

      final alpha = pixel.alphaValue * fadeOut;
      if (alpha <= 0) continue;

      final px = pixel.currentX;
      final py = pixel.currentY;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(pixel.currentRotation);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: pixel.size,
        height: pixel.size,
      );

      // Layer 3: Glow effect for selected pixels
      if (pixel.hasGlow && !reduceFx) {
        _pixelBrightGlowPaint.color = color.withOpacity(alpha * 0.6);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: pixel.size * 1.8,
            height: pixel.size * 1.8,
          ),
          _pixelBrightGlowPaint,
        );
      }

      // Layer 2: Pixel with gradient fade (outer pixels fade faster)
      final distanceFade = (pixel.distance / (effectSize * 2)).clamp(0.0, 1.0);
      _pixelFadePaint.color = Color.lerp(
        color,
        Colors.transparent,
        distanceFade * 0.5,
      )!.withOpacity(alpha);
      canvas.drawRect(rect, _pixelFadePaint);

      // Layer 1: Core pixel with slight color variation
      final pixelColor = _random.nextBool() ? color : secondaryColor;
      _pixelFillPaint.color = pixelColor.withOpacity(alpha * 0.9);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: pixel.size * 0.7,
          height: pixel.size * 0.7,
        ),
        _pixelFillPaint,
      );

      // Subtle inner highlight
      if (!reduceFx && pixel.hasGlow) {
        _pixelGlowPaint.color = Colors.white.withOpacity(alpha * 0.3);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: pixel.size * 0.3,
            height: pixel.size * 0.3,
          ),
          _pixelGlowPaint,
        );
      }

      canvas.restore();
    }
  }

  void _drawScanlines(Canvas canvas, double progress) {
    if (progress > 0.6) return; // Scanlines fade out early

    final scanlineAlpha = (1 - progress / 0.6);
    final tertiaryColor = _getTertiaryColor(0.8, 1.2);

    for (final scanline in _scanlines) {
      if (!scanline.isActive) continue;

      final alpha = scanline.alphaValue * scanlineAlpha;
      if (alpha <= 0) continue;

      final y = scanline.currentY;
      final halfWidth = scanline.width / 2;

      // Outer glow
      _scanlinePaint.color = tertiaryColor.withOpacity(alpha * 0.3);
      canvas.drawLine(
        Offset(-halfWidth, y),
        Offset(halfWidth, y),
        _scanlinePaint..strokeWidth = scanline.thickness * 3,
      );

      // Core bright line
      _scanlineCorePaint
        ..color = Colors.white.withOpacity(alpha * 0.8)
        ..strokeWidth = scanline.thickness;
      canvas.drawLine(
        Offset(-halfWidth, y),
        Offset(halfWidth, y),
        _scanlineCorePaint,
      );

      // Animated segments along the scanline (digital effect)
      if (!reduceFx) {
        final segmentCount = 5;
        for (int i = 0; i < segmentCount; i++) {
          final segX = -halfWidth + (i / segmentCount) * scanline.width;
          final flicker = math.sin(_time * 20 + i * 3) > 0.3 ? 1.0 : 0.3;

          _scanlineCorePaint.color = color.withOpacity(alpha * flicker * 0.6);
          canvas.drawRect(
            Rect.fromLTWH(segX, y - 1, scanline.width / segmentCount * 0.8, 2),
            _scanlineCorePaint,
          );
        }
      }
    }
  }

  void _drawDigitalNoise(Canvas canvas, double progress) {
    if (progress > 0.5) return; // Noise fades out mid-effect

    final noiseAlpha = (1 - progress / 0.5) * 0.4;
    final noiseCount = _scaledCount(20, allowZero: true);

    for (int i = 0; i < noiseCount; i++) {
      // Use time-based randomization for animated noise
      final noiseX = (math.sin(_time * 30 + i * 7) * 0.5 + 0.5 - 0.5) * effectSize * 1.2;
      final noiseY = (math.cos(_time * 25 + i * 11) * 0.5 + 0.5 - 0.5) * effectSize * 1.2;

      // Only draw noise within the effect area
      final distFromCenter = math.sqrt(noiseX * noiseX + noiseY * noiseY);
      if (distFromCenter > effectSize * (1 - progress * 0.5)) continue;

      final noiseSize = 1 + (math.sin(_time * 50 + i) * 0.5 + 0.5) * 2;
      final flicker = math.sin(_time * 40 + i * 5) > 0 ? 1.0 : 0.3;

      // Random RGB channels for glitch effect
      final channelChoice = ((_time * 10 + i) % 3).floor();
      Color noiseColor;
      switch (channelChoice) {
        case 0:
          noiseColor = const Color(0xFFFF0000);
          break;
        case 1:
          noiseColor = const Color(0xFF00FF00);
          break;
        default:
          noiseColor = const Color(0xFF0000FF);
      }

      _noisePaint.color = noiseColor.withOpacity(noiseAlpha * flicker);
      canvas.drawRect(
        Rect.fromCenter(center: Offset(noiseX, noiseY), width: noiseSize, height: noiseSize),
        _noisePaint,
      );
    }
  }

  void _drawDataParticles(Canvas canvas, double progress) {
    final secondaryColor = _getSecondaryColor(-20);

    for (final particle in _dataParticles) {
      if (!particle.isActive) continue;

      final alpha = particle.alphaValue * (1 - progress);
      if (alpha <= 0) continue;

      final px = particle.currentX;
      final py = particle.currentY;

      // Draw trail
      if (!reduceFx && particle.prevX != 0) {
        _dataTrailPaint
          ..color = secondaryColor.withOpacity(alpha * 0.3)
          ..strokeWidth = particle.size * 0.5;
        canvas.drawLine(
          Offset(particle.prevX, particle.prevY),
          Offset(px, py),
          _dataTrailPaint,
        );
      }

      // Particle glow
      _dataParticleGlowPaint.color = color.withOpacity(alpha * 0.4);
      canvas.drawCircle(Offset(px, py), particle.size * 1.5, _dataParticleGlowPaint);

      // Particle core (alternating shape based on index)
      _dataParticlePaint.color = Colors.white.withOpacity(alpha * 0.8);

      // Some particles are dots, some are small squares
      if (_dataParticles.indexOf(particle) % 3 == 0) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset(px, py), width: particle.size, height: particle.size),
          _dataParticlePaint,
        );
      } else {
        canvas.drawCircle(Offset(px, py), particle.size * 0.5, _dataParticlePaint);
      }
    }
  }

  void _drawFinalFlash(Canvas canvas) {
    final flashRadius = effectSize * 0.6 * _flashIntensity;

    // Outer soft glow
    _flashOuterPaint.color = color.withOpacity(_flashIntensity * 0.2);
    canvas.drawCircle(Offset.zero, flashRadius * 2, _flashOuterPaint);

    // Mid glow
    _flashMidPaint.color = color.withOpacity(_flashIntensity * 0.4);
    canvas.drawCircle(Offset.zero, flashRadius * 1.2, _flashMidPaint);

    // Core bright flash
    _flashCorePaint.color = Colors.white.withOpacity(_flashIntensity * 0.8);
    canvas.drawCircle(Offset.zero, flashRadius * 0.5, _flashCorePaint);

    // RGB chromatic aberration on flash
    if (!reduceFx) {
      final offset = 3 * _flashIntensity;

      _flashMidPaint.color = const Color(0xFFFF0000).withOpacity(_flashIntensity * 0.2);
      canvas.drawCircle(Offset(-offset, 0), flashRadius, _flashMidPaint);

      _flashMidPaint.color = const Color(0xFF0000FF).withOpacity(_flashIntensity * 0.2);
      canvas.drawCircle(Offset(offset, 0), flashRadius, _flashMidPaint);
    }
  }

  void _recycle() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    if (parent != null) {
      removeFromParent();
    }
    if (_inPool) return;
    if (_pool.length < maxPool) {
      _inPool = true;
      _pool.add(this);
    }
  }

  @override
  void onRemove() {
    if (_counted) {
      if (_activeCount > 0) {
        _activeCount -= 1;
      }
      _counted = false;
    }
    super.onRemove();
  }
}

/// Individual pixel in the disintegration grid
class _DisintegrationPixel {
  _DisintegrationPixel({
    required this.startX,
    required this.startY,
    required this.angle,
    required this.speed,
    required this.size,
    required this.lifetime,
    required this.delay,
    required this.hasGlow,
    required this.rotationSpeed,
    required this.gravity,
  }) : _time = 0,
       distance = 0,
       currentRotation = 0,
       _velocityY = 0;

  final double startX;
  final double startY;
  final double angle;
  final double speed;
  final double size;
  final double lifetime;
  final double delay;
  final bool hasGlow;
  final double rotationSpeed;
  final double gravity;

  double _time;
  double distance;
  double currentRotation;
  double _velocityY;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get currentX => startX + math.cos(angle) * distance;
  double get currentY => startY + math.sin(angle) * distance + _velocityY;

  void update(double dt) {
    _time += dt;
    if (_time > delay) {
      final activeTime = _time - delay;
      final decay = 1 - activeTime / lifetime * 0.4;
      distance += speed * dt * decay;
      currentRotation += rotationSpeed * dt;
      _velocityY += gravity * dt * dt * 20; // Subtle gravity pull
    }
  }
}

/// Floating data particle that lingers after disintegration
class _DataParticle {
  _DataParticle({
    required this.startX,
    required this.startY,
    required this.driftAngle,
    required this.driftSpeed,
    required this.size,
    required this.lifetime,
    required this.delay,
    required this.oscillationSpeed,
    required this.oscillationAmplitude,
  }) : _time = 0,
       _prevX = 0,
       _prevY = 0;

  final double startX;
  final double startY;
  final double driftAngle;
  final double driftSpeed;
  final double size;
  final double lifetime;
  final double delay;
  final double oscillationSpeed;
  final double oscillationAmplitude;

  double _time;
  double _prevX;
  double _prevY;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get prevX => _prevX;
  double get prevY => _prevY;

  double get currentX {
    if (_time <= delay) return startX;
    final activeTime = _time - delay;
    final baseX = startX + math.cos(driftAngle) * driftSpeed * activeTime;
    final oscillation = math.sin(activeTime * oscillationSpeed) * oscillationAmplitude;
    return baseX + math.cos(driftAngle + math.pi / 2) * oscillation;
  }

  double get currentY {
    if (_time <= delay) return startY;
    final activeTime = _time - delay;
    final baseY = startY + math.sin(driftAngle) * driftSpeed * activeTime;
    final oscillation = math.sin(activeTime * oscillationSpeed) * oscillationAmplitude;
    return baseY + math.sin(driftAngle + math.pi / 2) * oscillation - activeTime * 10; // Float upward
  }

  void update(double dt) {
    _prevX = currentX;
    _prevY = currentY;
    _time += dt;
  }
}

/// Scanline segment that sweeps through the disintegrating form
class _ScanlineSegment {
  _ScanlineSegment({
    required this.startY,
    required this.width,
    required this.speed,
    required this.thickness,
    required this.lifetime,
    required this.delay,
  }) : _time = 0;

  final double startY;
  final double width;
  final double speed;
  final double thickness;
  final double lifetime;
  final double delay;

  double _time;

  bool get isActive => _time > delay && _time < lifetime + delay;

  double get alphaValue {
    if (_time <= delay) return 0;
    final activeTime = _time - delay;
    return (1 - activeTime / lifetime).clamp(0.0, 1.0);
  }

  double get currentY {
    if (_time <= delay) return startY;
    final activeTime = _time - delay;
    return startY + speed * activeTime;
  }

  void update(double dt) {
    _time += dt;
  }
}
