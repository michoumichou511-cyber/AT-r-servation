import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
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
    final initiales = user?.initiales ?? '?';
    final total = ((_stats['total'] ?? _stats['total_missions'] ?? 0) as num).toInt();
    final enAttente = ((_stats['en_attente'] ?? _stats['soumis'] ?? 0) as num).toInt();
    final approuvees = ((_stats['approuvees'] ?? _stats['approuve'] ?? 0) as num).toInt();
    final refusees = ((_stats['refusees'] ?? _stats['rejete'] ?? 0) as num).toInt();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: DS.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: const Color(0xFF1A0050),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1A0050), Color(0xFF5B21B6), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(child: Text(initiales, style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
                            ))),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Bonjour, ${name.isNotEmpty ? name : "Admin"}',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text('Panneau d\'administration',
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          ])),
                        ]),
                        const SizedBox(height: 16),
                        Row(children: [
                          _HeaderPill('$total missions', Icons.assignment_rounded),
                          const SizedBox(width: 8),
                          _HeaderPill('$enAttente en attente', Icons.schedule_rounded, color: ATColors.warning),
                        ]),
                      ],
                    ),
                  )),
                ),
              ),
              title: Text('Administration', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              actions: [
                IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () => context.go('/notifications')),
              ],
            ),

            // ── Stats ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: _loading
                  ? const Padding(padding: EdgeInsets.all(40), child: Center(child: SpinKitWave(color: DS.primary, size: 30)))
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        _SectionTitle('Vue globale'),
                        const SizedBox(height: 12),
                        Row(children: [
                          _StatTile('Total', total, ATColors.secondary, Icons.assignment_outlined),
                          const SizedBox(width: 10),
                          _StatTile('En attente', enAttente, ATColors.warning, Icons.hourglass_empty_rounded),
                        ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
                        const SizedBox(height: 10),
                        Row(children: [
                          _StatTile('Approuvées', approuvees, ATColors.success, Icons.check_circle_outline_rounded),
                          const SizedBox(width: 10),
                          _StatTile('Refusées', refusees, ATColors.error, Icons.cancel_outlined),
                        ]).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15),
                      ]),
                    ),
            ),

            // ── Raccourcis ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _SectionTitle('Accès rapides'),
                  const SizedBox(height: 12),
                  _QuickLink('Utilisateurs', Icons.people_outline_rounded, ATColors.secondary, () => context.go('/admin/utilisateurs')),
                  _QuickLink('Statistiques', Icons.bar_chart_rounded, const Color(0xFF7C3AED), () => context.go('/admin/statistiques')),
                  _QuickLink('Audit Logs', Icons.security_rounded, ATColors.info, () => context.go('/admin/audit-logs')),
                  _QuickLink('Budgets', Icons.account_balance_wallet_outlined, ATColors.warning, () => context.go('/admin/budgets')),
                  _QuickLink('Prestataires', Icons.business_outlined, const Color(0xFF0891B2), () => context.go('/admin/prestataires')),
                  _QuickLink('Mon profil', Icons.person_outline_rounded, ATColors.textSecondary, () => context.go('/profil')),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
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

    final now = DateTime.now();
    final greet = now.hour < 12 ? 'Bonjour' :
                  now.hour < 18 ? 'Bon après-midi' : 'Bonsoir';

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

            // ── Header ───────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
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
                      gradient: LinearGradient(
                        colors: [DS.primary, DS.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF001F6B), Color(0xFF003DA5), Color(0xFF0052CC)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle decorative circles
                      Positioned(
                        right: -40, top: -30,
                        child: Container(
                          width: 180, height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -30, bottom: -20,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: DS.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('$greet, $prenom',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 14, fontWeight: FontWeight.w500,
                                )),
                              const SizedBox(height: 4),
                              Text('Tableau de bord',
                                style: GoogleFonts.inter(
                                  color: Colors.white, fontSize: 26,
                                  fontWeight: FontWeight.w900, letterSpacing: -0.8,
                                )),
                              const SizedBox(height: 14),
                              if (!_loading)
                                Row(children: [
                                  _HeaderPill('$total missions', Icons.assignment_rounded),
                                  const SizedBox(width: 8),
                                  _HeaderPill('$approuv approuvées', Icons.check_circle_rounded,
                                      color: DS.primary),
                                ]),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: Text('Accueil', style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white,
              )),
            ),

            // ── Body ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [

                  // ── Stats row ─────────────────────────────────
                  const SizedBox(height: 20),
                  _loading
                    ? _ShimmerStatsRow()
                    : Row(children: [
                        _StatTile('Total', total, ATColors.secondary, Icons.assignment_rounded),
                        const SizedBox(width: 10),
                        _StatTile('En attente', enAttente, ATColors.warning, Icons.schedule_rounded),
                      ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15),
                  const SizedBox(height: 10),
                  if (!_loading)
                    Row(children: [
                      _StatTile('Approuvées', approuv, ATColors.success, Icons.check_circle_outline_rounded),
                      const SizedBox(width: 10),
                      _StatTile('Refusées', refusees, ATColors.error, Icons.cancel_outlined),
                    ]).animate(delay: 80.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15),

                  // ── Chart ─────────────────────────────────────
                  const SizedBox(height: 24),
                  _ChartCard(missions: _missions, loading: _loading),

                  // ── Actions rapides ───────────────────────────
                  const SizedBox(height: 24),
                  const _SectionTitle('Actions rapides'),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 88,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ActionChip('Nouvelle\nmission', Icons.add_circle_outline_rounded,
                        DS.primary,   () => context.push('/new-mission')),
                    _ActionChip('Mes\nmissions',  Icons.description_outlined,
                        DS.secondary, () => context.go('/missions')),
                    _ActionChip('Message-\nrie',    Icons.chat_bubble_outline_rounded,
                        const Color(0xFF0891B2), () => context.go('/messagerie')),
                    _ActionChip('Recherche',     Icons.search_rounded,
                        const Color(0xFF7C3AED), () => context.push('/search')),
                    _ActionChip('Notifi-\ncations', Icons.notifications_outlined,
                        ATColors.warning, () => context.go('/notifications')),
                  ],
                ),
              ),
            ),

            // ── Missions récentes ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: _SectionHeader(
                  title: 'Missions récentes',
                  onMore: () => context.go('/missions'),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [
                  const SizedBox(height: 8),
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
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    final initiales = context.watch<AuthProvider>().user?.initiales ?? '?';
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: RefreshIndicator(
        onRefresh: _load,
        color: ATColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180,
              pinned: true,
              backgroundColor: ATColors.secondary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF001F6B), Color(0xFF003DA5), Color(0xFF0052CC)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40, top: -20,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      SafeArea(child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(child: Text(initiales, style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
                                ))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Bonjour, $prenom',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('Tableau Directeur',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              ])),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              _HeaderPill('${_validations.length} à valider', Icons.task_alt_rounded, color: ATColors.warning),
                            ]),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              title: Text('Accueil', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (_loading)
                  _ShimmerStatsRow()
                else
                  Row(children: [
                    _StatTile('À valider', _validations.length,
                        ATColors.error, Icons.task_alt_rounded),
                    const SizedBox(width: 10),
                    _StatTile('Approuvées', _counts['approuve'] ?? 0,
                        ATColors.success, Icons.check_circle_outline_rounded),
                    const SizedBox(width: 10),
                    _StatTile('Rejetées', _counts['rejete'] ?? 0,
                        ATColors.warning, Icons.cancel_outlined),
                  ]).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2, curve: Curves.easeOutBack),
                const SizedBox(height: 24),

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
                  const _EmptyHint('Aucune validation en attente')
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
                const SizedBox(height: 120),
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
    final initiales = context.watch<AuthProvider>().user?.initiales ?? '?';
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
              expandedHeight: 180,
              pinned: true,
              backgroundColor: ATColors.secondary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFF001F6B), Color(0xFF003DA5), Color(0xFF0052CC)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -40, top: -20,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.04),
                          ),
                        ),
                      ),
                      SafeArea(child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white.withValues(alpha: 0.25), Colors.white.withValues(alpha: 0.1)],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(child: Text(initiales, style: GoogleFonts.inter(
                                  color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16,
                                ))),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Bonjour, $prenom',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 2),
                                Text('Tableau DML',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                              ])),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              _HeaderPill('$aTraiter à traiter', Icons.local_shipping_rounded, color: ATColors.warning),
                              const SizedBox(width: 8),
                              _HeaderPill('$terminees terminées', Icons.check_circle_rounded, color: DS.primary),
                            ]),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ),
              title: Text('Accueil', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(delegate: SliverChildListDelegate([
                if (_loading)
                  _ShimmerStatsRow()
                else
                  Row(children: [
                    _StatTile('À traiter', aTraiter,
                        ATColors.error, Icons.local_shipping_outlined),
                    const SizedBox(width: 10),
                    _StatTile('En cours', enCours,
                        ATColors.warning, Icons.hourglass_empty_rounded),
                    const SizedBox(width: 10),
                    _StatTile('Terminées', terminees,
                        ATColors.success, Icons.check_circle_outline_rounded),
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
                  const _EmptyHint('Aucune mission à traiter')
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
                const SizedBox(height: 120),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ══════════════════════════════════════════════════════════════════════════════

// ─── Header pill (glassmorphism-light) ─────────────────────────
class _HeaderPill extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color? color;
  const _HeaderPill(this.text, this.icon, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: c, size: 14),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(
          color: c, fontSize: 12, fontWeight: FontWeight.w600,
        )),
      ]),
    );
  }
}

// ─── Stat tile (clean card) ─────────────────────────────────────
class _StatTile extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  const _StatTile(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [BoxShadow(
          color: context.shadowColor,
          blurRadius: 8, offset: const Offset(0, 2),
        )],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: value),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text('$v', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w900, color: color,
              letterSpacing: -0.5,
            )),
          ),
        ]),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(
          fontSize: 11, color: context.textSecondary,
          fontWeight: FontWeight.w600,
        )),
      ]),
    ),
  );
}

// ─── Quick link (admin list item) ─────────────────────────────
class _QuickLink extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickLink(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: context.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.borderColor),
          ),
          child: Row(children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: GoogleFonts.inter(
              color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 14,
            ))),
            Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 20),
          ]),
        ),
      ),
    ),
  );
}

// ─── Section title ────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Text(title,
    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary));
}

// ─── Section header with "Voir tout" ──────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMore;
  const _SectionHeader({required this.title, this.onMore});

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(title,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
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
        child: Text('Voir tout', style: GoogleFonts.inter(
            fontSize: 13, fontWeight: FontWeight.w700)),
      ),
  ]);
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
        Text('Évolution', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w800, color: context.textPrimary)),
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
      ]),
      const SizedBox(height: 12),
      Container(
        height: 160,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.borderColor),
          boxShadow: [BoxShadow(color: context.shadowColor, blurRadius: 12, offset: const Offset(0, 4))],
        ),
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: loading
          ? const Center(child: SpinKitFadingCircle(color: DS.primary, size: 32))
          : _MiniLineChart(missions: missions),
      ),
    ]);
  }
}

// ─── Action chip ──────────────────────────────────────────────
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
      width: 78,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.15)),
            ),
            child: Icon(icon, color: color, size: 22),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DS.primary.withValues(alpha: 0.15)),
        boxShadow: [BoxShadow(color: context.shadowColor, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: DS.gradientGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Créer votre première mission', style: GoogleFonts.inter(
              fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
            const SizedBox(height: 4),
            Text('Commencez par soumettre une demande.',
                style: GoogleFonts.inter(fontSize: 12, color: context.textSecondary)),
          ]),
        ),
        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textMuted),
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
    _pulse = Tween<double>(begin: 1.0, end: 1.08)
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

// ─── Shimmer stats row ────────────────────────────────────────
class _ShimmerStatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Row(children: List.generate(2, (i) => Expanded(
      child: Container(
        margin: EdgeInsets.only(right: i < 1 ? 10 : 0),
        height: 85,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ))),
  );
}

// ─── Empty hint ───────────────────────────────────────────────
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
      style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13,
          fontStyle: FontStyle.italic))),
  );
}

// ─── Mini Line Chart ──────────────────────────────────────────
class _MiniLineChart extends StatelessWidget {
  final List<MissionModel> missions;
  const _MiniLineChart({required this.missions});

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
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    final now = DateTime.now();
    final currentMonthIdx = now.month - 1;
    final displayMonths = List.generate(6, (i) {
      final monthIdx = ((currentMonthIdx - 5 + i) % 12 + 12) % 12;
      return months[monthIdx];
    });

    return LineChart(
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
    );
  }
}
