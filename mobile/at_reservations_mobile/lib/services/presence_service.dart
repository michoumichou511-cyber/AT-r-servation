import 'dart:async';
import '../utils/date_utils.dart';
import 'api_service.dart';

/// Service singleton gérant le statut de présence (en ligne / hors ligne).
///
/// Usage :
///   PresenceService().startHeartbeat();   // après login
///   PresenceService().stopHeartbeat();    // avant logout
class PresenceService {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  // ── État interne ───────────────────────────────────────────────────────────
  Timer? _heartbeatTimer;
  final _api = ApiService();

  // ── Heartbeat (toutes les 5 minutes) ──────────────────────────────────────

  /// Démarre le heartbeat : envoie `is_online: true` immédiatement puis
  /// toutes les 5 minutes.
  void startHeartbeat() {
    stopHeartbeat(); // évite double timer
    _updateStatus(true);
    _heartbeatTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _updateStatus(true),
    );
  }

  /// Arrête le heartbeat et marque l'utilisateur hors ligne.
  Future<void> stopHeartbeat() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _updateStatus(false);
  }

  // ── Appel API ──────────────────────────────────────────────────────────────

  Future<void> _updateStatus(bool isOnline) async {
    try {
      await _api.patch('/user/presence', {'is_online': isOnline});
    } catch (_) {
      // Silencieux — pas bloquant si le réseau est indisponible
    }
  }

  // ── Lecture du statut d'un interlocuteur ───────────────────────────────────

  /// Retourne le statut de présence d'un utilisateur par son [userId].
  /// Retourne `null` en cas d'erreur réseau.
  Future<PresenceStatus?> fetchStatus(int userId) async {
    try {
      final data = await _api.get('/users/$userId/presence');
      final isOnline = data['is_online'] as bool? ?? false;
      final lastSeen = parseBackendDate(data['last_seen']);
      return PresenceStatus(isOnline: isOnline, lastSeen: lastSeen);
    } catch (_) {
      return null;
    }
  }
}

/// Résultat de `fetchStatus`.
class PresenceStatus {
  final bool      isOnline;
  final DateTime? lastSeen;

  const PresenceStatus({required this.isOnline, this.lastSeen});

  /// Texte lisible ("En ligne", "Vu il y a 5 min", "Vu le 24/05/2026").
  String get label {
    if (isOnline) return 'En ligne';
    if (lastSeen == null) return 'Hors ligne';

    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inMinutes < 1)  return 'Vu à l\'instant';
    if (diff.inMinutes < 60) return 'Vu il y a ${diff.inMinutes} min';
    if (diff.inHours   < 24) return 'Vu il y a ${diff.inHours} h';

    final d = lastSeen!;
    final day   = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    return 'Vu le $day/$month/${d.year}';
  }
}
