import 'package:flutter/material.dart';

/// Lightweight shimmer effect without external deps.
/// Wrap any placeholder child to show an animated shimmer sweep.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.baseColor = const Color(0x22FFFFFF),
    this.highlightColor = const Color(0x55FFFFFF),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // Sweep from left (-1) to right (2) so gradient fully passes through
        final t = _c.value * 3 - 1; // range [-1, 2]
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment(-1 + t, 0),
              end: Alignment(1 + t, 0),
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

