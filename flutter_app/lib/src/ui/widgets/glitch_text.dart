import 'dart:async';
import 'package:flutter/material.dart';

class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration duration;
  final Color glitchColor;

  const GlitchText({
    super.key,
    required this.text,
    this.style,
    this.duration = const Duration(milliseconds: 2000),
    this.glitchColor = Colors.cyan,
  });

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText> with SingleTickerProviderStateMixin {
  late String _displayedText;
  late Timer _timer;
  int _charIndex = 0;
  int _rngState = 0x1f123bb5;
  int _lcgNext() {
    _rngState = (1664525 * _rngState + 1013904223) & 0x7fffffff;
    return _rngState;
  }
  int _nextInt(int max) => max <= 0 ? 0 : _lcgNext() % max;
  
  // Character set for glitching
  static const _glitchChars = r'!@#$%^&*()_+-=[]{}|;:,.<>/?æøå01';

  @override
  void initState() {
    super.initState();
    _displayedText = '';
    _startAnimation();
  }

  void _startAnimation() {
    final charDuration = widget.duration.inMilliseconds ~/ widget.text.length;
    _timer = Timer.periodic(Duration(milliseconds: charDuration), (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _charIndex++;
          _updateText();
        });
      } else {
        _timer.cancel();
        // Final polish to remove glitch chars
        setState(() {
          _displayedText = widget.text;
        });
      }
    });
  }

  void _updateText() {
    final baseText = widget.text.substring(0, _charIndex);
    if (_charIndex < widget.text.length) {
      // Add a couple of random glitch characters at the end
      String suffix = '';
      for (int i = 0; i < 2; i++) {
        suffix += _glitchChars[_nextInt(_glitchChars.length)];
      }
      _displayedText = baseText + suffix;
    } else {
      _displayedText = baseText;
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.style,
    );
  }
}
