import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api_service.dart';

class OfflineAction {
  final String method;
  final String path;
  final Map<String, dynamic>? body;
  final DateTime createdAt;

  OfflineAction({
    required this.method,
    required this.path,
    this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'method': method,
    'path': path,
    'body': body,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OfflineAction.fromJson(Map<String, dynamic> j) => OfflineAction(
    method: j['method'],
    path: j['path'],
    body: j['body'] as Map<String, dynamic>?,
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );
}

class OfflineService extends ChangeNotifier {
  static final OfflineService _instance = OfflineService._();
  factory OfflineService() => _instance;
  OfflineService._();

  final _connectivity = Connectivity();
  final _api = ApiService();
  StreamSubscription? _sub;
  bool _isOnline = true;
  Box? _cacheBox;
  Box? _queueBox;

  bool get isOnline => _isOnline;
  bool get isOffline => !_isOnline;

  int get pendingCount => _queueBox?.length ?? 0;

  Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('at_cache');
    _queueBox = await Hive.openBox('at_offline_queue');

    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final wasOffline = !_isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);
      notifyListeners();

      if (wasOffline && _isOnline) {
        _syncQueue();
      }
    });
  }

  // ── Cache local ──────────────────────────────────────────────────

  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox?.put(key, jsonEncode({
      'data': data,
      'cachedAt': DateTime.now().toIso8601String(),
    }));
  }

  dynamic getCachedData(String key) {
    final raw = _cacheBox?.get(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw as String);
      return decoded['data'];
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheMissions(List<dynamic> missions) async {
    await cacheData('user_missions', missions);
  }

  List<dynamic> getCachedMissions() {
    return (getCachedData('user_missions') as List?) ?? [];
  }

  Future<void> cacheConversations(List<dynamic> conversations) async {
    await cacheData('conversations', conversations);
  }

  List<dynamic> getCachedConversations() {
    return (getCachedData('conversations') as List?) ?? [];
  }

  Future<void> cacheNotifications(List<dynamic> notifs) async {
    await cacheData('notifications', notifs);
  }

  List<dynamic> getCachedNotifications() {
    return (getCachedData('notifications') as List?) ?? [];
  }

  // ── File d'attente hors-ligne ──────────────────────────────────

  Future<void> enqueue(OfflineAction action) async {
    final key = 'q_${DateTime.now().millisecondsSinceEpoch}';
    await _queueBox?.put(key, jsonEncode(action.toJson()));
    notifyListeners();

    Fluttertoast.showToast(
      msg: 'Action sauvegardée hors-ligne',
      backgroundColor: const Color(0xFFF59E0B),
      textColor: Colors.white,
    );
  }

  Future<void> _syncQueue() async {
    if (_queueBox == null || _queueBox!.isEmpty) return;

    final keys = _queueBox!.keys.toList()..sort();
    int synced = 0;

    for (final key in keys) {
      try {
        final raw = _queueBox!.get(key);
        if (raw == null) continue;
        final action = OfflineAction.fromJson(
          jsonDecode(raw as String) as Map<String, dynamic>,
        );

        switch (action.method.toUpperCase()) {
          case 'POST':
            await _api.post(action.path, action.body ?? {});
          case 'PUT':
            await _api.put(action.path, action.body ?? {});
          case 'DELETE':
            await _api.delete(action.path);
        }

        await _queueBox!.delete(key);
        synced++;
      } catch (_) {
        break;
      }
    }

    if (synced > 0) {
      notifyListeners();
      Fluttertoast.showToast(
        msg: '$synced action${synced > 1 ? 's' : ''} synchronisée${synced > 1 ? 's' : ''}',
        backgroundColor: const Color(0xFF10B981),
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
