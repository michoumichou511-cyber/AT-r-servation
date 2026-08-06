import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design/design_system.dart';
import '../services/api_service.dart';
import '../utils/haptics.dart';

class SOSButton extends StatefulWidget {
  final int missionId;
  final String? dmlPhone;

  const SOSButton({
    super.key,
    required this.missionId,
    this.dmlPhone,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    Haptics.impact();
    setState(() => _expanded = !_expanded);
  }

  Future<void> _callDml() async {
    if (widget.dmlPhone != null) {
      await launchUrl(Uri.parse('tel:${widget.dmlPhone}'));
    }
  }

  Future<void> _sendUrgent() async {
    Haptics.warning();
    try {
      await ApiService().post('/missions/${widget.missionId}/sos', {
        'type': 'urgent',
        'message': 'Besoin d\'assistance urgente',
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message SOS envoyé à la DML'),
            backgroundColor: DS.success,
          ),
        );
        setState(() => _expanded = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: DS.error),
        );
      }
    }
  }

  Future<void> _sendGps() async {
    Haptics.warning();
    try {
      await ApiService().post('/missions/${widget.missionId}/sos', {
        'type': 'localisation',
        'message': 'Besoin d\'assistance — position GPS envoyée',
        'timestamp': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position envoyée à la DML'),
            backgroundColor: DS.success,
          ),
        );
        setState(() => _expanded = false);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_expanded) ...[
          _SOSOption(
            icon: Icons.phone,
            label: 'Appeler DML',
            color: DS.info,
            onTap: _callDml,
            delay: 0,
          ),
          const SizedBox(height: 8),
          _SOSOption(
            icon: Icons.message,
            label: 'Message urgent',
            color: DS.warning,
            onTap: _sendUrgent,
            delay: 80,
          ),
          const SizedBox(height: 8),
          _SOSOption(
            icon: Icons.gps_fixed,
            label: 'Envoyer ma position',
            color: DS.primary,
            onTap: _sendGps,
            delay: 160,
          ),
          const SizedBox(height: 12),
        ],

        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (context, child) {
            final glow = _pulseCtrl.value * 0.6;
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: DS.error.withValues(alpha: glow),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: DS.error,
            child: AnimatedRotation(
              turns: _expanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.sos, size: 28, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _SOSOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int delay;

  const _SOSOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(28),
      color: color,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 200.ms)
        .slideX(begin: 0.3, end: 0);
  }
}
