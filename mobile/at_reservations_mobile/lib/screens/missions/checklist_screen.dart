import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design/design_system.dart';
import '../../utils/haptics.dart';

class ChecklistItem {
  final String id;
  final String label;
  final IconData icon;
  bool checked;

  ChecklistItem({
    required this.id,
    required this.label,
    required this.icon,
    this.checked = false,
  });
}

class ChecklistScreen extends StatefulWidget {
  final int missionId;
  final String? transportType;
  final bool hasHotel;
  final bool isRemboursement;

  const ChecklistScreen({
    super.key,
    required this.missionId,
    this.transportType,
    this.hasHotel = false,
    this.isRemboursement = false,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late List<ChecklistItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _generateItems();
    _loadState();
  }

  List<ChecklistItem> _generateItems() {
    final items = <ChecklistItem>[
      ChecklistItem(
        id: 'documents',
        label: 'Documents d\'identité',
        icon: Icons.badge,
      ),
      ChecklistItem(
        id: 'ordre',
        label: 'Ordre de mission imprimé / PDF',
        icon: Icons.description,
      ),
    ];

    if (widget.transportType?.toLowerCase() == 'avion') {
      items.add(ChecklistItem(
        id: 'billet',
        label: 'Billet d\'avion',
        icon: Icons.flight,
      ));
    }

    if (widget.hasHotel) {
      items.add(ChecklistItem(
        id: 'hotel',
        label: 'Confirmation hôtel',
        icon: Icons.hotel,
      ));
    }

    items.add(ChecklistItem(
      id: 'contacts',
      label: 'Contacts DML enregistrés',
      icon: Icons.contacts,
    ));

    if (widget.isRemboursement) {
      items.add(ChecklistItem(
        id: 'justificatifs',
        label: 'Justificatifs de dépenses',
        icon: Icons.receipt_long,
      ));
    }

    items.add(ChecklistItem(
      id: 'chargeur',
      label: 'Chargeur / batterie externe',
      icon: Icons.battery_charging_full,
    ));

    return items;
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    for (final item in _items) {
      item.checked = prefs.getBool('checklist_${widget.missionId}_${item.id}') ?? false;
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggle(ChecklistItem item) async {
    Haptics.selection();
    setState(() => item.checked = !item.checked);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('checklist_${widget.missionId}_${item.id}', item.checked);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final checked = _items.where((i) => i.checked).length;
    final total = _items.length;
    final progress = total > 0 ? checked / total : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Check-list voyage')),
      body: Column(
        children: [
          // Barre de progression
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dark ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: DS.shadowSm,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$checked / $total',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: DS.primary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: progress == 1.0
                            ? DS.success.withValues(alpha: 0.15)
                            : DS.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        progress == 1.0 ? 'Prêt !' : 'En préparation',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: progress == 1.0 ? DS.success : DS.warning,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearPercentIndicator(
                  lineHeight: 8,
                  percent: progress,
                  backgroundColor: dark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                  linearGradient: const LinearGradient(
                    colors: [DS.primary, Color(0xFF059669)],
                  ),
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                  animation: true,
                  animationDuration: 600,
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          // Liste
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return _ChecklistTile(
                  item: item,
                  onTap: () => _toggle(item),
                  delay: index * 80,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  final VoidCallback onTap;
  final int delay;

  const _ChecklistTile({
    required this.item,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: item.checked
            ? DS.primary.withValues(alpha: 0.08)
            : dark ? const Color(0xFF1E293B) : Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.checked ? DS.primary : Colors.transparent,
                    border: Border.all(
                      color: item.checked ? DS.primary : DS.textPlaceholder,
                      width: 2,
                    ),
                  ),
                  child: item.checked
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Icon(item.icon, size: 20,
                    color: item.checked ? DS.primary : DS.textMuted),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: item.checked
                          ? DS.primary
                          : dark ? Colors.white : DS.textPrimary,
                      decoration: item.checked
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
        .slideX(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
