// Stub for non-web platforms — mirrors the dart:html API used in the app
class Location {
  String href = '';
  void reload() {}
}

class Window {
  final Location location = Location();
}

final Window window = Window();
