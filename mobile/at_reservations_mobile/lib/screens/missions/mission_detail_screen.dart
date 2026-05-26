import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../design/design_system.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../utils/status_utils.dart';
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
  bool   _loading      = true;
  bool   _exportingPdf = false;
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
          ? const Center(child: SpinKitWave(color: DS.primary, size: 30))
          : _error != null
              ? _buildError()
              : _buildBodySafe(),
    );
  }

  Widget _buildBodySafe() {
    try {
      return _buildBody();
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Impossible de charger cette mission',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              e.toString(),
              style: GoogleFonts.inter(
                color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DS.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }
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
    if (_mission == null || _raw == null) return const SizedBox.shrink();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Exporter PDF',
            onPressed: _exportingPdf ? null : _exportPdf,
          ),
          const SizedBox(width: 4),
        ],
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
              _DetailRow(label: 'Titre',        value: m.titre ?? m.objetMission ?? 'Sans titre'),
              _DetailRow(label: 'Objet',        value: m.objetMission ?? m.titre ?? 'Non renseigné'),
              _DetailRow(label: 'Destination',  value: m.destination ?? 'Non renseignée'),
              _DetailRow(label: 'Type',         value: _typeMissionLabel(m.typeMission)),
              _DetailRow(label: 'Statut',       value: statusLabel(m.statut),
                  valueColor: statColor),
            ],
          ).animate(delay: 80.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
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
          ).animate(delay: 160.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
          const SizedBox(height: 10),

          // ── Réservations ─────────────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(Icons.hotel_outlined, color: DS.info),
            title: 'Réservations',
            children: _buildReservations(raw),
          ).animate(delay: 240.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
          const SizedBox(height: 10),

          // ── Timeline validation ──────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(Icons.timeline, color: DS.success),
            title: 'Historique de validation',
            children: _buildTimeline(raw),
          ).animate(delay: 320.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
          const SizedBox(height: 10),

          // ── Documents ────────────────────────────────────────────────
          _ExpansionCard(
            leading: const Icon(IconlyLight.document, color: DS.error),
            title: 'Documents',
            children: _buildDocuments(raw),
          ).animate(delay: 400.ms).fadeIn(duration: 300.ms).slideY(begin: 0.06),
          const SizedBox(height: 24),

          // ── Boutons d'action conditionnels ───────────────────────────
          ..._buildActions(m),
          const SizedBox(height: 140),
        ])),
      ),
    ]);
  }

  /// Convertit une valeur numérique ou String en String lisible.
  static String? _toStr(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isNotEmpty ? v : null;
    if (v is num)   return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    return v.toString();
  }

  static String? _typeMissionLabel(String? t) {
    if (t == null) return null;
    switch (t.toLowerCase()) {
      case 'formation':   return 'Formation';
      case 'conference':  return 'Conférence';
      case 'reunion':     return 'Réunion';
      case 'inspection':  return 'Inspection';
      case 'audit':       return 'Audit';
      case 'autre':       return 'Autre';
      default:            return t;
    }
  }

  List<Widget> _buildReservations(Map<String, dynamic> raw) {
    // L'API renvoie raw['reservations'] via ReservationResource
    final List? reservations = raw['reservations'] as List?;
    if (reservations == null || reservations.isEmpty) {
      return [const _EmptySection('Aucune réservation')];
    }
    return reservations.map((r) {
      final rm   = r as Map<String, dynamic>;
      final type = rm['type_label'] as String?
          ?? rm['type'] as String? ?? 'Réservation';
      final notes   = _toStr(rm['notes']);
      final montant = _toStr(rm['montant_estime']);
      final statut  = rm['statut'] as String? ?? '';
      final icon = switch (rm['type'] as String? ?? '') {
        'hebergement' => Icons.hotel_outlined,
        'billet'      => Icons.confirmation_number_outlined,
        'restauration'=> Icons.restaurant_outlined,
        _             => Icons.receipt_long_outlined,
      };
      final color = switch (rm['type'] as String? ?? '') {
        'hebergement' => DS.info,
        'billet'      => DS.primary,
        'restauration'=> DS.warning,
        _             => DS.secondary,
      };
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: TextStyle(
                    fontWeight: FontWeight.w700, color: color, fontSize: 13)),
                if (notes != null && notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(notes, style: const TextStyle(
                        fontSize: 12, color: DS.textSecondary)),
                  ),
                if (montant != null && montant.isNotEmpty)
                  Text('Budget : $montant', style: const TextStyle(
                      fontSize: 12, color: DS.textSecondary)),
              ],
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statutResaColor(statut).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(statut, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: _statutResaColor(statut))),
            ),
          ]),
        ),
      );
    }).toList();
  }

  Color _statutResaColor(String s) {
    switch (s) {
      case 'confirme': return DS.success;
      case 'annule':   return DS.error;
      default:         return DS.warning;
    }
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
    // L'API renvoie raw['documentation'] via DocumentResource
    final List? docs = raw['documentation'] as List?
        ?? raw['documents'] as List?;
    if (docs == null || docs.isEmpty) {
      return [const _EmptySection('Aucun document joint')];
    }
    return docs.map((d) {
      final dm   = d as Map<String, dynamic>;
      final nom  = dm['nom_fichier'] as String?
          ?? dm['nom'] as String? ?? dm['name'] as String? ?? 'Document';
      final mime = dm['mime_type'] as String? ?? '';
      final isPdf = mime.contains('pdf') || nom.toLowerCase().endsWith('.pdf');
      final isImg = mime.contains('image');
      final icon  = isPdf ? Icons.picture_as_pdf_outlined
          : isImg ? Icons.image_outlined
          : Icons.insert_drive_file_outlined;
      final color = isPdf ? DS.error : isImg ? DS.info : DS.secondary;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(child: Text(nom, style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis)),
            Icon(Icons.download_outlined, size: 18, color: DS.textSecondary),
          ]),
        ),
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
        onTap: () => _editDraft(m),
      ));
      actions.add(const SizedBox(height: 10));
      actions.add(_ActionButton(
        label: 'Supprimer le brouillon',
        icon: Icons.delete_outline_rounded,
        color: DS.error,
        outlined: true,
        onTap: () => _deleteDraft(m.id),
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

  // ── Génération PDF Ordre de Mission ──────────────────────────────────────
  Future<void> _exportPdf() async {
    if (_mission == null || _raw == null) return;
    setState(() => _exportingPdf = true);

    try {
      final m   = _mission!;
      final raw = _raw!;
      final doc = pw.Document();

      // ── Couleur AT pour le PDF ───────────────────────────────────────────
      const atBlue  = PdfColor.fromInt(0xFF003DA5);
      const atGreen = PdfColor.fromInt(0xFF00A650);
      const grey    = PdfColor.fromInt(0xFF6B7280);
      const lightBg = PdfColor.fromInt(0xFFF0F4FF);

      // Helpers
      pw.Widget buildField(String label, String? value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: grey)),
          ),
          pw.Expanded(child: pw.Text(value?.isNotEmpty == true ? value! : '—',
            style: pw.TextStyle(
              fontSize: 10, fontWeight: pw.FontWeight.bold))),
        ]),
      );

      pw.Widget buildSection(String title, List<pw.Widget> children) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: lightBg,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6), topRight: pw.Radius.circular(6)),
            ),
            child: pw.Text(title,
              style: pw.TextStyle(
                fontSize: 9, fontWeight: pw.FontWeight.bold, color: atBlue)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children),
          ),
        ]),
      );

      // ── Documents list ───────────────────────────────────────────────────
      final docs = (raw['documentation'] as List? ?? raw['documents'] as List? ?? [])
          .map((d) {
            final dm = d as Map<String, dynamic>;
            return dm['nom_fichier'] as String?
                ?? dm['nom'] as String?
                ?? dm['name'] as String?
                ?? 'Document';
          })
          .toList();

      // ── Dates helpers ────────────────────────────────────────────────────
      final fmt     = DateFormat('dd/MM/yyyy');
      final nowFmt  = fmt.format(DateTime.now());
      final createdAt = raw['created_at'] as String?;
      String createdFmt = '—';
      if (createdAt != null) {
        try { createdFmt = fmt.format(DateTime.parse(createdAt)); } catch (_) {}
      }

      final departRaw = m.dates?.depart;
      final retourRaw = m.dates?.retour;
      String departFmt = '—', retourFmt = '—';
      if (departRaw != null) { try { departFmt = fmt.format(DateTime.parse(departRaw)); } catch (_) {} }
      if (retourRaw != null) { try { retourFmt = fmt.format(DateTime.parse(retourRaw)); } catch (_) {} }

      // ── Demandeur ────────────────────────────────────────────────────────
      final demandeur = raw['demandeur'] as Map<String, dynamic>?;
      final demName   = demandeur != null
          ? '${demandeur['prenom'] ?? ''} ${demandeur['nom'] ?? ''}'.trim()
          : (raw['user_name'] as String? ?? '—');
      final demPoste  = demandeur?['poste'] as String?
          ?? demandeur?['titre'] as String? ?? '—';
      final demDir    = demandeur?['direction'] as String?
          ?? raw['direction'] as String? ?? '—';

      // ── Page ─────────────────────────────────────────────────────────────
      doc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [atBlue, PdfColor.fromInt(0xFF0057CC)]),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                    pw.Text('AT',
                      style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                    pw.Container(width: 30, height: 2,
                      color: atGreen,
                      margin: const pw.EdgeInsets.only(top: 2)),
                    pw.SizedBox(height: 4),
                    pw.Text('Algérie Télécom',
                      style: pw.TextStyle(fontSize: 9, color: const PdfColor(1, 1, 1, 0.7))),
                  ]),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                    pw.Text('ORDRE DE MISSION',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
                    if (m.numeroUnique != null)
                      pw.Text(m.numeroUnique!,
                        style: pw.TextStyle(fontSize: 10, color: const PdfColor(1, 1, 1, 0.7))),
                    pw.Text('Généré le $nowFmt',
                      style: pw.TextStyle(fontSize: 8, color: const PdfColor(1, 1, 1, 0.54))),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ── Titre mission ────────────────────────────────────────────
            pw.Text(m.displayTitre,
              style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold, color: atBlue)),
            pw.SizedBox(height: 4),
            pw.Row(children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(statusColor(m.statut).toARGB32()),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                ),
                child: pw.Text(statusLabel(m.statut),
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold)),
              ),
              if (m.typeMission != null) ...[
                pw.SizedBox(width: 8),
                pw.Text(m.typeMission!,
                  style: pw.TextStyle(fontSize: 9, color: grey)),
              ],
            ]),
            pw.SizedBox(height: 16),

            // ── Sections ─────────────────────────────────────────────────
            buildSection('DEMANDEUR', [
              buildField('Nom complet', demName),
              buildField('Poste',       demPoste),
              buildField('Direction',   demDir),
            ]),

            buildSection('DÉPLACEMENT', [
              buildField('Objet de la mission', m.objetMission ?? m.titre),
              buildField('Destination',  m.destination),
              buildField('Date départ',  departFmt),
              buildField('Date retour',  retourFmt),
              buildField('Date création', createdFmt),
            ]),

            if (docs.isNotEmpty)
              buildSection('PIÈCES JUSTIFICATIVES', [
                ...docs.map((name) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Row(children: [
                    pw.Text('•  ', style: pw.TextStyle(color: atBlue)),
                    pw.Text(name, style: pw.TextStyle(fontSize: 10)),
                  ]),
                )),
              ]),

            pw.Spacer(),

            // ── Footer ──────────────────────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(
                    color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5))),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('© Algérie Télécom — AT Réservations',
                    style: pw.TextStyle(fontSize: 8, color: grey)),
                  pw.Text('Document généré automatiquement',
                    style: pw.TextStyle(fontSize: 8, color: grey)),
                ],
              ),
            ),
          ],
        ),
      ));

      // ── Partage natif ────────────────────────────────────────────────────
      await Printing.sharePdf(
        bytes: await doc.save(),
        filename: 'mission_${m.numeroUnique ?? m.id}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur PDF : $e'),
          backgroundColor: DS.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
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

  // ── Modifier brouillon ────────────────────────────────────────────────────
  Future<void> _editDraft(MissionModel m) async {
    final objetCtrl = TextEditingController(
        text: m.objetMission ?? m.titre ?? '');
    final destCtrl  = TextEditingController(text: m.destination ?? '');
    DateTime? depart = m.dates?.depart != null
        ? DateTime.tryParse(m.dates!.depart!) : null;
    DateTime? retour = m.dates?.retour != null
        ? DateTime.tryParse(m.dates!.retour!) : null;
    bool saving = false;

    final fmt = DateFormat('yyyy-MM-dd');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Modifier la mission',
                style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: DS.textPrimary)),
              const SizedBox(height: 20),
              // Objet
              TextField(
                controller: objetCtrl,
                decoration: InputDecoration(
                  labelText: 'Objet de la mission',
                  prefixIcon: const Icon(Icons.work_outline_rounded, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              // Destination
              TextField(
                controller: destCtrl,
                decoration: InputDecoration(
                  labelText: 'Destination (ville, pays)',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true, fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 12),
              // Dates
              Row(children: [
                Expanded(child: _DatePickerField(
                  label: 'Date départ',
                  date: depart,
                  onPicked: (d) => setModal(() => depart = d),
                )),
                const SizedBox(width: 10),
                Expanded(child: _DatePickerField(
                  label: 'Date retour',
                  date: retour,
                  firstDate: depart,
                  onPicked: (d) => setModal(() => retour = d),
                )),
              ]),
              const SizedBox(height: 20),
              // Bouton sauvegarder
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                  icon: saving
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Enregistrement…' : 'Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: saving ? null : () async {
                    setModal(() => saving = true);
                    try {
                      final parts = destCtrl.text.split(',');
                      await ApiService().put('/missions/${m.id}', {
                        'objet_mission': objetCtrl.text.trim(),
                        'titre': objetCtrl.text.trim(),
                        if (parts.isNotEmpty)
                          'destination_ville': parts[0].trim(),
                        'destination_pays': parts.length > 1
                            ? parts[1].trim() : 'Algérie',
                        if (depart != null)
                          'date_depart': fmt.format(depart!),
                        if (retour != null)
                          'date_retour': fmt.format(retour!),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      _load();   // refresh
                    } catch (e) {
                      setModal(() => saving = false);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                          content: Text(e.toString()),
                          backgroundColor: DS.error,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ),
    );
    objetCtrl.dispose();
    destCtrl.dispose();
  }

  Future<void> _deleteDraft(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Supprimer ce brouillon ?'),
        content: const Text(
            'Cette action est irréversible. La mission sera définitivement supprimée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: DS.error),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ApiService().delete('/missions/$id');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brouillon supprimé'),
            backgroundColor: DS.error,
            behavior: SnackBarBehavior.floating));
      context.pop();   // retour à la liste
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

// ─── Date picker inline ───────────────────────────────────────────────────────
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPicked;
  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onPicked,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () async {
        final now  = DateTime.now();
        final first = firstDate ?? now;
        final init  = (date != null && !date!.isBefore(first)) ? date! : first;
        final picked = await showDatePicker(
          context: context,
          initialDate: init,
          firstDate: first,
          lastDate: DateTime(now.year + 3),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
              colorScheme: const ColorScheme.light(
                primary: DS.secondary, onPrimary: Colors.white)),
            child: child!),
        );
        if (picked != null) onPicked(picked);
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true, fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 10),
        ),
        child: Text(
          date != null ? fmt.format(date!) : 'Choisir…',
          style: TextStyle(
            fontSize: 13,
            color: date != null ? DS.textPrimary : DS.textSecondary,
          ),
        ),
      ),
    );
  }
}
