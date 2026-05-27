import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';
import '../../widgets/tilt_3d.dart';

class DmlScreen extends StatefulWidget {
  const DmlScreen({super.key});
  @override
  State<DmlScreen> createState() => _DmlScreenState();
}

class _DmlScreenState extends State<DmlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<MissionModel> _missions = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
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

  List<MissionModel> _filtered(String statut) =>
      _missions.where((m) => m.statut == statut).toList();

  @override
  Widget build(BuildContext context) {
    final aTraiter  = _filtered('approuve');
    final enCours   = _filtered('en_traitement_logistique');
    final terminees = _filtered('termine');

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: ATColors.secondary,
            foregroundColor: Colors.white,
            title: const Text('Logistique DML',
                style: TextStyle(fontWeight: FontWeight.w700)),
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
                padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                child: Row(
                  children: [
                    Expanded(child: Tilt3D(intensity: 0.22,
                        child: _StatCard('À traiter', aTraiter.length, ATColors.error))),
                    const SizedBox(width: 10),
                    Expanded(child: Tilt3D(intensity: 0.22,
                        child: _StatCard('En cours', enCours.length, ATColors.warning))),
                    const SizedBox(width: 10),
                    Expanded(child: Tilt3D(intensity: 0.22,
                        child: _StatCard('Terminées', terminees.length, ATColors.success))),
                  ],
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                color: ATColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              labelPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              tabs: const [
                Tab(text: 'À traiter'),
                Tab(text: 'En cours'),
                Tab(text: 'Terminées'),
              ],
            ),
          ),
        ],
        body: _loading
            ? const _ShimmerDmlList()
            : _error != null
                ? _buildErrorState()
                : TabBarView(
                    controller: _tab,
                    children: [
                      _DmlList(missions: aTraiter,  onRefresh: _load),
                      _DmlList(missions: enCours,   onRefresh: _load),
                      _DmlList(missions: terminees, onRefresh: _load, readonly: true),
                    ],
                  ),
      ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: ATColors.error.withValues(alpha: 0.10),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.wifi_off_outlined,
            color: ATColors.error, size: 30),
      ),
      const SizedBox(height: 16),
      const Text('Erreur de chargement',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: ATColors.textPrimary)),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(_error!,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: ATColors.textSecondary, fontSize: 13)),
      ),
      const SizedBox(height: 20),
      ElevatedButton.icon(
        onPressed: _load,
        icon: const Icon(Icons.refresh),
        label: const Text('Réessayer'),
        style: ElevatedButton.styleFrom(
          backgroundColor: ATColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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

// ─── Liste DML ─────────────────────────────────────────────────────────────
class _DmlList extends StatelessWidget {
  final List<MissionModel> missions;
  final VoidCallback onRefresh;
  final bool readonly;
  const _DmlList(
      {required this.missions, required this.onRefresh, this.readonly = false});

  @override
  Widget build(BuildContext context) {
    if (missions.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🚛', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('Aucune mission ici',
              style: TextStyle(color: ATColors.textSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 140),
        itemCount: missions.length,
        itemBuilder: (ctx, i) => _DmlCard(
          mission: missions[i],
          index: i,
          onRefresh: onRefresh,
          readonly: readonly,
        ),
      ),
    );
  }
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

  // ── Dialog : Logistique OK (simple confirmation + observations) ─────────
  Future<void> _logistiqueOk() async {
    final obsCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Confirmer logistique OK'),
        content: TextField(
          controller: obsCtrl,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Observations (optionnel)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: ATColors.primary),
            child: const Text('Confirmer ✓'),
          ),
        ],
      ),
    );
    obsCtrl.dispose();
    if (ok != true) return;
    setState(() => _acting = true);
    try {
      await ApiService().post(
        '/dml/missions/${widget.mission.id}/logistique-ok',
        obsCtrl.text.trim().isNotEmpty
            ? {'observations': obsCtrl.text.trim()}
            : null,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ── Dialog : Modifier logistique DML (correction 3) ────────────────────
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
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.edit_note_rounded,
                      color: ATColors.secondary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Modifications logistiques',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ATColors.secondary),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Mission : ${widget.mission.numeroUnique ?? "#${widget.mission.id}"}',
                  style: const TextStyle(
                      fontSize: 12, color: ATColors.textSecondary),
                ),
                const SizedBox(height: 20),

                // Nom de l'hôtel
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

                // Numéro de billet
                TextField(
                  controller: numeroBilletCtrl,
                  decoration: InputDecoration(
                    labelText: 'Numéro de billet ✈',
                    hintText: 'Ex: AH1234567890',
                    prefixIcon:
                        const Icon(Icons.confirmation_number_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 12),

                // Compagnie aérienne
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

                // Prix hébergement réel
                TextField(
                  controller: prixHebergCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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

                // Bouton enregistrer
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
                            // Vérifier qu'au moins un champ est rempli
                            final hasData = nomHotelCtrl.text.trim().isNotEmpty ||
                                numeroBilletCtrl.text.trim().isNotEmpty ||
                                compagnieCtrl.text.trim().isNotEmpty ||
                                prixHebergCtrl.text.trim().isNotEmpty;
                            if (!hasData) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Veuillez renseigner au moins un champ.'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            setModal(() => saving = true);
                            try {
                              final body = <String, dynamic>{};
                              if (nomHotelCtrl.text.trim().isNotEmpty) {
                                body['nom_hotel'] = nomHotelCtrl.text.trim();
                              }
                              if (numeroBilletCtrl.text.trim().isNotEmpty) {
                                body['numero_billet'] =
                                    numeroBilletCtrl.text.trim();
                              }
                              if (compagnieCtrl.text.trim().isNotEmpty) {
                                body['compagnie'] = compagnieCtrl.text.trim();
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

  @override
  Widget build(BuildContext context) => Column(children: [
    MissionCard(
      mission: widget.mission,
      index: widget.index,
      showUser: true,
    ),
    if (!widget.readonly)
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(children: [
          // Bouton Modifier logistique
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
          // Bouton Logistique OK
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _acting ? null : _logistiqueOk,
              icon: _acting
                  ? const SpinKitFadingCircle(color: Colors.white, size: 22)
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Logistique OK',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ATColors.primary,
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Container(
                    height: 13, width: double.infinity, color: Colors.white),
                const SizedBox(height: 6),
                Container(height: 10, width: 160, color: Colors.white),
              ]),
            ),
          ]),
          const SizedBox(height: 12),
          Container(height: 10, width: double.infinity, color: Colors.white),
          const SizedBox(height: 6),
          Container(height: 10, width: 220, color: Colors.white),
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
