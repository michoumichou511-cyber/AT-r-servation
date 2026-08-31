/// URL de base de l'API backend.
///
/// Surchargeable au build : flutter run --dart-define=API_BASE_URL=https://…/api
///  - Appareil physique (Wi-Fi PC) : http://192.168.1.7:8000/api
///  - Émulateur Android            : http://10.0.2.2:8000/api
///  - Tunnel ADB reverse (USB)    : http://127.0.0.1:8000/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.1.7:8000/api',
);
const String kClientType = 'mobile';

