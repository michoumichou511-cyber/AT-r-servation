import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class PrestatairesScreen extends StatefulWidget {
  const PrestatairesScreen({super.key});

  @override
  State<PrestatairesScreen> createState() => _PrestatairesScreenState();
}

class _PrestatairesScreenState extends State<PrestatairesScreen> {
  final _api = ApiService();
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  String _typeFilter = 'Tous';

  final _types = ['Tous', 'Hôtel', 'Transport', 'Traiteur', 'Autre'];
  final _typeMap = {'Hôtel': 'hotel', 'Transport': 'transport', 'Traiteur': 'traiteur', 'Autre': 'autre'};
  final _typeIcons = {
    'hotel': Icons.hotel,
    'transport': Icons.directions_bus,
    'traiteur': Icons.restaurant,
    'autre': Icons.business,
  };
  final _typeColors = {
    'hotel': ATColors.info,
    'transport': ATColors.secondary,
    'traiteur': ATColors.warning,
    'autre': ATColors.textSecondary,
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
      final data = await _api.get('/prestataires');
      final list = (data is List ? data : (data['data'] ?? [])) as List;
      setState(() {
        _items = list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
      _applyFilters();
    } on ApiException catch (e) {
      if (e.statusCode == 404) setState(() { _items = []; _loading = false; _applyFilters(); });
      else setState(() => _loading = false);
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _applyFilters() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _items.where((p) {
        final matchSearch = q.isEmpty || (p['nom'] as String? ?? '').toLowerCase().contains(q) ||
            (p['email'] as String? ?? '').toLowerCase().contains(q);
        final matchType = _typeFilter == 'Tous' || p['type'] == _typeMap[_typeFilter];
        return matchSearch && matchType;
      }).toList();
    });
  }

  void _showAddBottomSheet() {
    final nomCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String type = 'hotel';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Nouveau prestataire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'hotel', child: Text('Hôtel')),
                DropdownMenuItem(value: 'transport', child: Text('Transport')),
                DropdownMenuItem(value: 'traiteur', child: Text('Traiteur')),
                DropdownMenuItem(value: 'autre', child: Text('Autre')),
              ],
              onChanged: (v) => setS(() => type = v!),
            ),
            const SizedBox(height: 10),
            TextField(controller: telCtrl, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder()), keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: ATColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _api.post('/prestataires', {
                      'nom': nomCtrl.text, 'type': type,
                      'telephone': telCtrl.text, 'email': emailCtrl.text,
                    });
                    _load();
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                  }
                },
                child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
        itemCount: 6,
        itemBuilder: (_, __) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
      ),
    );
  }

  Widget _buildRatingStars(dynamic rating) {
    if (rating == null) return const SizedBox.shrink();
    final r = (rating as num).toDouble().clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < r.floor() ? Icons.star : (i < r ? Icons.star_half : Icons.star_border),
        size: 14, color: ATColors.warning,
      )),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final type = (p['type'] as String? ?? 'autre').toLowerCase();
    final color = _typeColors[type] ?? ATColors.textSecondary;
    final icon = _typeIcons[type] ?? Icons.business;
    final isActive = p['is_active'] == true || p['is_active'] == 1;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const Spacer(),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(color: isActive ? ATColors.success : ATColors.error, shape: BoxShape.circle),
            ),
          ]),
          const SizedBox(height: 8),
          Text(p['nom'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(type[0].toUpperCase() + type.substring(1), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 6),
          if (p['telephone'] != null)
            Row(children: [
              const Icon(Icons.phone, size: 12, color: ATColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(p['telephone'] as String, style: const TextStyle(fontSize: 11, color: ATColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ]),
          if (p['email'] != null)
            Row(children: [
              const Icon(Icons.email, size: 12, color: ATColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(p['email'] as String, style: const TextStyle(fontSize: 11, color: ATColors.textSecondary), overflow: TextOverflow.ellipsis)),
            ]),
          if (p['note'] != null || p['rating'] != null) ...[
            const SizedBox(height: 4),
            _buildRatingStars(p['note'] ?? p['rating']),
          ],
        ]),
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
              title: const Text('Prestataires', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Rechercher un prestataire...',
                  prefixIcon: const Icon(Icons.search, color: ATColors.textSecondary),
                  filled: true, fillColor: Colors.white,
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
                itemCount: _types.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _types[i];
                  final selected = _typeFilter == t;
                  return FilterChip(
                    label: Text(t),
                    selected: selected,
                    onSelected: (_) { setState(() => _typeFilter = t); _applyFilters(); },
                    selectedColor: ATColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: ATColors.primary,
                  );
                },
              ),
            ),
          ),
          if (_loading)
            SliverFillRemaining(child: _buildShimmerGrid())
          else if (_filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.store_outlined, size: 64, color: ATColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text('Aucun prestataire trouvé', style: TextStyle(color: ATColors.textSecondary)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildCard(_filtered[i]),
                  childCount: _filtered.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.78,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        backgroundColor: ATColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
