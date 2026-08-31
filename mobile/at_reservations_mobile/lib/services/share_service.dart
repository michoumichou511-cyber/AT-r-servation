import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/constants.dart';
import 'api_service.dart';

class ShareService {
  static final _storage = const FlutterSecureStorage();

  static Future<void> shareMissionPdf(int missionId, {String? titre}) async {
    final token = await _storage.read(key: 'sanctum_token');
    final baseUrl = await ApiService().getBaseUrl();
    final response = await http.get(
      Uri.parse('$baseUrl/missions/$missionId/pdf'),
      headers: {
        'Accept': 'application/pdf',
        'Authorization': 'Bearer $token',
        'X-Client-Type': kClientType,
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Erreur ${response.statusCode}');
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'ordre_mission_$missionId.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: titre ?? 'Ordre de Mission #$missionId',
      text: 'Ordre de mission — AT Réservations',
    );
  }

  static Future<void> shareMissionText({
    required String titre,
    required String destination,
    required String dateDepart,
    required String dateRetour,
    required String statut,
  }) async {
    final text = '''
📋 Mission AT Réservations
━━━━━━━━━━━━━━━━
📌 $titre
📍 Destination : $destination
📅 Du $dateDepart au $dateRetour
📊 Statut : $statut
━━━━━━━━━━━━━━━━
Envoyé depuis AT Réservations
''';

    await Share.share(text, subject: 'Mission — $titre');
  }
}
