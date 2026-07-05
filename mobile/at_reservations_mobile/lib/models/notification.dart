import 'package:intl/intl.dart';

// Format retourné par le backend Laravel : "dd/MM/yyyy HH:mm:ss"
final _backendFmt = DateFormat('dd/MM/yyyy HH:mm:ss');

DateTime? _parseDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString();
  // ISO 8601 (cas standard)
  final iso = DateTime.tryParse(s);
  if (iso != null) return iso.toLocal();
  // Format backend : "24/05/2026 14:30:00"
  try { return _backendFmt.parseStrict(s).toLocal(); } catch (_) {}
  return null;
}

class NotificationModel {
  final int id;
  final String? titre;
  final String? message;
  final String? type;
  final bool lu;
  final DateTime? createdAt;

  NotificationModel({
    required this.id,
    this.titre,
    this.message,
    this.type,
    required this.lu,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> j) =>
      NotificationModel(
        id:        j['id'] as int,
        titre:     j['titre'] as String?,
        message:   j['message'] as String?,
        type:      j['type'] as String?,
        lu:        (j['lu'] as bool?) ?? (j['is_read'] as bool?) ?? false,
        createdAt: _parseDate(j['created_at']),
      );

  NotificationModel copyWith({bool? lu}) => NotificationModel(
    id: id, titre: titre, message: message, type: type,
    lu: lu ?? this.lu, createdAt: createdAt,
  );
}
