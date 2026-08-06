import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design/design_system.dart';

class OnboardingSlide {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  const OnboardingSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

const _slides = [
  OnboardingSlide(
    icon: Icons.flight_takeoff,
    title: 'Créez vos missions',
    description: 'Soumettez vos ordres de mission en quelques taps.\nSuivi du circuit de validation en temps réel.',
    color: DS.primary,
  ),
  OnboardingSlide(
    icon: Icons.notifications_active,
    title: 'Restez informé',
    description: 'Notifications instantanées pour chaque étape.\nMessagerie intégrée avec votre équipe.',
    color: DS.secondary,
  ),
  OnboardingSlide(
    icon: Icons.wifi_off,
    title: 'Mode hors-ligne',
    description: 'Travaillez sans connexion.\nVos actions se synchronisent automatiquement.',
    color: Color(0xFF8B5CF6),
  ),
  OnboardingSlide(
    icon: Icons.qr_code_scanner,
    title: 'Scanner intelligent',
    description: 'Scannez billets et justificatifs.\nExtraction automatique des données.',
    color: Color(0xFFF59E0B),
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _slides[_page].color,
                  _slides[_page].color.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Pages
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Icon(slide.icon, size: 72, color: Colors.white),
                    )
                        .animate()
                        .scale(duration: 600.ms, curve: Curves.elasticOut)
                        .fadeIn(duration: 400.ms),
                    const SizedBox(height: 48),
                    Text(
                      slide.title,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 16),
                    Text(
                      slide.description,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
                  ],
                ),
              );
            },
          ),

          // Skip
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  'Passer',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),

          // Bottom
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 32 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _page == i
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 32),

                // Bouton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _page == _slides.length - 1
                          ? _finish
                          : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _slides[_page].color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        _page == _slides.length - 1
                            ? 'Commencer'
                            : 'Suivant',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
