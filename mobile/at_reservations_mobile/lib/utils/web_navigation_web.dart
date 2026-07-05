// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Force browser navigation to login page then reload (Flutter web only).
/// Fixes BUG 3: token persists in IndexedDB after logout on web.
void navigateToLoginBrowser() {
  html.window.location.href = '/#/login';
  html.window.location.reload();
}
