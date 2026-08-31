import 'dart:async';
import 'package:flutter/material.dart';
import 'api_service.dart';

enum NotifCategory { mission, validation, logistique, message, systeme }

class NotifCategoryConfig {
  final Color color;
  final IconData icon;
  final String label;
  const NotifCategoryConfig(this.color, this.icon, this.label);
}

const notifCategoryConfigs = {
  NotifCategory.mission: NotifCategoryConfig(
    Color(0xFF3B82F6), Icons.flight_takeoff, 'Mission',
  ),
  NotifCategory.validation: NotifCategoryConfig(
    Color(0xFF10B981), Icons.check_circle, 'Validation',
  ),
  NotifCategory.logistique: NotifCategoryConfig(
    Color(0xFF8B5CF6), Icons.local_shipping, 'Logistique',
  ),
  NotifCategory.message: NotifCategoryConfig(
    Color(0xFFF59E0B), Icons.message, 'Message',
  ),
  NotifCategory.systeme: NotifCategoryConfig(
    Color(0xFFEF4444), Icons.warning_amber, 'Système',
  ),
};

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final _api = ApiService();
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollTimer;

  List<Map<String, dynamic>> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  NotifCategory detectCategory(Map<String, dynamic> n) {
    final type = (n['type'] ?? '').toString().toLowerCase();
    final titre = (n['titre'] ?? n['title'] ?? '').toString().toLowerCase();
    final cat = (n['categorie'] ?? n['category'] ?? '').toString().toLowerCase();
    final combined = '$type $titre $cat';

    if (combined.contains('valid') || combined.contains('approuv') ||
        combined.contains('rejet')) {
      return NotifCategory.validation;
    }
    if (combined.contains('logist') || combined.contains('billet') ||
        combined.contains('hotel') || combined.contains('transport')) {
      return NotifCategory.logistique;
    }
    if (combined.contains('message') || combined.contains('chat') ||
        combined.contains('msg')) {
      return NotifCategory.message;
    }
    if (combined.contains('system') || combined.contains('erreur') ||
        combined.contains('alert')) {
      return NotifCategory.systeme;
    }
    return NotifCategory.mission;
  }

  Future<void> init() async {
    await fetchNotifications();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchNotifications(),
    );
  }

  Future<void> fetchNotifications() async {
    try {
      final res = await _api.get('/notifications');
      final data = res is Map ? (res['data'] ?? res) : res;
      if (data is List) {
        _notifications = List<Map<String, dynamic>>.from(data);
        _unreadCount = _notifications.where((n) => n['lu'] != true && n['read'] != true).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final res = await _api.get('/notifications/count');
      final data = res is Map ? res : {};
      _unreadCount = data['data']?['count'] ?? data['count'] ?? _unreadCount;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.post('/notifications/$id/read', {});
      final idx = _notifications.indexWhere((n) => n['id'] == id);
      if (idx >= 0) {
        _notifications[idx]['lu'] = true;
        _notifications[idx]['read'] = true;
        _unreadCount = _notifications.where((n) => n['lu'] != true && n['read'] != true).length;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all', {});
      for (final n in _notifications) {
        n['lu'] = true;
        n['read'] = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
