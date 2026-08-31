import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/missions/missions_screen.dart';
import '../screens/missions/mission_detail_screen.dart';
import '../screens/missions/new_mission_screen.dart';
import '../screens/validation/validation_screen.dart';
import '../screens/dml/dml_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profil/profil_screen.dart';
import '../screens/messagerie/messagerie_screen.dart';
import '../screens/messagerie/conversation_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/rapports/rapports_screen.dart';
import '../screens/organigramme/organigramme_screen.dart';
import '../screens/admin/utilisateurs_screen.dart';
import '../screens/admin/audit_logs_screen.dart';
import '../screens/admin/statistiques_screen.dart';
import '../screens/admin/budgets_screen.dart';
import '../screens/admin/prestataires_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dml/scan_ticket_screen.dart';
import '../screens/missions/scan_justificatif_screen.dart';
import '../screens/missions/geolocation_screen.dart';
import '../screens/missions/checklist_screen.dart';
import '../widgets/floating_nav_bar.dart';
import '../widgets/offline_banner.dart';
import '../services/notification_service.dart';

// ─── Shell avec FloatingNavBar ─────────────────────────────────────────────
class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final List<FloatingNavItem> tabs;
  const _ShellScaffold({required this.child, required this.tabs});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) { currentIndex = i; break; }
    }
    final unread = context.select<NotificationService, int>((s) => s.unreadCount);
    final notifIdx = tabs.indexWhere((t) => t.path == '/notifications');
    final badges = <int, int>{
      if (notifIdx >= 0 && unread > 0) notifIdx: unread,
    };

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      extendBody: false,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: currentIndex,
        items: tabs,
        onTap: (i) => context.go(tabs[i].path),
        badges: badges,
      ),
    );
  }
}

// ─── Shared axis page transition helper ───────────────────────────────────
Page<void> _page(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (ctx, animation, secondary, child) =>
        SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondary,
          transitionType: SharedAxisTransitionType.horizontal,
          child: child,
        ),
  );
}

// ─── Router factory ────────────────────────────────────────────────────────
GoRouter buildRouter(AuthProvider auth) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/splash',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      if (loc == '/splash' || loc == '/onboarding') return null;
      if (auth.isLoading) return null;
      final loggedIn = auth.isAuthenticated;
      final onLogin  = loc == '/login';
      if (!loggedIn && !onLogin)  return '/login';
      if (loggedIn  && onLogin)   return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (ctx, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (ctx, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (_, a, _, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (ctx, state) => _page(state, const LoginScreen()),
      ),

      // ── Search (hors shell, plein écran) ────────────────────────────
      GoRoute(
        path: '/search',
        pageBuilder: (ctx, state) => _page(state, const SearchScreen()),
      ),

      // ── Scan QR (hors shell, plein écran) ──────────────────────────
      GoRoute(
        path: '/scan-ticket',
        pageBuilder: (ctx, state) => _page(state, const ScanTicketScreen()),
      ),

      // ── Scan justificatif (hors shell) ─────────────────────────────
      GoRoute(
        path: '/missions/:id/justificatif',
        pageBuilder: (ctx, state) => _page(state, ScanJustificatifScreen(
          missionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        )),
      ),

      // ── Geolocation pointage (hors shell) ──────────────────────────
      GoRoute(
        path: '/missions/:id/pointage',
        pageBuilder: (ctx, state) => _page(state, GeolocationScreen(
          missionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        )),
      ),

      // ── Checklist voyage (hors shell) ──────────────────────────────
      GoRoute(
        path: '/missions/:id/checklist',
        pageBuilder: (ctx, state) => _page(state, ChecklistScreen(
          missionId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        )),
      ),

      // ── Shell principal ──────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          final role = context.watch<AuthProvider>().roleName;
          final tabs = role == 'admin'
              ? tabsAdmin
              : role == 'directeur'
                  ? tabsDirecteur
                  : role == 'agent_dml'
                      ? tabsDml
                      : tabsDemandeur;
          return _ShellScaffold(tabs: tabs, child: child);
        },
        routes: [
          // Dashboard (page d'accueil)
          GoRoute(
            path: '/dashboard',
            pageBuilder: (ctx, state) => _page(state, const DashboardScreen()),
          ),

          // Missions
          GoRoute(
            path: '/missions',
            pageBuilder: (ctx, state) => _page(state, const MissionsScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (ctx, state) => _page(state, MissionDetailScreen(
                    id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0)),
              ),
            ],
          ),

          // Nouvelle mission
          GoRoute(
            path: '/new-mission',
            pageBuilder: (ctx, state) => _page(state, const NewMissionScreen()),
          ),

          // Rapports & exports
          GoRoute(
            path: '/rapports',
            pageBuilder: (ctx, state) => _page(state, const RapportsScreen()),
          ),

          // Organigramme
          GoRoute(
            path: '/organigramme',
            pageBuilder: (ctx, state) => _page(state, const OrganigrammeScreen()),
          ),

          // Validations (directeur)
          GoRoute(
            path: '/validations',
            pageBuilder: (ctx, state) => _page(state, const ValidationScreen()),
          ),

          // DML (agent_dml)
          GoRoute(
            path: '/dml',
            pageBuilder: (ctx, state) => _page(state, const DmlScreen()),
          ),

          // Messagerie
          GoRoute(
            path: '/messagerie',
            pageBuilder: (ctx, state) => _page(state, const ImessagerieScreen()),
            routes: [
              GoRoute(
                path: ':id',
                pageBuilder: (ctx, state) => _page(state, ConversationScreen(
                  conversationId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  nomCorrespondant: state.uri.queryParameters['nom'],
                  receiverId: int.tryParse(state.uri.queryParameters['receiverId'] ?? ''),
                )),
              ),
            ],
          ),

          // Notifications
          GoRoute(
            path: '/notifications',
            pageBuilder: (ctx, state) => _page(state, const NotificationsScreen()),
          ),

          // Profil
          GoRoute(
            path: '/profil',
            pageBuilder: (ctx, state) => _page(state, const ProfilScreen()),
          ),

          // ── Routes admin ─────────────────────────────────────────────
          GoRoute(
            path: '/admin/utilisateurs',
            pageBuilder: (ctx, state) => _page(state, const UtilisateursScreen()),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            pageBuilder: (ctx, state) => _page(state, const AuditLogsScreen()),
          ),
          GoRoute(
            path: '/admin/statistiques',
            pageBuilder: (ctx, state) => _page(state, const StatistiquesScreen()),
          ),
          GoRoute(
            path: '/admin/budgets',
            pageBuilder: (ctx, state) => _page(state, const BudgetsScreen()),
          ),
          GoRoute(
            path: '/admin/prestataires',
            pageBuilder: (ctx, state) => _page(state, const PrestatairesScreen()),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page introuvable: ${state.error}')),
    ),
  );
}
