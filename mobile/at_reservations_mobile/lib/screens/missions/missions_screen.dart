import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/mission.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';

enum _Filter { toutes, actives, approuvees, brouillons, terminees }

extension _FilterExt on _Filter {
  String get label {
    switch (this) {
      case _Filter.toutes:     return 'Toutes';
      case _Filter.actives:    return 'En cours';
      case _Filter.approuvees: return 'Approuvées';
      case _Filter.brouillons: return 'Brouillons';
      case _Filter.terminees:  return 'Terminées';
    }
  }

  IconData get icon {
    switch (this) {
      case _Filter.toutes:     return Icons.apps_rounded;
      case _Filter.actives:    return Icons.play_circle_outline;
      case _Filter.approuvees: return Icons.check_circle_outline;
      case _Filter.brouillons: return Icons.edit_outlined;
      case _Filter.terminees:  return Icons.done_all;
    }
  }

  bool match(MissionModel m) {
    switch (this) {
      case _Filter.toutes:     return true;
      case _Filter.actives:    return ['soumis', 'en_attente', 'en_validation',
                                       'en_traitement_logistique'].contains(m.statut);
      case _Filter.approuvees: return ['approuve', 'valide'].contains(m.statut);
      case _Filter.brouillons: return m.statut == 'brouillon';
      case _Filter.terminees:  return m.statut == 'termine';
    }
  }
}

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});
  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen>
    with SingleTickerProviderStateMixin {
  List<MissionModel> _missions = [];
  bool    _loading  = true;
  String? _error;
  _Filter _filter   = _Filter.toutes;
  late final AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _load();
  }

  @override
  void dispose() { _fabCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().get('/missions');
      final dynamic raw = data['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (data is List ? data : []));
      if (!mounted) return;
      setState(() {
        _missions = (list as List)
            .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
      _fabCtrl.forward();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  List<MissionModel> get _filtered => _missions.where(_filter.match).toList();
  int _count(_Filter f) => _missions.where(f.match).length;

  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final prenom  = auth.user?.prenom ?? '';
    final initiales = auth.user?.initiales ?? '?';
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
            // ── Hero AppBar ───────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 185,
              floating: false,
              pinned: true,
              stretch: true,
              backgroundColor: DS.secondary,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: _load,
                  tooltip: 'Actualiser',
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(fit: StackFit.expand, children: [
                  // Deep blue gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF001A5E), Color(0xFF003DA5), Color(0xFF0057CC)],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Geometric decorators
                  Positioned(
                    right: -30, top: -30,
                    child: Container(
                      width: 160, height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 40, top: 30,
                    child: Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20, bottom: -20,
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DS.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  // Diagonal accent line
                  CustomPaint(
                    painter: _DiagonalPainter(),
                  ),
                  // Content
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(
                                        color: DS.primary,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text('Bonjour, $prenom',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 13, fontWeight: FontWeight.w500,
                                      )),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text('Mes Missions',
                                    style: GoogleFonts.inter(
                                      color: Colors.white, fontSize: 28,
                                      fontWeight: FontWeight.w800, height: 1.1,
                                    )),
                                  const SizedBox(height: 6),
                                  if (!_loading)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.15)),
                                      ),
                                      child: Text(
                                        '${_missions.length} mission${_missions.length > 1 ? "s" : ""}',
                                        style: GoogleFonts.inter(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: 12, fontWeight: FontWeight.w600,
                                        )),
                                    ),
                                ],
                              )),
                              // Avatar bouton profil
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.go('/profil');
                                },
                                child: Container(
                                  width: 48, height: 48,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        DS.primary.withValues(alpha: 0.7),
                                        DS.primary.withValues(alpha: 0.4),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.4),
                                        width: 2),
                                    boxShadow: [BoxShadow(
                                      color: DS.primary.withValues(alpha: 0.4),
                                      blurRadius: 12, offset: const Offset(0, 4),
                                    )],
                                  ),
                                  child: Center(child: Text(initiales,
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900, fontSize: 16,
                                    ))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
              title: Text('Mes Missions',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
            ),

            // ── Filter chips ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Builder(
                builder: (ctx) => _FilterDelegate(
                  filters: _Filter.values,
                  selected: _filter,
                  counts: { for (final f in _Filter.values) f: _count(f) },
                  onSelect: (f) {
                    HapticFeedback.selectionClick();
                    setState(() => _filter = f);
                  },
                ).build(ctx, 0, false),
              ),
            ),

            // ── Contenu ───────────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => const MissionCardSkeleton(),
                  childCount: 6,
                ),
              )
            else if (_error != null)
              SliverFillRemaining(child: _ErrorView(error: _error!, onRetry: _load))
            else if (filtered.isEmpty)
              SliverFillRemaining(child: _EmptyView(filter: _filter, onRefresh: _load))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => MissionCard(
                    mission: filtered[i],
                    index: i,
                    onTap: () async {
                      await ctx.push('/missions/${filtered[i].id}');
                      _load();
                    },
                  )
                      .animate(delay: (i * 60).ms)
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.15, duration: 300.ms, curve: Curves.easeOut),
                  childCount: filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      // Le DML ne cree pas de missions (role = traitement logistique uniquement)
      floatingActionButton: !_loading && _error == null && auth.roleName != 'agent_dml'
          ? ScaleTransition(
              scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
              child: Container(
                decoration: BoxDecoration(
                  gradient: DS.gradientGreen,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: DS.shadowGreen,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _showNewMissionSheet(context);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 14),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.add_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 8),
                        Text('Nouvelle mission',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 15,
                          )),
                      ]),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _showNewMissionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: sheetCtx.cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: sheetCtx.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: DS.gradientBlue,
              shape: BoxShape.circle,
              boxShadow: DS.shadowBlue,
            ),
            child: const Icon(Icons.flight_takeoff_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(height: 16),
          Text('Nouvelle mission',
            style: GoogleFonts.inter(
              fontSize: 20, fontWeight: FontWeight.w800,
              color: sheetCtx.textPrimary,
            )),
          const SizedBox(height: 8),
          Text('Créez votre demande de mission directement depuis l\'application',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: sheetCtx.textSecondary, fontSize: 14)),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity, height: 54,
            child: Container(
              decoration: BoxDecoration(
                gradient: DS.gradientGreen,
                borderRadius: BorderRadius.circular(16),
                boxShadow: DS.shadowGreen,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push('/new-mission');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Créer une mission',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700,
                      )),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Diagonal painter ─────────────────────────────────────────────────────
class _DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(size.width * 0.5 + i * 30, 0),
        Offset(size.width + 40, size.height * 0.7 + i * 30),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(_) => false;
}

// ─── Filter chips delegate ─────────────────────────────────────────────────
class _FilterDelegate extends SliverPersistentHeaderDelegate {
  final List<_Filter> filters;
  final _Filter selected;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onSelect;

  const _FilterDelegate({
    required this.filters, required this.selected,
    required this.counts, required this.onSelect,
  });

  @override double get minExtent => 60;
  @override double get maxExtent => 60;
  @override bool shouldRebuild(_FilterDelegate o) =>
      o.selected != selected || o.counts != counts;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: context.scaffoldBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: filters.map((f) {
            final isSelected = f == selected;
            final count = counts[f] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: isSelected ? DS.gradientBlue : null,
                    color: isSelected ? null : context.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : context.borderColor,
                    ),
                    boxShadow: isSelected ? DS.shadowBlue : [
                      BoxShadow(
                        color: context.shadowColor,
                        blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(f.icon,
                      size: 13,
                      color: isSelected
                          ? Colors.white
                          : context.textSecondary),
                    const SizedBox(width: 5),
                    Text(f.label,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : context.textSecondary,
                        fontSize: 13, fontWeight: FontWeight.w700,
                      )),
                    if (count > 0 && f != _Filter.toutes) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : DS.secondary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                          style: GoogleFonts.inter(
                            color: isSelected ? Colors.white : DS.secondary,
                            fontSize: 10, fontWeight: FontWeight.w800,
                          )),
                      ),
                    ],
                  ]),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  final _Filter filter;
  final VoidCallback onRefresh;
  const _EmptyView({required this.filter, required this.onRefresh});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Decorative rings
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.secondary.withValues(alpha: 0.04),
              ),
            ),
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.secondary.withValues(alpha: 0.07),
              ),
            ),
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                gradient: DS.gradientBlue,
                shape: BoxShape.circle,
                boxShadow: DS.shadowBlue,
              ),
              child: const Icon(Icons.inbox_rounded,
                  size: 26, color: Colors.white),
            ),
          ]),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.95, end: 1.0, duration: 2000.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 24),
        Text(
          filter == _Filter.toutes
              ? 'Aucune mission'
              : 'Aucune mission « ${filter.label} »',
          style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w800,
            color: context.textPrimary,
          ),
          textAlign: TextAlign.center,
        )
            .animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          filter == _Filter.toutes
              ? 'Vos demandes de mission apparaîtront ici'
              : 'Essayez un autre filtre',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14),
          textAlign: TextAlign.center,
        )
            .animate().fadeIn(delay: 300.ms),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: DS.secondary.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, size: 16, color: DS.secondary),
              const SizedBox(width: 8),
              Text('Actualiser',
                style: GoogleFonts.inter(
                  color: DS.secondary, fontWeight: FontWeight.w700,
                )),
            ]),
          ),
        )
            .animate().fadeIn(delay: 400.ms),
      ]),
    ),
  );
}

// ─── Error State ──────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: DS.error.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.wifi_off_outlined, size: 38, color: DS.error),
        ),
        const SizedBox(height: 20),
        Text('Connexion impossible',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
              color: context.textPrimary)),
        const SizedBox(height: 8),
        Text(error,
          textAlign: TextAlign.center, maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: DS.gradientGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: DS.shadowGreen,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text('Réessayer',
                style: GoogleFonts.inter(
                  color: Colors.white, fontWeight: FontWeight.w700,
                )),
            ]),
          ),
        ),
      ]),
    ),
  );
}
