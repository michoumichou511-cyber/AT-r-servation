import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

// ─── Modèles légers ────────────────────────────────────────────────────────

class _MissionRow {
  final String numero;
  final String objet;
  final String demandeur;
  final String direction;
  final String dateDepart;
  final String statut;

  _MissionRow({
    required this.numero,
    required this.objet,
    required this.demandeur,
    required this.direction,
    required this.dateDepart,
    required this.statut,
  });

  factory _MissionRow.fromJson(Map<String, dynamic> j) {
    return _MissionRow(
      numero: (j['id'] ?? j['numero'] ?? '–').toString(),
      objet: (j['objet'] ?? j['titre'] ?? '–').toString(),
      demandeur: (j['demandeur'] ?? j['user']?['name'] ?? '–').toString(),
      direction: (j['direction'] ?? '–').toString(),
      dateDepart: (j['date_debut'] ?? j['date_depart'] ?? '–').toString(),
      statut: (j['statut'] ?? '–').toString(),
    );
  }
}

class _DepenseRow {
  final String mission;
  final String hebergement;
  final String transport;
  final String restauration;
  final String total;

  _DepenseRow({
    required this.mission,
    required this.hebergement,
    required this.transport,
    required this.restauration,
    required this.total,
  });

  factory _DepenseRow.fromJson(Map<String, dynamic> j) {
    num h = num.tryParse(j['hebergement']?.toString() ?? '0') ?? 0;
    num t = num.tryParse(j['transport']?.toString() ?? '0') ?? 0;
    num r = num.tryParse(j['restauration']?.toString() ?? '0') ?? 0;
    num total = num.tryParse(j['total']?.toString() ?? '0') ?? (h + t + r);
    return _DepenseRow(
      mission: (j['mission'] ?? j['objet'] ?? '–').toString(),
      hebergement: _fmt(h),
      transport: _fmt(t),
      restauration: _fmt(r),
      total: _fmt(total),
    );
  }

  static String _fmt(num v) => '${v.toStringAsFixed(0)} DZD';
}

class _PrestataireStat {
  final String nom;
  final int missions;
  final String total;

  _PrestataireStat({
    required this.nom,
    required this.missions,
    required this.total,
  });

  factory _PrestataireStat.fromJson(Map<String, dynamic> j) {
    return _PrestataireStat(
      nom: (j['nom'] ?? j['name'] ?? '–').toString(),
      missions: int.tryParse(j['missions_count']?.toString() ?? '0') ?? 0,
      total: (j['total_amount'] ?? j['montant_total'] ?? '0').toString(),
    );
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  late final TabController _tabCtrl;

  // ── Filtres ──────────────────────────────────────────────────────────────
  bool _filtersExpanded = false;
  DateTime _dateDebut = DateTime(DateTime.now().year, 1, 1);
  DateTime _dateFin = DateTime(DateTime.now().year, 12, 31);
  String? _selectedDirection;
  String? _selectedType;

  // ── Données ──────────────────────────────────────────────────────────────
  bool _loading = false;
  List<_MissionRow> _missions = [];
  List<_DepenseRow> _depenses = [];
  List<_PrestataireStat> _prestataires = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() {});
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _dateDebutStr =>
      '${_dateDebut.day.toString().padLeft(2, '0')}/${_dateDebut.month.toString().padLeft(2, '0')}/${_dateDebut.year}';
  String get _dateFinStr =>
      '${_dateFin.day.toString().padLeft(2, '0')}/${_dateFin.month.toString().padLeft(2, '0')}/${_dateFin.year}';

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _loadData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadMissions(),
      _loadDepenses(),
      _loadPrestataires(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMissions() async {
    try {
      String url =
          '/missions?date_debut=${_isoDate(_dateDebut)}&date_fin=${_isoDate(_dateFin)}';
      if (_selectedDirection != null) url += '&direction=$_selectedDirection';
      final res = await _api.get(url);
      final list = (res['data'] ?? res['missions'] ?? res ?? []) as List;
      _missions = list
          .map((e) => _MissionRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        _missions = [];
      }
    } catch (_) {
      _missions = [];
    }
  }

  Future<void> _loadDepenses() async {
    try {
      final url =
          '/depenses?date_debut=${_isoDate(_dateDebut)}&date_fin=${_isoDate(_dateFin)}';
      final res = await _api.get(url);
      final list = (res['data'] ?? res['depenses'] ?? res ?? []) as List;
      _depenses = list
          .map((e) => _DepenseRow.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) _depenses = [];
    } catch (_) {
      _depenses = [];
    }
  }

  Future<void> _loadPrestataires() async {
    try {
      final res = await _api.get('/prestataires');
      final list = (res['data'] ?? res['prestataires'] ?? res ?? []) as List;
      _prestataires = list
          .map((e) => _PrestataireStat.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      if (e.statusCode == 404) _prestataires = [];
    } catch (_) {
      _prestataires = [];
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _dateDebut, end: _dateFin),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: ATColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateDebut = picked.start;
        _dateFin = picked.end;
      });
    }
  }

  void _appliquer() {
    _loadData();
    setState(() => _filtersExpanded = false);
  }

  void _reinitialiser() {
    setState(() {
      _dateDebut = DateTime(DateTime.now().year, 1, 1);
      _dateFin = DateTime(DateTime.now().year, 12, 31);
      _selectedDirection = null;
      _selectedType = null;
    });
    _loadData();
  }

  Future<void> _export(String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Export $format en cours...'),
        backgroundColor: ATColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await _api.get(
          '/export/missions/$format?date_debut=${_isoDate(_dateDebut)}&date_fin=${_isoDate(_dateFin)}');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export $format terminé.'),
          backgroundColor: ATColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'export.'),
          backgroundColor: ATColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ATColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Rapports & Exports',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [ATColors.secondary, ATColors.primary],
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Missions'),
                Tab(text: 'Dépenses'),
                Tab(text: 'Prestataires'),
              ],
            ),
          ),
        ],
        body: Column(
          children: [
            _buildFilterSection(),
            _buildExportRow(),
            Expanded(
              child: _loading
                  ? _buildShimmer()
                  : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildMissionsTab(),
                        _buildDepensesTab(),
                        _buildPrestatairesTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section filtres ───────────────────────────────────────────────────────

  Widget _buildFilterSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                setState(() => _filtersExpanded = !_filtersExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      size: 18, color: ATColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtres  ·  $_dateDebutStr → $_dateFinStr',
                      style: const TextStyle(
                          fontSize: 13, color: ATColors.textSecondary),
                    ),
                  ),
                  Icon(
                    _filtersExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: ATColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_filtersExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plage de dates
                  OutlinedButton.icon(
                    onPressed: _pickDateRange,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('$_dateDebutStr  →  $_dateFinStr'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ATColors.secondary,
                      side: const BorderSide(color: ATColors.secondary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtres direction + type
                  Row(
                    children: [
                      Expanded(child: _buildDropdown(
                        hint: 'Direction',
                        value: _selectedDirection,
                        items: const [
                          'Direction Générale',
                          'Direction Technique',
                          'Direction Administrative',
                          'Direction Financière',
                        ],
                        onChanged: (v) =>
                            setState(() => _selectedDirection = v),
                      )),
                      const SizedBox(width: 8),
                      Expanded(child: _buildDropdown(
                        hint: 'Type',
                        value: _selectedType,
                        items: const ['Nationale', 'Internationale'],
                        onChanged: (v) =>
                            setState(() => _selectedType = v),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _appliquer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ATColors.primary,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _reinitialiser,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ATColors.textSecondary,
                            side: const BorderSide(
                                color: ATColors.textSecondary),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 1),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text('Tous', style: TextStyle(color: ATColors.textSecondary)),
        ),
        ...items.map((e) => DropdownMenuItem(value: e, child: Text(e))),
      ],
      onChanged: onChanged,
    );
  }

  // ── Boutons export ────────────────────────────────────────────────────────

  Widget _buildExportRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _export('pdf'),
              icon: const Icon(Icons.picture_as_pdf, size: 16),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ATColors.error,
                side: const BorderSide(color: ATColors.error),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _export('excel'),
              icon: const Icon(Icons.table_chart, size: 16),
              label: const Text('Excel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ATColors.success,
                side: const BorderSide(color: ATColors.success),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Onglet Missions ───────────────────────────────────────────────────────

  Widget _buildMissionsTab() {
    if (_missions.isEmpty) {
      return _emptyState(
          'Aucune mission trouvée', Icons.assignment_outlined);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              ATColors.secondary.withValues(alpha: 0.08)),
          columns: const [
            DataColumn(label: Text('N°', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Objet', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Demandeur', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Direction', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Départ', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _missions.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return DataRow(
              color: WidgetStateProperty.all(
                i.isEven ? Colors.white : ATColors.background,
              ),
              cells: [
                DataCell(Text(m.numero)),
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(m.objet,
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                )),
                DataCell(Text(m.demandeur)),
                DataCell(Text(m.direction)),
                DataCell(Text(m.dateDepart)),
                DataCell(_statutBadge(m.statut)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Onglet Dépenses ───────────────────────────────────────────────────────

  Widget _buildDepensesTab() {
    if (_depenses.isEmpty) {
      return _emptyState('Aucune dépense trouvée', Icons.receipt_long_outlined);
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              ATColors.secondary.withValues(alpha: 0.08)),
          columns: const [
            DataColumn(label: Text('Mission', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Hébergement', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Transport', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Restauration', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _depenses.asMap().entries.map((entry) {
            final i = entry.key;
            final d = entry.value;
            return DataRow(
              color: WidgetStateProperty.all(
                  i.isEven ? Colors.white : ATColors.background),
              cells: [
                DataCell(ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(d.mission,
                      overflow: TextOverflow.ellipsis, maxLines: 2),
                )),
                DataCell(Text(d.hebergement)),
                DataCell(Text(d.transport)),
                DataCell(Text(d.restauration)),
                DataCell(Text(d.total,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ATColors.secondary))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Onglet Prestataires ───────────────────────────────────────────────────

  Widget _buildPrestatairesTab() {
    if (_prestataires.isEmpty) {
      return _emptyState(
          'Aucun prestataire trouvé', Icons.business_outlined);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
      itemCount: _prestataires.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final p = _prestataires[i];
        return Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      ATColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    p.nom.isNotEmpty ? p.nom[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: ATColors.primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nom,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '${p.missions} mission${p.missions != 1 ? 's' : ''}',
                        style: const TextStyle(
                            color: ATColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.total} DZD',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ATColors.secondary,
                          fontSize: 13),
                    ),
                    const Text('Total',
                        style: TextStyle(
                            color: ATColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Widgets utilitaires ───────────────────────────────────────────────────

  Widget _statutBadge(String statut) {
    final color = ATColors.forStatut(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        statut.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: ATColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(message,
              style: const TextStyle(
                  color: ATColors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
        itemCount: 6,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 50,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
