import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:provider/provider.dart';
import '../../design/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

const _roleLabels = {
  'admin':      'Administrateur',
  'directeur':  'Directeur',
  'assistante': 'Assistante',
  'demandeur':  'Demandeur',
  'agent_dml':  'Agent DML',
};

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _stats;
  late final AnimationController _headerCtrl;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _headerCtrl.forward();
    _loadStats();
  }

  @override
  void dispose() { _headerCtrl.dispose(); super.dispose(); }

  Future<void> _loadStats() async {
    try {
      final res = await ApiService().get('/missions?per_page=100');
      final dynamic raw = res['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (res is List ? res : []));
      final missions = list as List;
      final total    = missions.length;
      final approuve = missions.where((m) =>
          ['approuve', 'valide'].contains(m['statut'])).length;
      final termine  = missions.where((m) =>
          m['statut'] == 'termine').length;
      if (mounted) {
        setState(() => _stats = {
          'total':    total,
          'approuve': approuve,
          'termine':  termine,
          'taux': total > 0 ? (approuve * 100 ~/ total) : 0,
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final user      = auth.user;
    if (user == null) return const SizedBox.shrink();

    final roleColor = DS.colorForRole(auth.roleName);
    final roleLabel = _roleLabels[auth.roleName] ?? auth.roleName;
    final isLdap    = user.authMethod == 'ldap';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(slivers: [

        // ── Hero Header ──────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          stretch: true,
          backgroundColor: DS.secondary,
          foregroundColor: Colors.white,
          title: Text('Mon Profil',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700, color: Colors.white)),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(IconlyLight.setting, size: 20),
                onPressed: () {},
                tooltip: 'Paramètres',
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(fit: StackFit.expand, children: [
              // Background gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF001A5E), Color(0xFF003DA5), Color(0xFF0050B3)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Decorative circles
              Positioned(
                right: -50, top: -50,
                child: Container(
                  width: 200, height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                left: -30, bottom: 50,
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: roleColor.withValues(alpha: 0.10),
                  ),
                ),
              ),
              // Content
              SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar with glow ring
                    Stack(alignment: Alignment.center, children: [
                      // Outer glow
                      Container(
                        width: 106, height: 106,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              roleColor.withValues(alpha: 0.6),
                              DS.primary.withValues(alpha: 0.4),
                              roleColor.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                      // White separator ring
                      Container(
                        width: 100, height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      // Avatar itself
                      Container(
                        width: 94, height: 94,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [DS.secondary, const Color(0xFF0057CC)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(child: Text(user.initiales,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 32, fontWeight: FontWeight.w900,
                          ))),
                      ),
                      // Role badge dot
                      Positioned(
                        right: 2, bottom: 2,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [BoxShadow(
                              color: roleColor.withValues(alpha: 0.5),
                              blurRadius: 8, offset: const Offset(0, 2),
                            )],
                          ),
                          child: const Icon(Icons.verified_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ])
                        .animate(controller: _headerCtrl)
                        .scale(begin: const Offset(0.7, 0.7), end: const Offset(1.0, 1.0),
                            duration: 600.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 14),
                    Text(user.nomComplet,
                      style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ))
                        .animate(controller: _headerCtrl)
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.3, delay: 200.ms),
                    const SizedBox(height: 4),
                    Text(user.email,
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 13,
                      ))
                        .animate(controller: _headerCtrl)
                        .fadeIn(delay: 300.ms),
                    const SizedBox(height: 12),
                    // Role pill avec glassmorphism
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 7),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(roleLabel,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700, fontSize: 13,
                            )),
                        ),
                      ),
                    )
                        .animate(controller: _headerCtrl)
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, delay: 400.ms),
                  ],
                ),
              ),
            ]),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Column(children: [

              // ── Stats missions ───────────────────────────────────────────
              if (_stats != null)
                _StatsCard(stats: _stats!)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),

              // ── Auth badge ───────────────────────────────────────────────
              _AuthBadge(isLdap: isLdap)
                  .animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // ── Infos perso ──────────────────────────────────────────────
              _InfoSection(
                title: 'INFORMATIONS',
                icon: IconlyLight.profile,
                items: [
                  _InfoItem(icon: Icons.badge_outlined,
                      label: 'Matricule', value: user.matricule),
                  _InfoItem(icon: Icons.business_outlined,
                      label: 'Direction', value: user.direction),
                  _InfoItem(icon: Icons.group_outlined,
                      label: 'Service', value: user.service),
                  _InfoItem(icon: Icons.work_outline,
                      label: 'Poste', value: user.poste),
                  _InfoItem(icon: IconlyLight.call,
                      label: 'Téléphone', value: user.telephone),
                ],
              )
                  .animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 16),

              // ── Paramètres ───────────────────────────────────────────────
              _ActionSection(
                title: 'PARAMÈTRES',
                icon: Icons.settings_outlined,
                items: [
                  _ActionItem(
                    icon: IconlyLight.notification,
                    label: 'Notifications',
                    subtitle: 'Gérer les alertes',
                    color: const Color(0xFF7C3AED),
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Icons.palette_outlined,
                    label: 'Apparence',
                    subtitle: 'Thème et couleurs',
                    color: DS.info,
                    onTap: () {},
                  ),
                  _ActionItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Aide & Support',
                    subtitle: 'FAQ et contact',
                    color: DS.warning,
                    onTap: () {},
                  ),
                ],
              )
                  .animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 24),

              // ── Déconnexion ──────────────────────────────────────────────
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _confirmLogout(context, auth);
                },
                child: Container(
                  width: double.infinity, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [DS.error, const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [BoxShadow(
                      color: DS.error.withValues(alpha: 0.35),
                      blurRadius: 16, offset: const Offset(0, 6),
                    )],
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.logout_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Se déconnecter',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w700,
                      )),
                  ]),
                ),
              )
                  .animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 16),
              Text('AT Réservations · Algérie Télécom · v1.0.0',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: DS.textPlaceholder, fontSize: 11))
                  .animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 100),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _confirmLogout(BuildContext ctx, AuthProvider auth) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: DS.error.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded, color: DS.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Déconnexion',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 18,
                color: DS.textPrimary,
              )),
            const SizedBox(height: 8),
            Text('Voulez-vous vraiment vous déconnecter ?',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: DS.textSecondary, fontSize: 14)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text('Annuler',
                      style: GoogleFonts.inter(
                        color: DS.textSecondary,
                        fontWeight: FontWeight.w600,
                      ))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DS.error,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: DS.error.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Center(child: Text('Déconnecter',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ))),
                  ),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
    if (ok == true) await auth.logout();
  }
}

// ─── Stats Card ────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsCard({required this.stats});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
    decoration: BoxDecoration(
      gradient: DS.gradientDeepBlue,
      borderRadius: BorderRadius.circular(24),
      boxShadow: DS.shadowBlue,
    ),
    child: Row(children: [
      _StatCell('${stats['total']}', 'Missions', Colors.white,
          Icons.flight_takeoff_rounded),
      _Divider(),
      _StatCell('${stats['approuve']}', 'Approuvées',
          const Color(0xFF6EE7B7), Icons.check_circle_outline),
      _Divider(),
      _StatCell('${stats['termine']}', 'Terminées',
          const Color(0xFF93C5FD), Icons.done_all),
      _Divider(),
      _StatCell('${stats['taux']}%', 'Taux', const Color(0xFFFCD34D),
          Icons.trending_up_rounded),
    ]),
  );
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _StatCell(this.value, this.label, this.color, this.icon);

  @override
  Widget build(BuildContext context) => Expanded(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Column(children: [
        Icon(icon, color: color.withValues(alpha: v), size: 18),
        const SizedBox(height: 6),
        Text(value,
          style: GoogleFonts.inter(
            color: color, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.65 * v),
            fontSize: 10, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 44,
    color: Colors.white.withValues(alpha: 0.12),
    margin: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ─── Auth Badge ────────────────────────────────────────────────────────────
class _AuthBadge extends StatelessWidget {
  final bool isLdap;
  const _AuthBadge({required this.isLdap});

  @override
  Widget build(BuildContext context) {
    final color = isLdap ? DS.info : DS.success;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: DS.shadowSm,
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.security_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Authentification',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, color: DS.textPrimary,
                fontSize: 14)),
            Text(isLdap ? 'Active Directory (LDAP)' : 'Compte local',
              style: GoogleFonts.inter(
                color: DS.textSecondary, fontSize: 12)),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Text(
            isLdap ? '🏢 LDAP' : '🔑 Local',
            style: GoogleFonts.inter(
              color: color, fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ]),
    );
  }
}

// ─── Info Section ──────────────────────────────────────────────────────────
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_InfoItem> items;
  const _InfoSection({
    required this.title, required this.icon, required this.items,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Row(children: [
          Icon(icon, size: 13,
              color: DS.secondary.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(title,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: DS.secondary.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            )),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: DS.shadowSm,
        ),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Container(height: 1,
                margin: const EdgeInsets.only(left: 48),
                color: const Color(0xFFF3F4F6)),
          ],
        ]),
      ),
    ],
  );
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  const _InfoItem({required this.icon, required this.label, this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: DS.secondary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: DS.secondary.withValues(alpha: 0.7), size: 16),
      ),
      const SizedBox(width: 12),
      Text(label,
        style: GoogleFonts.inter(color: DS.textSecondary, fontSize: 14)),
      const Spacer(),
      Text(value ?? 'Non renseigné',
        style: GoogleFonts.inter(
          color: value != null ? DS.textPrimary : DS.textPlaceholder,
          fontWeight: value != null ? FontWeight.w700 : FontWeight.w400,
          fontSize: 14,
          fontStyle: value != null ? FontStyle.normal : FontStyle.italic,
        )),
    ]),
  );
}

// ─── Action Section ────────────────────────────────────────────────────────
class _ActionSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ActionItem> items;
  const _ActionSection({
    required this.title, required this.icon, required this.items,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Row(children: [
          Icon(icon, size: 13,
              color: DS.secondary.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(title,
            style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w800,
              color: DS.secondary.withValues(alpha: 0.7),
              letterSpacing: 0.8,
            )),
        ]),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: DS.shadowSm,
        ),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Container(height: 1,
                margin: const EdgeInsets.only(left: 56),
                color: const Color(0xFFF3F4F6)),
          ],
        ]),
      ),
    ],
  );
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon, required this.label,
    required this.subtitle, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap();
    },
    borderRadius: BorderRadius.circular(18),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: DS.textPrimary, fontSize: 14)),
            Text(subtitle,
              style: GoogleFonts.inter(
                color: DS.textSecondary, fontSize: 12)),
          ],
        )),
        Icon(Icons.chevron_right_rounded,
            color: DS.textPlaceholder, size: 18),
      ]),
    ),
  );
}
