import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design/design_system.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late AnimationController _particleCtrl;
  late List<_SplashParticle> _particles;
  bool _showTagline = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    final rand = math.Random(42);
    _particles = List.generate(30, (_) => _SplashParticle(rand));

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showTagline = true);
    });

    Future.delayed(const Duration(milliseconds: 2800), _checkAuth);
  }

  Future<void> _checkAuth() async {
    if (_navigating || !mounted) return;
    _navigating = true;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (!onboardingDone && mounted) {
      context.go('/onboarding');
      return;
    }

    final auth = context.read<AuthProvider>();
    try {
      await auth.tryAutoLogin().timeout(const Duration(seconds: 5));
    } catch (_) {}

    if (!mounted) return;
    if (auth.isAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fond gradient
          Container(
            decoration: const BoxDecoration(gradient: DS.gradientLogin),
          ),

          // Particules flottantes
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (context, _) => CustomPaint(
              painter: _SplashParticlePainter(
                _particles,
                _particleCtrl.value,
              ),
              size: Size.infinite,
            ),
          ),

          // Contenu central
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo avec pulse
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseCtrl.value * 0.05);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: DS.primary.withValues(alpha: 0.4),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/fonts/test/Inter-Regular.ttf',
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.flight_takeoff,
                          size: 56,
                          color: DS.secondary,
                        ),
                      ),
                    ),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Titre
                Text(
                  'AT Réservations',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 8),

                // Sous-titre
                Text(
                  'Algérie Télécom',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 2,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 600.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                const SizedBox(height: 48),

                // Tagline animee
                AnimatedOpacity(
                  opacity: _showTagline ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 800),
                  child: Text(
                    'Gérez vos missions en toute simplicité',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Loader
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(
                      Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),

          // Version en bas
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Text(
              'v2.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          ),
        ],
      ),
    );
  }
}

// ── Particules du splash ──────────────────────────────────────────

class _SplashParticle {
  final double x, y, speed, size, opacity;
  _SplashParticle(math.Random r)
      : x = r.nextDouble(),
        y = r.nextDouble(),
        speed = 0.2 + r.nextDouble() * 0.8,
        size = 2 + r.nextDouble() * 4,
        opacity = 0.1 + r.nextDouble() * 0.3;
}

class _SplashParticlePainter extends CustomPainter {
  final List<_SplashParticle> particles;
  final double t;
  _SplashParticlePainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final py = (p.y + t * p.speed) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, py * size.height),
        p.size,
        Paint()
          ..color = Colors.white.withValues(alpha: p.opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SplashParticlePainter old) => true;
}
