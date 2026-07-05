import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/date_utils.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final _api = ApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  int _page = 1;
  int _lastPage = 1;
  String _actionFilter = 'Tous';

  final _filters = ['Tous', 'Login', 'Création', 'Modification', 'Suppression'];
  final _filterMap = {
    'Login': 'login',
    'Création': 'create',
    'Modification': 'update',
    'Suppression': 'delete',
  };

  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    setState(() => _loading = true);
    final action = _filterMap[_actionFilter] ?? '';
    final path = '/admin/audit-logs?page=$page${action.isNotEmpty ? '&action=$action' : ''}';
    try {
      final resp = await _api.get(path);
      // API: {"success":true,"data":{"audit_logs":{"current_page":1,"data":[...],"last_page":5}}}
      final inner = resp['data'] ?? resp;
      final paginated = (inner is Map && inner.containsKey('audit_logs'))
          ? inner['audit_logs'] as Map<String, dynamic>
          : (inner is Map && inner.containsKey('data') ? inner : {'data': inner is List ? inner : [], 'current_page': page, 'last_page': 1});
      final list = (paginated['data'] ?? []) as List;
      setState(() {
        _logs = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _page = paginated['current_page'] as int? ?? page;
        _lastPage = paginated['last_page'] as int? ?? 1;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Color _colorForAction(String action) {
    switch (action.toLowerCase()) {
      case 'login': return ATColors.info;
      case 'create': return ATColors.success;
      case 'update': return ATColors.warning;
      case 'delete': return ATColors.error;
      default: return ATColors.textSecondary;
    }
  }

  IconData _iconForAction(String action) {
    switch (action.toLowerCase()) {
      case 'login': return Icons.login;
      case 'create': return Icons.add_circle_outline;
      case 'update': return Icons.edit_outlined;
      case 'delete': return Icons.delete_outline;
      default: return Icons.info_outline;
    }
  }

  String _labelForAction(String action) {
    switch (action.toLowerCase()) {
      case 'login': return 'Connexion';
      case 'create': return 'Création';
      case 'update': return 'Modification';
      case 'delete': return 'Suppression';
      default: return action;
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final dt = parseBackendDate(raw);
    return dt != null ? DateFormat('dd/MM/yyyy HH:mm').format(dt) : raw;
  }

  String _initiales(Map<String, dynamic> log) {
    final user = log['user'] as Map<String, dynamic>?;
    if (user == null) return '?';
    final p = (user['prenom'] as String? ?? '?')[0];
    final n = (user['nom'] as String? ?? '?')[0];
    return '$p$n'.toUpperCase();
  }

  String _userName(Map<String, dynamic> log) {
    final user = log['user'] as Map<String, dynamic>?;
    if (user == null) return 'Système';
    return '${user['prenom'] ?? ''} ${user['nom'] ?? ''}'.trim();
  }

  String _userEmail(Map<String, dynamic> log) {
    final user = log['user'] as Map<String, dynamic>?;
    return user?['email'] as String? ?? '';
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, __) => Container(height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            actions: [
              IconButton(
                icon: const Icon(Icons.download, color: Colors.white),
                tooltip: 'Exporter CSV',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export en cours...')),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Journal d\'audit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF002B7A), Color(0xFF004DB5)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 50,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final f = _filters[i];
                  final selected = _actionFilter == f;
                  return FilterChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) { setState(() { _actionFilter = f; }); _load(1); },
                    selectedColor: ATColors.secondary.withValues(alpha: 0.2),
                    checkmarkColor: ATColors.secondary,
                  );
                },
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(child: _buildShimmer())
          else if (_logs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.history, size: 64, color: ATColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('Aucun log trouvé', style: TextStyle(color: ATColors.textSecondary)),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final log = _logs[i];
                  final action = (log['action'] as String? ?? '').toLowerCase();
                  final color = _colorForAction(action);
                  return Card(
                    margin: EdgeInsets.only(left: 16, right: 16, top: i == 0 ? 8 : 4, bottom: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        CircleAvatar(
                          backgroundColor: ATColors.secondary.withValues(alpha: 0.15),
                          child: Text(_initiales(log), style: const TextStyle(color: ATColors.secondary, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(_userName(log), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(_iconForAction(action), size: 12, color: color),
                                  const SizedBox(width: 4),
                                  Text(_labelForAction(action), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            ]),
                            Text(_userEmail(log), style: const TextStyle(fontSize: 11, color: ATColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(log['description'] as String? ?? log['action'] as String? ?? '', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.access_time, size: 12, color: ATColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(_formatDate(log['created_at'] as String?), style: const TextStyle(fontSize: 11, color: ATColors.textSecondary)),
                              if (log['ip_address'] != null) ...[
                                const SizedBox(width: 12),
                                const Icon(Icons.dns_outlined, size: 12, color: ATColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(log['ip_address'] as String, style: const TextStyle(fontSize: 11, color: ATColors.textSecondary)),
                              ],
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  );
                },
                childCount: _logs.length,
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                ElevatedButton.icon(
                  onPressed: _page > 1 ? () => _load(_page - 1) : null,
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Précédent'),
                  style: ElevatedButton.styleFrom(backgroundColor: ATColors.secondary),
                ),
                Text('Page $_page / $_lastPage', style: const TextStyle(color: ATColors.textSecondary)),
                ElevatedButton.icon(
                  onPressed: _page < _lastPage ? () => _load(_page + 1) : null,
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Suivant'),
                  style: ElevatedButton.styleFrom(backgroundColor: ATColors.secondary),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
