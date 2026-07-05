import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:iconly/iconly.dart';
import '../../config/theme.dart';
import '../../models/mission.dart';
import '../../services/api_service.dart';
import '../../widgets/mission_card.dart';

// ─── Mapping statut brut → label français ────────────────────────────────────
const _kStatusLabels = <String, String>{
  'brouillon':                'Brouillon',
  'soumis':                   'Soumise',
  'soumise':                  'Soumise',
  'en_attente':               'En attente',
  'en_validation':            'En validation',
  'approuve':                 'Approuvée',
  'approuvee':                'Approuvée',
  'rejete':                   'Rejetée',
  'rejetee':                  'Rejetée',
  'en_traitement_logistique': 'En logistique',
  'termine':                  'Terminée',
  'terminee':                 'Terminée',
  'valide':                   'Validée',
  'annule':                   'Annulée',
  'annulee':                  'Annulée',
};

String _statutLabel(String s) => const <String, String>{
  'brouillon':                'Brouillons',
  'soumis':                   'Soumises',
  'soumise':                  'Soumises',
  'en_attente':               'En attente',
  'en_validation':            'En validation',
  'approuve':                 'Approuvées',
  'approuvee':                'Approuvées',
  'rejete':                   'Rejetées',
  'rejetee':                  'Rejetées',
  'en_traitement_logistique': 'En logistique',
  'termine':                  'Terminées',
  'terminee':                 'Terminées',
  'valide':                   'Validées',
  'annule':                   'Annulées',
  'annulee':                  'Annulées',
}[s] ?? s;

// ─── Screen ──────────────────────────────────────────────────────────────────
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();

  List<MissionModel> _allMissions = [];   // cache chargé une fois
  List<MissionModel> _results     = [];
  bool _loading  = false;
  bool _searched = false;
  Timer? _debounce;

  late final AnimationController _animCtrl;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();

    _loadAll();   // pré-chargement de toutes les missions
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Chargement initial ────────────────────────────────────────────────────
  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService().get('/missions?per_page=1000');
      final dynamic raw = data['data'];
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map<String, dynamic>) {
        final inner = raw['data'];
        list = inner is List ? inner : [];
      } else if (data is List) {
        list = data;
      } else {
        list = [];
      }
      if (mounted) {
        setState(() {
          _allMissions = list
              .map((e) => MissionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Debounce saisie ───────────────────────────────────────────────────────
  void _onChanged(String q) {
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    _debounce =
        Timer(const Duration(milliseconds: 300), () => _filter(q.trim()));
  }

  // ── Filtrage local ────────────────────────────────────────────────────────
  // Cherche dans : titre, objet, destination, numéro, et label FR du statut
  void _filter(String q) {
    final lower = q.toLowerCase();
    setState(() {
      _searched = true;
      _results  = _allMissions.where((m) {
        final statutFr =
            (_kStatusLabels[m.statut] ?? m.statut).toLowerCase();
        return (m.titre?.toLowerCase().contains(lower)        ?? false)
            || (m.objetMission?.toLowerCase().contains(lower) ?? false)
            || (m.destination?.toLowerCase().contains(lower)  ?? false)
            || (m.numeroUnique?.toLowerCase().contains(lower) ?? false)
            ||  m.statut.toLowerCase().contains(lower)
            ||  statutFr.contains(lower);
      }).toList();
    });
  }

  // ── Filtre rapide par statut brut (chips) ─────────────────────────────────
  void _filterByStatut(String statut, String label) {
    _ctrl.text = label;
    setState(() {
      _searched = true;
      _results  = _allMissions.where((m) => m.statut == statut).toList();
    });
  }

  // ── Groupement par statut ─────────────────────────────────────────────────
  Map<String, List<MissionModel>> _grouped() {
    final Map<String, List<MissionModel>> m = {};
    for (final r in _results) {
      m.putIfAbsent(r.statut, () => []).add(r);
    }
    return m;
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/missions');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) { if (!didPop) _goBack(); },
      child: Scaffold(
      backgroundColor: ATColors.background,
      appBar: AppBar(
        backgroundColor: ATColors.secondary,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: Colors.white,
          tooltip: 'Retour',
          onPressed: _goBack,
        ),
        title: SlideTransition(
          position: _slideAnim,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              onChanged: _onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Titre, destination, numéro, statut…',
                hintStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(IconlyLight.search,
                    color: Colors.white70, size: 20),
                suffixIcon: _ctrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white70, size: 18),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() { _results = []; _searched = false; });
                          _focus.requestFocus();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: SpinKitWave(color: ATColors.primary, size: 30))
          : !_searched
              ? _buildSuggestions()
              : _results.isEmpty
                  ? _buildNoResult()
                  : _buildResults(grouped),
    ),  // PopScope
    );
  }

  // ── Corps : suggestions + chips ───────────────────────────────────────────
  Widget _buildSuggestions() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(children: [
      const SizedBox(height: 32),
      Icon(IconlyLight.search, size: 64,
          color: ATColors.textSecondary.withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      const Text('Rechercher dans vos missions',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
            color: ATColors.textPrimary)),
      const SizedBox(height: 8),
      const Text('Tapez un titre, une destination, un numéro ou un statut',
        textAlign: TextAlign.center,
        style: TextStyle(color: ATColors.textSecondary, fontSize: 14)),
      const SizedBox(height: 32),
      // Chips de filtre rapide (valeur brute en logique, label FR affiché)
      Wrap(spacing: 8, runSpacing: 8, children: [
        _QuickChip('Soumises',
            () => _filterByStatut('soumis',     'Soumises')),
        _QuickChip('En attente',
            () => _filterByStatut('en_attente', 'En attente')),
        _QuickChip('Approuvées',
            () => _filterByStatut('approuve',   'Approuvées')),
        _QuickChip('Terminées',
            () => _filterByStatut('termine',    'Terminées')),
        _QuickChip('Rejetées',
            () => _filterByStatut('rejete',     'Rejetées')),
        _QuickChip('Validées',
            () => _filterByStatut('valide',     'Validées')),
      ]),
    ]),
  );

  // ── Corps : liste de résultats ────────────────────────────────────────────
  Widget _buildResults(Map<String, List<MissionModel>> grouped) =>
      ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 140),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              '${_results.length} résultat${_results.length > 1 ? "s" : ""}',
              style: const TextStyle(
                  color: ATColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          ...grouped.entries.expand((entry) => [
            _GroupHeader(entry.key, _statutLabel(entry.key)),
            ...entry.value.asMap().entries.map((e) =>
                MissionCard(mission: e.value, index: e.key)
                    .animate(delay: (e.key * 60).ms)
                    .fadeIn()
                    .slideY(begin: 0.1)),
          ]),
        ],
      );

  // ── Corps : aucun résultat ────────────────────────────────────────────────
  Widget _buildNoResult() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(IconlyLight.search, size: 64,
          color: ATColors.textSecondary.withValues(alpha: 0.3)),
      const SizedBox(height: 16),
      const Text('Aucun résultat',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Aucune mission pour « ${_ctrl.text} »',
        style: const TextStyle(color: ATColors.textSecondary)),
      const SizedBox(height: 24),
      TextButton.icon(
        onPressed: () {
          _ctrl.clear();
          setState(() { _results = []; _searched = false; });
          _focus.requestFocus();
        },
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Réinitialiser'),
        style: TextButton.styleFrom(foregroundColor: ATColors.secondary),
      ),
    ]),
  );
}

// ─── Widgets auxiliaires ──────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String statut;
  final String label;
  const _GroupHeader(this.statut, this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          color: ATColors.forStatut(statut),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 8),
      Text(label,
        style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w800,
          color: ATColors.forStatut(statut),
          letterSpacing: 0.5,
        )),
    ]),
  );
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) => ActionChip(
    label: Text(label),
    onPressed: onTap,
    backgroundColor: ATColors.secondary.withValues(alpha: 0.08),
    labelStyle: const TextStyle(color: ATColors.secondary,
        fontWeight: FontWeight.w600, fontSize: 13),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    side: BorderSide(color: ATColors.secondary.withValues(alpha: 0.2)),
  );
}
