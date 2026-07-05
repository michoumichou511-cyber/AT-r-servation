class MissionDraft {
  String objetMission = '';
  String typeMission = 'autre';
  String wilayaDepart = '';
  String villeDepart = '';
  String wilayaArrivee = '';
  String villeArrivee = '';
  DateTime? dateDepart;
  DateTime? dateRetour;
  String moyenTransport = 'vehicule_service';

  // Hébergement
  bool hebergementRequis = false;
  String? nomHotel;
  DateTime? checkIn;
  DateTime? checkOut;

  // Restauration
  bool restaurationRequise = false;
  int nombreRepas = 0;
  double? budgetRestauration;

  // Billet
  bool billetRequis = false;
  String? compagnie;
  String? numeroBillet;

  // Documents
  List<Map<String, dynamic>> documents = []; // {name, size, bytes}
  String? commentaire;
}
