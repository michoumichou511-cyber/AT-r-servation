import 'dart:async';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../widgets/tilt_3d.dart';
import '../../models/mission.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';

// ─── Dashboard Screen (route → rôle) ──────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().roleName;
    return switch (role) {
      'admin'     => const _AdminDashboard(),
      'directeur' => const _DirecteurDashboard(),
      'agent_dml' => const _DmlDashboard(),
      _           => const _DemandeurDashboard(),
    };
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN
// ══════════════════════════════════════════════════════════════════════════════
class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard();
  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await ApiService().get('/admin/statistiques?year=${DateTime.now().year}');
      final inner = (resp['data'] ?? resp) as Map<String, dynamic>;
      setState(() { _stats = inner; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.nomComplet ?? '';
    final total = ((_stats['total'] ?? _stats['total_missions'] ?? 0) as num).toInt();
    final enAttente = ((_stats['en_attente'] ?? _stats['soumis'] ?? 0) as num).toInt();
    final approuvees = ((_stats['approuvees'] ?? _stats['approuve'] ?? 0) as num).toInt();
    final refusees = ((_stats['refusees'] ?? _stats['rejete'] ?? 0) as num).toInt();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0050), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(22)),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bonjour, ${name.isNotEmpty ? name : "Admin"}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const Text('Administration', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        ])),
                      ]),
                    ]),
                  )),
                ),
              ),
              title: const Text('Administration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              actions: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.go('/notifications')),
              ],
            ),

            // ── Stat cards ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: SpinKitWave(color: Color(0xFF00A650), size: 30)))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 12),
                          child: Text('Vue globale', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
                        ),
                        GridView.count(
                          crossAxisCount: 2, shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 10, mainAxisSpacing: 10,
                          childAspectRatio: 1.6,
                          children: [
                            _AdminStatCard(context, 'Total missions', total, ATColors.secondary, Icons.assignment_outlined),
                            _AdminStatCard(context, 'En attente', enAttente, ATColors.warning, Icons.hourglass_empty_outlined),
                            _AdminStatCard(context, 'Approuvées', approuvees, ATColors.success, Icons.check_circle_outline),
                            _AdminStatCard(context, 'Refusées', refusees, ATColors.error, Icons.cancel_outlined),
                          ],
                        ),
                      ]),
                    ),
            ),

            // ── Raccourcis admin ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Accès rapides', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2, shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10, mainAxisSpacing: 10,
                    childAspectRatio: 2.2,
                    children: [
                      _AdminShortcut('Utilisateurs', Icons.people_outline, ATColors.secondary, () => context.go('/admin/utilisateurs')),
                      _AdminShortcut('Statistiques', Icons.bar_chart, ATColors.primary, () => context.go('/admin/statistiques')),
                      _AdminShortcut('Audit Logs', Icons.security, const Color(0xFF7C3AED), () => context.go('/admin/audit-logs')),
                      _AdminShortcut('Budgets', Icons.account_balance_wallet_outlined, ATColors.warning, () => context.go('/admin/budgets')),
                      _AdminShortcut('Prestataires', Icons.business_outlined, ATColors.info, () => context.go('/admin/prestataires')),
                      _AdminShortcut('Mon profil', Icons.person_outline, ATColors.textSecondary, () => context.go('/profil')),
                    ],
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 140)),
          ],
        ),
      ),
    );
  }
}

Widget _AdminStatCard(BuildContext context, String label, int value, Color color, IconData icon) {
  return Container(
    decoration: BoxDecoration(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2))],
    ),
    padding: const EdgeInsets.all(14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const Spacer(),
        Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
      ]),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w500)),
    ]),
  );
}

Widget _AdminShortcut(String label, IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// DEMANDEUR
// ══════════════════════════════════════════════════════════════════════════════
class _DemandeurDashboard extends StatefulWidget {
  const _DemandeurDashboard();
  @override
  State<_DemandeurDashboard> createState() => _DemandeurDashboardState();
}

class _DemandeurDashboardState extends State<_DemandeurDashboard> {
  List<MissionModel> _missions = [];
  Map<String, int>  _counts   = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().get('/missions');
      final dynamic raw = data['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (data is List ? data : []));
      final missions = (list as List)
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final counts = <String, int>{};
      for (final m in missions) {
        counts[m.statut] = (counts[m.statut] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _missions = missions.take(3).toList();
        _counts   = counts;
        _loading  = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final prenom   = auth.user?.prenom ?? 'vous';
    final initiales = auth.user?.initiales ?? '?';
    final total    = _counts.values.fold(0, (a, b) => a + b);
    final approuv  = (_counts['approuve'] ?? 0) + (_counts['valide'] ?? 0);
    final refusees = _counts['rejete'] ?? 0;
    final enAttente = _counts['en_attente'] ?? 0;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      floatingActionButton: _PulseFab(
        onPressed: () => context.push('/new-mission'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: DS.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [

            // ── Header parallax glassmorphisme ────────────────────
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              stretch: true,
              backgroundColor: DS.secondary,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search_rounded, size: 22),
                  onPressed: () => context.push('/search'),
                ),
                GestureDetector(
                  onTap: () => context.go('/profil'),
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [DS.primary, DS.secondary],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(
                        color: DS.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )],
                    ),
                    child: Center(
                      child: Text(initiales, style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w800,
                        fontSize: 13,
                      )),
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: _DashboardHeader(
                  prenom: prenom,
                  total: total,
                  approuv: approuv,
                  loading: _loading,
                ),
              ),
              title: Text('Accueil', style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white,
              )),
            ),

            // ── Body ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(children: [

                // ── Bento Grid Stats ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _loading
                    ? _BentoSkeleton()
                    : _BentoStats(
                        total: total,
                        enAttente: enAttente,
                        approuvees: approuv,
                        refusees: refusees,
                      ),
                ),

                // ── Graphique évolution ─────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: _ChartCard(missions: _missions, loading: _loading),
                ),

                // ── Actions rapides (Bento horizontal) ──────────
                const _SectionHeader(title: 'Actions rapides'),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ActionChip('Nouvelle mission', Icons.add_circle_outline,
                          DS.primary,   () => context.push('/new-mission')),
                      _ActionChip('Mes missions',  Icons.description_outlined,
                          DS.secondary, () => context.go('/missions')),
                      _ActionChip('Messagerie',    Icons.chat_bubble_outline_rounded,
                          const Color(0xFF0891B2), () => context.go('/messagerie')),
                      _ActionChip('Recherche',     Icons.search_rounded,
                          const Color(0xFF7C3AED), () => context.push('/search')),
                      _ActionChip('Notifications', Icons.notifications_outlined,
                          ATColors.warning, () => context.go('/notifications')),
                    ],
                  ),
                ),

                // ── Missions récentes ───────────────────────────
                _SectionHeader(
                  title: 'Missions récentes',
                  onMore: () => context.go('/missions'),
                ),
                if (_loading)
                  ...List.generate(3, (_) => const MissionCardSkeleton())
                else if (_missions.isEmpty)
                  _EmptyMissionsCard(onTap: () => context.push('/new-mission'))
                else
                  ...List.generate(_missions.length, (i) => MissionCard(
                    mission: _missions[i],
                    index: i,
                    onTap: () => context.go('/missions/${_missions[i].id}'),
                  ).animate(delay: (i * 80).ms).fadeIn().slideY(begin: 0.1)),

                const SizedBox(height: 140),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dashboard Header avec glassmorphisme ─────────────────────
class _DashboardHeader extends StatelessWidget {
  final String prenom;
  final int total, approuv;
  final bool loading;
  const _DashboardHeader({
    required this.prenom, required this.total,
    required this.approuv, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greet = now.hour < 12 ? 'Bonjour' :
                  now.hour < 18 ? 'Bon après-midi' : 'Bonsoir';
    return Stack(
      children: [
        // Fond gradient avec blob
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF001F6B), Color(0xFF003DA5), Color(0xFF0052CC)],
            ),
          ),
        ),
        // Blob décoratif
        Positioned(
          right: -30, top: -20,
          child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                DS.primary.withValues(alpha: 0.3),
                DS.primary.withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        Positioned(
          left: -50, bottom: 20,
          child: Container(
            width: 160, height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF0052CC).withValues(alpha: 0.4),
                const Color(0xFF0052CC).withValues(alpha: 0.0),
              ]),
            ),
          ),
        ),
        // Grille futuriste
        CustomPaint(
          painter: _GridPainter(),
          size: Size(MediaQuery.of(context).size.width, 220),
        ),
        // Contenu
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('$greet, $prenom 👋',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14, fontWeight: FontWeight.w500,
                  )),
                const SizedBox(height: 4),
                Text('Tableau de bord',
                  style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 26,
                    fontWeight: FontWeight.w900, letterSpacing: -0.8,
                  )),
                const SizedBox(height: 16),
                // Pills glassmorphisme
                if (!loading)
                  Row(children: [
                    _GlassPill('$total missions', Icons.assignment_outlined),
                    const SizedBox(width: 8),
                    _GlassPill('$approuv approuvées', Icons.check_circle_outline,
                        color: DS.primary),
                  ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const _GlassPill(this.text, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: (color ?? Colors.white).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (color ?? Colors.white).withValues(alpha: 0.3),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color ?? Colors.white, size: 13),
            const SizedBox(width: 5),
            Text(text, style: GoogleFonts.inter(
              color: color ?? Colors.white, fontSize: 12,
              fontWeight: FontWeight.w600,
            )),
          ]),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 1;
    for (int i = 0; i < 10; i++) {
      canvas.drawLine(Offset(0, size.height / 10 * i),
          Offset(size.width, size.height / 10 * i), p);
    }
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(Offset(size.width / 8 * i, 0),
          Offset(size.width / 8 * i, size.height), p);
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Bento Grid Stats ─────────────────────────────────────────
class _BentoStats extends StatelessWidget {
  final int total, enAttente, approuvees, refusees;
  const _BentoStats({
    required this.total, required this.enAttente,
    required this.approuvees, required this.refusees,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Row(children: [
        // Grande card Total (Bento)
        Expanded(
          flex: 3,
          child: Tilt3D(
            intensity: 0.20,
            child: _BentoCard(
              label: 'Total missions',
              value: total,
              icon: Icons.assignment_rounded,
              gradient: DS.gradientBlue,
              tall: true,
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
        ),
        const SizedBox(width: 10),
        // Colonne 2 petites cards
        Expanded(
          flex: 2,
          child: Column(children: [
            Tilt3D(
              child: _BentoCard(
                label: 'En attente',
                value: enAttente,
                icon: Icons.hourglass_empty_rounded,
                color: ATColors.warning,
              ),
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 10),
            Tilt3D(
              child: _BentoCard(
                label: 'Approuvées',
                value: approuvees,
                icon: Icons.check_circle_rounded,
                color: DS.primary,
              ),
            ).animate(delay: 150.ms).fadeIn().slideY(begin: 0.2),
          ]),
        ),
      ]),
      const SizedBox(height: 10),
      // Card refusées pleine largeur
      Tilt3D(
        intensity: 0.15,
        child: _BentoCardWide(
          label: 'Missions refusées',
          value: refusees,
          total: total,
          color: ATColors.error,
        ),
      ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.2),
    ]);
  }
}

class _BentoCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final LinearGradient? gradient;
  final Color? color;
  final bool tall;

  const _BentoCard({
    required this.label, required this.value, required this.icon,
    this.gradient, this.color, this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? DS.secondary;
    return Container(
      height: tall ? 150 : 82,
      decoration: BoxDecoration(
        gradient: gradient ?? LinearGradient(
          colors: [c.withValues(alpha: 0.12), c.withValues(alpha: 0.06)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (gradient != null ? Colors.white : c).withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.15),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: tall
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const Spacer(),
            _AnimCounter(value: value, style: GoogleFonts.inter(
              fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white,
              letterSpacing: -1,
            )),
            const SizedBox(height: 2),
            Text(label, style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            )),
          ])
        : Row(children: [
            Icon(icon, color: c, size: 20),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              _AnimCounter(value: value, style: GoogleFonts.inter(
                fontSize: 22, fontWeight: FontWeight.w900, color: c,
                letterSpacing: -0.5,
              )),
              Text(label, style: GoogleFonts.inter(
                fontSize: 9, color: c.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              )),
            ]),
          ]),
    );
  }
}

class _BentoCardWide extends StatelessWidget {
  final String label;
  final int value, total;
  final Color color;
  const _BentoCardWide({
    required this.label, required this.value,
    required this.total, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.1),
          blurRadius: 10, offset: const Offset(0, 3),
        )],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.cancel_rounded, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: GoogleFonts.inter(
                fontSize: 12, color: color, fontWeight: FontWeight.w600,
              )),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: pct),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => LinearProgressIndicator(
                    value: v,
                    backgroundColor: color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _AnimCounter(value: value, style: GoogleFonts.inter(
          fontSize: 24, fontWeight: FontWeight.w900, color: color,
          letterSpacing: -0.5,
        )),
      ]),
    );
  }
}

// ─── Animated counter ─────────────────────────────────────────
class _AnimCounter extends StatelessWidget {
  final int value;
  final TextStyle style;
  const _AnimCounter({required this.value, required this.style});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<int>(
    tween: IntTween(begin: 0, end: value),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    builder: (_, v, _) => Text('$v', style: style),
  );
}

// ─── Bento skeleton ───────────────────────────────────────────
class _BentoSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Column(children: [
      Row(children: [
        Expanded(flex: 3, child: Container(height: 150,
            decoration: BoxDecoration(color: context.cardBg,
                borderRadius: BorderRadius.circular(20)))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: Column(children: [
          Container(height: 76, decoration: BoxDecoration(color: context.cardBg,
              borderRadius: BorderRadius.circular(20))),
          const SizedBox(height: 10),
          Container(height: 76, decoration: BoxDecoration(color: context.cardBg,
              borderRadius: BorderRadius.circular(20))),
        ])),
      ]),
      const SizedBox(height: 10),
      Container(height: 70, decoration: BoxDecoration(color: context.cardBg,
          borderRadius: BorderRadius.circular(20))),
    ]),
  );
}

// ─── Chart card ───────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final List<MissionModel> missions;
  final bool loading;
  const _ChartCard({required this.missions, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Évolution', style: DS.h4),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: DS.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('6 mois', style: GoogleFonts.inter(
            fontSize: 11, color: DS.primary, fontWeight: FontWeight.w600,
          )),
        ),
        const Spacer(),
        Icon(Icons.trending_up_rounded, color: DS.primary, size: 18),
        const SizedBox(width: 4),
        Text('Progression', style: DS.caption.copyWith(color: DS.primary)),
      ]),
      const SizedBox(height: 12),
      Container(
        height: 160,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: context.shadowColor, blurRadius: 16, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: loading
          ? const Center(child: SpinKitFadingCircle(color: DS.primary, size: 32))
          : _MiniLineChart(missions: missions, loading: loading),
      ),
    ]);
  }
}

// ─── Action chip horizontal ───────────────────────────────────
class _ActionChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionChip(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 10),
      width: 80,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 10, offset: const Offset(0, 4),
              )],
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: GoogleFonts.inter(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  );
}

// ─── Empty missions card ──────────────────────────────────────
class _EmptyMissionsCard extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyMissionsCard({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DS.primary.withValues(alpha: 0.06),
            DS.secondary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DS.primary.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            gradient: DS.gradientGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: DS.shadowGreen,
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Créer votre première mission', style: DS.h4),
            const SizedBox(height: 4),
            Text('Commencez par soumettre une demande de déplacement.',
                style: DS.caption),
          ]),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: context.textMuted),
      ]),
    ),
  );
}

// ─── Pulse FAB ────────────────────────────────────────────────
class _PulseFab extends StatefulWidget {
  final VoidCallback onPressed;
  const _PulseFab({required this.onPressed});
  @override
  State<_PulseFab> createState() => _PulseFabState();
}

class _PulseFabState extends State<_PulseFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))..repeat();
    _pulse = Tween<double>(begin: 1.0, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _pulse,
    child: Container(
      decoration: BoxDecoration(
        gradient: DS.gradientGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: DS.shadowGreen,
      ),
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: Text('Nouvelle', style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
        )),
      ),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// DIRECTEUR
// ══════════════════════════════════════════════════════════════════════════════
class _DirecteurDashboard extends StatefulWidget {
  const _DirecteurDashboard();
  @override
  State<_DirecteurDashboard> createState() => _DirecteurDashboardState();
}

class _DirecteurDashboardState extends State<_DirecteurDashboard> {
  List<Map<String, dynamic>> _validations = [];
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService().get('/validations');
      final dynamic raw = res['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (res is List ? res : []));
      final vals = (list as List).map((e) => e as Map<String, dynamic>).toList();

      final mRes = await ApiService().get('/missions');
      final dynamic mRaw = mRes['data'];
      final mList = mRaw is List ? mRaw
          : (mRaw is Map<String, dynamic> ? (mRaw['data'] ?? mRaw)
          : (mRes is List ? mRes : []));
      final counts = <String, int>{};
      for (final m in (mList as List)) {
        final s = (m as Map<String, dynamic>)['statut'] as String? ?? '';
        counts[s] = (counts[s] ?? 0) + 1;
      }
      setState(() {
        _validations = vals;
        _counts = counts;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<BarChartGroupData> _barGroups() {
    final statuts = ['brouillon', 'en_attente', 'approuve', 'rejete', 'termine'];
    final colors  = [ATColors.textSecondary, ATColors.warning, ATColors.success,
        ATColors.error, ATColors.info];
    return List.generate(statuts.length, (i) {
      final val = (_counts[statuts[i]] ?? 0).toDouble();
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(
          toY: val, color: colors[i], width: 22,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true, toY: (_counts.values.fold(0, (a, b) => a + b) + 2).toDouble(),
            color: colors[i].withValues(alpha: 0.05),
          ),
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prenom = context.watch<AuthProvider>().user?.prenom ?? 'vous';
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: ATColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 155,
              pinned: true,
              backgroundColor: ATColors.secondary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF002B7A), Color(0xFF004DB5)],
                    ),
                  ),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour, $prenom 👋',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Tableau Directeur',
                          style: TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                  )),
                ),
              ),
              title: const Text('Accueil',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (_loading)
                  _SkeletonStatsRow()
                else
                  Row(children: [
                    _AnimatedStatCard('À valider', _validations.length,
                        ATColors.error, Icons.task_alt),
                    const SizedBox(width: 10),
                    _AnimatedStatCard('Approuvées', _counts['approuve'] ?? 0,
                        ATColors.success, Icons.check_circle_outline),
                    const SizedBox(width: 10),
                    _AnimatedStatCard('Rejetées', _counts['rejete'] ?? 0,
                        ATColors.warning, Icons.cancel_outlined),
                  ]).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                const SizedBox(height: 24),

                // Bar chart
                _SectionHeader(title: 'Répartition des missions', onMore: null),
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: context.shadowColor,
                      blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: _loading || _counts.isEmpty
                      ? const Center(child: SpinKitFadingCircle(color: ATColors.primary, size: 32))
                      : BarChart(BarChartData(
                          barGroups: _barGroups(),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                const labels = ['Draft', 'Attente', 'Appro.', 'Rejeté', 'Terminé'];
                                final i = val.toInt();
                                if (i < 0 || i >= labels.length) {
                                  return const SizedBox();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(labels[i],
                                    style: TextStyle(fontSize: 9,
                                        color: context.textSecondary,
                                        fontWeight: FontWeight.w600)),
                                );
                              },
                            )),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: const FlGridData(show: false),
                          barTouchData: BarTouchData(enabled: true),
                        )),
                ),
                const SizedBox(height: 24),

                _SectionHeader(
                  title: 'Validations en attente',
                  onMore: () => context.go('/validations'),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const MissionCardSkeleton()
                else if (_validations.isEmpty)
                  const _EmptyHint('Aucune validation en attente ✅')
                else
                  ..._validations.take(2).toList().asMap().entries.map((e) {
                    final v  = e.value;
                    final mj = v['mission'] as Map<String, dynamic>? ?? v;
                    return MissionCard(
                      mission: MissionModel.fromJson(mj),
                      showUser: true, index: e.key,
                      onTap: () => context.go('/validations'),
                    ).animate(delay: (e.key * 80).ms).fadeIn().slideY(begin: 0.1);
                  }),
                const SizedBox(height: 140),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// AGENT DML
// ══════════════════════════════════════════════════════════════════════════════
class _DmlDashboard extends StatefulWidget {
  const _DmlDashboard();
  @override
  State<_DmlDashboard> createState() => _DmlDashboardState();
}

class _DmlDashboardState extends State<_DmlDashboard> {
  List<MissionModel> _missions = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().get('/dml/missions-validees');
      final dynamic raw = data['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (data is List ? data : []));
      setState(() {
        _missions = (list as List)
            .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        _loading  = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prenom    = context.watch<AuthProvider>().user?.prenom ?? 'vous';
    final aTraiter  = _missions.where((m) => m.statut == 'approuve').length;
    final enCours   = _missions.where((m) =>
        m.statut == 'en_traitement_logistique').length;
    final terminees = _missions.where((m) => m.statut == 'termine').length;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: ATColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 155,
              pinned: true,
              backgroundColor: ATColors.secondary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF002B7A), Color(0xFF004DB5)],
                    ),
                  ),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour, $prenom 👋',
                          style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        const Text('Tableau DML',
                          style: TextStyle(color: Colors.white, fontSize: 24,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                      ],
                    ),
                  )),
                ),
              ),
              title: const Text('Accueil',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (_loading)
                  _SkeletonStatsRow()
                else
                  Row(children: [
                    _AnimatedStatCard('À traiter', aTraiter,
                        ATColors.error, Icons.local_shipping_outlined),
                    const SizedBox(width: 10),
                    _AnimatedStatCard('En cours', enCours,
                        ATColors.warning, Icons.hourglass_empty_outlined),
                    const SizedBox(width: 10),
                    _AnimatedStatCard('Terminées', terminees,
                        ATColors.success, Icons.check_circle_outline),
                  ]).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                const SizedBox(height: 24),

                _SectionHeader(
                  title: 'Missions à traiter',
                  onMore: () => context.go('/dml'),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  ...List.generate(2, (_) => const MissionCardSkeleton())
                else if (_missions.isEmpty)
                  const _EmptyHint('Aucune mission à traiter 🚛')
                else
                  ..._missions
                      .where((m) => m.statut == 'approuve')
                      .take(3)
                      .toList()
                      .asMap()
                      .entries
                      .map((e) => MissionCard(
                        mission: e.value, index: e.key,
                        onTap: () => context.go('/dml'),
                      ).animate(delay: (e.key * 80).ms).fadeIn().slideY(begin: 0.1)),
                const SizedBox(height: 140),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated stat card ────────────────────────────────────────────────────
class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _AnimatedStatCard(this.label, this.count, this.color, this.icon);
  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _countAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _countAnim = IntTween(begin: 0, end: widget.count)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedStatCard old) {
    super.didUpdateWidget(old);
    if (old.count != widget.count) {
      _countAnim = IntTween(begin: old.count, end: widget.count)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.15),
            blurRadius: 14, offset: const Offset(0, 5)),
          BoxShadow(
            color: context.shadowColor,
            blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: widget.color, size: 20),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _countAnim,
          builder: (_, _) => Text('${_countAnim.value}',
            style: TextStyle(color: widget.color, fontSize: 24,
                fontWeight: FontWeight.w900)),
        ),
        const SizedBox(height: 2),
        Text(widget.label, textAlign: TextAlign.center,
          style: TextStyle(color: context.textSecondary,
              fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

// ─── Skeleton stats row ────────────────────────────────────────────────────
class _SkeletonStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Row(children: List.generate(3, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 2 ? 10 : 0),
        height: 100,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ))),
  );
}


// ─── Section header ────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
          color: context.textPrimary)),
    const Spacer(),
    if (onMore != null)
      TextButton(
        onPressed: onMore,
        style: TextButton.styleFrom(
          foregroundColor: ATColors.primary,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: const Text('Voir tout →',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ),
  ]);
}

// ─── Mini Line Chart ──────────────────────────────────────────────────────
class _MiniLineChart extends StatelessWidget {
  final List<MissionModel> missions;
  final bool loading;
  const _MiniLineChart({required this.missions, required this.loading});

  List<FlSpot> _spots() {
    final total = missions.length;
    double _r(double v) => double.parse(v.toStringAsFixed(1));
    return [
      FlSpot(0, _r((total * 0.1).clamp(0, 20).toDouble())),
      FlSpot(1, _r((total * 0.25).clamp(0, 20).toDouble())),
      FlSpot(2, _r((total * 0.4).clamp(0, 20).toDouble())),
      FlSpot(3, _r((total * 0.6).clamp(0, 20).toDouble())),
      FlSpot(4, _r((total * 0.8).clamp(0, 20).toDouble())),
      FlSpot(5, _r(total.clamp(0, 20).toDouble())),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Shimmer.fromColors(
        baseColor: context.shimmerBase,
        highlightColor: context.shimmerHighlight,
        child: Container(height: 160,
          decoration: BoxDecoration(color: context.cardBg,
              borderRadius: BorderRadius.circular(20))),
      );
    }
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final now = DateTime.now();
    final currentMonthIdx = now.month - 1;
    final displayMonths = List.generate(6, (i) {
      final monthIdx = ((currentMonthIdx - 5 + i) % 12 + 12) % 12;
      return months[monthIdx];
    });

    return Container(
      height: 160,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: context.shadowColor,
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: LineChart(
        LineChartData(
          minX: 0, maxX: 5,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: context.dividerColor, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (val, _) {
                final i = val.toInt();
                if (i < 0 || i >= displayMonths.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(displayMonths[i],
                    style: TextStyle(fontSize: 10,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w600)),
                );
              },
            )),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _spots(),
              isCurved: true,
              color: ATColors.primary,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, _, _) =>
                    FlDotCirclePainter(radius: 3.5,
                        color: ATColors.primary,
                        strokeColor: context.cardBg,
                        strokeWidth: 1.5),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ATColors.primary.withValues(alpha: 0.2),
                    ATColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty hint ───────────────────────────────────────────────────────────
class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: context.surfaceVariant,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.borderColor),
    ),
    child: Center(child: Text(text,
      style: TextStyle(color: context.textSecondary,
          fontStyle: FontStyle.italic))),
  );
}
