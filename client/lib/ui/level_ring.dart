import 'package:flutter/material.dart';

class LevelRing extends StatelessWidget {
  final int xp;
  final int perLevel;
  final double size;
  const LevelRing({super.key, required this.xp, this.perLevel = 100, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final level = (xp ~/ perLevel) + 1;
    final pct = ((xp % perLevel) / perLevel).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(size: Size.square(size), painter: _RingPainter(pct: pct, color: Theme.of(context).colorScheme.primary)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Lv $level', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('${(pct * 100).round()}%', style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          )
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
    final center = Offset(size.width/2, size.height/2);
    final r = (size.shortestSide - stroke) / 2;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0x33FFFFFF)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), 0, 6.28318530718, false, bg);

    final arcAngle = pct * 6.28318530718;
    if (arcAngle <= 0.0001) return;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = SweepGradient(colors: [color.withOpacity(0.9), const Color(0xFF3B969D).withOpacity(0.9)], startAngle: -1.5708, endAngle: -1.5708 + arcAngle)
          .createShader(Rect.fromCircle(center: center, radius: r))
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), -1.5708, arcAngle, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.pct != pct || oldDelegate.color != color;
}
