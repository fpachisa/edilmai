import 'package:flutter/material.dart';

class MasteryRing extends StatelessWidget {
  final String label;
  final double progress; // 0.0..1.0
  final double size;
  final VoidCallback? onTap;

  const MasteryRing({
    super.key,
    required this.label,
    required this.progress,
    this.size = 88,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pct = progress.clamp(0.0, 1.0);
    final ring = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(pct: pct, color: Theme.of(context).colorScheme.primary),
        child: Center(
          child: Text('${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ring,
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double pct;
  final Color color;
  _RingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 8.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final r = (size.shortestSide - stroke) / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x33FFFFFF)
      ..strokeCap = StrokeCap.round;

    final arcAngle = pct * 6.28318530718; // 2*pi
    // background circle
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 0, 6.28318530718, false, bg);

    if (arcAngle <= 0.0001) {
      // Avoid zero-length gradient arcs which can crash on web
      return;
    }

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(
        colors: [color.withOpacity(0.9), const Color(0xFF3B969D).withOpacity(0.9)],
        startAngle: -1.5708,
        endAngle: -1.5708 + arcAngle,
      ).createShader(Rect.fromCircle(center: center, radius: r))
      ..strokeCap = StrokeCap.round;
    // progress arc starting from top (-90deg)
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -1.5708, arcAngle, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}
