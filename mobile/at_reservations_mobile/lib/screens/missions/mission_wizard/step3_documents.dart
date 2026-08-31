import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/theme.dart';
import 'mission_draft.dart';

class Step3Documents extends StatefulWidget {
  final MissionDraft draft;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step3Documents({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step3Documents> createState() => _Step3DocumentsState();
}

class _Step3DocumentsState extends State<Step3Documents> {
  late TextEditingController _commentCtrl;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _commentCtrl =
        TextEditingController(text: widget.draft.commentaire ?? '');
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'jpg', 'jpeg', 'png',
          'doc', 'docx', 'xls', 'xlsx',
        ],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        const maxSize = 5 * 1024 * 1024; // 5 Mo
        final rejected = <PlatformFile>[];
        setState(() {
          for (final f in result.files) {
            if (f.size > maxSize) {
              rejected.add(f);
              continue;
            }
            final alreadyAdded = widget.draft.documents
                .any((d) => d['name'] == f.name && d['size'] == f.size);
            if (!alreadyAdded) {
              widget.draft.documents.add({
                'name': f.name,
                'size': f.size,
                'bytes': f.bytes,
                'extension': f.extension ?? '',
                'type_document': 'formulaire',
              });
            }
          }
        });
        if (rejected.isNotEmpty && mounted) {
          final names = rejected.map((f) =>
            '• ${f.name} (${(f.size / (1024 * 1024)).toStringAsFixed(1)} Mo)').join('\n');
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: const [
                Icon(Icons.warning_amber_rounded, color: ATColors.error, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text('Fichier trop volumineux', style: TextStyle(fontSize: 16))),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('La taille maximale autorisée est de 5 Mo.\n'
                      'Veuillez remplacer le(s) fichier(s) suivant(s) :',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(names, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600, color: ATColors.error)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ATColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Compris'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeDocument(int index) {
    setState(() => widget.draft.documents.removeAt(index));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} Ko';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  IconData _iconForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _colorForExt(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return ATColors.error;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return ATColors.info;
      case 'doc':
      case 'docx':
        return ATColors.secondary;
      case 'xls':
      case 'xlsx':
        return ATColors.success;
      default:
        return context.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Upload section
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.attach_file_outlined,
                      color: ATColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'PIÈCES JOINTES',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ATColors.secondary,
                        letterSpacing: 0.3),
                  ),
                ]),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _picking ? null : _pickFiles,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: ATColors.secondary.withValues(alpha: 0.4),
                          width: 1.5,
                          style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(10),
                      color: ATColors.secondary.withValues(alpha: 0.03),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _picking
                              ? Icons.hourglass_top_outlined
                              : Icons.cloud_upload_outlined,
                          size: 36,
                          color: ATColors.secondary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _picking
                              ? 'Chargement…'
                              : 'Appuyez pour ajouter des documents',
                          style: TextStyle(
                              color: ATColors.secondary.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF, JPG, PNG, DOC, DOCX',
                          style: TextStyle(
                              fontSize: 12,
                              color: context.textSecondary.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // File list
        if (widget.draft.documents.isNotEmpty) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DOCUMENTS AJOUTÉS',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ATColors.secondary,
                            letterSpacing: 0.3),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: ATColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.draft.documents.length}',
                          style: const TextStyle(
                              color: ATColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(widget.draft.documents.length, (i) {
                    final doc = widget.draft.documents[i];
                    final ext = (doc['extension'] as String? ?? '');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.inputFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.grey.withValues(alpha: 0.2)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_iconForExt(ext),
                                  color: _colorForExt(ext), size: 28),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(doc['name'] as String,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 2),
                                  Text(_formatSize(doc['size'] as int),
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: context.textSecondary)),
                                  const SizedBox(height: 6),
                                  // Sélecteur de type
                                  DropdownButtonFormField<String>(
                                    initialValue: (doc['type_document'] as String?) ?? 'formulaire',
                                    isDense: true,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                              color: ATColors.secondary.withValues(alpha: 0.3))),
                                      filled: true,
                                      fillColor: ATColors.secondary.withValues(alpha: 0.04),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'formulaire',
                                          child: Text('Formulaire', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'ordre_mission',
                                          child: Text('Ordre de mission', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'autorisation',
                                          child: Text('Autorisation', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'justificatif',
                                          child: Text('Justificatif', style: TextStyle(fontSize: 12))),
                                      DropdownMenuItem(value: 'autre',
                                          child: Text('Autre', style: TextStyle(fontSize: 12))),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() =>
                                          widget.draft.documents[i]['type_document'] = v);
                                      }
                                    },
                                  ),
                                ],
                              )),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: ATColors.error, size: 20),
                                onPressed: () => _removeDocument(i),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],

        // Commentaire
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: context.shadowColor,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.comment_outlined,
                      color: ATColors.secondary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'NOTE / COMMENTAIRE',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: ATColors.secondary,
                        letterSpacing: 0.3),
                  ),
                ]),
                const SizedBox(height: 12),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 4,
                  onChanged: (v) => widget.draft.commentaire = v.trim(),
                  decoration: InputDecoration(
                    hintText: 'Informations complémentaires…',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: context.inputFill,
                  ),
                ),
              ],
            ),
          ),
        ),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onPrev,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ATColors.secondary,
                  side: const BorderSide(color: ATColors.secondary),
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.onNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Suivant',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ATColors.secondary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
