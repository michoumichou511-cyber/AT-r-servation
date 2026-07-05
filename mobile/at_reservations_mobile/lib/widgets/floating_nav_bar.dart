import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconly/iconly.dart';
import '../design/design_system.dart';

// ─── Définition d'un onglet ────────────────────────────────────
class FloatingNavItem {
  final String path;
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  const FloatingNavItem({
    required this.path,
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
  });
}

// ─── Tabs par rôle ─────────────────────────────────────────────
const tabsDemandeur = [
  FloatingNavItem(path: '/dashboard',     label: 'Accueil',
      activeIcon: IconlyBold.home,         inactiveIcon: IconlyLight.home),
  FloatingNavItem(path: '/missions',      label: 'Missions',
      activeIcon: IconlyBold.document,     inactiveIcon: IconlyLight.document),
  FloatingNavItem(path: '/messagerie',    label: 'Messages',
      activeIcon: IconlyBold.chat,         inactiveIcon: IconlyLight.chat),
  FloatingNavItem(path: '/notifications', label: 'Notifs',
      activeIcon: IconlyBold.notification, inactiveIcon: IconlyLight.notification),
  FloatingNavItem(path: '/profil',        label: 'Profil',
      activeIcon: IconlyBold.profile,      inactiveIcon: IconlyLight.profile),
];

const tabsDirecteur = [
  FloatingNavItem(path: '/dashboard',     label: 'Accueil',
      activeIcon: IconlyBold.home,         inactiveIcon: IconlyLight.home),
  FloatingNavItem(path: '/validations',   label: 'Validations',
      activeIcon: Icons.task_alt,          inactiveIcon: Icons.task_alt_outlined),
  FloatingNavItem(path: '/messagerie',    label: 'Messages',
      activeIcon: IconlyBold.chat,         inactiveIcon: IconlyLight.chat),
  FloatingNavItem(path: '/notifications', label: 'Notifs',
      activeIcon: IconlyBold.notification, inactiveIcon: IconlyLight.notification),
  FloatingNavItem(path: '/profil',        label: 'Profil',
      activeIcon: IconlyBold.profile,      inactiveIcon: IconlyLight.profile),
];

const tabsDml = [
  FloatingNavItem(path: '/dashboard',     label: 'Accueil',
      activeIcon: IconlyBold.home,         inactiveIcon: IconlyLight.home),
  FloatingNavItem(path: '/dml',           label: 'DML',
      activeIcon: Icons.local_shipping,    inactiveIcon: Icons.local_shipping_outlined),
  FloatingNavItem(path: '/messagerie',    label: 'Messages',
      activeIcon: IconlyBold.chat,         inactiveIcon: IconlyLight.chat),
  FloatingNavItem(path: '/notifications', label: 'Notifs',
      activeIcon: IconlyBold.notification, inactiveIcon: IconlyLight.notification),
  FloatingNavItem(path: '/profil',        label: 'Profil',
      activeIcon: IconlyBold.profile,      inactiveIcon: IconlyLight.profile),
];

const tabsAdmin = [
  FloatingNavItem(path: '/dashboard',          label: 'Accueil',
      activeIcon: IconlyBold.home,              inactiveIcon: IconlyLight.home),
  FloatingNavItem(path: '/admin/utilisateurs', label: 'Utilisateurs',
      activeIcon: IconlyBold.profile,           inactiveIcon: IconlyLight.profile),
  FloatingNavItem(path: '/admin/statistiques', label: 'Stats',
      activeIcon: Icons.bar_chart,              inactiveIcon: Icons.bar_chart_outlined),
  FloatingNavItem(path: '/admin/budgets',      label: 'Budgets',
      activeIcon: Icons.account_balance_wallet, inactiveIcon: Icons.account_balance_wallet_outlined),
  FloatingNavItem(path: '/profil',             label: 'Profil',
      activeIcon: IconlyBold.profile,           inactiveIcon: IconlyLight.profile),
];

// ─── Item animé ────────────────────────────────────────────────
class _NavItemWidget extends StatefulWidget {
  final FloatingNavItem item;
  final bool isActive;
  final VoidCallback onTap;
  const _NavItemWidget(
      {required this.item, required this.isActive, required this.onTap});
  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _handleTap() {
    HapticFeedback.selectionClick();
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 32,
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? DS.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.isActive
                      ? widget.item.activeIcon
                      : widget.item.inactiveIcon,
                  color: widget.isActive ? DS.primary : DS.textPlaceholder,
                  size: 22,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: widget.isActive
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: widget.isActive ? DS.primary : DS.textPlaceholder,
                ),
                child: Text(widget.item.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── FloatingNavBar ─────────────────────────────────────────────
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 70,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 32,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        child: Row(
          children: items.asMap().entries.map((e) => _NavItemWidget(
            item: e.value,
            isActive: currentIndex == e.key,
            onTap: () => onTap(e.key),
          )).toList(),
        ),
      ),
    );
  }
}
