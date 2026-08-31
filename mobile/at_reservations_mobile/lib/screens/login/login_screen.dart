import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/constellation_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _storage   = const FlutterSecureStorage();
  bool _showPass = false;
  bool _loading  = false;
  bool _biometricAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final hasCreds = await _storage.read(key: 'bio_email');
      if (hasCreds == null || hasCreds.isEmpty) return;
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      if (mounted && (canCheck || isSupported)) {
        setState(() => _biometricAvailable = true);
      }
    } catch (_) {}
  }

  Future<void> _saveBioCredentials(String email, String pass) async {
    await _storage.write(key: 'bio_email', value: email);
    await _storage.write(key: 'bio_pass', value: pass);
  }

  Future<void> _loginBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Connectez-vous avec votre empreinte',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      if (!authenticated || !mounted) return;
      HapticFeedback.lightImpact();
      setState(() { _loading = true; _error = null; });

      final email = await _storage.read(key: 'bio_email');
      final pass  = await _storage.read(key: 'bio_pass');
      if (email == null || pass == null) {
        if (mounted) setState(() => _error = 'Identifiants non sauvegardés. Connectez-vous manuellement.');
        return;
      }
      await context.read<AuthProvider>().login(email, pass);
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString()
            .replaceAll('Exception:', '')
            .replaceAll('TimeoutException', 'Connexion impossible. Vérifiez votre réseau WiFi.')
            .trim());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final pass  = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }

    HapticFeedback.lightImpact();
    setState(() { _loading = true; _error = null; });

    try {
      await context.read<AuthProvider>().login(email, pass);
      await _saveBioCredentials(email, pass);
    } catch (e) {
      if (mounted) {
        HapticFeedback.vibrate();
        setState(() {
          _error = e.toString()
              .replaceAll('Exception:', '')
              .replaceAll('TimeoutException',
                  'Connexion impossible. Vérifiez votre réseau WiFi.')
              .trim();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final size   = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: ConstellationBackground()),
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: bottom > 0 ? size.height * 0.28 : size.height * 0.45,
                child: _buildHeader(),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft:  Radius.circular(36),
                      topRight: Radius.circular(36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x30000000),
                        blurRadius: 40,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                        28, 24, 28, bottom > 0 ? bottom + 16 : 24),
                    child: _buildForm(),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.dns_outlined, color: Colors.white70),
              tooltip: 'Configuration Serveur API',
              onPressed: _showServerConfigDialog,
            ),
          ),
        ],
      ),
    );
  }

  void _showServerConfigDialog() async {
    final apiService = ApiService();
    final currentUrl = await apiService.getBaseUrl();
    final ctrl = TextEditingController(text: currentUrl);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.dns, color: Color(0xFF0056B3)),
            SizedBox(width: 8),
            Text('Serveur API Backend', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Adresse du serveur backend Laravel :', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.7:8000/api',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ActionChip(
                  label: const Text('Wi-Fi PC (192.168.1.7)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://192.168.1.7:8000/api',
                ),
                ActionChip(
                  label: const Text('USB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = 'http://127.0.0.1:8000/api',
                ),
                ActionChip(
                  label: const Text('Reset Défaut', style: TextStyle(fontSize: 11)),
                  onPressed: () => ctrl.text = kApiBaseUrl,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await apiService.setCustomUrl(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Serveur configuré : ${ctrl.text}')),
                );
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        FadeInDown(
          duration: const Duration(milliseconds: 600),
          child: LoopAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 2400),
            builder: (ctx, value, child) {
              final glow = 0.3 + 0.5 * sin(value * 2 * pi);
              return Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A650).withAlpha((glow * 140).round()),
                      blurRadius: 20 + glow * 20,
                      spreadRadius: 2 + glow * 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFF003DA5).withAlpha((glow * 60).round()),
                      blurRadius: 30 + glow * 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(45),
              child: Image.asset(
                'assets/images/logo_at.jpg',
                width: 90,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('AT',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF003DA5),
                          fontSize: 28, fontWeight: FontWeight.w900,
                        )),
                    Container(
                      width: 32, height: 2.5,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00A650), Color(0xFF003DA5)]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeIn(
          delay: const Duration(milliseconds: 400),
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                  text: 'AT ',
                  style: GoogleFonts.inter(
                      color: const Color(0xFF00A650),
                      fontSize: 26, fontWeight: FontWeight.w800)),
              TextSpan(
                  text: 'Réservations',
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 26, fontWeight: FontWeight.w800)),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        FadeIn(
          delay: const Duration(milliseconds: 600),
          child: Text('Espace Personnel',
              style: GoogleFonts.inter(
                color: Colors.white.withAlpha(160),
                fontSize: 13, letterSpacing: 2.0,
              )),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 50, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF003DA5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Connexion',
                  style: GoogleFonts.inter(
                      fontSize: 24, fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A))),
              Text('Identifiants Algérie Télécom',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFF64748B))),
            ]),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8F0),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF00A650).withAlpha(60)),
              ),
              child: Row(children: [
                const Icon(Icons.security_outlined,
                    size: 14, color: Color(0xFF00A650)),
                const SizedBox(width: 4),
                Text('Sécurisé',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: const Color(0xFF00A650),
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(_error!,
                      style: GoogleFonts.inter(
                          color: const Color(0xFFDC2626), fontSize: 13))),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1F2937)),
          decoration: _inputDeco('Adresse e-mail', Icons.alternate_email_rounded),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _passCtrl,
          obscureText: !_showPass,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _login(),
          style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF1F2937)),
          decoration: _inputDeco(
            'Mot de passe', Icons.lock_outline_rounded,
            suffix: IconButton(
              icon: Icon(
                _showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF94A3B8), size: 20,
              ),
              onPressed: () => setState(() => _showPass = !_showPass),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Material(
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _loading ? null : _login,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00A650), Color(0xFF003DA5)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00A650).withAlpha(80),
                      blurRadius: 20, offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: _loading
                      ? const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Se connecter',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
        if (_biometricAvailable) ...[
          const SizedBox(height: 20),
          Center(
            child: FadeIn(
              delay: const Duration(milliseconds: 200),
              child: GestureDetector(
                onTap: _loading ? null : _loginBiometric,
                child: Column(children: [
                  LoopAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 2000),
                    builder: (ctx, value, child) {
                      final pulse = 0.6 + 0.4 * sin(value * 2 * pi);
                      return Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF003DA5).withAlpha(12),
                          border: Border.all(
                            color: const Color(0xFF003DA5).withAlpha((pulse * 120).round()),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003DA5).withAlpha((pulse * 50).round()),
                              blurRadius: 16 + pulse * 8,
                              spreadRadius: pulse * 2,
                            ),
                          ],
                        ),
                        child: child,
                      );
                    },
                    child: const Icon(Icons.fingerprint, size: 32, color: Color(0xFF003DA5)),
                  ),
                  const SizedBox(height: 8),
                  Text('Connexion biométrique',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF003DA5), fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Center(
          child: Text('© 2026 Algérie Télécom',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF94A3B8))),
        ),
      ],
    );
  }

  InputDecoration _inputDeco(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
          color: const Color(0xFF64748B), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF00A650), width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
