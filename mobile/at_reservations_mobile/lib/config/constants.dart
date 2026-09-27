/// URL de base de l'API backend.
///
/// Par défaut : backend en ligne (Render). L'APK fonctionne partout avec Internet.
/// Surchargeable au build pour le développement local :
///   flutter run --dart-define=API_BASE_URL=http://…/api
///  - Appareil physique (Wi-Fi PC) : http://192.168.1.7:8000/api
///  - Émulateur Android            : http://10.0.2.2:8000/api
///  - Tunnel ADB reverse (USB)    : http://127.0.0.1:8000/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://at-r-servation.onrender.com/api',
);
const String kClientType = 'mobile';

