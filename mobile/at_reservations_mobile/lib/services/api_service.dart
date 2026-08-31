import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  Function? onUnauthorized;
  String? _currentBaseUrl;

  /// Récupère l'URL de base active (avec priorité à l'URL personnalisée).
  Future<String> getBaseUrl() async {
    if (_currentBaseUrl != null) return _currentBaseUrl!;
    final customUrl = await _storage.read(key: 'custom_api_url');
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _currentBaseUrl = customUrl.trim();
    } else {
      _currentBaseUrl = kApiBaseUrl;
    }
    return _currentBaseUrl!;
  }

  /// Définit une nouvelle URL de base pour l'API.
  Future<void> setCustomUrl(String? url) async {
    if (url == null || url.trim().isEmpty) {
      await _storage.delete(key: 'custom_api_url');
      _currentBaseUrl = kApiBaseUrl;
    } else {
      String clean = url.trim();
      if (!clean.endsWith('/api') && !clean.endsWith('/api/')) {
        if (clean.endsWith('/')) {
          clean = '${clean}api';
        } else {
          clean = '$clean/api';
        }
      }
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        clean = 'http://$clean';
      }
      await _storage.write(key: 'custom_api_url', value: clean);
      _currentBaseUrl = clean;
    }
  }

  /// Tente de détecter automatiquement une URL fonctionnelle en cas de problème de connexion.
  Future<String> _autoDetectWorkingUrl() async {
    final active = await getBaseUrl();
    final candidates = [
      active,
      'http://192.168.1.7:8000/api',
      'http://127.0.0.1:8000/api',
      'http://10.0.2.2:8000/api',
    ];

    for (final candidate in candidates) {
      try {
        final res = await http.get(Uri.parse('$candidate/health'))
            .timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          _currentBaseUrl = candidate;
          await _storage.write(key: 'custom_api_url', value: candidate);
          return candidate;
        }
      } catch (_) {}
    }
    return active;
  }

  Future<Map<String, String>> _headers([String? path]) async {
    final isAuthPublicRoute = path != null &&
        (path.contains('/auth/login') || path.contains('/auth/register'));
    final token = isAuthPublicRoute ? null : await _storage.read(key: 'sanctum_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Type': kClientType,
      'ngrok-skip-browser-warning': 'true',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  void _handleStatus(int code, String body, [String? path]) {
    if (code == 401) {
      final isAuthRoute = path != null &&
          (path.contains('/auth/login') || path.contains('/auth/logout'));
      if (!isAuthRoute) {
        onUnauthorized?.call();
      }
      String msg = 'Identifiants incorrects ou session expirée.';
      try {
        final j = jsonDecode(body) as Map<String, dynamic>;
        msg = j['message'] as String? ?? j['error'] as String? ?? msg;
      } catch (_) {}
      throw ApiException(401, msg);
    }
    if (code >= 400) {
      String msg = 'Erreur $code';
      try {
        final j = jsonDecode(body) as Map<String, dynamic>;
        msg = j['message'] as String? ?? j['error'] as String? ?? msg;
      } catch (_) {}
      throw ApiException(code, msg);
    }
  }

  Future<T> _executeWithFallback<T>(Future<T> Function(String baseUrl) requestFn) async {
    String baseUrl = await getBaseUrl();
    try {
      return await requestFn(baseUrl);
    } catch (e) {
      if (e is ApiException) rethrow;

      // Auto-fallback sur erreur réseau
      final newUrl = await _autoDetectWorkingUrl();
      if (newUrl != baseUrl) {
        try {
          return await requestFn(newUrl);
        } catch (_) {}
      }

      throw ApiException(
        0,
        "Connexion impossible au serveur backend.\n"
        "Vérifiez que le serveur Laravel tourne et que votre téléphone et votre PC sont sur le même réseau Wi-Fi (IP: 192.168.1.7).",
      );
    }
  }

  Future<dynamic> get(String path) async {
    return _executeWithFallback((baseUrl) async {
      final res = await http.get(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(path),
      ).timeout(const Duration(seconds: 15));
      _handleStatus(res.statusCode, res.body, path);
      return jsonDecode(res.body);
    });
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    return _executeWithFallback((baseUrl) async {
      final res = await http.post(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(path),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      _handleStatus(res.statusCode, res.body, path);
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    });
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    return _executeWithFallback((baseUrl) async {
      final res = await http.patch(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(path),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      _handleStatus(res.statusCode, res.body, path);
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    });
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    return _executeWithFallback((baseUrl) async {
      final res = await http.put(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(path),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      _handleStatus(res.statusCode, res.body, path);
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    });
  }

  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    required List<int> fileBytes,
    required String fileName,
    String fileField = 'fichier',
  }) async {
    return _executeWithFallback((baseUrl) async {
      final token = await _storage.read(key: 'sanctum_token');
      final uri = Uri.parse('$baseUrl$path');
      final req = http.MultipartRequest('POST', uri)
        ..headers['Accept'] = 'application/json'
        ..headers['X-Client-Type'] = kClientType;
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      if (fields != null) req.fields.addAll(fields);
      req.files.add(http.MultipartFile.fromBytes(
        fileField, fileBytes, filename: fileName));
      final streamed = await req.send().timeout(const Duration(seconds: 45));
      final body = await streamed.stream.bytesToString();
      _handleStatus(streamed.statusCode, body, path);
      if (body.isEmpty) return {};
      return jsonDecode(body);
    });
  }

  Future<dynamic> delete(String path) async {
    return _executeWithFallback((baseUrl) async {
      final res = await http.delete(
        Uri.parse('$baseUrl$path'),
        headers: await _headers(path),
      ).timeout(const Duration(seconds: 15));
      _handleStatus(res.statusCode, res.body, path);
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    });
  }
}

