import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  Function? onUnauthorized;

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'sanctum_token');
    return {
      'Content-Type':  'application/json',
      'Accept':        'application/json',
      'X-Client-Type': kClientType,
      // Bypass la page de warning ngrok (necessaire pour partage public via ngrok)
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  void _handleStatus(int code, String body) {
    if (code == 401) {
      onUnauthorized?.call();
      throw ApiException(401, 'Session expirée. Veuillez vous reconnecter.');
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

  Future<dynamic> get(String path) async {
    final res = await http.get(
      Uri.parse('$kApiBaseUrl$path'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));
    _handleStatus(res.statusCode, res.body);
    return jsonDecode(res.body);
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('$kApiBaseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
    _handleStatus(res.statusCode, res.body);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final res = await http.patch(
      Uri.parse('$kApiBaseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
    _handleStatus(res.statusCode, res.body);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  Future<dynamic> put(String path, [Map<String, dynamic>? body]) async {
    final res = await http.put(
      Uri.parse('$kApiBaseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    ).timeout(const Duration(seconds: 30));
    _handleStatus(res.statusCode, res.body);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }

  /// Upload d'un fichier unique en multipart/form-data.
  /// [fields] : champs texte supplémentaires.
  /// [fileBytes] / [fileName] / [fileField] : le fichier à envoyer.
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? fields,
    required List<int> fileBytes,
    required String fileName,
    String fileField = 'fichier',
  }) async {
    final token = await _storage.read(key: 'sanctum_token');
    final uri = Uri.parse('$kApiBaseUrl$path');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['X-Client-Type'] = kClientType;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    if (fields != null) req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(
      fileField, fileBytes, filename: fileName));
    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final body = await streamed.stream.bytesToString();
    _handleStatus(streamed.statusCode, body);
    if (body.isEmpty) return {};
    return jsonDecode(body);
  }

  Future<dynamic> delete(String path) async {
    final res = await http.delete(
      Uri.parse('$kApiBaseUrl$path'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 30));
    _handleStatus(res.statusCode, res.body);
    if (res.body.isEmpty) return {};
    return jsonDecode(res.body);
  }
}
