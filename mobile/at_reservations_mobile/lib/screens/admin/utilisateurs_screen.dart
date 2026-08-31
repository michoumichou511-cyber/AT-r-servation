import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<UtilisateursScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _roleFilter = 'Tous';

  final _roles = ['Tous', 'Demandeur', 'Directeur', 'Agent DML', 'Admin'];
  final _roleMap = {
    'Demandeur': 'demandeur',
    'Directeur': 'directeur',
    'Agent DML': 'agent_dml',
    'Admin': 'admin',
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('/admin/utilisateurs');
      final raw = data['data'] ?? data;
      final list = (raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : [])) as List;
      setState(() {
        _users = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
      _applyFilters();
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) {
        final matchSearch = query.isEmpty ||
            '${u['nom']} ${u['prenom']} ${u['email']}'.toLowerCase().contains(query);
        // role peut être string directe ou via objet nested
        final roleRaw = u['role'];
        final roleVal = (roleRaw is String ? roleRaw : null)
            ?? (u['role_name'] as String?)
            ?? (u['roleName'] as String?)
            ?? (roleRaw is Map ? roleRaw['name'] as String? : null)
            ?? 'demandeur';
        final matchRole = _roleFilter == 'Tous' ||
            roleVal == _roleMap[_roleFilter];
        return matchSearch && matchRole;
      }).toList();
    });
  }

  Future<void> _toggleActive(int id, bool value) async {
    try {
      await _api.patch('/admin/utilisateurs/$id', {'is_active': value});
      final idx = _users.indexWhere((u) => u['id'] == id);
      if (idx != -1) {
        setState(() => _users[idx]['is_active'] = value);
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: ATColors.error),
        );
      }
    }
  }

  Color _colorForRole(String role) {
    switch (role) {
      case 'directeur': return ATColors.secondary;
      case 'agent_dml': return ATColors.warning;
      case 'admin': return const Color(0xFF7C3AED);
      default: return ATColors.primary;
    }
  }

  String _labelForRole(String role) {
    switch (role) {
      case 'directeur': return 'Directeur';
      case 'agent_dml': return 'Agent DML';
      case 'admin': return 'Admin';
      default: return 'Demandeur';
    }
  }

  void _showCreateDialog() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'demandeur';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Nouvel utilisateur'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
              const SizedBox(height: 8),
              TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedRole,
                decoration: const InputDecoration(labelText: 'Rôle'),
                items: const [
                  DropdownMenuItem(value: 'demandeur', child: Text('Demandeur')),
                  DropdownMenuItem(value: 'directeur', child: Text('Directeur')),
                  DropdownMenuItem(value: 'agent_dml', child: Text('Agent DML')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setS(() => selectedRole = v!),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ATColors.primary),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _api.post('/admin/utilisateurs', {
                    'nom': nomCtrl.text, 'prenom': prenomCtrl.text,
                    'email': emailCtrl.text, 'role': selectedRole,
                  });
                  _load();
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                }
              },
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, _) => Container(height: 72, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
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
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Utilisateurs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher un utilisateur...',
                  prefixIcon: Icon(Icons.search, color: context.textSecondary),
                  filled: true, fillColor: context.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _roles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final r = _roles[i];
                  final selected = _roleFilter == r;
                  return FilterChip(
                    label: Text(r),
                    selected: selected,
                    onSelected: (_) { setState(() => _roleFilter = r); _applyFilters(); },
                    selectedColor: ATColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: ATColors.primary,
                  );
                },
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(child: _buildShimmer())
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.people_outline, size: 64, color: context.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('Aucun utilisateur trouvé', style: TextStyle(color: context.textSecondary)),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final u = _filtered[i];
                  final roleR = u['role'];
                  final role = (roleR is String ? roleR : null)
                      ?? (u['role_name'] as String?)
                      ?? (u['roleName'] as String?)
                      ?? (roleR is Map ? roleR['name'] as String? : null)
                      ?? 'demandeur';
                  final initiales = '${(u['prenom'] as String? ?? ' ')[0]}${(u['nom'] as String? ?? ' ')[0]}'.toUpperCase();
                  return Card(
                    margin: EdgeInsets.only(left: 16, right: 16, top: i == 0 ? 8 : 4, bottom: 4),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _colorForRole(role),
                        child: Text(initiales, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      title: Text('${u['prenom']} ${u['nom']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(u['email'] as String? ?? '', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: _colorForRole(role).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                          child: Text(_labelForRole(role), style: TextStyle(fontSize: 11, color: _colorForRole(role), fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Switch(
                          value: u['is_active'] == true || u['is_active'] == 1,
                          activeThumbColor: ATColors.primary,
                          onChanged: (v) => _toggleActive(u['id'] as int, v),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          onSelected: (action) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$action pour ${u['prenom']}')));
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'Changer rôle', child: Text('Changer rôle')),
                            PopupMenuItem(value: 'Changer structure', child: Text('Changer structure')),
                            PopupMenuItem(value: 'Voir profil', child: Text('Voir profil')),
                          ],
                        ),
                      ]),
                    ),
                  );
                },
                childCount: _filtered.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        backgroundColor: ATColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
