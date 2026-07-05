import 'dart:math' as math;
import 'package:flutter/material.dart';

class ConstellationBackground extends StatefulWidget {
  const ConstellationBackground({super.key});
  @override
  State<ConstellationBackground> createState() =>
      _ConstellationBackgroundState();
}

class _ConstellationBackgroundState extends State<ConstellationBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    final rand = math.Random(42);
    _particles = List.generate(55, (i) => _Particle(
      x: rand.nextDouble(),
      y: rand.nextDouble(),
      vx: (rand.nextDouble() - 0.5) * 0.0008,
      vy: (rand.nextDouble() - 0.5) * 0.0008,
      radius: rand.nextDouble() * 3.5 + 1.5,
      color: i % 3 == 0
          ? const Color(0xFF00A650)
          : i % 3 == 1
              ? const Color(0xFF4DA8FF)
              : const Color(0xFF00D4FF),
      pulse: rand.nextDouble() * math.pi * 2,
    ));
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
      builder: (context, _) {
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          if (p.x < 0 || p.x > 1) p.vx = -p.vx;
          if (p.y < 0 || p.y > 1) p.vy = -p.vy;
          p.x = p.x.clamp(0.0, 1.0);
          p.y = p.y.clamp(0.0, 1.0);
        }
        return SizedBox.expand(
          child: CustomPaint(
            painter: _ConstellationPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  double x, y, vx, vy, radius, pulse;
  final Color color;
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.pulse,
  });
}

class _ConstellationPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ConstellationPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint();
    final bgGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF020B18),
        Color(0xFF041428),
        Color(0xFF061E3C),
      ],
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      bgPaint
        ..shader = bgGradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    _drawWaves(canvas, size);

    final linePaint = Paint()..strokeWidth = 0.6;
    for (int i = 0; i < particles.length; i++) {
      for (int j = i + 1; j < particles.length; j++) {
        final p1 = particles[i];
        final p2 = particles[j];
        final dx = (p1.x - p2.x) * size.width;
        final dy = (p1.y - p2.y) * size.height;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 120) {
          final opacity = (1 - dist / 120) * 0.5;
          linePaint.color = Color.lerp(
            const Color(0xFF00A650),
            const Color(0xFF003DA5),
            p1.x,
          )!.withAlpha((opacity * 255).toInt());

          canvas.drawLine(
            Offset(p1.x * size.width, p1.y * size.height),
            Offset(p2.x * size.width, p2.y * size.height),
            linePaint,
          );
        }
      }
    }

    for (final p in particles) {
      final cx = p.x * size.width;
      final cy = p.y * size.height;
      final pulse = math.sin(progress * math.pi * 2 + p.pulse);
      final r = p.radius + pulse * 0.8;

      canvas.drawCircle(
        Offset(cx, cy),
        r * 3,
        Paint()..color = p.color.withAlpha(25),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()..color = p.color,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r * 0.4,
        Paint()..color = Colors.white.withAlpha(180),
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size) {
    final wave1 = Path();
    wave1.moveTo(0, size.height * 0.78);
    wave1.quadraticBezierTo(
        size.width * 0.25, size.height * 0.72,
        size.width * 0.5, size.height * 0.78);
    wave1.quadraticBezierTo(
        size.width * 0.75, size.height * 0.84,
        size.width, size.height * 0.78);
    wave1.lineTo(size.width, size.height);
    wave1.lineTo(0, size.height);
    wave1.close();
    canvas.drawPath(
        wave1, Paint()..color = const Color(0xFF0A2340).withAlpha(180));

    final wave2 = Path();
    wave2.moveTo(0, size.height * 0.86);
    wave2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.82,
        size.width * 0.6, size.height * 0.88);
    wave2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.92,
        size.width, size.height * 0.86);
    wave2.lineTo(size.width, size.height);
    wave2.lineTo(0, size.height);
    wave2.close();
    canvas.drawPath(
        wave2, Paint()..color = const Color(0xFF063344).withAlpha(200));
  }

  @override
  bool shouldRepaint(_ConstellationPainter old) => true;
}
