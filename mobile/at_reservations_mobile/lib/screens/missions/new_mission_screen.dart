import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import 'mission_wizard/mission_draft.dart';
import 'mission_wizard/step1_informations.dart';
import 'mission_wizard/step2_reservations.dart';
import 'mission_wizard/step3_documents.dart';
import 'mission_wizard/step4_recap.dart';

class NewMissionScreen extends StatefulWidget {
  const NewMissionScreen({super.key});

  @override
  State<NewMissionScreen> createState() => _NewMissionScreenState();
}

class _NewMissionScreenState extends State<NewMissionScreen> {
  final PageController _pageCtrl = PageController();
  final MissionDraft _draft = MissionDraft();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _submitted = false;  // guard anti-double-tap

  static const _stepLabels = ['Infos', 'Réservations', 'Documents', 'Récap'];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentStep < 3) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _onPrev() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  Map<String, dynamic> _buildBody({String? statut}) {
    final body = <String, dynamic>{
      'titre': _draft.objetMission.isNotEmpty ? _draft.objetMission : 'Mission',
      'objet_mission': _draft.objetMission,
      'type_mission': _draft.typeMission,
      'transport_type': _draft.moyenTransport == 'vehicule_service' ? 'terrestre' : _draft.moyenTransport,
      'destination_ville': _draft.wilayaArrivee.isNotEmpty ? _draft.wilayaArrivee : (_draft.villeArrivee.isNotEmpty ? _draft.villeArrivee : 'Non précisé'),
      'destination_pays': 'Algérie',
      'ville_depart': _draft.villeDepart.isNotEmpty ? _draft.villeDepart : (_draft.wilayaDepart.isNotEmpty ? _draft.wilayaDepart : null),
      'date_depart': _fmtDate(_draft.dateDepart),
      'date_retour': _fmtDate(_draft.dateRetour),
      'budget_mode': _draft.budgetMode,
      'demande_avance': _draft.demandeAvance,
      if (_draft.demandeAvance && _draft.montantAvance != null)
        'montant_avance': _draft.montantAvance,
      'description': _draft.description.isNotEmpty ? _draft.description : _draft.commentaire,
      if (_draft.priorite != 'normale') 'priorite': _draft.priorite,
    };
    if (statut != null) body['statut'] = statut;
    return body;
  }

  int? _createdMissionId;

  // ── Flux complet : mission → réservations → documents → submit ──────────
  Future<void> _submitMission({bool asDraft = false}) async {
    if (_isLoading) return;
    if (_submitted && !asDraft) return;
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      int missionId;

      if (_createdMissionId != null) {
        missionId = _createdMissionId!;
      } else {
        final body = _buildBody(statut: 'brouillon');
        final created = await api.post('/missions', body);
        missionId = (created['data']?['id']
            ?? created['id']
            ?? created['data']?['mission']?['id']) as int?
            ?? (throw Exception('ID mission introuvable'));
        _createdMissionId = missionId;

        if (_draft.hebergementRequis) {
          await api.post('/missions/$missionId/reservations', {
            'type': 'hebergement',
            if (_draft.nomHotel?.isNotEmpty == true)
              'notes': _draft.nomHotel,
            'montant_estime': 0,
          });
        }
        if (_draft.restaurationRequise) {
          await api.post('/missions/$missionId/reservations', {
            'type': 'restauration',
            'notes': '${_draft.nombreRepas} repas/jour'
                '${_draft.budgetRestauration != null ? " — budget ${_draft.budgetRestauration} DZD" : ""}',
            'montant_estime': _draft.budgetRestauration ?? 0,
          });
        }
        if (_draft.billetRequis) {
          await api.post('/missions/$missionId/reservations', {
            'type': 'billet',
            'notes': [
              if (_draft.compagnie?.isNotEmpty == true) _draft.compagnie,
              if (_draft.numeroBillet?.isNotEmpty == true) 'N° ${_draft.numeroBillet}',
            ].join(' — '),
            'montant_estime': 0,
          });
        }
      }

      for (final doc in _draft.documents) {
        if (doc['_uploaded'] == true) continue;
        final bytes = doc['bytes'] as List<int>?;
        if (bytes == null || bytes.isEmpty) continue;
        await api.postMultipart(
          '/missions/$missionId/documents',
          fields: {'type_document': (doc['type_document'] as String?) ?? 'formulaire'},
          fileBytes: bytes,
          fileName: doc['name'] as String,
          fileField: 'fichier',
        );
        doc['_uploaded'] = true;
      }

      if (!asDraft) {
        await api.post('/missions/$missionId/submit');
        _submitted = true;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(asDraft
            ? 'Mission enregistrée en brouillon.'
            : 'Mission soumise avec succès !'),
        backgroundColor: ATColors.success,
      ));
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : ${e.message}'),
        backgroundColor: ATColors.error,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur inattendue : $e'),
        backgroundColor: ATColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: ATColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nouvelle mission',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          _WizardStepper(currentStep: _currentStep, labels: _stepLabels),
          Expanded(
            child: PageView(
              controller: _pageCtrl,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Step1Informations(
                  draft: _draft,
                  onNext: _onNext,
                ),
                Step2Reservations(
                  draft: _draft,
                  onNext: _onNext,
                  onPrev: _onPrev,
                ),
                Step3Documents(
                  draft: _draft,
                  onNext: _onNext,
                  onPrev: _onPrev,
                ),
                Step4Recap(
                  draft: _draft,
                  isLoading: _isLoading,
                  onPrev: _onPrev,
                  onSubmit: () => _submitMission(asDraft: false),
                  onSaveDraft: () => _submitMission(asDraft: true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WizardStepper extends StatelessWidget {
  final int currentStep;
  final List<String> labels;

  const _WizardStepper({
    required this.currentStep,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ATColors.secondary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: List.generate(labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIndex = (i - 1) ~/ 2;
            final isDone = stepIndex < currentStep - 1;
            return Expanded(
              child: Container(
                height: 2,
                color: isDone
                    ? ATColors.primary
                    : Colors.white.withValues(alpha: 0.3),
              ),
            );
          }

          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentStep;
          final isActive = stepIndex == currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? ATColors.primary
                      : isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.2),
                  border: isActive
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            color: isActive
                                ? ATColors.secondary
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[stepIndex],
                style: TextStyle(
                  fontSize: 10,
                  color: (isActive || isDone)
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.5),
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.normal,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
