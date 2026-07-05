import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() => _storage.read(key: 'sanctum_token');

  Future<void> saveToken(String token) =>
      _storage.write(key: 'sanctum_token', value: token);

  Future<UserModel?> getSavedUser() async {
    final raw = await _storage.read(key: 'user_data');
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    final j = {
      'id':          user.id,
      'nom':         user.nom,
      'prenom':      user.prenom,
      'email':       user.email,
      'role':        user.roleName,
      'matricule':   user.matricule,
      'direction':   user.direction,
      'service':     user.service,
      'poste':       user.poste,
      'telephone':   user.telephone,
      'auth_method': user.authMethod,
    };
    await _storage.write(key: 'user_data', value: jsonEncode(j));
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
