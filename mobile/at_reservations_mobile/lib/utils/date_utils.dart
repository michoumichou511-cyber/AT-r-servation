/// Parsing robuste des dates renvoyées par le backend.
///
/// L'API mélange deux formats selon les endpoints :
///  - ISO 8601 : "2026-07-20T00:00:00.000000Z"
///  - Français : "20/07/2026" ou "02/07/2026 20:03:16"
/// DateTime.parse() jette sur le format français → dates silencieusement
/// nulles (heures de messages absentes, tris cassés). Ce helper accepte
/// les deux.
DateTime? parseBackendDate(dynamic raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  // ISO 8601 (contient 'T' ou commence par yyyy-)
  if (s.contains('T') || RegExp(r'^\d{4}-').hasMatch(s)) {
    try {
      return DateTime.parse(s).toLocal();
    } catch (_) {}
  }

  // dd/MM/yyyy [HH:mm[:ss]]
  final m = RegExp(
    r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?$',
  ).firstMatch(s);
  if (m != null) {
    return DateTime(
      int.parse(m.group(3)!),
      int.parse(m.group(2)!),
      int.parse(m.group(1)!),
      int.parse(m.group(4) ?? '0'),
      int.parse(m.group(5) ?? '0'),
      int.parse(m.group(6) ?? '0'),
    );
  }

  // Dernier recours : parse standard
  try {
    return DateTime.parse(s).toLocal();
  } catch (_) {
    return null;
  }
}
