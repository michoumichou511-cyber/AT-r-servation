import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/mission.dart';

// ─── Badge statut ──────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String statut;
  const StatusBadge(this.statut, {super.key});

  static const _icons = {
    'brouillon':                Icons.edit_outlined,
    'soumis':                   Icons.send_outlined,
    'en_attente':               Icons.hourglass_empty,
    'en_validation':            Icons.pending_outlined,
    'approuve':                 Icons.check_circle_outline,
    'rejete':                   Icons.cancel_outlined,
    'termine':                  Icons.done_all,
    'en_traitement_logistique': Icons.local_shipping_outlined,
    'valide':                   Icons.verified_outlined,
    'annule':                   Icons.block_outlined,
    'en_cours':                 Icons.play_circle_outline,
  };

  @override
  Widget build(BuildContext context) {
    final color = DS.colorForStatut(statut);
    final icon  = _icons[statut] ?? Icons.circle_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          DS.labelForStatut(statut),
          style: GoogleFonts.inter(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ]),
    );
  }
}

// ─── Shimmer skeleton ──────────────────────────────────────────
class MissionCardSkeleton extends StatelessWidget {
  const MissionCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 116,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20),
      ),
    ),
  );
}

// ─── MissionCard ───────────────────────────────────────────────
class MissionCard extends StatefulWidget {
  final MissionModel mission;
  final VoidCallback? onTap;
  final bool showUser;
  final int index;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.showUser = false,
    this.index = 0,
  });

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard>
    // FIX-5 : 2 AnimationController (_pressCtrl + _flipCtrl) necessitent
    // TickerProviderStateMixin (SingleTickerProviderStateMixin ne supporte
    // qu'un seul vsync, causait crash sur builds release).
    with TickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;

  // 3D flip
  late final AnimationController _flipCtrl;
  late final Animation<double> _flipAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _pressAnim = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
    _flipCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 520));
    _flipAnim = Tween<double>(begin: 0.0, end: pi)
        .animate(CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    _flipCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) { HapticFeedback.lightImpact(); _pressCtrl.forward(); }
  void _onTapUp(_) => _pressCtrl.reverse();
  void _onTapCancel() => _pressCtrl.reverse();

  void _flipCard() {
    HapticFeedback.mediumImpact();
    if (_flipCtrl.isCompleted) {
      _flipCtrl.reverse();
    } else {
      _flipCtrl.forward();
    }
  }

  Widget _buildBack(Color color) {
    final m = widget.mission;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.75)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.40),
            blurRadius: 22, offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row: title + flip button
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(m.displayTitre,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.w800, height: 1.25,
                ),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _flipCard,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flip_camera_android_rounded,
                    color: Colors.white, size: 15),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Statut badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(DS.labelForStatut(m.statut),
              style: GoogleFonts.inter(
                color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700,
              )),
          ),
          const SizedBox(height: 10),
          // Destination
          Row(children: [
            const Icon(Icons.location_on_outlined, color: Colors.white70, size: 13),
            const SizedBox(width: 5),
            Expanded(child: Text(m.displayDest,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.88), fontSize: 12),
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: 5),
          // Dates
          Row(children: [
            const Icon(Icons.calendar_today_outlined, color: Colors.white70, size: 13),
            const SizedBox(width: 5),
            Text(m.displayDates,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.88), fontSize: 12)),
          ]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statutColor = DS.colorForStatut(widget.mission.statut);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 260 + widget.index * 50),
      curve: Curves.easeOutCubic,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 20 * (1 - v)), child: child),
      ),
      child: AnimatedBuilder(
        animation: _flipAnim,
        builder: (ctx, frontChild) {
          final angle = _flipAnim.value;
          final showFront = angle <= pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showFront
              ? frontChild!
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(pi),
                  child: _buildBack(statutColor),
                ),
          );
        },
        child: ScaleTransition(
          scale: _pressAnim,
          child: GestureDetector(
            onTapDown: widget.onTap != null ? _onTapDown : null,
            onTapUp:   widget.onTap != null ? _onTapUp   : null,
            onTapCancel: widget.onTap != null ? _onTapCancel : null,
            onTap: widget.onTap,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statutColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: context.shadowColor,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: IntrinsicHeight(
                  child: Row(children: [
                    // Bande colorée gauche
                    Container(
                      width: 5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [statutColor, statutColor.withValues(alpha: 0.4)],
                        ),
                      ),
                    ),

                    // Contenu
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Numéro + badge + flip button
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  widget.mission.numeroUnique ?? 'OM-????',
                                  style: GoogleFonts.inter(
                                    color: context.textMuted,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Spacer(),
                                StatusBadge(widget.mission.statut),
                                const SizedBox(width: 6),
                                GestureDetector(
                                  onTap: _flipCard,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: context.subtleBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.flip_camera_android_rounded,
                                      size: 12,
                                      color: context.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Titre
                            Text(
                              widget.mission.displayTitre,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: context.textPrimary,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),

                            // Demandeur (validations)
                            if (widget.showUser && widget.mission.user != null) ...[
                              const SizedBox(height: 4),
                              Row(children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 12,
                                    color: DS.secondary.withValues(alpha: 0.7)),
                                const SizedBox(width: 4),
                                Text(
                                  widget.mission.user!.nomComplet,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: DS.secondary.withValues(alpha: 0.8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ]),
                            ],

                            const SizedBox(height: 10),
                            Container(height: 1, color: context.dividerColor),
                            const SizedBox(height: 10),

                            // Destination + Dates
                            Row(children: [
                              Expanded(
                                child: Row(children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 13, color: DS.primary),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      widget.mission.displayDest,
                                      style: DS.caption.copyWith(color: context.textMuted),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ]),
                              ),
                              const SizedBox(width: 8),
                              Row(children: [
                                Icon(Icons.calendar_today_outlined,
                                    size: 13, color: DS.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  widget.mission.displayDates,
                                  style: DS.caption.copyWith(color: context.textMuted),
                                ),
                              ]),
                            ]),
                          ],
                        ),
                      ),
                    ),

                    // Chevron
                    if (widget.onTap != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: context.textMuted,
                          size: 20,
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
