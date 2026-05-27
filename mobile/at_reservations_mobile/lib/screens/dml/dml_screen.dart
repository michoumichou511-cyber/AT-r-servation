import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/tilt_3d.dart';

enum _DmlFilter { toutes, enAttente, traitees }

class DmlScreen extends StatefulWidget {
  const DmlScreen({super.key});
  @override
  State<DmlScreen> createState() => _DmlScreenState();
}

class _DmlScreenState extends State<DmlScreen> {
  List<MissionModel> _missions = [];
  bool    _loading = true;
  String? _error;
  _DmlFilter _filter = _DmlFilter.enAttente;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService().get('/dml/missions-validees');
      final dynamic raw = data['data'];
      final list = raw is List
          ? raw
          : (raw is Map<String, dynamic>
              ? (raw['data'] ?? raw)
              : (data is List ? data : []));
      setState(() => _missions = (list as List)
          .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
          .toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Filtres locaux ───────────────────────────────────────────────────────
  List<MissionModel> get _aTraiter =>
      _missions.where((m) => m.statut == 'approuve').toList();
  List<MissionModel> get _traitees => _missions
      .where((m) =>
          m.statut == 'en_traitement_logistique' || m.statut == 'termine')
      .toList();

  List<MissionModel> get _visibles {
    switch (_filter) {
      case _DmlFilter.toutes:    return _missions;
      case _DmlFilter.enAttente: return _aTraiter;
      case _DmlFilter.traitees:  return _traitees;
    }
  }

  bool get _filterIsReadonly => _filter == _DmlFilter.traitees;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          // ─── AppBar gradient + stats ────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: ATColors.secondary,
            foregroundColor: Colors.white,
            title: const Text('Logistique DML',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              IconButton(
                tooltip: 'Rafraîchir',
                icon: const Icon(Icons.refresh),
                onPressed: _loading ? null : _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF003DA5), Color(0xFF1565C0)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Amélioration 2 : compteur
                    _buildCounter(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Tilt3D(intensity: 0.22,
                            child: _StatCard('À traiter', _aTraiter.length, ATColors.error))),
                        const SizedBox(width: 10),
                        Expanded(child: Tilt3D(intensity: 0.22,
                            child: _StatCard('Traitées', _traitees.length, ATColors.success))),
                        const SizedBox(width: 10),
                        Expanded(child: Tilt3D(intensity: 0.22,
                            child: _StatCard('Total', _missions.length, ATColors.warning))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Filter chips ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF0F4FF),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  _filterChip('Toutes',              _DmlFilter.toutes,     _missions.length),
                  const SizedBox(width: 8),
                  _filterChip('En attente logistique', _DmlFilter.enAttente, _aTraiter.length),
                  const SizedBox(width: 8),
                  _filterChip('Traitées',            _DmlFilter.traitees,   _traitees.length),
                ],
              ),
            ),
          ),

          // ─── Liste ──────────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
                child: _ShimmerDmlList())
          else if (_error != null)
            SliverFillRemaining(child: _buildErrorState())
          else if (_visibles.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('🚛', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Aucune mission ici',
                      style: TextStyle(color: ATColors.textSecondary)),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _DmlCard(
                  mission: _visibles[i],
                  index: i,
                  onRefresh: _load,
                  readonly: _filterIsReadonly,
                ),
                childCount: _visibles.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Compteur principal ───────────────────────────────────────────────────
  Widget _buildCounter() {
    final n   = _aTraiter.length;
    final hot = n > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hot
            ? ATColors.error.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hot
              ? ATColors.error.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hot ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: hot ? Colors.white : Colors.white70,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hot
                  ? '$n mission${n > 1 ? "s" : ""} en attente de traitement logistique'
                  : 'Aucune mission en attente',
              style: TextStyle(
                color: hot ? Colors.white : Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chip filter ──────────────────────────────────────────────────────────
  Widget _filterChip(String label, _DmlFilter value, int count) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? ATColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? ATColors.primary : const Color(0xFFE2E8F0),
            ),
            boxShadow: selected
                ? [BoxShadow(
                    color: ATColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3))]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : ATColors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text('$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : ATColors.secondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Erreur réseau ────────────────────────────────────────────────────────
  Widget _buildErrorState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('Erreur de connexion',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A650),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            ),
          ),
        ]),
      );
}

// ─── Mini stat card ────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final int    count;
  final Color  color;
  const _StatCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$count',
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      );
}

// ─── Carte DML ─────────────────────────────────────────────────────────────
class _DmlCard extends StatefulWidget {
  final MissionModel mission;
  final int          index;
  final VoidCallback onRefresh;
  final bool         readonly;
  const _DmlCard({
    required this.mission,
    required this.index,
    required this.onRefresh,
    required this.readonly,
  });
  @override
  State<_DmlCard> createState() => _DmlCardState();
}

class _DmlCardState extends State<_DmlCard> {
  bool _acting = false;

  // ── Helper initiales du demandeur ──────────────────────────────────────
  String _initials(MissionUser? u) {
    if (u == null) return '?';
    final p = (u.prenom).isNotEmpty ? u.prenom[0] : '';
    final n = (u.nom).isNotEmpty    ? u.nom[0]    : '';
    final s = (p + n).toUpperCase();
    return s.isEmpty ? '?' : s;
  }

  // ── Ouverture du détail mission ────────────────────────────────────────
  void _openDetail() {
    HapticFeedback.lightImpact();
    context.push('/missions/${widget.mission.id}');
  }

  // ── Dialog confirmation Logistique OK (Amélioration 3) ─────────────────
  Future<void> _logistiqueOk() async {
    final titre = widget.mission.displayTitre;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer le traitement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marquer la mission « $titre » comme traitée logistiquement ?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              widget.mission.numeroUnique ?? 'Mission #${widget.mission.id}',
              style: const TextStyle(
                  fontSize: 12,
                  color: ATColors.textSecondary,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Confirmer'),
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00A650),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    // Dialog optionnel pour les observations
    final obsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Observations (optionnel)'),
        content: TextField(
          controller: obsCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Notes ou remarques sur le traitement…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: ATColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Valider ✓'),
          ),
        ],
      ),
    );
    final obs = obsCtrl.text.trim();
    obsCtrl.dispose();
    if (ok != true) return;

    setState(() => _acting = true);
    try {
      await ApiService().post(
        '/dml/missions/${widget.mission.id}/logistique-ok',
        obs.isNotEmpty ? {'observations': obs} : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Logistique confirmée !'),
          ]),
          backgroundColor: ATColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()),
          backgroundColor: ATColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  // ── BottomSheet : Modifier logistique DML ──────────────────────────────
  Future<void> _modifierLogistique() async {
    final nomHotelCtrl     = TextEditingController();
    final numeroBilletCtrl = TextEditingController();
    final compagnieCtrl    = TextEditingController();
    final prixHebergCtrl   = TextEditingController();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Row(children: const [
                  Icon(Icons.edit_note_rounded,
                      color: ATColors.secondary, size: 22),
                  SizedBox(width: 8),
                  Text('Modifications logistiques',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: ATColors.secondary)),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Mission : ${widget.mission.numeroUnique ?? "#${widget.mission.id}"}',
                  style: const TextStyle(
                      fontSize: 12, color: ATColors.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nomHotelCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'hôtel (si modifié)',
                    hintText: 'Laisser vide si inchangé',
                    prefixIcon:
                        const Icon(Icons.hotel_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: numeroBilletCtrl,
                  decoration: InputDecoration(
                    labelText: 'Numéro de billet ✈',
                    hintText: 'Ex: AH1234567890',
                    prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: compagnieCtrl,
                  decoration: InputDecoration(
                    labelText: 'Compagnie aérienne / Opérateur',
                    hintText: 'Ex: Air Algérie',
                    prefixIcon:
                        const Icon(Icons.flight_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prixHebergCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Prix hébergement réel (DZD)',
                    hintText: 'Montant facturé par l\'hôtel',
                    prefixIcon:
                        const Icon(Icons.payments_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.save_outlined),
                    label: Text(saving
                        ? 'Enregistrement…'
                        : 'Enregistrer les modifications logistiques'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ATColors.secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: saving
                        ? null
                        : () async {
                            final hasData = nomHotelCtrl.text.trim().isNotEmpty ||
                                numeroBilletCtrl.text.trim().isNotEmpty ||
                                compagnieCtrl.text.trim().isNotEmpty ||
                                prixHebergCtrl.text.trim().isNotEmpty;
                            if (!hasData) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Veuillez renseigner au moins un champ.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setModal(() => saving = true);
                            try {
                              final body = <String, dynamic>{};
                              if (nomHotelCtrl.text.trim().isNotEmpty) {
                                body['nom_hotel'] =
                                    nomHotelCtrl.text.trim();
                              }
                              if (numeroBilletCtrl.text.trim().isNotEmpty) {
                                body['numero_billet'] =
                                    numeroBilletCtrl.text.trim();
                              }
                              if (compagnieCtrl.text.trim().isNotEmpty) {
                                body['compagnie'] =
                                    compagnieCtrl.text.trim();
                              }
                              if (prixHebergCtrl.text.trim().isNotEmpty) {
                                body['prix_hebergement_reel'] =
                                    double.tryParse(
                                        prixHebergCtrl.text.trim());
                              }
                              await ApiService().patch(
                                '/missions/${widget.mission.id}/logistique',
                                body,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              widget.onRefresh();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Row(children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 8),
                                      Text('Modifications enregistrées !'),
                                    ]),
                                    backgroundColor: ATColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              setModal(() => saving = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: ATColors.error,
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
      ),
    );

    nomHotelCtrl.dispose();
    numeroBilletCtrl.dispose();
    compagnieCtrl.dispose();
    prixHebergCtrl.dispose();
  }

  // ── Bloc demandeur (Amélioration 4) ────────────────────────────────────
  Widget _buildDemandeurBlock() {
    final u = widget.mission.user;
    if (u == null) return const SizedBox.shrink();
    final initials = _initials(u);
    final dateDepart = widget.mission.dates?.depart;
    String? formattedDate;
    if (dateDepart != null) {
      try {
        formattedDate =
            DateFormat('dd/MM/yyyy').format(DateTime.parse(dateDepart));
      } catch (_) {}
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          // Avatar initiales
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003DA5), Color(0xFF1565C0)],
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initials,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  u.nomComplet,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: ATColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (formattedDate != null)
                  Text(
                    'Mission prévue le $formattedDate',
                    style: const TextStyle(
                        fontSize: 11, color: ATColors.textSecondary),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: ATColors.textSecondary, size: 18),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        // Carte mission cliquable (FIX 1)
        MissionCard(
          mission: widget.mission,
          index: widget.index,
          showUser: true,
          onTap: _openDetail,
        ),

        // Bloc demandeur avec avatar (Amélioration 4)
        _buildDemandeurBlock(),

        if (!widget.readonly)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
            child: Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _acting ? null : _modifierLogistique,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Modifier',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ATColors.secondary,
                    side: const BorderSide(color: ATColors.secondary),
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _acting ? null : _logistiqueOk,
                  icon: _acting
                      ? const SpinKitFadingCircle(
                          color: Colors.white, size: 22)
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Logistique OK',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ATColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ]),
          ),
      ])
          .animate(delay: (widget.index * 70).ms)
          .fadeIn(duration: 320.ms, curve: Curves.easeOut)
          .slideY(begin: 0.08, duration: 320.ms, curve: Curves.easeOut);
}

// ─── Shimmer skeleton ──────────────────────────────────────────────────────
class _ShimmerDmlList extends StatelessWidget {
  const _ShimmerDmlList();

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
        baseColor: const Color(0xFFE8EDF5),
        highlightColor: const Color(0xFFF5F8FF),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
          itemCount: 5,
          itemBuilder: (_, i) => Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: 13,
                                width: double.infinity,
                                color: Colors.white),
                            const SizedBox(height: 6),
                            Container(
                                height: 10,
                                width: 160,
                                color: Colors.white),
                          ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                      height: 10,
                      width: double.infinity,
                      color: Colors.white),
                  const SizedBox(height: 6),
                  Container(
                      height: 10, width: 220, color: Colors.white),
                  const SizedBox(height: 12),
                  Container(
                      height: 38,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10))),
                ]),
          ),
        ),
      );
}
