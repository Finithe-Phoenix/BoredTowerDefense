import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/neon_theme.dart';
import '../widgets/glitch_text.dart';
import '../widgets/epic_neon_button.dart';

class BriefingOverlay extends StatefulWidget {
  final int levelId;
  final VoidCallback onDismiss;

  const BriefingOverlay({
    super.key,
    required this.levelId,
    required this.onDismiss,
  });

  @override
  State<BriefingOverlay> createState() => _BriefingOverlayState();
}

class _BriefingOverlayState extends State<BriefingOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isVisible = true;

  String get _briefingText {
    if (widget.levelId == 1) return 'BRECHA DETECTADA EN EL SECTOR 0. EL DECOMPILER HA EMPEZADO EL FORMATEO. DESPLIEGA ANCLAS DE ARQUIA INMEDIATAMENTE.';
    if (widget.levelId == 11) return 'ANOMALÍAS EN LA MALLA. EL VIRUS ESTÁ USANDO GRIETAS PARA SALTAR LA SEGURIDAD. ADÁPTATE O SÉ ELIMINADO.';
    if (widget.levelId == 21) return 'ZONA DE SILENCIO. LA SEÑAL ES DÉBIL. EL ENEMIGO ACECHA EN EL RUIDO. ILUMINA EL CAMINO.';
    return 'ESTADO DEL SISTEMA: INESTABLE. CONTINÚA LA RESTAURACIÓN.';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: NeonColors.darkBg,
              border: Border.all(color: NeonColors.cyan, width: 2),
              boxShadow: [
                BoxShadow(color: NeonColors.cyan.withOpacity(0.3), blurRadius: 40, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: NeonColors.cyan, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'BRIEFING DE MISIÓN',
                        style: NeonTextStyles.subtitle.copyWith(color: NeonColors.cyan, letterSpacing: 4),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: NeonColors.cyan, thickness: 1),
                const SizedBox(height: 24),
                GlitchText(
                  text: _briefingText,
                  style: NeonTextStyles.body.copyWith(color: NeonColors.white, height: 1.5, fontSize: 16),
                  duration: const Duration(seconds: 4),
                ),
                const SizedBox(height: 40),
                EpicNeonButton(
                  text: 'EJECUTAR',
                  color: NeonColors.cyan,
                  onPressed: () {
                    _controller.reverse().then((_) {
                      setState(() => _isVisible = false);
                      widget.onDismiss();
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
