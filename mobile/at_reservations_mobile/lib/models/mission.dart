class MissionDates {
  final String? depart;
  final String? retour;
  MissionDates({this.depart, this.retour});
  factory MissionDates.fromJson(Map<String, dynamic> j) =>
      MissionDates(depart: j['depart'] as String?, retour: j['retour'] as String?);
}

class MissionUser {
  final int id;
  final String nom;
  final String prenom;
  final String? matricule;
  final String? direction;
  final String? service;
  final String? telephone;
  final String? email;
  final String? fonction;
  MissionUser({
    required this.id,
    required this.nom,
    required this.prenom,
    this.matricule,
    this.direction,
    this.service,
    this.telephone,
    this.email,
    this.fonction,
  });
  String get nomComplet => '$prenom $nom';
  factory MissionUser.fromJson(Map<String, dynamic> j) => MissionUser(
    id: j['id'] as int? ?? 0,
    nom: j['nom'] as String? ?? '',
    prenom: j['prenom'] as String? ?? '',
    matricule: j['matricule'] as String?,
    direction: j['direction'] as String?,
    service: j['service'] as String?,
    telephone: j['telephone'] as String?,
    email: j['email'] as String?,
    fonction: j['fonction'] as String?,
  );
}

class MissionModel {
  final int id;
  final String? numeroUnique;
  final String? titre;
  final String? objetMission;
  final String? destination;
  final String? destinationVille;
  final MissionDates? dates;
  final String statut;
  final String? typeMission;
  final MissionUser? user;

  MissionModel({
    required this.id,
    this.numeroUnique,
    this.titre,
    this.objetMission,
    this.destination,
    this.destinationVille,
    this.dates,
    required this.statut,
    this.typeMission,
    this.user,
  });

  String get displayTitre => titre ?? objetMission ?? 'Mission #$id';
  String get displayDest => destination ?? '—';
  String get displayDates {
    if (dates == null) return '—';
    final d = dates!.depart ?? '';
    final r = dates!.retour ?? '';
    if (d.isEmpty && r.isEmpty) return '—';
    if (d.isEmpty) return r;
    if (r.isEmpty) return d;
    return '$d → $r';
  }

  static String? _dest(Map<String, dynamic> j) {
    final d = j['destination'] as String?;
    if (d != null && d.isNotEmpty) return d;
    final ville = j['destination_ville'] as String? ?? '';
    final pays  = j['destination_pays']  as String? ?? '';
    if (ville.isEmpty && pays.isEmpty) return null;
    if (pays.isEmpty)  return ville;
    if (ville.isEmpty) return pays;
    return '$ville, $pays';
  }

  static MissionDates? _dates(Map<String, dynamic> j) {
    if (j['dates'] != null) {
      try {
        return MissionDates.fromJson(j['dates'] as Map<String, dynamic>);
      } catch (_) {}
    }
    // Fallback : champs plats date_depart / date_retour
    final dep = j['date_depart'] as String?;
    final ret = j['date_retour'] as String?;
    if (dep != null || ret != null) {
      return MissionDates(depart: dep, retour: ret);
    }
    return null;
  }

  factory MissionModel.fromJson(Map<String, dynamic> j) => MissionModel(
    id:               j['id'] as int? ?? 0,
    numeroUnique:     j['numero_unique'] as String?,
    titre:            j['titre'] as String?,
    objetMission:     j['objet_mission'] as String?,
    destination:      _dest(j),
    destinationVille: j['destination_ville'] as String?,
    dates:            _dates(j),
    statut:           j['statut'] as String? ?? 'brouillon',
    typeMission:      j['type_mission'] as String?,
    user:             j['user'] != null ? MissionUser.fromJson(j['user'] as Map<String, dynamic>) : null,
  );
}
