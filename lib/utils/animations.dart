import 'package:flutter/material.dart';

/// Reusable animation curves and durations for consistent motion design
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 500);
  
  // Curves
  static const Curve easeOut = Curves.easeOut;
static const Curve easeIn = Curves.easeIn;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve spring = Curves.elasticOut;
  static const Curve bounce = Curves.bounceOut;
  
  // Common transitions
  static Curve get defaultCurve => smooth;
  static Duration get defaultDuration => normal;
}

/// Extension for adding hover animations to any widget
extension HoverExtension on Widget {
  Widget withHoverScale({
    double scale = 1.05,
    Duration duration = const Duration(milliseconds: 150),
    Curve curve = Curves.easeOut,
  }) {
    return _HoverScaleWrapper(
      scale: scale,
      duration: duration,
      curve: curve,
 child: this,
    );
  }
  
  Widget withHoverOpacity({
    double opacity = 0.8,
    Duration duration = const Duration(milliseconds: 150),
  }) {
    return _HoverOpacityWrapper(
      opacity: opacity,
      duration: duration,
      child: this,
 );
  }
}

class _HoverScaleWrapper extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;
  
  const _HoverScaleWrapper({
    required this.child,
 required this.scale,
    required this.duration,
    required this.curve,
  });
  
  @override
  State<_HoverScaleWrapper> createState() => _HoverScaleWrapperState();
}

class _HoverScaleWrapperState extends State<_HoverScaleWrapper> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
   scale: _isHovered ? widget.scale : 1.0,
        duration: widget.duration,
      curve: widget.curve,
        child: widget.child,
 ),
    );
  }
}

class _HoverOpacityWrapper extends StatefulWidget {
  final Widget child;
  final double opacity;
  final Duration duration;
  
const _HoverOpacityWrapper({
    required this.child,
  required this.opacity,
    required this.duration,
  });
  
  @override
  State<_HoverOpacityWrapper> createState() => _HoverOpacityWrapperState();
}

class _HoverOpacityWrapperState extends State<_HoverOpacityWrapper> {
  bool _isHovered = false;
  
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
  onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedOpacity(
        opacity: _isHovered ? widget.opacity : 1.0,
   duration: widget.duration,
      child: widget.child,
      ),
    );
  }
}

/// Shimmer loading animation builder
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;
  
  const ShimmerLoading({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor = const Color(0xFF1A1A1A),
    this.highlightColor = const Color(0xFF2A2A2A),
  });
  
  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
  with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
   blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
  begin: Alignment.topLeft,
     end: Alignment.bottomRight,
       colors: [
     widget.baseColor,
       widget.highlightColor,
      widget.baseColor,
 ],
      stops: [
   0.0,
        _controller.value,
          1.0,
         ],
            ).createShader(bounds);
        },
          child: child,
    );
      },
    );
  }
}
