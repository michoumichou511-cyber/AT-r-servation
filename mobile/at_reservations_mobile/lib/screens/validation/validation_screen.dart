import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/design_system.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});
  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  List<Map<String, dynamic>> _validations = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().get('/validations/mes-validations');
      final dynamic raw = data['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (data is List ? data : []));
      if (!mounted) return;
      setState(() => _validations =
          (list as List).map((e) => e as Map<String, dynamic>).toList());
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final count = _validations.length;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
            // ── Hero AppBar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              stretch: true,
              backgroundColor: DS.secondary,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(fit: StackFit.expand, children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF001A5E), Color(0xFF003DA5),
                          Color(0xFF0057CC)],
                        stops: [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                  // Decorative blobs
                  Positioned(
                    right: -30, top: -30,
                    child: Container(
                      width: 150, height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -20, bottom: -20,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DS.warning.withValues(alpha: 0.10),
                      ),
                    ),
                  ),
                  SafeArea(child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DS.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.pending_actions_rounded,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text('Validations',
                            style: GoogleFonts.inter(
                              color: Colors.white, fontSize: 26,
                              fontWeight: FontWeight.w800,
                            )),
                          if (count > 0) ...[
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DS.warning,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(
                                  color: DS.warning.withValues(alpha: 0.4),
                                  blurRadius: 8, offset: const Offset(0, 2),
                                )],
                              ),
                              child: Text('$count',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 13, fontWeight: FontWeight.w800,
                                )),
                            ),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          count == 0
                              ? 'Aucune demande en attente'
                              : '$count demande${count > 1 ? "s" : ""} à traiter',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 13,
                          )),
                      ],
                    ),
                  )),
                ]),
              ),
              title: Row(children: [
                Text('Validations',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 16,
                    color: Colors.white,
                  )),
                if (count > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: DS.warning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$count',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 11, fontWeight: FontWeight.w800,
                      )),
                  ),
                ],
              ]),
            ),

            // ── Contenu ───────────────────────────────────────────────────
            if (_loading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ATShimmerCard(height: 180),
                  childCount: 4,
                ),
              )
            else if (_validations.isEmpty)
              SliverFillRemaining(child: _EmptyValidation())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _ValidationItem(
                    key: ValueKey(_validations[i]['id']),
                    validationId: _validations[i]['id'] as int,
                    mission: MissionModel.fromJson(
                        _validations[i]['mission'] as Map<String, dynamic>?
                        ?? _validations[i]),
                    index: i,
                    onAction: () {
                      HapticFeedback.mediumImpact();
                      _load();
                    },
                    onRefresh: _load,
                  )
                      .animate(delay: (i * 80).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.1, duration: 300.ms,
                          curve: Curves.easeOut),
                  childCount: _validations.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class _EmptyValidation extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          width: 110, height: 110,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 110, height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: DS.success.withValues(alpha: 0.04),
              ),
            ),
            Container(
              width: 76, height: 76,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [DS.success, const Color(0xFF059669)],
                ),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: DS.success.withValues(alpha: 0.35),
                  blurRadius: 20, offset: const Offset(0, 8),
                )],
              ),
              child: const Icon(Icons.task_alt_rounded,
                  size: 34, color: Colors.white),
            ),
          ]),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.95, end: 1.0, duration: 2000.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 24),
        Text('Tout est traité !',
          style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800,
            color: DS.textPrimary,
          )),
        const SizedBox(height: 8),
        Text('Aucune validation en attente',
          style: GoogleFonts.inter(
            color: DS.textSecondary, fontSize: 14)),
      ]),
    ),
  );
}

// ─── Validation Item ──────────────────────────────────────────────────────
class _ValidationItem extends StatefulWidget {
  final int validationId;
  final MissionModel mission;
  final int index;
  final VoidCallback onAction;
  final VoidCallback onRefresh;
  const _ValidationItem({
    super.key,
    required this.validationId,
    required this.mission,
    required this.index,
    required this.onAction,
    required this.onRefresh,
  });
  @override
  State<_ValidationItem> createState() => _ValidationItemState();
}

class _ValidationItemState extends State<_ValidationItem> {
  bool _acting = false;

  Future<void> _approuver() async {
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _acting = true);
    try {
      await ApiService()
          .post('/validations/${widget.validationId}/approuver');
      if (mounted) widget.onAction();
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _actionWithComment(String titre, String hint,
      Color color, String endpoint) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                endpoint.contains('rejet')
                    ? Icons.cancel_outlined
                    : Icons.edit_outlined,
                color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(titre,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 18,
                color: DS.textPrimary,
              )),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: DS.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: DS.border),
              ),
              child: TextField(
                controller: ctrl,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: GoogleFonts.inter(
                      color: DS.textPlaceholder, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DS.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
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
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: Center(child: Text('Envoyer',
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
    if (ok != true || ctrl.text.trim().isEmpty) return;
    if (!mounted) return;
    setState(() => _acting = true);
    try {
      await ApiService().post(
        '/validations/${widget.validationId}/$endpoint',
        {'commentaire': ctrl.text.trim()},
      );
      if (mounted) widget.onAction();
    } catch (e) {
      _showError(e.toString());
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: DS.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Dismissible(
        key: ValueKey('swipe_${widget.validationId}'),
        confirmDismiss: (direction) async {
          if (_acting) return false;
          if (direction == DismissDirection.startToEnd) {
            await _approuver();
            return false;
          } else {
            await _actionWithComment(
              'Motif du refus',
              'Expliquez le motif du refus…',
              DS.error, 'rejeter',
            );
            return false;
          }
        },
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: DS.gradientGreen,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            Text('Approuver',
              style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          ]),
        ),
        secondaryBackground: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFFDC2626), DS.error],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('Refuser',
              style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(width: 8),
            const Icon(Icons.cancel, color: Colors.white, size: 28),
          ]),
        ),
        child: MissionCard(
          mission: widget.mission,
          showUser: true,
          index: widget.index,
        ),
      ).animate(delay: (widget.index * 80).ms).fadeIn().slideY(begin: 0.1),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: _acting
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: SpinKitFadingCircle(color: DS.primary, size: 28),
                ),
              )
            : Row(children: [
                Expanded(
                  flex: 2,
                  child: _ActionBtn(
                    label: 'Valider',
                    gradient: DS.gradientGreen,
                    shadowColor: DS.primary,
                    onTap: _acting ? null : _approuver,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionBtn(
                    label: 'Modifier',
                    gradient: LinearGradient(
                      colors: [DS.warning,
                        DS.warning.withValues(alpha: 0.8)],
                    ),
                    shadowColor: DS.warning,
                    onTap: _acting ? null : () => _actionWithComment(
                        'Demander modifications',
                        'Modifications souhaitées…',
                        DS.warning, 'modifier'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _ActionBtn(
                    label: 'Refuser',
                    gradient: LinearGradient(
                      colors: [DS.error, const Color(0xFFDC2626)],
                    ),
                    shadowColor: DS.error,
                    onTap: _acting ? null : () => _actionWithComment(
                        'Motif du refus',
                        'Expliquez le motif du refus…',
                        DS.error, 'rejeter'),
                  ),
                ),
              ]),
      ),
      Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        color: DS.border.withValues(alpha: 0.5),
      ),
      const SizedBox(height: 4),
    ]);
  }
}

// ─── Action button ────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final String label;
  final LinearGradient gradient;
  final Color shadowColor;
  final VoidCallback? onTap;
  const _ActionBtn({
    required this.label,
    required this.gradient,
    required this.shadowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.selectionClick();
      onTap?.call();
    },
    child: Container(
      height: 42,
      decoration: BoxDecoration(
        gradient: onTap != null ? gradient : null,
        color: onTap == null ? DS.surfaceVariant : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: onTap != null ? [BoxShadow(
          color: shadowColor.withValues(alpha: 0.3),
          blurRadius: 8, offset: const Offset(0, 3),
        )] : null,
      ),
      child: Center(
        child: Text(label,
          style: GoogleFonts.inter(
            color: onTap != null ? Colors.white : DS.textMuted,
            fontSize: 13, fontWeight: FontWeight.w800,
          )),
      ),
    ),
  );
}
