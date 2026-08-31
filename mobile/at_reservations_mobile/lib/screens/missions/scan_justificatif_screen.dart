import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../utils/image_compressor.dart';

class ScanJustificatifScreen extends StatefulWidget {
  final int missionId;
  const ScanJustificatifScreen({super.key, required this.missionId});
  @override
  State<ScanJustificatifScreen> createState() => _ScanJustificatifScreenState();
}

class _ScanJustificatifScreenState extends State<ScanJustificatifScreen> {
  File? _selectedFile;
  String? _fileName;
  int? _originalSize;
  int? _compressedSize;
  bool _uploading = false;

  final _montantCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _prestataireCtrl = TextEditingController();

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    _fileName = result.files.single.name;
    _originalSize = await file.length();

    final compressed = await ImageCompressor.compress(file);
    _compressedSize = await compressed.length();

    setState(() => _selectedFile = compressed);
    HapticFeedback.lightImpact();
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() => _uploading = true);

    try {
      final bytes = await _selectedFile!.readAsBytes();
      await ApiService().postMultipart(
        '/missions/${widget.missionId}/documents',
        fileBytes: bytes,
        fileName: _fileName ?? 'justificatif.jpg',
        fields: {
          if (_montantCtrl.text.isNotEmpty) 'montant': _montantCtrl.text,
          if (_dateCtrl.text.isNotEmpty) 'date_justificatif': _dateCtrl.text,
          if (_prestataireCtrl.text.isNotEmpty) 'prestataire': _prestataireCtrl.text,
        },
      );

      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Justificatif envoyé avec succès'),
            backgroundColor: DS.success,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: DS.error),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _dateCtrl.dispose();
    _prestataireCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un justificatif')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Zone de selection
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DS.primary.withValues(alpha: 0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: _selectedFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(_selectedFile!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DS.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${_formatSize(_originalSize!)} → ${_formatSize(_compressedSize!)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              size: 48, color: DS.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'Prendre une photo ou choisir un fichier',
                            style: GoogleFonts.inter(
                              color: context.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPG, PNG ou PDF — max 10 MB',
                            style: GoogleFonts.inter(
                              color: DS.textPlaceholder,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            const SizedBox(height: 24),

            Text('Informations (optionnel)',
                style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                )),
            const SizedBox(height: 12),

            _buildField(_montantCtrl, 'Montant (DA)', Icons.payments,
                keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _buildField(_dateCtrl, 'Date (JJ/MM/AAAA)', Icons.calendar_today),
            const SizedBox(height: 12),
            _buildField(_prestataireCtrl, 'Prestataire', Icons.business),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _selectedFile == null || _uploading ? null : _upload,
                icon: _uploading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  _uploading ? 'Envoi en cours...' : 'Envoyer le justificatif',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DS.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                ),
              ),
            ).animate().slideY(begin: 0.2, delay: 200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
