import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../design/design_system.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../providers/theme_provider.dart';
import '../../services/app_preferences.dart';
import '../../utils/web_navigation.dart'
    if (dart.library.html) '../../utils/web_navigation_web.dart';

// ─── Role labels ─────────────────────────────────────────────────────────────
const _roleLabels = {
  'admin':       'Administrateur',
  'validateur':  'Validateur',
  'utilisateur': 'Utilisateur',
  'directeur':   'Directeur',
  'assistante':  'Assistante',
  'demandeur':   'Demandeur',
  'agent_dml':   'Agent DML',
};

// ─── Tile record type ─────────────────────────────────────────────────────────
typedef _Tile = (IconData, String, String, Color, VoidCallback?);

// ══════════════════════════════════════════════════════════════════════════════
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _lastMissions = [];
  bool _isLoggingOut = false;

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    if (!mounted) return;
    try {
      final res = await ApiService().get('/missions?per_page=100');
      if (!mounted) return;
      final dynamic raw = res['data'];
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw) : []);
      final ms   = list as List;
      final tot  = ms.length;
      final apr  = ms.where((m) => ['approuve', 'valide'].contains(m['statut'])).length;
      final ter  = ms.where((m) => m['statut'] == 'termine').length;
      setState(() {
        _stats = {
          'total': tot, 'approuve': apr, 'termine': ter,
          'taux': tot > 0 ? (apr * 100 ~/ tot) : 0,
        };
        _lastMissions = ms.take(3).toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _stats = {'total': 0, 'approuve': 0, 'termine': 0, 'taux': 0});
    }
  }

  Future<void> _showSheet(String title) {
    Widget child;
    switch (title) {
      case 'Notifications':  child = const _NotificationsSheet(); break;
      case 'Apparence':      child = const _AppearanceSheet();    break;
      case 'Aide & Support': child = const _HelpSheet();          break;
      default:               child = const _HelpSheet();
    }
    return showModalBottomSheet<void>(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => _Sheet(title: title, child: child),
    );
  }

  Future<void> _showChangePassword() => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => const _ChangePasswordSheet(),
  );

  Future<void> _showEditProfile() => showModalBottomSheet<void>(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (_) => _EditProfileSheet(onSaved: () {
      context.read<AuthProvider>().refreshUser();
    }),
  );

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Déconnexion', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text('Voulez-vous vous déconnecter ?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text('Annuler', style: GoogleFonts.inter())),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text('Déconnecter',
                  style: GoogleFonts.inter(color: DS.error, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isLoggingOut = true);
    await context.read<AuthProvider>().logout();
    navigateToLoginBrowser();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (_isLoggingOut || user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF003DA5), strokeWidth: 2.5)),
      );
    }
    final role    = auth.roleName;
    final roleCol = DS.colorForRole(role);
    final roleLbl = _roleLabels[role] ?? role;
    final isLdap  = user.authMethod?.contains('ldap') == true;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Sliver AppBar ─────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 260, pinned: true,
            backgroundColor: const Color(0xFF003DA5), foregroundColor: Colors.white,
            title: Text('Mon Profil',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded), tooltip: 'Rafraîchir',
                onPressed: () { setState(() => _stats = null); _loadData(); },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: _ProfilHeader(user: user, roleCol: roleCol, roleLbl: roleLbl),
            ),
          ),

          // ── Stats Banner ──────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _stats != null
                ? _StatsBanner(s: _stats!).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2)
                : const ATShimmerCard(height: 104),
          )),

          // ── Informations ──────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _InfoSection(user: user)
                .animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.2),
          )),

          // ── Bouton Modifier profil ───────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: GestureDetector(
              onTap: _showEditProfile,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF003DA5), Color(0xFF0052CC)]),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Color(0x30003DA5), blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text('Modifier mon profil', style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms).slideY(begin: 0.2),
          )),

          // ── Paramètres ────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CardSection(
              title: 'Paramètres', icon: Icons.settings_outlined, iconColor: DS.info,
              tiles: [
                (Icons.notifications_outlined, 'Notifications', 'Gérer vos alertes', const Color(0xFF8B5CF6), () => _showSheet('Notifications')),
                (Icons.palette_outlined, 'Apparence', 'Thème et affichage', DS.info, () => _showSheet('Apparence')),
                (Icons.help_outline_rounded, 'Aide & Support', 'FAQ et contact', DS.success, () => _showSheet('Aide & Support')),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.2),
          )),

          // ── Sécurité ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _CardSection(
              title: 'Sécurité', icon: Icons.shield_outlined, iconColor: DS.warning,
              tiles: [
                (
                  isLdap ? Icons.domain_rounded : Icons.lock_outlined,
                  isLdap ? '🏢 Active Directory' : '🔑 Authentification locale',
                  isLdap ? "Géré par l'entreprise" : 'Identifiants AT Réservations',
                  const Color(0xFF6366F1), null,
                ),
                if (!isLdap)
                  (Icons.key_outlined, 'Changer le mot de passe', 'Mettre à jour vos identifiants', DS.error, _showChangePassword),
              ],
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms).slideY(begin: 0.2),
          )),

          // ── Section rôle ──────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _RoleSection(role: role, roleCol: roleCol, stats: _stats, missions: _lastMissions)
                .animate().fadeIn(delay: 400.ms, duration: 400.ms).slideY(begin: 0.2),
          )),

          // ── Bouton déconnexion ────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            child: GestureDetector(
              onTap: _confirmLogout,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Color(0x55EF4444), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text('Se déconnecter', style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 400.ms),
          )),

          // ── Footer ────────────────────────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 140),
            child: Center(child: Text(
              'AT Réservations · Algérie Télécom · v1.0.0',
              style: GoogleFonts.inter(fontSize: 12, color: context.textMuted, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 500.ms)),
          )),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════════════
class _ProfilHeader extends StatefulWidget {
  final dynamic user;
  final Color roleCol;
  final String roleLbl;
  const _ProfilHeader({required this.user, required this.roleCol, required this.roleLbl});
  @override
  State<_ProfilHeader> createState() => _ProfilHeaderState();
}

class _ProfilHeaderState extends State<_ProfilHeader> {
  bool _uploading = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u.avatarUrl != null && (u.avatarUrl as String).isNotEmpty) {
      _avatarUrl = u.avatarUrl as String;
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 80);
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await File(picked.path).readAsBytes();
      final res = await ApiService().postMultipart(
        '/auth/avatar',
        fileBytes: bytes,
        fileName: picked.name,
        fileField: 'avatar',
      );
      if (!mounted) return;
      final data = res is Map ? res : {};
      final url = data['avatar_url'] as String? ?? data['data']?['avatar_url'] as String?;
      if (url != null) {
        setState(() => _avatarUrl = url);
        context.read<AuthProvider>().refreshUser();
      }
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil mise à jour'), backgroundColor: Color(0xFF00A650)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString().replaceFirst(RegExp(r'^Exception: '), '')}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final roleCol = widget.roleCol;
    final roleLbl = widget.roleLbl;
    final isLdap = user.authMethod?.contains('ldap') == true;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF001A5E), Color(0xFF003DA5), Color(0xFF0052CC)],
        ),
      ),
      child: Stack(children: [
        Positioned(top: -50, right: -50, child: _Circle(180, Colors.white.withValues(alpha: 0.05))),
        Positioned(bottom: 10, left: -70, child: _Circle(140, Colors.white.withValues(alpha: 0.04))),
        Positioned(top: 30, left: 30, child: _Circle(60, Colors.white.withValues(alpha: 0.03))),
        SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 48),
            GestureDetector(
              onTap: _uploading ? null : _pickAndUploadPhoto,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                  width: 108, height: 108,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: roleCol, width: 3),
                    boxShadow: [BoxShadow(color: roleCol.withValues(alpha: 0.45), blurRadius: 20)],
                  ),
                ),
                Container(
                  width: 94, height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipOval(
                    child: _uploading
                        ? const Center(child: SizedBox(width: 30, height: 30,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : _avatarUrl != null
                            ? Image.network(_avatarUrl!, fit: BoxFit.cover, width: 94, height: 94,
                                errorBuilder: (_, __, ___) => Center(child: Text(user.initiales,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800))))
                            : Center(child: Text(user.initiales,
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800))),
                  ),
                ),
                Positioned(bottom: 0, right: 0, child: Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A650),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                )),
              ]),
            ),
            const SizedBox(height: 14),
            Text(user.nomComplet, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: roleCol.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleCol.withValues(alpha: 0.5)),
              ),
              child: Text(roleLbl, style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            Text(user.email, textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
            if (isLdap) ...[
              const SizedBox(height: 7),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('🏢 Active Directory',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ),
            ],
          ]),
        ))),
      ]),
    );
  }
}

class _Circle extends StatelessWidget {
  final double size;
  final Color color;
  const _Circle(this.size, this.color);
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// STATS BANNER
// ══════════════════════════════════════════════════════════════════════════════
class _StatsBanner extends StatelessWidget {
  final Map<String, dynamic> s;
  const _StatsBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        gradient: DS.gradientDeepBlue,
        borderRadius: BorderRadius.circular(20),
        boxShadow: DS.shadowBlue,
      ),
      child: Row(children: [
        _StatCell(s['total'],   'Total',      Colors.white,              Icons.flight_takeoff_rounded, suffix: ''),
        _VDivider(),
        _StatCell(s['approuve'],'Approuvées', const Color(0xFF6EE7B7),  Icons.check_circle_outline,   suffix: ''),
        _VDivider(),
        _StatCell(s['termine'], 'Terminées',  const Color(0xFF93C5FD),  Icons.done_all,               suffix: ''),
        _VDivider(),
        _StatCell(s['taux'],    'Taux',       const Color(0xFFFCD34D),  Icons.trending_up_rounded,    suffix: '%'),
      ]),
    );
  }
}

class _VDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, height: 44, margin: const EdgeInsets.symmetric(horizontal: 4),
    color: Colors.white.withValues(alpha: 0.12),
  );
}

class _StatCell extends StatelessWidget {
  final dynamic value;
  final String label;
  final Color color;
  final IconData icon;
  final String suffix;
  const _StatCell(this.value, this.label, this.color, this.icon, {required this.suffix});

  @override
  Widget build(BuildContext context) {
    final target = (value is num) ? (value as num).toDouble() : 0.0;
    return Expanded(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: target),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Text('${v.round()}$suffix',
            style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ),
      const SizedBox(height: 2),
      Text(label, textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.65), fontSize: 10, fontWeight: FontWeight.w600)),
    ]));
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION INFORMATIONS
// ══════════════════════════════════════════════════════════════════════════════
class _InfoSection extends StatelessWidget {
  final dynamic user;
  const _InfoSection({required this.user});

  Widget _row(BuildContext context, Color col, IconData icon, String label, String? val) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 18, color: col),
      ),
      const SizedBox(width: 12),
      Text('$label :', style: GoogleFonts.inter(fontSize: 13, color: context.textMuted)),
      const SizedBox(width: 8),
      Expanded(child: Text(
        val ?? 'Non renseigné',
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: val != null ? FontWeight.w600 : FontWeight.w400,
          color: val != null ? context.textPrimary : DS.textPlaceholder,
          fontStyle: val == null ? FontStyle.italic : FontStyle.normal,
        ),
      )),
    ]),
  );

  @override
  Widget build(BuildContext context) => ATCard(
    padding: const EdgeInsets.all(20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Informations', style: DS.h3),
      const SizedBox(height: 16),
      _row(context, DS.info,                      Icons.email_outlined,    'Email',     user.email),
      _row(context, const Color(0xFF6366F1),      Icons.badge_outlined,    'Matricule', user.matricule),
      _row(context, DS.secondary,                 Icons.business_outlined, 'Direction', user.direction),
      _row(context, DS.success,                   Icons.group_outlined,    'Service',   user.service),
      _row(context, DS.warning,                   Icons.work_outline,      'Poste',     user.poste),
      _row(context, const Color(0xFF0EA5E9),      Icons.phone_outlined,    'Téléphone', user.telephone),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION PARAMÈTRES / SÉCURITÉ (carte générique à tuiles)
// ══════════════════════════════════════════════════════════════════════════════
class _CardSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<_Tile> tiles;
  const _CardSection({required this.title, required this.icon, required this.iconColor, required this.tiles});

  @override
  Widget build(BuildContext context) => ATCard(
    padding: EdgeInsets.zero,
    child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Text(title, style: DS.h4),
        ]),
      ),
      const ATDivider(),
      ...tiles.map((t) {
        final (ic, ttl, sub, col, onTap) = t;
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(ic, color: col, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(ttl, style: DS.body.copyWith(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                Text(sub, style: DS.caption),
              ])),
              if (onTap != null) Icon(Icons.chevron_right_rounded, color: context.textMuted, size: 20),
            ]),
          ),
        );
      }),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// SECTION RÔLE
// ══════════════════════════════════════════════════════════════════════════════
class _RoleSection extends StatelessWidget {
  final String role;
  final Color roleCol;
  final Map<String, dynamic>? stats;
  final List<dynamic> missions;
  const _RoleSection({required this.role, required this.roleCol, required this.stats, required this.missions});

  @override
  Widget build(BuildContext context) {
    if (stats == null) return const SizedBox.shrink();
    return switch (role) {
      'demandeur'  => _DemandeurSection(missions: missions, roleCol: roleCol),
      'directeur'  => _RoleStatsCard('Validations', Icons.how_to_vote_rounded, roleCol, [
          ('En attente', '${stats!['total'] ?? 0}', roleCol),
          ('Approuvées', '${stats!['approuve'] ?? 0}', DS.success),
          ('Terminées',  '${stats!['termine'] ?? 0}', DS.info),
        ]),
      'agent_dml'  => _RoleStatsCard('Logistique', Icons.local_shipping_rounded, roleCol, [
          ('Missions à traiter', '${stats!['total'] ?? 0}', roleCol),
          ('En traitement',      '${stats!['approuve'] ?? 0}', DS.info),
          ('Terminées',          '${stats!['termine'] ?? 0}', DS.success),
        ]),
      'assistante' => _RoleStatsCard('Tableau de bord', Icons.supervisor_account_rounded, roleCol, [
          ('Total missions gérées',   '${stats!['total'] ?? 0}', roleCol),
          ("Taux d'approbation",      '${stats!['taux'] ?? 0}%', DS.success),
        ]),
      _ => const SizedBox.shrink(),
    };
  }
}

class _RoleStatsCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color col;
  final List<(String, String, Color)> rows;
  const _RoleStatsCard(this.title, this.icon, this.col, this.rows);

  @override
  Widget build(BuildContext context) => ATCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: col.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: col, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: DS.h4),
      ]),
      const SizedBox(height: 12),
      ...rows.map((r) {
        final (lbl, val, c) = r;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            Expanded(child: Text(lbl, style: DS.caption)),
            Text(val, style: DS.body.copyWith(color: c, fontWeight: FontWeight.w700)),
          ]),
        );
      }),
    ]),
  );
}

class _DemandeurSection extends StatelessWidget {
  final List<dynamic> missions;
  final Color roleCol;
  const _DemandeurSection({required this.missions, required this.roleCol});

  @override
  Widget build(BuildContext context) => ATCard(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: roleCol.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.history_rounded, color: roleCol, size: 18),
        ),
        const SizedBox(width: 12),
        Text('Mes dernières missions', style: DS.h4),
      ]),
      const SizedBox(height: 12),
      if (missions.isEmpty)
        Center(child: Text('Aucune mission récente',
            style: DS.caption.copyWith(fontStyle: FontStyle.italic)))
      else
        ...missions.map((m) {
          final statut = (m['statut'] as String?) ?? '';
          final c = DS.colorForStatut(statut);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Text(
                  m['objet'] as String? ?? 'Sans objet',
                  style: DS.body, overflow: TextOverflow.ellipsis)),
              ATBadge(label: DS.labelForStatut(statut), color: c, small: true),
            ]),
          );
        }),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// BOTTOM SHEETS
// ══════════════════════════════════════════════════════════════════════════════
class _Sheet extends StatelessWidget {
  final String title;
  final Widget child;
  const _Sheet({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.cardBg,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: DS.border, borderRadius: BorderRadius.circular(2)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          Text(title, style: DS.h3),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
              onPressed: () => Navigator.pop(context)),
        ]),
      ),
      const ATDivider(),
      child,
    ]),
  );
}

// ── Notifications ──────────────────────────────────────────────────────────
// Les preferences sont persistees via AppPreferences (SharedPreferences).
class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  Widget _row(BuildContext context, String title, String sub, bool val, ValueChanged<bool> cb) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
              Text(sub, style: GoogleFonts.inter(
                  fontSize: 12, color: context.textMuted)),
            ])),
          Switch(
            value: val,
            onChanged: cb,
            activeTrackColor: DS.primary,
            activeThumbColor: Colors.white,
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final prefs = context.watch<AppPreferences>();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 8),
        _row(context, 'Missions', 'Créations et mises à jour de vos missions',
            prefs.notifMissions,    (v) => prefs.setNotifMissions(v)),
        _row(context, 'Validations', 'Approbations et rejets',
            prefs.notifValidations, (v) => prefs.setNotifValidations(v)),
        _row(context, 'Messages', 'Nouveaux messages reçus',
            prefs.notifMessages,   (v) => prefs.setNotifMessages(v)),
        _row(context, 'Système', 'Maintenances et mises à jour',
            prefs.notifSysteme,    (v) => prefs.setNotifSysteme(v)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Préférences enregistrées automatiquement sur l\'appareil.',
              style: GoogleFonts.inter(fontSize: 11, color: context.textMuted),
              textAlign: TextAlign.center),
        ),
      ]),
    );
  }
}

// ── Apparence ──────────────────────────────────────────────────────────────
class _AppearanceSheet extends StatelessWidget {
  const _AppearanceSheet();

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final prefs = context.watch<AppPreferences>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thème', style: GoogleFonts.inter(
              fontSize: 13, fontWeight: FontWeight.w700, color: context.textMuted)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => themeProv.setSetting(ThemeSetting.light),
              child: _ThemeCard('Clair', Icons.wb_sunny_rounded,
                  themeProv.setting == ThemeSetting.light),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => themeProv.setSetting(ThemeSetting.dark),
              child: _ThemeCard('Sombre', Icons.nightlight_round,
                  themeProv.setting == ThemeSetting.dark),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => themeProv.setSetting(ThemeSetting.auto),
              child: _ThemeCard('Auto', Icons.brightness_auto,
                  themeProv.setting == ThemeSetting.auto),
            )),
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DS.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: DS.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Préférences appliquées instantanément. Les écrans s\'adapteront automatiquement.',
                style: GoogleFonts.inter(fontSize: 11, color: DS.primary),
              )),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  const _ThemeCard(this.label, this.icon, this.active);
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: active ? DS.primary.withValues(alpha: 0.08) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: active ? DS.primary : Colors.transparent, width: 1.5),
    ),
    child: Column(children: [
      Icon(icon, color: active ? DS.primary : context.textMuted, size: 22),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.inter(
        fontSize: 12, fontWeight: FontWeight.w600,
        color: active ? DS.primary : context.textMuted)),
    ]),
  );
}

class _LangChip extends StatelessWidget {
  final String label, code, current;
  final ValueChanged<String> onTap;
  const _LangChip(this.label, this.code, this.current, this.onTap);
  @override
  Widget build(BuildContext context) {
    final sel = code == current;
    return GestureDetector(
      onTap: () => onTap(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? DS.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: sel ? Colors.white : context.textMuted)),
      ),
    );
  }
}

// ── Aide & Support ─────────────────────────────────────────────────────────
class _HelpSheet extends StatelessWidget {
  const _HelpSheet();

  Widget _item(BuildContext context, IconData icon, Color col, String title, String sub) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: col, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary)),
              Text(sub, style: GoogleFonts.inter(
                  fontSize: 12, color: context.textMuted)),
            ])),
        ]),
      );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const SizedBox(height: 4),
      _item(context, Icons.email_outlined,         DS.primary,  'Support technique',       'support@algerie-telecom.dz'),
      _item(context, Icons.phone_outlined,         DS.success,  'Assistance téléphonique', '+213 (0) 21 — XXX XXX'),
      _item(context, Icons.help_center_outlined,   DS.warning,  'FAQ',                     'Consultez les questions fréquentes'),
      _item(context, Icons.bug_report_outlined,    DS.error,    'Signaler un problème',    'Envoyez un rapport de bug'),
      const SizedBox(height: 12),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: DS.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('AT Réservations', style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w600, color: context.textMuted)),
            Text('v1.0.0 — Algérie Télécom', style: GoogleFonts.inter(
                fontSize: 12, color: context.textMuted)),
          ]),
      ),
    ]),
  );}


// ── Changement de mot de passe ─────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _curCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();
  bool _loading = false, _hideCur = true, _hideNew = true, _hideConf = true;
  String? _error;
  bool _success = false;

  @override
  void dispose() { _curCtrl.dispose(); _newCtrl.dispose(); _confCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_newCtrl.text != _confCtrl.text) { setState(() => _error = 'Les mots de passe ne correspondent pas.'); return; }
    if (_newCtrl.text.length < 8) { setState(() => _error = 'Minimum 8 caractères requis.'); return; }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().post('/auth/change-password', {
        'current_password': _curCtrl.text,
        'new_password': _newCtrl.text,
        'new_password_confirmation': _confCtrl.text,
      });
      if (!mounted) return;
      setState(() { _loading = false; _success = true; });
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst(RegExp(r'^Exception: '), ''); });
    }
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Changer le mot de passe',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ATTextField(
          controller: _curCtrl, label: 'Mot de passe actuel',
          prefixIcon: Icons.lock_outlined, obscure: _hideCur,
          suffix: IconButton(
            icon: Icon(_hideCur ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: context.textMuted),
            onPressed: () => setState(() => _hideCur = !_hideCur)),
        ),
        const SizedBox(height: 12),
        ATTextField(
          controller: _newCtrl, label: 'Nouveau mot de passe',
          prefixIcon: Icons.key_outlined, obscure: _hideNew,
          suffix: IconButton(
            icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: context.textMuted),
            onPressed: () => setState(() => _hideNew = !_hideNew)),
        ),
        const SizedBox(height: 12),
        ATTextField(
          controller: _confCtrl, label: 'Confirmer le mot de passe',
          prefixIcon: Icons.check_circle_outline, obscure: _hideConf,
          suffix: IconButton(
            icon: Icon(_hideConf ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: context.textMuted),
            onPressed: () => setState(() => _hideConf = !_hideConf)),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: DS.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, color: DS.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: DS.caption.copyWith(color: DS.error))),
            ]),
          ),
        ],
        if (_success) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: DS.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: DS.success, size: 18),
              const SizedBox(width: 8),
              Text('Mot de passe modifié !', style: DS.caption.copyWith(color: DS.success)),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        ATButton(label: 'Enregistrer', onPressed: _submit, loading: _loading, icon: Icons.save_outlined),
      ]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// EDIT PROFILE SHEET
// ══════════════════════════════════════════════════════════════════════════════
class _EditProfileSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _EditProfileSheet({required this.onSaved});
  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  static const _directions = [
    'Direction Générale',
    'Ressources Humaines',
    'Logistique',
    'Technique',
    'Commerciale',
    'Financière',
    'Système d\'Information',
    'Juridique',
    'Communication',
    'Audit Interne',
    'Achats',
    'Exploitation',
    'Maintenance',
    'Réseaux',
    'Développement',
  ];
  static const _services = [
    'Administration',
    'Recrutement',
    'Formation',
    'Paie',
    'Achats',
    'Stock',
    'Transport',
    'IT',
    'Réseau',
    'Sécurité',
    'Support Technique',
    'Comptabilité',
    'Trésorerie',
    'Marketing',
    'Ventes',
    'Service Client',
    'Qualité',
    'Planification',
    'Projets',
  ];

  final _nomCtrl    = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl    = TextEditingController();
  final _posteCtrl  = TextEditingController();
  String? _selectedDirection;
  String? _selectedService;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null) {
      _nomCtrl.text    = user.nom;
      _prenomCtrl.text = user.prenom;
      _telCtrl.text    = user.telephone ?? '';
      _posteCtrl.text  = user.poste ?? '';
      _selectedDirection = _directions.contains(user.direction) ? user.direction : null;
      _selectedService   = _services.contains(user.service) ? user.service : null;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose(); _posteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nomCtrl.text.trim().isEmpty || _prenomCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Nom et prénom sont obligatoires.');
      return;
    }
    final tel = _telCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
    if (tel.isNotEmpty && tel.length != 10) {
      setState(() => _error = 'Le numéro de téléphone doit contenir 10 chiffres.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ApiService().put('/auth/profile', {
        'nom': _nomCtrl.text.trim(),
        'prenom': _prenomCtrl.text.trim(),
        'telephone': tel.isEmpty ? null : tel,
        'direction': _selectedDirection,
        'service': _selectedService,
        'poste': _posteCtrl.text.trim().isEmpty ? null : _posteCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _loading = false; _success = true; });
      widget.onSaved();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e.toString().replaceFirst(RegExp(r'^Exception: '), ''); });
    }
  }

  Widget _dropdown(String label, IconData icon, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
        ),
        style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1F2937)),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(14),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _Sheet(
    title: 'Modifier mon profil',
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(child: ATTextField(controller: _prenomCtrl, label: 'Prénom', prefixIcon: Icons.person_outline)),
          const SizedBox(width: 10),
          Expanded(child: ATTextField(controller: _nomCtrl, label: 'Nom', prefixIcon: Icons.person_outline)),
        ]),
        const SizedBox(height: 10),
        ATTextField(controller: _telCtrl, label: 'Téléphone (10 chiffres)', prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone),
        const SizedBox(height: 10),
        _dropdown('Direction', Icons.business_outlined, _selectedDirection, _directions, (v) => setState(() => _selectedDirection = v)),
        const SizedBox(height: 10),
        _dropdown('Service', Icons.group_outlined, _selectedService, _services, (v) => setState(() => _selectedService = v)),
        const SizedBox(height: 10),
        ATTextField(controller: _posteCtrl, label: 'Poste', prefixIcon: Icons.work_outline),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: DS.error.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.error_outline_rounded, color: DS.error, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!, style: DS.caption.copyWith(color: DS.error))),
            ]),
          ),
        ],
        if (_success) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: DS.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.check_circle_outline, color: DS.success, size: 18),
              const SizedBox(width: 8),
              Text('Profil mis à jour !', style: DS.caption.copyWith(color: DS.success)),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        ATButton(label: 'Enregistrer', onPressed: _submit, loading: _loading, icon: Icons.save_outlined),
      ]),
    ),
  );
}
