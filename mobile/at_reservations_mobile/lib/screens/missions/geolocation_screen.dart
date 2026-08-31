import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';

class GeolocationScreen extends StatefulWidget {
  final int missionId;
  final String? destination;
  const GeolocationScreen({
    super.key,
    required this.missionId,
    this.destination,
  });
  @override
  State<GeolocationScreen> createState() => _GeolocationScreenState();
}

class _GeolocationScreenState extends State<GeolocationScreen> {
  bool _loading = false;
  bool _done = false;
  String? _error;
  Position? _position;
  String? _address;
  String _type = 'arrivee';

  Future<void> _pointer() async {
    setState(() { _loading = true; _error = null; });

    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() => _error = 'Activez la localisation dans les paramètres');
        return;
      }

      _position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          _position!.latitude, _position!.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          _address = [p.street, p.locality, p.administrativeArea]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (_) {
        _address = '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
      }

      await ApiService().post('/missions/${widget.missionId}/pointage', {
        'type': _type,
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'adresse': _address,
        'timestamp': DateTime.now().toIso8601String(),
      });

      HapticFeedback.heavyImpact();
      setState(() => _done = true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Pointage GPS')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icone animee
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _done
                      ? const LinearGradient(colors: [DS.success, Color(0xFF059669)])
                      : DS.gradientPrimary,
                  boxShadow: [
                    BoxShadow(
                      color: (_done ? DS.success : DS.primary).withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _done ? Icons.check : Icons.my_location,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate(target: _done ? 1 : 0)
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1),
                      duration: 300.ms, curve: Curves.elasticOut),

              const SizedBox(height: 24),

              Text(
                _done ? 'Pointage enregistré !' : "J'y suis — Pointer mon ${_type == 'arrivee' ? 'arrivée' : 'départ'}",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms),

              if (_address != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place, size: 16, color: DS.primary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _address!,
                        style: GoogleFonts.inter(
                          fontSize: 13, color: context.textMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DS.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: GoogleFonts.inter(
                    color: DS.error, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 32),

              if (!_done) ...[
                // Toggle arrivee/depart
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'arrivee', label: Text('Arrivée'),
                        icon: Icon(Icons.flight_land)),
                    ButtonSegment(value: 'depart', label: Text('Départ'),
                        icon: Icon(Icons.flight_takeoff)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) => setState(() => _type = v.first),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _pointer,
                    icon: _loading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.gps_fixed, size: 22),
                    label: Text(
                      _loading ? 'Localisation...' : 'Pointer maintenant',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DS.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Retour à la mission'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DS.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
