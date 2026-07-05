/// URL de base de l'API backend.
///
/// Surchargeable au build : flutter run --dart-define=API_BASE_URL=https://…/api
///  - Émulateur Android : http://10.0.2.2:8000/api (défaut — 10.0.2.2 = localhost du PC)
///  - Appareil physique : IP LAN du PC (ex. http://192.168.1.20:8000/api) ou tunnel ngrok
///  - Web/desktop       : http://localhost:8000/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8000/api',
);
const String kClientType = 'mobile';
