import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/notification.dart';
import '../../services/api_service.dart';

// ─── Config par type ───────────────────────────────────────────────────────
class _NotifStyle {
  final Color color;
  final IconData icon;
  final String emoji;
  const _NotifStyle(this.color, this.icon, this.emoji);
}

_NotifStyle _styleFor(String? type) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('valid') || t.contains('approu') || t == 'success') {
    return _NotifStyle(DS.success, Icons.check_circle_outline, '✅');
  }
  if (t.contains('rejet') || t.contains('refus') || t == 'danger') {
    return _NotifStyle(DS.error, Icons.cancel_outlined, '❌');
  }
  if (t.contains('modif') || t == 'warning') {
    return _NotifStyle(DS.warning, Icons.warning_amber_outlined, '⚠️');
  }
  return _NotifStyle(DS.info, Icons.notifications_outlined, '🔔');
}

String _group(DateTime? d) {
  if (d == null) return "Aujourd'hui"; // date inconnue → groupe aujourd'hui
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day   = DateTime(d.year, d.month, d.day);
  final diff  = today.difference(day).inDays;
  if (diff == 0) return "Aujourd'hui";
  if (diff <= 7) return 'Cette semaine';
  return 'Plus ancien';
}

// ─── Notifications Screen ──────────────────────────────────────────────────
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifs = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService().get('/notifications');
      final dynamic raw = data['data'];
      final list = raw is List ? raw
          : (raw is Map<String, dynamic> ? (raw['data'] ?? raw)
          : (data is List ? data : []));
      if (!mounted) return;
      setState(() => _notifs = (list as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList());
    } catch (_) {}
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _markAllRead() async {
    HapticFeedback.mediumImpact();
    try {
      await ApiService().put('/notifications/tout-lire');
      if (mounted) {
        setState(() => _notifs =
            _notifs.map((n) => n.copyWith(lu: true)).toList());
      }
    } catch (_) {}
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService().put('/notifications/$id/lire');
    } catch (_) {}
    if (mounted) {
      setState(() => _notifs = _notifs.map((n) =>
          n.id == id ? n.copyWith(lu: true) : n).toList());
    }
  }

  Future<void> _dismiss(int id) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService().delete('/notifications/$id');
    } catch (_) {}
    if (!mounted) return;
    setState(() => _notifs.removeWhere((n) => n.id == id));
  }

  List<Widget> _buildGrouped() {
    final Map<String, List<NotificationModel>> groups = {};
    const order = ["Aujourd'hui", 'Cette semaine', 'Plus ancien', 'Date inconnue'];
    for (final n in _notifs) {
      groups.putIfAbsent(_group(n.createdAt), () => []).add(n);
    }
    final widgets = <Widget>[];
    var globalIdx = 0;
    for (final key in order) {
      if (!groups.containsKey(key)) continue;
      widgets.add(_GroupHeader(key));
      for (final n in groups[key]!) {
        widgets.add(_NotifCard(
          notif:     n,
          index:     globalIdx++,
          onTap:     () { if (!n.lu) _markRead(n.id); },
          onDismiss: () => _dismiss(n.id),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => !n.lu).length;
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Hero AppBar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 140,
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
                      colors: [Color(0xFF001A5E), Color(0xFF003DA5), Color(0xFF0057CC)],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // Decorative elements
                Positioned(
                  right: -30, top: -30,
                  child: Container(
                    width: 140, height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),
                Positioned(
                  left: 20, bottom: -10,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DS.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                SafeArea(child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Flexible(child: Text('Notifications',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white, fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ))),
                        if (unread > 0) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3),
                            decoration: BoxDecoration(
                              color: DS.error,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(
                                color: DS.error.withValues(alpha: 0.4),
                                blurRadius: 8, offset: const Offset(0, 2),
                              )],
                            ),
                            child: Text('$unread',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12, fontWeight: FontWeight.w800,
                              )),
                          ),
                        ],
                        const Spacer(),
                        if (_notifs.isNotEmpty)
                          GestureDetector(
                            onTap: _markAllRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.done_all,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text('Tout lire',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                  )),
                              ]),
                            ),
                          ),
                      ]),
                    ],
                  ),
                )),
              ]),
            ),
            title: Row(children: [
              Flexible(child: Text('Notifications',
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white))),
              if (unread > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: DS.error,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$unread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w800,
                    )),
                ),
              ],
            ]),
          ),

          // ── Hint swipe ────────────────────────────────────────────────
          if (!_loading && unread > 0)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: DS.info.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DS.info.withValues(alpha: 0.18)),
                ),
                child: Row(children: [
                  Icon(Icons.swipe_left_rounded,
                      size: 16, color: DS.info.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Glissez pour supprimer · Appuyez pour marquer lu',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: DS.info.withValues(alpha: 0.8)))),
                ]),
              ),
            ),

          // ── Contenu ───────────────────────────────────────────────────
          if (_loading)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) => _NotifSkeleton(),
                childCount: 6,
              ),
            )
          else if (_notifs.isEmpty)
            SliverFillRemaining(child: _EmptyState())
          else
            SliverList(
              delegate: SliverChildListDelegate([
                ..._buildGrouped(),
                const SizedBox(height: 120),
              ]),
            ),
        ],
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
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
                color: DS.success.withValues(alpha: 0.05),
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
              child: const Icon(Icons.done_all,
                  size: 34, color: Colors.white),
            ),
          ]),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 0.95, end: 1.0, duration: 2000.ms,
                curve: Curves.easeInOut),
        const SizedBox(height: 24),
        Text('Tout est lu !',
          style: GoogleFonts.inter(
            fontSize: 22, fontWeight: FontWeight.w800, color: context.textPrimary))
            .animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 8),
        Text('Aucune notification pour le moment',
          style: GoogleFonts.inter(color: context.textSecondary, fontSize: 14))
            .animate().fadeIn(delay: 200.ms),
      ]),
    ),
  );
}

// ─── Skeleton ─────────────────────────────────────────────────────────────
class _NotifSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: context.shimmerBase,
    highlightColor: context.shimmerHighlight,
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 88,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}

// ─── Group header ──────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: DS.secondary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w800,
            color: DS.secondary.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          )),
      ),
      const SizedBox(width: 10),
      Expanded(child: Container(
        height: 1,
        color: DS.secondary.withValues(alpha: 0.08),
      )),
    ]),
  );
}

// ─── Notification card ────────────────────────────────────────────────────
class _NotifCard extends StatelessWidget {
  final NotificationModel notif;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  const _NotifCard({
    required this.notif,
    required this.index,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(notif.type);
    final dateStr = notif.createdAt != null
        ? DateFormat('dd MMM · HH:mm', 'fr_FR').format(notif.createdAt!)
        : 'À l\'instant';

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [DS.error, const Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
          const SizedBox(height: 3),
          Text('Supprimer',
            style: GoogleFonts.inter(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
        ]),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: context.shadowColor, blurRadius: 4, offset: const Offset(0, 2))],
            border: Border(
              left: BorderSide(
                color: notif.lu
                    ? style.color.withValues(alpha: 0.25)
                    : style.color,
                width: notif.lu ? 3 : 5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon container
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      style.color.withValues(alpha: notif.lu ? 0.10 : 0.20),
                      style.color.withValues(alpha: notif.lu ? 0.05 : 0.12),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon,
                  color: style.color.withValues(alpha: notif.lu ? 0.55 : 1.0),
                  size: 20),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(child: Text(notif.titre ?? 'Notification',
                      style: GoogleFonts.inter(
                        fontWeight: notif.lu ? FontWeight.w600 : FontWeight.w800,
                        fontSize: 14, color: context.textPrimary,
                      ))),
                    if (!notif.lu) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 9, height: 9,
                        decoration: BoxDecoration(
                          color: style.color,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(
                            color: style.color.withValues(alpha: 0.4),
                            blurRadius: 4, spreadRadius: 1,
                          )],
                        ),
                      ),
                    ],
                  ]),
                  if (notif.message != null) ...[
                    const SizedBox(height: 4),
                    Text(notif.message!,
                      style: GoogleFonts.inter(
                        color: context.textMuted.withValues(
                            alpha: notif.lu ? 0.7 : 1.0),
                        fontSize: 12, height: 1.4),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: DS.textPlaceholder),
                    const SizedBox(width: 4),
                    Text(dateStr,
                      style: GoogleFonts.inter(
                        color: DS.textPlaceholder, fontSize: 11)),
                  ]),
                ],
              )),
            ]),
          ),
        ),
      ),
    )
        .animate(delay: (index * 40).ms)
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, duration: 280.ms, curve: Curves.easeOut);
  }
}
