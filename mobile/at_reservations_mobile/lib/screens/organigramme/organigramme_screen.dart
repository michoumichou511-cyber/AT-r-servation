import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

// ─── Modèle nœud ──────────────────────────────────────────────────────────

class OrgNode {
  final int id;
  final String nom;
  final String prenom;
  final String poste;
  final String direction;
  final List<OrgNode> children;

  OrgNode({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.poste,
    required this.direction,
    required this.children,
  });

  String get displayName => '$prenom $nom'.trim();
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  factory OrgNode.fromJson(Map<String, dynamic> j) {
    final childList = j['children'] as List? ?? [];
    return OrgNode(
      id: int.tryParse(j['id']?.toString() ?? '0') ?? 0,
      nom: (j['nom'] ?? j['last_name'] ?? j['name'] ?? '').toString(),
      prenom: (j['prenom'] ?? j['first_name'] ?? '').toString(),
      poste: (j['poste'] ?? j['role'] ?? j['function'] ?? '–').toString(),
      direction: (j['direction'] ?? j['department'] ?? '').toString(),
      children: childList
          .map((c) => OrgNode.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─── Écran principal ──────────────────────────────────────────────────────

class OrganigrammeScreen extends StatefulWidget {
  const OrganigrammeScreen({super.key});

  @override
  State<OrganigrammeScreen> createState() => _OrganigrammeScreenState();
}

class _OrganigrammeScreenState extends State<OrganigrammeScreen> {
  final _api = ApiService();
  bool _loading = true;
  bool _hasError = false;
  List<OrgNode> _roots = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final res = await _api.get('/users/organigramme');
      final raw = res['data'] ?? res['organigramme'] ?? res ?? [];
      if (raw is List && raw.isNotEmpty) {
        _roots = raw
            .map((e) => OrgNode.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (raw is Map<String, dynamic>) {
        _roots = [OrgNode.fromJson(raw)];
      } else {
        _roots = _mockOrgData();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Endpoint non encore déployé — afficher données de démonstration
        _roots = _mockOrgData();
      } else {
        _hasError = true;
      }
    } catch (_) {
      // Fallback démonstration si API inaccessible
      _roots = _mockOrgData();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Données de démonstration pour la soutenance
  List<OrgNode> _mockOrgData() {
    return [
      OrgNode(
        id: 1, nom: 'Benali', prenom: 'Mohamed',
        poste: 'Directeur Général', direction: 'Direction Générale',
        children: [
          OrgNode(
            id: 2, nom: 'Khelifi', prenom: 'Nadia',
            poste: 'Directrice Administrative', direction: 'Direction Administrative',
            children: [
              OrgNode(id: 5, nom: 'Amrani', prenom: 'Karim', poste: 'Chef de service', direction: 'Direction Administrative', children: []),
              OrgNode(id: 6, nom: 'Bouzid', prenom: 'Sara', poste: 'Gestionnaire RH', direction: 'Direction Administrative', children: []),
            ],
          ),
          OrgNode(
            id: 3, nom: 'Messaoudi', prenom: 'Ahmed',
            poste: 'Directeur Technique', direction: 'Direction Technique',
            children: [
              OrgNode(id: 7, nom: 'Rahmani', prenom: 'Farid', poste: 'Ingénieur réseau', direction: 'Direction Technique', children: []),
              OrgNode(id: 8, nom: 'Ouali', prenom: 'Leila', poste: 'Ingénieure systèmes', direction: 'Direction Technique', children: []),
            ],
          ),
          OrgNode(
            id: 4, nom: 'Hadjadj', prenom: 'Fatima',
            poste: 'Directrice Financière', direction: 'Direction Financière',
            children: [
              OrgNode(id: 9, nom: 'Djemaa', prenom: 'Youcef', poste: 'Comptable', direction: 'Direction Financière', children: []),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ATColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Organigramme',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _load,
                tooltip: 'Actualiser',
              ),
            ],
          ),
          SliverFillRemaining(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return _buildShimmer();
    if (_hasError) return _buildErrorState();
    if (_roots.isEmpty) return _buildEmptyState();

    return InteractiveViewer(
      boundaryMargin: const EdgeInsets.all(500),
      minScale: 0.3,
      maxScale: 3.0,
      constrained: false,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _roots
              .map((root) => _OrgTreeWidget(node: root, onTap: _showDetail))
              .toList(),
        ),
      ),
    );
  }

  void _showDetail(OrgNode node) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _colorForDirection(node.direction),
              child: Text(
                node.initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Text(node.displayName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(node.poste,
                style: const TextStyle(
                    color: ATColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            if (node.direction.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: ATColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(node.direction,
                    style: const TextStyle(
                        color: ATColors.secondary, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _shimmerBox(120, 72),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(110, 68),
                const SizedBox(width: 40),
                _shimmerBox(110, 68),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _shimmerBox(100, 64),
                const SizedBox(width: 24),
                _shimmerBox(100, 64),
                const SizedBox(width: 24),
                _shimmerBox(100, 64),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(10)),
      );

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined,
              size: 80,
              color: ATColors.textSecondary.withValues(alpha: 0.35)),
          const SizedBox(height: 16),
          const Text(
            'Organigramme non disponible',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ATColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aucune donnée d\'organigramme n\'a été trouvée.',
            style: TextStyle(color: ATColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 64, color: ATColors.error),
          const SizedBox(height: 16),
          const Text('Impossible de charger l\'organigramme.',
              style: TextStyle(color: ATColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ─── Couleur par direction ────────────────────────────────────────────────

Color _colorForDirection(String direction) {
  final d = direction.toLowerCase();
  if (d.contains('financ')) return ATColors.warning;
  if (d.contains('tech')) return ATColors.info;
  if (d.contains('admin')) return ATColors.secondary;
  if (d.contains('générale') || d.contains('general')) {
    return ATColors.primary;
  }
  final colors = [
    ATColors.primary,
    ATColors.secondary,
    ATColors.info,
    const Color(0xFF7C3AED),
    const Color(0xFF0891B2),
  ];
  return colors[direction.length % colors.length];
}

// ─── Widget nœud ──────────────────────────────────────────────────────────

class _OrgNodeWidget extends StatelessWidget {
  final OrgNode node;
  final VoidCallback onTap;

  const _OrgNodeWidget({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = _colorForDirection(node.direction);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(
              color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  node.initials,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.displayName,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: ATColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.poste,
                      style: const TextStyle(
                          fontSize: 10, color: ATColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Arbre récursif avec lignes ───────────────────────────────────────────

class _OrgTreeWidget extends StatelessWidget {
  final OrgNode node;
  final void Function(OrgNode) onTap;

  const _OrgTreeWidget({required this.node, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OrgNodeWidget(node: node, onTap: () => onTap(node)),
        if (node.children.isNotEmpty) ...[
          // Ligne verticale vers le bas
          CustomPaint(
            size: const Size(2, 20),
            painter: _VerticalLinePainter(),
          ),
          // Ligne horizontale + sous-arbres
          _ChildrenRow(children: node.children, onTap: onTap),
        ],
      ],
    );
  }
}

class _ChildrenRow extends StatelessWidget {
  final List<OrgNode> children;
  final void Function(OrgNode) onTap;

  const _ChildrenRow({required this.children, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (children.length == 1) {
      return _OrgTreeWidget(node: children.first, onTap: onTap);
    }
    return CustomPaint(
      painter: _HorizontalBridgePainter(count: children.length),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((child) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(2, 20),
                  painter: _VerticalLinePainter(),
                ),
                _OrgTreeWidget(node: child, onTap: onTap),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _VerticalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ATColors.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HorizontalBridgePainter extends CustomPainter {
  final int count;
  const _HorizontalBridgePainter({required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;
    final paint = Paint()
      ..color = ATColors.textSecondary.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Horizontal line connecting children at top
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width, 0),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
