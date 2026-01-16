import 'package:flutter/material.dart';
import '../widgets/tron_materialization_widget.dart';
import '../theme/neon_theme.dart';

/// Custom page route with Tron-style materialization effect
class TronPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration _transitionDuration;
  final TronPattern pattern;

  TronPageRoute({
    required this.builder,
    this.primaryColor = NeonColors.cyan,
    this.secondaryColor = const Color(0xFFFF6600), // Orange
    Duration transitionDuration = const Duration(milliseconds: 800),
    this.pattern = TronPattern.lightCycle,
    RouteSettings? settings,
  }) : _transitionDuration = transitionDuration, super(settings: settings);

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return TronMaterializationWidget(
      duration: _transitionDuration,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      autoStart: true,
      pattern: pattern,
      child: builder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade transition combined with materialization
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Hexagonal pattern page route for special transitions
class TronHexPageRoute<T> extends TronPageRoute<T> {
  TronHexPageRoute({
    required super.builder,
    super.primaryColor,
    super.secondaryColor,
    super.transitionDuration = const Duration(milliseconds: 1000),
    super.settings,
  }) : super(pattern: TronPattern.hexagonal);
}

/// Radial pattern page route for dramatic reveals
class TronRadialPageRoute<T> extends TronPageRoute<T> {
  TronRadialPageRoute({
    required super.builder,
    super.primaryColor,
    super.secondaryColor,
    super.transitionDuration = const Duration(milliseconds: 900),
    super.settings,
  }) : super(pattern: TronPattern.radial);
}

/// Grid pattern page route for standard screens
class TronGridPageRoute<T> extends TronPageRoute<T> {
  TronGridPageRoute({
    required super.builder,
    super.primaryColor,
    super.secondaryColor,
    super.transitionDuration = const Duration(milliseconds: 800),
    super.settings,
  }) : super(pattern: TronPattern.grid);
}
