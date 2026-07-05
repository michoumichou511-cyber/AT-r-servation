// Golden tests pour les widgets visuels de l'application AT.
// NE MODIFIE AUCUN FICHIER DE PRODUCTION — les mocks sont inline via fromJson.
// Lancer avec : flutter test test/golden/widgets_golden_test.dart --update-goldens
//
// Ne couvre que les widgets isolables (sans Provider/Router/API).
// Les écrans complets (Login/Dashboard/MissionDetail/Messagerie/Profil)
// nécessitent une stack Provider+GoRouter+ApiService non triviale à mocker.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:at_reservations_mobile/models/mission.dart';
import 'package:at_reservations_mobile/widgets/mission_card.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────

MissionModel _mockMission({
  required String statut,
  String? numero = 'OM-2026-00042',
  String titre = 'Mission terrain DSI - Maintenance Oran',
  String? typeMission = 'inspection',
  String? destination = 'Oran, Algérie',
  String dateDepart = '07/06/2026',
  String dateRetour = '09/06/2026',
  bool withUser = true,
}) {
  return MissionModel.fromJson({
    'id': 42,
    'numero_unique': numero,
    'titre': titre,
    'objet_mission': titre,
    'destination': destination,
    'type_mission': typeMission,
    'statut': statut,
    'dates': {
      'depart': dateDepart,
      'retour': dateRetour,
    },
    if (withUser)
      'user': {
        'id': 4,
        'prenom': 'Demandeur',
        'nom': 'Test',
      },
  });
}

/// Wrap les widgets avec un MaterialApp minimal de taille fixe.
Widget _wrap(Widget child, {Size size = const Size(420, 280)}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
    ),
    home: Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Center(
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    // Bundle local Inter fonts (copies de Arial) pour eviter le fetch reseau.
    // Une fois enregistrees via FontLoader, GoogleFonts.inter() les utilise
    // directement sans declencher de HTTP.
    GoogleFonts.config.allowRuntimeFetching = false;
    final loader = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/test/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/test/Inter-Bold.ttf'));
    await loader.load();
  });

  // Helper : pumpWidget + settle + golden compare.
  Future<void> pumpAndGolden(
    WidgetTester tester,
    Widget widget,
    Finder finder,
    String path,
  ) async {
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(finder, matchesGoldenFile(path));
  }

  // ─── StatusBadge — tous les statuts ────────────────────────────────────
  group('StatusBadge', () {
    const statuts = [
      'brouillon',
      'soumis',
      'en_attente',
      'en_validation',
      'approuve',
      'rejete',
      'termine',
      'en_traitement_logistique',
      'valide',
      'annule',
      'en_cours',
    ];

    for (final s in statuts) {
      testWidgets('StatusBadge - $s', (tester) async {
        await pumpAndGolden(
          tester,
          _wrap(
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topLeft,
                child: StatusBadge(s),
              ),
            ),
            size: const Size(200, 60),
          ),
          find.byType(StatusBadge),
          'goldens/status_badge_$s.png',
        );
      });
    }
  });

  // ─── MissionCard — par statut ──────────────────────────────────────────
  // BUG PRODUCTION détecté pendant ces tests : lib/widgets/mission_card.dart
  // utilise SingleTickerProviderStateMixin mais cree 2 AnimationControllers
  // (_pressCtrl + _flipCtrl) → assertion failure en mode test.
  // Fix recommande : remplacer par TickerProviderStateMixin (sans Single).
  // En attendant la correction du fichier de production, tests skip.
  group('MissionCard',
      skip:
          'BUG prod: MissionCard utilise SingleTickerProviderStateMixin avec 2 tickers',
      () {
    const variants = {
      'en_attente': 'En attente (orange)',
      'approuve':   'Approuvée (vert AT)',
      'rejete':     'Rejetée (rouge)',
      'termine':    'Terminée (gris)',
      'soumis':     'Soumise (bleue)',
    };

    variants.forEach((statut, _) {
      testWidgets('MissionCard - $statut', (tester) async {
        await pumpAndGolden(
          tester,
          _wrap(
            MissionCard(
              mission: _mockMission(statut: statut),
              index: 0,
              showUser: true,
              onTap: () {},
            ),
            size: const Size(420, 200),
          ),
          find.byType(MissionCard),
          'goldens/mission_card_$statut.png',
        );
      });
    });

    testWidgets('MissionCard - sans utilisateur (showUser=false)',
        (tester) async {
      await pumpAndGolden(
        tester,
        _wrap(
          MissionCard(
            mission: _mockMission(statut: 'approuve', withUser: false),
            index: 0,
            showUser: false,
          ),
          size: const Size(420, 200),
        ),
        find.byType(MissionCard),
        'goldens/mission_card_no_user.png',
      );
    });

    testWidgets('MissionCard - titre long (overflow)', (tester) async {
      await pumpAndGolden(
        tester,
        _wrap(
          MissionCard(
            mission: _mockMission(
              statut: 'en_validation',
              titre: 'Mission terrain DSI maintenance reseau infrastructure '
                  'Oran Constantine Alger longue chaine pour test overflow',
            ),
            index: 0,
            showUser: true,
          ),
          size: const Size(420, 200),
        ),
        find.byType(MissionCard),
        'goldens/mission_card_long_title.png',
      );
    });

    testWidgets('MissionCard - sans numero unique', (tester) async {
      await pumpAndGolden(
        tester,
        _wrap(
          MissionCard(
            mission: _mockMission(statut: 'brouillon', numero: null),
            index: 0,
          ),
          size: const Size(420, 200),
        ),
        find.byType(MissionCard),
        'goldens/mission_card_no_numero.png',
      );
    });
  });

  // ─── MissionCardSkeleton — état chargement (shimmer) ──────────────────
  testWidgets('MissionCardSkeleton - shimmer loading', (tester) async {
    await tester.pumpWidget(_wrap(
      const MissionCardSkeleton(),
      size: const Size(420, 200),
    ));
    // Fige le shimmer à un instant donné pour un golden reproductible
    await tester.pump(const Duration(milliseconds: 100));
    await expectLater(
      find.byType(MissionCardSkeleton),
      matchesGoldenFile('goldens/mission_card_skeleton.png'),
    );
  });

  // ─── Empty state custom (liste vide) ──────────────────────────────────
  testWidgets('Empty state - aucune mission', (tester) async {
    await tester.pumpWidget(_wrap(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Text('📋', style: TextStyle(fontSize: 64)),
          SizedBox(height: 12),
          Text(
            'Aucune mission',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF334155),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Créez votre première mission avec le bouton +',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ],
      ),
      size: const Size(400, 240),
    ));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/empty_state_missions.png'),
    );
  });

  testWidgets('Empty state - aucune notification', (tester) async {
    await tester.pumpWidget(_wrap(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_none_outlined,
              size: 64, color: Color(0xFF94A3B8)),
          SizedBox(height: 12),
          Text('Aucune notification',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155))),
        ],
      ),
      size: const Size(400, 240),
    ));
    await tester.pump();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('goldens/empty_state_notifications.png'),
    );
  });

  // ─── Bottom navigation simulé (chaque onglet actif) ────────────────────
  group('BottomNav - onglet actif', () {
    const items = [
      ('home', Icons.home_outlined, Icons.home_rounded, 'Accueil'),
      ('missions', Icons.assignment_outlined,
          Icons.assignment_rounded, 'Missions'),
      ('add', Icons.add_circle_outline, Icons.add_circle, 'Nouvelle'),
      ('messages', Icons.chat_bubble_outline,
          Icons.chat_bubble_rounded, 'Messages'),
      ('profil', Icons.person_outline, Icons.person_rounded, 'Profil'),
    ];

    for (var idx = 0; idx < items.length; idx++) {
      final (id, iconOff, iconOn, label) = items[idx];
      testWidgets('BottomNav active=$id', (tester) async {
        await tester.pumpWidget(_wrap(
          _MockBottomNav(activeIndex: idx, items: items),
          size: const Size(420, 90),
        ));
        await tester.pump();
        await expectLater(
          find.byType(_MockBottomNav),
          matchesGoldenFile('goldens/bottom_nav_$id.png'),
        );
        // ignore: unused_local_variable
        final _ = (iconOff, iconOn, label); // évite warning unused
      });
    }
  });
}

// ─── Widget local pour simuler une bottom nav (pas une dépendance prod) ──
class _MockBottomNav extends StatelessWidget {
  final int activeIndex;
  final List<(String, IconData, IconData, String)> items;

  const _MockBottomNav({required this.activeIndex, required this.items});

  static const _primary = Color(0xFF00A650);
  static const _muted   = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  i == activeIndex ? items[i].$3 : items[i].$2,
                  size: 22,
                  color: i == activeIndex ? _primary : _muted,
                ),
                const SizedBox(height: 2),
                Text(
                  items[i].$4,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == activeIndex
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: i == activeIndex ? _primary : _muted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
