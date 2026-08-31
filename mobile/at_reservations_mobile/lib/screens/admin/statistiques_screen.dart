import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/status_utils.dart';

class StatistiquesScreen extends StatefulWidget {
  const StatistiquesScreen({super.key});

  @override
  State<StatistiquesScreen> createState() => _StatistiquesScreenState();
}

class _StatistiquesScreenState extends State<StatistiquesScreen> with SingleTickerProviderStateMixin {
  final _api = ApiService();
  bool _loading = true;
  int _year = 2026;
  Map<String, dynamic> _stats = {};
  late TabController _tabCtrl;

  final _years = [2023, 2024, 2025, 2026];
  final _months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
  // Couleurs et labels via source unique : status_utils.dart

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/admin/statistiques?year=$_year');
      // API: {"success":true,"data":{"annee":2026,"missions_par_mois":[...],"directions":[...],...}}
      final inner = (resp['data'] ?? resp) as Map<String, dynamic>;
      setState(() { _stats = inner; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<double> get _monthData {
    final raw = _stats['missions_par_mois'] as List?
        ?? _stats['par_mois'] as List?
        ?? <dynamic>[];
    if (raw.isEmpty) return List.filled(12, 0.0);
    // Format {"mois":"04/2026","total":24} — map by month number
    if (raw.first is Map) {
      final result = List<double>.filled(12, 0.0);
      for (final item in raw) {
        final m = item as Map;
        final moisStr = (m['mois'] as String? ?? '').split('/');
        final monthIdx = (int.tryParse(moisStr.isNotEmpty ? moisStr[0] : '0') ?? 0) - 1;
        if (monthIdx >= 0 && monthIdx < 12) {
          result[monthIdx] = ((m['total'] ?? m['count'] ?? 0) as num).toDouble();
        }
      }
      return result;
    }
    return List.generate(12, (i) => (raw.length > i ? (raw[i] as num).toDouble() : 0.0));
  }

  Map<String, int> get _statutData {
    // API retourne par_statut map ou consommation_budget (fallback)
    final raw = _stats['par_statut'] as Map?
        ?? _stats['repartition_statuts'] as Map?
        ?? {};
    return raw.map((k, v) => MapEntry(k as String, (v as num).toInt()));
  }

  List<Map<String, dynamic>> get _directionData {
    // API retourne directions (list) ou par_direction
    final raw = _stats['directions'] as List?
        ?? _stats['par_direction'] as List?
        ?? [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(children: [
        Container(margin: const EdgeInsets.all(16), height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
        Container(margin: const EdgeInsets.symmetric(horizontal: 16), height: 250, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      ]),
    );
  }

  Widget _buildStatCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: context.textSecondary), textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final data = _monthData;
    final maxY = data.reduce((a, b) => a > b ? a : b) + 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          minX: 0, maxX: 11,
          minY: 0, maxY: maxY,
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i < 0 || i >= 12) return const SizedBox.shrink();
              return Text(_months[i], style: const TextStyle(fontSize: 9));
            })),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(12, (i) => FlSpot(i.toDouble(), data[i])),
              isCurved: true,
              color: ATColors.secondary,
              barWidth: 3,
              dotData: FlDotData(show: true, getDotPainter: (spot, xPct, bar, idx) => FlDotCirclePainter(radius: 4, color: ATColors.primary, strokeColor: Colors.white, strokeWidth: 2)),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [ATColors.secondary.withValues(alpha: 0.3), ATColors.secondary.withValues(alpha: 0.0)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    final data = _statutData;
    if (data.isEmpty) return Center(child: Text('Aucune donnée', style: TextStyle(color: context.textSecondary)));
    final total = data.values.fold(0, (a, b) => a + b);
    final sections = data.entries.map((e) {
      final color = statusColor(e.key);
      final pct = total > 0 ? e.value / total * 100 : 0.0;
      return PieChartSectionData(value: e.value.toDouble(), color: color, title: '${pct.toStringAsFixed(0)}%', radius: 80, titleStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold));
    }).toList();
    return Column(children: [
      SizedBox(height: 200, child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 30))),
      Wrap(spacing: 12, runSpacing: 6, children: data.entries.map((e) {
        final color = statusColor(e.key);
        return Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text('${statusLabel(e.key)} (${e.value})', style: const TextStyle(fontSize: 12)),
        ]);
      }).toList()),
    ]);
  }

  Widget _buildBarChart() {
    final data = _directionData;
    if (data.isEmpty) return Center(child: Text('Aucune donnée', style: TextStyle(color: context.textSecondary)));
    final maxV = data.map((d) => (d['missions_total'] as num? ?? d['count'] as num? ?? 0).toDouble()).reduce((a, b) => a > b ? a : b) + 2;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(BarChartData(
        maxY: maxV,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= data.length) return const SizedBox.shrink();
            final name = data[i]['direction'] as String? ?? '';
            return Padding(padding: const EdgeInsets.only(top: 4), child: Text(name.length > 6 ? '${name.substring(0, 6)}.' : name, style: const TextStyle(fontSize: 9)));
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)))),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(data.length, (i) {
          final count = (data[i]['missions_total'] as num? ?? data[i]['count'] as num? ?? 0).toDouble();
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: count, color: ATColors.secondary, width: 18, borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(colors: [ATColors.secondary, ATColors.primary], begin: Alignment.bottomCenter, end: Alignment.topCenter)),
          ]);
        }),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Statistiques', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF002B7A), Color(0xFF004DB5)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: [
                const Text('Année:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: _year,
                  items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                  onChanged: (v) { setState(() => _year = v!); _load(); },
                ),
              ]),
            ),
          ),
          if (_loading)
            SliverToBoxAdapter(child: _buildShimmer())
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  _buildStatCard('Total', (s['total'] ?? s['total_missions'] ?? 0 as num).toInt(), ATColors.secondary, Icons.assignment),
                  _buildStatCard('En attente', (s['en_attente'] ?? s['soumis'] ?? 0 as num).toInt(), ATColors.warning, Icons.hourglass_empty),
                  _buildStatCard('Approuvées', (s['approuvees'] ?? s['approuve'] ?? 0 as num).toInt(), ATColors.success, Icons.check_circle_outline),
                  _buildStatCard('Refusées', (s['refusees'] ?? s['rejete'] ?? 0 as num).toInt(), ATColors.error, Icons.cancel_outlined),
                ]),
              ),
            ),
            SliverToBoxAdapter(
              child: TabBar(
                controller: _tabCtrl,
                labelColor: ATColors.secondary,
                unselectedLabelColor: context.textSecondary,
                indicatorColor: ATColors.secondary,
                tabs: const [Tab(text: 'Par mois'), Tab(text: 'Par statut'), Tab(text: 'Par direction')],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildLineChart(),
                    SingleChildScrollView(padding: const EdgeInsets.all(16), child: _buildPieChart()),
                    _buildBarChart(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
