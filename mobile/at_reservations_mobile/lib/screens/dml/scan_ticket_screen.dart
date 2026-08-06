import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../design/design_system.dart';
import '../../services/api_service.dart';

class ScanTicketScreen extends StatefulWidget {
  const ScanTicketScreen({super.key});
  @override
  State<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends State<ScanTicketScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _scanned = false;
  bool _torch = false;
  bool _saving = false;
  Map<String, String> _ticketData = {};

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    HapticFeedback.heavyImpact();
    setState(() {
      _scanned = true;
      _ticketData = _parseQR(barcode!.rawValue!);
    });
  }

  Map<String, String> _parseQR(String raw) {
    final data = <String, String>{};
    data['raw'] = raw;

    final volMatch = RegExp(r'(AH\s?\d{3,4})').firstMatch(raw);
    if (volMatch != null) data['numero_vol'] = volMatch.group(1)!.replaceAll(' ', '');

    final dateMatch = RegExp(r'(\d{2}[/\-]\d{2}[/\-]\d{2,4})').firstMatch(raw);
    if (dateMatch != null) data['date_vol'] = dateMatch.group(1)!;

    final pnrMatch = RegExp(r'([A-Z]{6})').firstMatch(raw);
    if (pnrMatch != null) data['pnr'] = pnrMatch.group(1)!;

    final nameMatch = RegExp(r'([A-Z]+/[A-Z]+)').firstMatch(raw);
    if (nameMatch != null) data['passager'] = nameMatch.group(1)!;

    return data;
  }

  Future<void> _saveTicket() async {
    setState(() => _saving = true);
    try {
      await ApiService().post('/dml/tickets', _ticketData);
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Billet enregistré avec succès'),
            backgroundColor: DS.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: DS.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    setState(() {
      _scanned = false;
      _ticketData = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scanner Billet'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_torch ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torch = !_torch);
            },
          ),
        ],
      ),
      body: _scanned ? _buildResult() : _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
        ),
        Center(
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              border: Border.all(color: DS.primary, width: 3),
              borderRadius: BorderRadius.circular(24),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.03, 1.03),
                duration: 1200.ms,
              ),
        ),
        Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Placez le QR code du billet dans le cadre',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [DS.secondary, DS.secondary.withValues(alpha: 0.8)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.qr_code_scanner, size: 64, color: Colors.white)
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 16),
              Text(
                'Billet détecté !',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: DS.shadowLg,
                  ),
                  child: ListView(
                    children: [
                      if (_ticketData['numero_vol'] != null)
                        _field('N° Vol', _ticketData['numero_vol']!, Icons.flight),
                      if (_ticketData['date_vol'] != null)
                        _field('Date', _ticketData['date_vol']!, Icons.calendar_today),
                      if (_ticketData['passager'] != null)
                        _field('Passager', _ticketData['passager']!, Icons.person),
                      if (_ticketData['pnr'] != null)
                        _field('PNR', _ticketData['pnr']!, Icons.confirmation_number),
                      if (_ticketData.length <= 1)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'QR non reconnu comme billet Air Algérie.\nDonnées brutes : ${_ticketData['raw'] ?? ''}',
                            style: GoogleFonts.inter(
                              color: DS.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().slideY(begin: 0.2, duration: 400.ms, curve: Curves.easeOut),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-scanner'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveTicket,
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: const Text('Confirmer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DS.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: DS.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: DS.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(
                fontSize: 12, color: DS.textMuted)),
              Text(value, style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: DS.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
