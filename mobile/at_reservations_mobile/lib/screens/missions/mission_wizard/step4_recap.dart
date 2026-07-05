import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import 'mission_draft.dart';

class Step4Recap extends StatelessWidget {
  final MissionDraft draft;
  final VoidCallback onSubmit;
  final VoidCallback onSaveDraft;
  final VoidCallback onPrev;
  final bool isLoading;

  const Step4Recap({
    super.key,
    required this.draft,
    required this.onSubmit,
    required this.onSaveDraft,
    required this.onPrev,
    required this.isLoading,
  });

  static final _fmt = DateFormat('dd/MM/yyyy');

  String _formatDate(DateTime? d) => d != null ? _fmt.format(d) : '—';

  String _labelTransport(String v) {
    switch (v) {
      case 'vehicule_service':
        return 'Véhicule de service';
      case 'train':
        return 'Train';
      case 'avion':
        return 'Avion';
      default:
        return 'Autre';
    }
  }

  String _labelType(String v) {
    switch (v) {
      case 'deplacement':
        return 'Déplacement';
      case 'formation':
        return 'Formation';
      case 'inspection':
        return 'Inspection';
      case 'audit':
        return 'Audit';
      case 'reunion':
        return 'Réunion';
      default:
        return v;
    }
  }

  Widget _card({required String title, required IconData icon, required List<Widget> rows}) {
    return Container(
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
            Row(children: [
              Icon(icon, color: ATColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ATColors.secondary,
                      letterSpacing: 0.3)),
            ]),
            const Divider(height: 20),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: ATColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? ATColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ATColors.secondary, Color(0xFF0052CC)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Icon(Icons.summarize_outlined,
                color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Récapitulatif de la mission',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text('Vérifiez les informations avant de soumettre',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
            ]),
          ]),
        ),

        // INFORMATIONS
        _card(
          title: 'INFORMATIONS',
          icon: Icons.info_outline,
          rows: [
            _row('Objet', draft.objetMission),
            const SizedBox(height: 2),
            Row(
              children: [
                const SizedBox(
                  width: 130,
                  child: Text('Type',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary)),
                ),
                _badge(_labelType(draft.typeMission), ATColors.secondary),
              ],
            ),
            const SizedBox(height: 8),
            _row('Départ',
                '${draft.wilayaDepart} — ${draft.villeDepart}'.trim()),
            _row('Arrivée',
                '${draft.wilayaArrivee} — ${draft.villeArrivee}'.trim()),
            _row('Date départ', _formatDate(draft.dateDepart)),
            _row('Date retour', _formatDate(draft.dateRetour)),
            Row(children: [
              const SizedBox(
                width: 130,
                child: Text('Transport',
                    style: TextStyle(
                        fontSize: 13, color: ATColors.textSecondary)),
              ),
              _badge(_labelTransport(draft.moyenTransport), ATColors.primary),
            ]),
          ],
        ),

        // RÉSERVATIONS
        _card(
          title: 'RÉSERVATIONS',
          icon: Icons.bookmark_outline,
          rows: [
            Row(children: [
              const SizedBox(
                  width: 130,
                  child: Text('Hébergement',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary))),
              _badge(
                draft.hebergementRequis ? 'Oui' : 'Non',
                draft.hebergementRequis ? ATColors.success : ATColors.textSecondary,
              ),
            ]),
            if (draft.hebergementRequis) ...[
              const SizedBox(height: 6),
              _row('Hôtel', draft.nomHotel ?? '—'),
              _row('Check-in', _formatDate(draft.checkIn)),
              _row('Check-out', _formatDate(draft.checkOut)),
            ],
            const SizedBox(height: 6),
            Row(children: [
              const SizedBox(
                  width: 130,
                  child: Text('Restauration',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary))),
              _badge(
                draft.restaurationRequise ? 'Oui' : 'Non',
                draft.restaurationRequise ? ATColors.success : ATColors.textSecondary,
              ),
            ]),
            if (draft.restaurationRequise) ...[
              const SizedBox(height: 6),
              _row('Repas / jour', '${draft.nombreRepas}'),
            ],
            const SizedBox(height: 6),
            Row(children: [
              const SizedBox(
                  width: 130,
                  child: Text('Billet',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary))),
              _badge(
                draft.billetRequis ? 'Oui' : 'Non',
                draft.billetRequis ? ATColors.success : ATColors.textSecondary,
              ),
            ]),
            if (draft.billetRequis) ...[
              const SizedBox(height: 6),
              _row('Compagnie', draft.compagnie ?? '—'),
              _row('N° billet', draft.numeroBillet ?? '—'),
            ],
          ],
        ),

        // DOCUMENTS
        _card(
          title: 'DOCUMENTS',
          icon: Icons.attach_file_outlined,
          rows: [
            Row(children: [
              const SizedBox(
                  width: 130,
                  child: Text('Pièces jointes',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary))),
              _badge(
                '${draft.documents.length} fichier(s)',
                draft.documents.isEmpty
                    ? ATColors.textSecondary
                    : ATColors.primary,
              ),
            ]),
            if (draft.commentaire != null &&
                draft.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _row('Note', draft.commentaire!),
            ],
          ],
        ),

        // Buttons
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: ATColors.primary),
            ),
          )
        else ...[
          OutlinedButton.icon(
            onPressed: onPrev,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Précédent'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ATColors.secondary,
              side: const BorderSide(color: ATColors.secondary),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onSaveDraft,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Enregistrer en brouillon',
                style: TextStyle(fontWeight: FontWeight.w500)),
            style: OutlinedButton.styleFrom(
              foregroundColor: ATColors.textSecondary,
              side: const BorderSide(color: Colors.grey),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: onSubmit,
            icon: const Icon(Icons.send_outlined),
            label: const Text('Soumettre la mission',
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: ATColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 2,
            ),
          ),
        ],
      ],
    );
  }
}
