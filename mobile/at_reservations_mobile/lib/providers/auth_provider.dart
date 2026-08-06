import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/presence_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String?    _token;
  bool       _loading = true;

  UserModel? get user           => _user;
  String?    get token          => _token;
  bool       get isLoading      => _loading;
  bool       get isAuthenticated => _user != null && _token != null;
  String     get roleName        => _user?.roleName ?? '';

  final _api  = ApiService();
  final _auth = AuthService();

  AuthProvider() {
    _api.onUnauthorized = _onSessionExpired;
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    _loading = true;
    notifyListeners();
    try {
      final token = await _auth.getToken();
      if (token != null) {
        _token = token;
        final res  = await _api.get('/auth/me');
        final data = res['data'] as Map<String, dynamic>?;
        final uMap = data?['user'] as Map<String, dynamic>? ?? data;
        if (uMap != null) {
          _user = UserModel.fromJson(uMap);
          await _auth.saveUser(_user!);
          PresenceService().startHeartbeat();
        } else {
          await _auth.clear();
          _token = null;
        }
      }
    } catch (_) {
      await _auth.clear();
      _token = null;
      _user  = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> tryAutoLogin() => _restoreSession();

  Future<void> login(String email, String password) async {
    final res  = await _api.post('/auth/login', {'email': email, 'password': password});
    final body = res as Map<String, dynamic>;
    final t    = body['data']?['token'] as String? ?? body['token'] as String?;
    final uMap = body['data']?['user'] as Map<String, dynamic>?
        ?? body['user'] as Map<String, dynamic>?;

    if (t == null || uMap == null) {
      throw Exception('Réponse serveur invalide.');
    }

    final u = UserModel.fromJson(uMap);
    if (u.roleName == 'admin') {
      throw Exception(
        "L'accès administrateur n'est pas disponible sur mobile.\n"
        "Veuillez utiliser la version web.",
      );
    }

    await _auth.saveToken(t);
    await _auth.saveUser(u);
    _token = t;
    _user  = u;
    PresenceService().startHeartbeat();
    notifyListeners();
  }

  Future<void> logout() async {
    _loading = true;          // bloque le redirect GoRouter pendant le logout
    notifyListeners();
    await PresenceService().stopHeartbeat();
    try { await _api.post('/auth/logout'); } catch (_) {}
    _token = null;
    _user  = null;
    await _auth.clear();
    _loading = false;
    notifyListeners();        // GoRouter redirige maintenant vers /login
  }

  void _onSessionExpired() {
    _auth.clear();
    _token = null;
    _user  = null;
    notifyListeners();
  }
}
