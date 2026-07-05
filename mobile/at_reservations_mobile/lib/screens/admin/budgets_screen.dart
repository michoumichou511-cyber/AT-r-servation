import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _budgets = [];
  bool _loading = true;
  int _year = 2026;
  Map<String, dynamic>? _totals;

  final _years = [2023, 2024, 2025, 2026];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await _api.get('/admin/budgets?year=$_year');
      // API: {"success":true,"data":{"budgets":[...],"totaux":{...}}} ou {"data":[...]}
      final inner = resp['data'] ?? resp;
      List rawList;
      Map<String, dynamic>? totauxMap;
      if (inner is Map) {
        rawList = (inner['budgets'] as List?) ?? (inner['data'] as List?) ?? [];
        totauxMap = inner['totaux'] as Map<String, dynamic>?;
      } else if (inner is List) {
        rawList = inner;
      } else {
        rawList = [];
      }
      setState(() {
        _budgets = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _totals = totauxMap;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        setState(() { _budgets = []; _loading = false; });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  // Helpers pour supporter les deux noms de clés API
  num _budgetAlloue(Map<String, dynamic> b) =>
      b['montant_alloue'] as num? ?? b['budget_alloue'] as num? ?? 0;
  num _budgetConsomme(Map<String, dynamic> b) =>
      b['montant_consomme'] as num? ?? b['budget_consomme'] as num? ?? 0;

  String _formatAmount(num amount) {
    final str = amount.toStringAsFixed(0);
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buffer.write(' ');
      buffer.write(str[i]);
      count++;
    }
    return '${buffer.toString().split('').reversed.join()} DZD';
  }

  Color _colorForPercent(double pct) {
    if (pct > 0.90) return ATColors.error;
    if (pct > 0.75) return ATColors.warning;
    return ATColors.success;
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(height: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildTotalCard() {
    if (_totals == null && _budgets.isEmpty) return const SizedBox.shrink();
    final totalAlloue = _totals != null
        ? (_totals!['total_alloue'] as num? ?? 0).toDouble()
        : _budgets.fold(0.0, (s, b) => s + ((_budgetAlloue(b)).toDouble()));
    final totalConsomme = _totals != null
        ? (_totals!['total_consomme'] as num? ?? 0).toDouble()
        : _budgets.fold(0.0, (s, b) => s + ((_budgetConsomme(b)).toDouble()));
    final pct = totalAlloue > 0 ? (totalConsomme / totalAlloue).clamp(0.0, 1.0) : 0.0;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: ATColors.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Budget Global', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text(_formatAmount(totalAlloue), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8,
            percent: pct,
            backgroundColor: Colors.white24,
            progressColor: _colorForPercent(pct),
            barRadius: const Radius.circular(4),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Consommé: ${_formatAmount(totalConsomme)}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(color: _colorForPercent(pct), fontWeight: FontWeight.bold, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 120,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text('Budgets', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              SliverFillRemaining(child: _buildShimmer())
            else if (_budgets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.account_balance_wallet_outlined, size: 64, color: ATColors.textSecondary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    const Text('Aucun budget disponible pour cette période', style: TextStyle(color: ATColors.textSecondary), textAlign: TextAlign.center),
                  ]),
                ),
              )
            else ...[
              SliverToBoxAdapter(child: _buildTotalCard()),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final b = _budgets[i];
                    final alloue = _budgetAlloue(b).toDouble();
                    final consomme = _budgetConsomme(b).toDouble();
                    final pct = alloue > 0 ? (consomme / alloue).clamp(0.0, 1.0) : 0.0;
                    final color = _colorForPercent(pct);
                    return Card(
                      margin: EdgeInsets.only(left: 16, right: 16, top: i == 0 ? 8 : 4, bottom: 4),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(
                              child: Text(b['direction'] as String? ?? b['nom'] as String? ?? 'Direction', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                              child: Text('${(pct * 100).toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ]),
                          const SizedBox(height: 8),
                          LinearPercentIndicator(
                            lineHeight: 10,
                            percent: pct,
                            backgroundColor: Colors.grey.shade200,
                            progressColor: color,
                            barRadius: const Radius.circular(5),
                            padding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Alloué', style: TextStyle(fontSize: 11, color: ATColors.textSecondary)),
                              Text(_formatAmount(alloue), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              const Text('Consommé', style: TextStyle(fontSize: 11, color: ATColors.textSecondary)),
                              Text(_formatAmount(consomme), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
                            ]),
                          ]),
                        ]),
                      ),
                    );
                  },
                  childCount: _budgets.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
