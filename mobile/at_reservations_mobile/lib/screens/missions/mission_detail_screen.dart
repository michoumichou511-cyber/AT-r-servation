import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import '../../design/design_system.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';

class MissionDetailScreen extends StatefulWidget {
  final int id;
  const MissionDetailScreen({super.key, required this.id});
  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  Map<String, dynamic>? _raw;
  MissionModel?         _mission;
  bool   _loading = true;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService().get('/missions/${widget.id}');
      final m = data['data'] ?? data;
      final mMap = m as Map<String, dynamic>;
      setState(() {
        _raw     = mMap;
        _mission = MissionModel.fromJson(mMap);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: DS.primary))
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  Widget _buildError() => Scaffold(
    appBar: AppBar(
      title: Text('Détail Mission',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      backgroundColor: DS.secondary,
      foregroundColor: Colors.white,
    ),
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
          color: DS.error.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.wifi_off_outlined, color: DS.error, size: 32),
      ),
      const SizedBox(height: 16),
      Text('Erreur de chargement',
        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      Text(_error!,
        style: GoogleFonts.inter(color: DS.textSecondary, fontSize: 13)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: _load,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: DS.gradientGreen,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Réessayer',
            style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    ])),
  );

  Widget _buildBody() {
    final m        = _mission!;
    final raw      = _raw!;
    final statColor = DS.colorForStatut(m.statut);

    return CustomScrollView(slivers: [
      // ── AppBar gradient ──────────────────────────────────────────────
      SliverAppBar(
        expandedHeight: 220,
        pinned: true,
        stretch: true,
        backgroundColor: DS.secondary,
        foregroundColor: Colors.white,
        title: Text(m.numeroUnique ?? 'Détail Mission',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
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
              right: -40, top: -40,
              child: Container(
                width: 180, height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -20, bottom: -20,
              child: Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Numéro badge
                  if (m.numeroUnique != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(m.numeroUnique!,
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11, fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        )),
                    ),
                  const SizedBox(height: 8),
                  Text(m.displayTitre,
                    style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 19,
                      fontWeight: FontWeight.w800, height: 1.2,
                    ),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 12),
                  Row(children: [
                    StatusBadge(m.statut),
                    const SizedBox(width: 8),
                    if (m.typeMission != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Text(m.typeMission!,
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w600,
                          )),
                      ),
                  ]),
                ],
              ),
            )),
          ]),
        ),
      ),

      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        sliver: SliverList(delegate: SliverChildListDelegate([

          // ── Infos générales ──────────────────────────────────────────
          _ExpansionCard(
            leading: Icon(IconlyLight.document, color: DS.secondary),
            title: 'Informations générales',
            initiallyExpanded: true,
            children: [
              _DetailRow(label: 'N° unique',    value: m.numeroUnique),
              _DetailRow(label: 'Titre',        value: m.titre),
              _DetailRow(label: 'Objet',        value: m.objetMission),
              _DetailRow(label: 'Destination',  value: m.destination),
              _DetailRow(label: 'Type',         value: m.typeMission),
              _DetailRow(label: 'Statut',       value: m.statut,
                  valueColor: statColor),
            ],
          ),
          const SizedBox(height: 10),

          // ── Déplacement ──────────────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(IconlyLight.location, color: DS.warning),
            title: 'Déplacement',
            children: [
              _DetailRow(label: 'Date départ', value: m.dates?.depart),
              _DetailRow(label: 'Date retour', value: m.dates?.retour),
              _DetailRow(label: 'Destination', value: m.destination),
              // Try reading extra fields from raw
              _DetailRow(label: 'Moyen transport',
                  value: raw['moyen_transport'] as String?),
              _DetailRow(label: 'Lieu départ',
                  value: raw['lieu_depart'] as String?),
            ],
          ),
          const SizedBox(height: 10),

          // ── Réservations ─────────────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(Icons.hotel_outlined, color: DS.info),
            title: 'Réservations',
            children: _buildReservations(raw),
          ),
          const SizedBox(height: 10),

          // ── Timeline validation ──────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(Icons.timeline, color: DS.success),
            title: 'Historique de validation',
            children: _buildTimeline(raw),
          ),
          const SizedBox(height: 10),

          // ── Documents ────────────────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(IconlyLight.document, color: DS.error),
            title: 'Documents',
            children: _buildDocuments(raw),
          ),
          const SizedBox(height: 24),

          // ── Boutons d'action conditionnels ───────────────────────────
          ..._buildActions(m),
          const SizedBox(height: 100),
        ])),
      ),
    ]);
  }

  List<Widget> _buildReservations(Map<String, dynamic> raw) {
    final List? hotels = raw['reservations_hotel'] as List?
        ?? (raw['hotel'] != null ? [raw['hotel']] : null);
    final List? billets = raw['billets_avion'] as List?;

    if ((hotels == null || hotels.isEmpty) && (billets == null || billets.isEmpty)) {
      return [const _EmptySection('Aucune réservation')];
    }
    return [
      if (hotels != null && hotels.isNotEmpty) ...[
        const _SubTitle('Hôtels'),
        ...hotels.map((h) {
          final hm = h as Map<String, dynamic>;
          return _DetailRow(
            label: hm['hotel_nom'] as String? ?? hm['nom'] as String? ?? 'Hôtel',
            value: '${hm['check_in'] ?? ''} → ${hm['check_out'] ?? ''}',
          );
        }),
      ],
      if (billets != null && billets.isNotEmpty) ...[
        const _SubTitle('Billets d\'avion'),
        ...billets.map((b) {
          final bm = b as Map<String, dynamic>;
          return _DetailRow(
            label: '${bm['depart'] ?? ''} → ${bm['arrivee'] ?? ''}',
            value: bm['compagnie'] as String?,
          );
        }),
      ],
    ];
  }

  List<Widget> _buildTimeline(Map<String, dynamic> raw) {
    final List? history = raw['historique_validation'] as List?
        ?? raw['validations'] as List?;
    if (history == null || history.isEmpty) {
      return [const _EmptySection('Aucun historique')];
    }
    return List.generate(history.length, (i) {
      final item = history[i] as Map<String, dynamic>;
      final action = item['action'] as String?
          ?? item['statut'] as String? ?? 'Action';
      final acteur = item['acteur'] as String?
          ?? item['validateur'] as String? ?? '';
      DateTime? date;
      final rawDate = item['created_at'] as String?
          ?? item['date'] as String?;
      if (rawDate != null) {
        try { date = DateTime.parse(rawDate); } catch (_) {}
      }
      return _TimelineItem(
        action:   action,
        acteur:   acteur,
        date:     date != null ? DateFormat('dd/MM/yyyy HH:mm').format(date) : '',
        isLast:   i == history.length - 1,
        color:    _timelineColor(action),
      );
    });
  }

  Color _timelineColor(String action) {
    final a = action.toLowerCase();
    if (a.contains('valid') || a.contains('approu')) return DS.success;
    if (a.contains('rejet') || a.contains('refus')) return DS.error;
    if (a.contains('modif')) return DS.warning;
    return DS.info;
  }

  List<Widget> _buildDocuments(Map<String, dynamic> raw) {
    final List? docs = raw['documents'] as List?
        ?? raw['fichiers'] as List?;
    if (docs == null || docs.isEmpty) {
      return [const _EmptySection('Aucun document joint')];
    }
    return docs.map((d) {
      final dm = d as Map<String, dynamic>;
      final nom = dm['nom'] as String? ?? dm['name'] as String? ?? 'Document';
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: DS.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.picture_as_pdf_outlined,
              color: DS.error, size: 20),
        ),
        title: Text(nom, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.download_outlined, size: 18,
            color: DS.textSecondary),
      );
    }).toList();
  }

  List<Widget> _buildActions(MissionModel m) {
    final s = m.statut;
    final actions = <Widget>[];

    if (s == 'brouillon') {
      actions.add(_ActionButton(
        label: 'Soumettre la mission',
        icon: Icons.send_outlined,
        color: DS.primary,
        onTap: () => _submit(m.id),
      ));
      actions.add(const SizedBox(height: 10));
      actions.add(_ActionButton(
        label: 'Modifier',
        icon: Icons.edit_outlined,
        color: DS.secondary,
        outlined: true,
        onTap: () {},
      ));
    } else if (s == 'soumis' || s == 'en_attente' || s == 'en_cours') {
      actions.add(_ActionButton(
        label: 'Annuler la demande',
        icon: Icons.cancel_outlined,
        color: DS.error,
        outlined: true,
        onTap: () => _cancel(m.id),
      ));
    }

    return actions;
  }

  Future<void> _submit(int id) async {
    try {
      await ApiService().post('/missions/$id/submit');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission soumise ✓'),
              backgroundColor: DS.success,
              behavior: SnackBarBehavior.floating));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: DS.error,
              behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _cancel(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Annuler la mission ?'),
        content: const Text('Cette action ne peut pas être annulée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: DS.error),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService().post('/missions/$id/cancel');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mission annulée'),
              backgroundColor: DS.warning,
              behavior: SnackBarBehavior.floating));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()),
              backgroundColor: DS.error,
              behavior: SnackBarBehavior.floating));
      }
    }
  }
}

// ─── ExpansionCard ─────────────────────────────────────────────────────────
class _ExpansionCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;
  const _ExpansionCard({
    required this.leading,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: DS.shadowSm,
    ),
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: leading,
        title: Text(title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w700,
              fontSize: 15, color: DS.textPrimary)),
        initiallyExpanded: initiallyExpanded,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    ),
  );
}

// ─── Detail Row ────────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final String  label;
  final String? value;
  final Color?  valueColor;
  const _DetailRow({required this.label, this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label,
            style: const TextStyle(color: DS.textSecondary, fontSize: 13)),
        ),
        Expanded(child: Text(value!,
          style: TextStyle(
            color: valueColor ?? DS.textPrimary,
            fontSize: 13, fontWeight: FontWeight.w600,
          ))),
      ]),
    );
  }
}

// ─── Sub title ─────────────────────────────────────────────────────────────
class _SubTitle extends StatelessWidget {
  final String text;
  const _SubTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 4),
    child: Text(text, style: const TextStyle(
        fontWeight: FontWeight.w700, fontSize: 13,
        color: DS.textSecondary)),
  );
}

// ─── Empty section ─────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  final String text;
  const _EmptySection(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(text,
      style: const TextStyle(color: DS.textSecondary,
          fontStyle: FontStyle.italic)),
  );
}

// ─── Timeline Item ─────────────────────────────────────────────────────────
class _TimelineItem extends StatelessWidget {
  final String action;
  final String acteur;
  final String date;
  final bool   isLast;
  final Color  color;
  const _TimelineItem({
    required this.action, required this.acteur,
    required this.date, required this.isLast, required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Ligne timeline
      Column(children: [
        Container(
          width: 14, height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (!isLast)
          Container(width: 2, height: 48, color: Colors.grey.shade200),
      ]),
      const SizedBox(width: 12),
      Expanded(child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(action,
            style: TextStyle(fontWeight: FontWeight.w700,
                fontSize: 13, color: color)),
          if (acteur.isNotEmpty)
            Text(acteur, style: const TextStyle(
                fontSize: 12, color: DS.textSecondary)),
          Text(date, style: const TextStyle(
              fontSize: 11, color: DS.textSecondary)),
        ]),
      )),
    ],
  );
}

// ─── Action Button ─────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     outlined;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.mediumImpact();
      onTap();
    },
    child: Container(
      width: double.infinity, height: 54,
      decoration: outlined
          ? BoxDecoration(
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(16),
            )
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 14, offset: const Offset(0, 5),
              )],
            ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 20,
            color: outlined ? color : Colors.white),
        const SizedBox(width: 10),
        Text(label,
          style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w700,
            color: outlined ? color : Colors.white,
          )),
      ]),
    ),
  );
}
