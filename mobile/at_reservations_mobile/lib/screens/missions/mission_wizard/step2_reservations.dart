import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/api_service.dart';
import 'mission_draft.dart';

class Step2Reservations extends StatefulWidget {
  final MissionDraft draft;
  final VoidCallback onNext;
  final VoidCallback onPrev;

  const Step2Reservations({
    super.key,
    required this.draft,
    required this.onNext,
    required this.onPrev,
  });

  @override
  State<Step2Reservations> createState() => _Step2ReservationsState();
}

class _Step2ReservationsState extends State<Step2Reservations> {
  String? _selectedHotelNom;
  late TextEditingController _hotelManuelCtrl;
  late TextEditingController _numeroBilletCtrl;
  late TextEditingController _budgetCtrl;

  // Prestataires + hôtels conventionnés chargés depuis l'API
  List<Map<String, dynamic>> _allPrestataires = [];
  List<Map<String, dynamic>> _hotelsConventions = [];
  bool _prestLoading = true;
  String? _prestError;

  @override
  void initState() {
    super.initState();
    _loadPrestataires();

    final currentHotel = widget.draft.nomHotel ?? '';
    _selectedHotelNom = currentHotel.isNotEmpty ? currentHotel : null;
    _hotelManuelCtrl = TextEditingController(
      text: currentHotel == 'Autre hôtel' ? '' : '',
    );
    _numeroBilletCtrl =
        TextEditingController(text: widget.draft.numeroBillet ?? '');
    _budgetCtrl = TextEditingController(
      text: widget.draft.budgetRestauration?.toString() ?? '',
    );
  }

  Future<void> _loadPrestataires() async {
    setState(() {
      _prestLoading = true;
      _prestError = null;
    });
    try {
      final api = ApiService();
      // Charger prestataires ET hôtels conventionnés en parallèle
      final results = await Future.wait([
        api.get('/prestataires?per_page=200'),
        api.get('/hotels-conventions').catchError((_) => <String, dynamic>{}),
      ]);

      // Prestataires
      final res = results[0] as Map<String, dynamic>;
      final rawData = res['data'] ?? res;
      final List<dynamic> list =
          rawData is List ? rawData : (rawData['data'] ?? []);

      // Hôtels conventionnés
      final resHotels = results[1] as Map<String, dynamic>;
      final rawHotels = resHotels['data'] ?? [];
      final List<dynamic> hotelsList =
          rawHotels is List ? rawHotels : [];

      setState(() {
        _allPrestataires = list.cast<Map<String, dynamic>>();
        _hotelsConventions = hotelsList.cast<Map<String, dynamic>>();
        _prestLoading = false;
        _syncHotelSelection();
      });
    } catch (e) {
      setState(() {
        _prestLoading = false;
        _prestError = e.toString();
      });
    }
  }

  void _syncHotelSelection() {
    final currentHotel = widget.draft.nomHotel ?? '';
    if (currentHotel.isEmpty) {
      _selectedHotelNom = null;
      return;
    }
    final hotels = _hotelsForCurrentWilaya();
    final inList = hotels.any((h) => h['nom'] == currentHotel);
    if (inList) {
      _selectedHotelNom = currentHotel;
    } else if (currentHotel.isNotEmpty) {
      _selectedHotelNom = 'Autre hôtel';
      _hotelManuelCtrl.text = currentHotel;
    }
  }

  @override
  void dispose() {
    _hotelManuelCtrl.dispose();
    _numeroBilletCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  // ── Filtrage des prestataires par type ──────────────────────────────────

  List<Map<String, dynamic>> _hotelsForCurrentWilaya() {
    final wilaya = widget.draft.wilayaArrivee.toLowerCase();
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];

    // 1) Hôtels conventionnés (prioritaires, badge Convention AT)
    for (final h in _hotelsConventions) {
      if (h['statut'] != 'active') continue;
      final hWilaya = (h['wilaya'] ?? '').toString().toLowerCase();
      final hVille = (h['ville'] ?? '').toString().toLowerCase();
      if (wilaya.isNotEmpty &&
          !hWilaya.contains(wilaya) &&
          !hVille.contains(wilaya) &&
          !wilaya.contains(hWilaya) &&
          !wilaya.contains(hVille)) continue;
      final nom = h['nom'] ?? '';
      if (nom.isEmpty || seen.contains(nom)) continue;
      seen.add(nom);
      result.add({
        'nom': nom,
        'etoiles': '4',
        'convention': 'true',
        'id': h['id'],
      });
    }

    // 2) Prestataires de type hôtel
    for (final p in _allPrestataires) {
      if (p['type'] != 'hotel' || p['is_active'] == false) continue;
      final pVille = (p['ville'] ?? '').toString().toLowerCase();
      final pAdresse = (p['adresse'] ?? '').toString().toLowerCase();
      if (wilaya.isNotEmpty &&
          !pVille.contains(wilaya) &&
          !pAdresse.contains(wilaya) &&
          !wilaya.contains(pVille)) continue;
      final nom = p['nom'] ?? '';
      if (nom.isEmpty || seen.contains(nom)) continue;
      seen.add(nom);
      result.add({
        'nom': nom,
        'etoiles': '${(p['note_performance'] as num?)?.toInt() ?? 0}',
        'convention': (p['is_favori'] == true) ? 'true' : 'false',
        'id': p['id'],
      });
    }

    result.add({'nom': 'Autre hôtel', 'etoiles': '0', 'convention': 'false'});
    return result;
  }

  List<Map<String, dynamic>> _compagniesFor(String transport) {
    final type =
        transport == 'train' ? 'agence_voyage' : 'compagnie_aerienne';
    final compagnies = _allPrestataires
        .where((p) => p['type'] == type && p['is_active'] != false)
        .toList();

    // Si train, inclure aussi les prestataires de type agence_voyage
    final List<Map<String, dynamic>> result = [];
    if (transport == 'train') {
      // Ajouter les prestataires ferroviaires
      final ferroviaires = _allPrestataires
          .where((p) =>
              (p['type'] == 'agence_voyage' || p['type'] == 'compagnie_aerienne') &&
              p['is_active'] != false &&
              (p['nom'] ?? '').toString().toLowerCase().contains('sntf'))
          .toList();
      for (final p in ferroviaires) {
        result.add({
          'nom': p['nom'] ?? '',
          'convention': (p['is_favori'] == true) ? 'true' : 'false',
        });
      }
      // Si pas de SNTF trouvé dans les prestataires, ajouter en dur
      if (!result.any((c) =>
          (c['nom'] as String).toLowerCase().contains('sntf'))) {
        result.add({'nom': 'SNTF', 'convention': 'true'});
      }
    } else {
      for (final p in compagnies) {
        result.add({
          'nom': p['nom'] ?? '',
          'convention': (p['is_favori'] == true) ? 'true' : 'false',
        });
      }
      // Compagnies par défaut si rien en base
      if (result.isEmpty) {
        result.addAll([
          {'nom': 'Air Algérie', 'convention': 'true'},
          {'nom': 'Tassili Airlines', 'convention': 'true'},
        ]);
      }
    }
    result.add({'nom': 'Autre', 'convention': 'false'});
    return result;
  }

  // ── Validation + navigation ────────────────────────────────────────────

  Future<void> _handleNext() async {
    if (widget.draft.hebergementRequis) {
      final nom = widget.draft.nomHotel ?? '';
      if (nom.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Veuillez choisir un hôtel.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: ATColors.error,
        ));
        return;
      }
    }
    final transport = widget.draft.moyenTransport;
    if ((transport == 'avion' || transport == 'train') &&
        widget.draft.billetRequis &&
        widget.draft.compagnie == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez sélectionner une compagnie.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: ATColors.error,
      ));
      return;
    }

    final aucuneOption = !widget.draft.hebergementRequis &&
        !widget.draft.restaurationRequise &&
        !widget.draft.billetRequis;
    if (aucuneOption) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.info_outline, color: Colors.orange),
            SizedBox(width: 8),
            Text('Aucune réservation'),
          ]),
          content: const Text(
            'Aucune réservation ajoutée (hébergement, restauration ou billet). '
            'Continuer ?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Retour'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dCtx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ATColors.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    widget.onNext();
  }

  // ── Date picker ────────────────────────────────────────────────────────

  Future<void> _pickDate(BuildContext ctx, bool isCheckIn) async {
    final now = DateTime.now();
    final base = widget.draft.dateDepart ?? now;
    final initial = isCheckIn
        ? (widget.draft.checkIn ?? base)
        : (widget.draft.checkOut ?? base);
    final first = isCheckIn ? base : (widget.draft.checkIn ?? base);
    final last = widget.draft.dateRetour ?? DateTime(now.year + 2);

    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: ATColors.secondary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          widget.draft.checkIn = picked;
          if (widget.draft.checkOut != null &&
              widget.draft.checkOut!.isBefore(picked)) {
            widget.draft.checkOut = null;
          }
        } else {
          widget.draft.checkOut = picked;
        }
      });
    }
  }

  // ── Widgets helpers ────────────────────────────────────────────────────

  Widget _dateField(String label, DateTime? date, bool isCheckIn) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => _pickDate(context, isCheckIn),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: context.inputFill,
        ),
        child: Text(
          date != null ? fmt.format(date) : 'Sélectionner…',
          style: TextStyle(
            color: date != null ? context.textPrimary : context.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
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
            Row(children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ATColors.secondary,
                      letterSpacing: 0.3)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  String _starStr(String etoiles) {
    final n = int.tryParse(etoiles) ?? 0;
    if (n <= 0) return '';
    return '★' * n;
  }

  // ── Widget dropdown hôtels (chargés depuis l'API) ─────────────────────
  Widget _buildHotelSelector() {
    if (_prestLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (_prestError != null) {
      return Column(children: [
        Text('Erreur chargement prestataires',
            style: TextStyle(color: ATColors.error, fontSize: 12)),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: _loadPrestataires,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Réessayer'),
        ),
      ]);
    }

    final hotels = _hotelsForCurrentWilaya();
    final wilaya = widget.draft.wilayaArrivee;

    if (hotels.length == 1 && hotels.first['nom'] == 'Autre hôtel') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (wilaya.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Aucun hôtel enregistré pour $wilaya',
                style: TextStyle(
                    fontSize: 12,
                    color: context.textSecondary,
                    fontStyle: FontStyle.italic),
              ),
            ),
          TextField(
            controller: _hotelManuelCtrl,
            onChanged: (v) =>
                widget.draft.nomHotel = v.trim().isEmpty ? null : v.trim(),
            decoration: InputDecoration(
              labelText: 'Nom de l\'hôtel',
              prefixIcon: const Icon(Icons.business_outlined, size: 18),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: context.inputFill,
            ),
          ),
          const SizedBox(height: 6),
          _noteInfo(
              '💡 L\'agent DML peut modifier ce choix après approbation.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (wilaya.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Hôtels disponibles à $wilaya',
              style: TextStyle(
                  fontSize: 12,
                  color: context.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ),
        DropdownButtonFormField<String>(
          value: (_selectedHotelNom != null &&
                  hotels.any((h) => h['nom'] == _selectedHotelNom))
              ? _selectedHotelNom
              : null,
          decoration: InputDecoration(
            labelText: 'Choisir un hôtel',
            prefixIcon: const Icon(Icons.hotel_outlined, size: 18),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: context.inputFill,
          ),
          hint: const Text('Sélectionner un hôtel…'),
          isExpanded: true,
          items: hotels.map((h) {
            final isConvention = h['convention'] == 'true';
            final stars = _starStr(h['etoiles'] ?? '0');
            final isAutre = h['nom'] == 'Autre hôtel';
            return DropdownMenuItem<String>(
              value: h['nom'] as String,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isAutre
                          ? '✏️ Autre hôtel (saisie manuelle)'
                          : h['nom'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontStyle:
                              isAutre ? FontStyle.italic : FontStyle.normal),
                    ),
                  ),
                  if (stars.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(stars,
                        style: const TextStyle(
                            fontSize: 10, color: ATColors.warning)),
                  ],
                  if (isConvention) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF00A650).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '⭐ Convention AT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF00A650),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (v) {
            setState(() {
              _selectedHotelNom = v;
              if (v != null && v != 'Autre hôtel') {
                widget.draft.nomHotel = v;
                _hotelManuelCtrl.clear();
              } else {
                widget.draft.nomHotel = null;
              }
            });
          },
        ),
        if (_selectedHotelNom == 'Autre hôtel') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _hotelManuelCtrl,
            onChanged: (v) =>
                widget.draft.nomHotel = v.trim().isEmpty ? null : v.trim(),
            decoration: InputDecoration(
              labelText: 'Nom de l\'hôtel (saisie manuelle)',
              prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: context.inputFill,
            ),
          ),
        ],
        const SizedBox(height: 6),
        _noteInfo(
            '💡 L\'agent DML peut modifier ce choix après approbation.'),
      ],
    );
  }

  // ── Badge convention compagnie ─────────────────────────────────────────
  Widget _buildConventionBadgeCompagnie() {
    if (widget.draft.compagnie == null) return const SizedBox.shrink();
    final list = _compagniesFor(widget.draft.moyenTransport);
    final match = list.where((c) => c['nom'] == widget.draft.compagnie);
    if (match.isEmpty) return const SizedBox.shrink();

    final isConvention = match.first['convention'] == 'true';

    if (isConvention) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(children: const [
          Icon(Icons.verified, color: Color(0xFF00A650), size: 16),
          SizedBox(width: 6),
          Text(
            'Convention AT — tarif négocié',
            style: TextStyle(
                color: Color(0xFF00A650),
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
        ]),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.info_outline, color: Colors.orange, size: 16),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hors convention — remboursement sur justificatif',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            _noteWarning(
                '⚠️ Les frais seront remboursés sur présentation de justificatifs originaux.'),
          ],
        ),
      );
    }
  }

  Widget _noteInfo(String text) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ATColors.info.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TextStyle(fontSize: 11, color: context.textSecondary)),
      );

  Widget _noteWarning(String text) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style:
                const TextStyle(fontSize: 11, color: Colors.deepOrange)),
      );

  // ── BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final transport = widget.draft.moyenTransport;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // ── HÉBERGEMENT ──────────────────────────────────────────────────
        _sectionCard(
          title: 'HÉBERGEMENT',
          icon: Icons.hotel_outlined,
          iconColor: ATColors.info,
          children: [
            SwitchListTile(
              value: widget.draft.hebergementRequis,
              onChanged: (v) =>
                  setState(() => widget.draft.hebergementRequis = v),
              title: const Text('Hébergement requis ?'),
              subtitle: const Text('Réservation hôtel nécessaire'),
              activeThumbColor: ATColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: widget.draft.hebergementRequis
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildHotelSelector(),
                  const SizedBox(height: 10),
                  _dateField('Check-in', widget.draft.checkIn, true),
                  const SizedBox(height: 10),
                  _dateField('Check-out', widget.draft.checkOut, false),
                ],
              ),
            ),
          ],
        ),

        // ── RESTAURATION ─────────────────────────────────────────────────
        _sectionCard(
          title: 'RESTAURATION',
          icon: Icons.restaurant_outlined,
          iconColor: ATColors.warning,
          children: [
            SwitchListTile(
              value: widget.draft.restaurationRequise,
              onChanged: (v) => setState(() {
                widget.draft.restaurationRequise = v;
                if (v && widget.draft.nombreRepas == 0) {
                  widget.draft.nombreRepas = 3;
                }
              }),
              title: const Text('Restauration requise ?'),
              subtitle: const Text('Prise en charge des repas'),
              activeThumbColor: ATColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: widget.draft.restaurationRequise
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('Nombre de repas',
                      style: TextStyle(
                          fontSize: 13, color: context.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (widget.draft.nombreRepas > 0) {
                            setState(() => widget.draft.nombreRepas--);
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: ATColors.secondary,
                      ),
                      Container(
                        width: 48,
                        alignment: Alignment.center,
                        child: Text(
                          '${widget.draft.nombreRepas}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (widget.draft.nombreRepas < 10) {
                            setState(() => widget.draft.nombreRepas++);
                          }
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: ATColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text('repas / jour',
                          style:
                              TextStyle(color: context.textSecondary)),
                    ],
                  ),
                  if (widget.draft.dateDepart != null &&
                      widget.draft.dateRetour != null &&
                      widget.draft.nombreRepas > 0) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      const bareme = 1500;
                      final jours = widget.draft.dateRetour!
                              .difference(widget.draft.dateDepart!)
                              .inDays +
                          1;
                      final total = jours * widget.draft.nombreRepas;
                      final budgetEstime = total * bareme;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _noteInfo(
                              '📊 $total repas sur $jours jour${jours > 1 ? "s" : ""} × $bareme DZD/repas = $budgetEstime DZD estimé'),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  widget.draft.budgetRestauration =
                                      budgetEstime.toDouble();
                                  _budgetCtrl.text =
                                      budgetEstime.toString();
                                });
                              },
                              icon: const Icon(Icons.calculate_outlined,
                                  size: 16),
                              label: Text(
                                  'Appliquer le barème ($budgetEstime DZD)'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: ATColors.primary,
                                side: const BorderSide(
                                    color: ATColors.primary),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: _budgetCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    onChanged: (v) => widget.draft.budgetRestauration =
                        double.tryParse(v),
                    decoration: InputDecoration(
                      labelText: 'Budget restauration (DZD)',
                      hintText:
                          'Saisissez ou utilisez le barème ci-dessus',
                      prefixIcon:
                          const Icon(Icons.payments_outlined, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: context.inputFill,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // ── BILLET DE TRANSPORT (avion ou train uniquement) ───────────────
        if (transport == 'avion' || transport == 'train')
          _sectionCard(
            title: 'BILLET DE TRANSPORT',
            icon: Icons.confirmation_number_outlined,
            iconColor: ATColors.primary,
            children: [
              _noteInfo(
                'ℹ️ Le billet est acheté par AT après approbation complète. '
                'Le numéro sera renseigné par l\'agent DML.',
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: widget.draft.billetRequis,
                onChanged: (v) =>
                    setState(() => widget.draft.billetRequis = v),
                title: const Text('Billet requis ?'),
                subtitle: const Text('Réservation billet de transport'),
                activeThumbColor: ATColors.primary,
                contentPadding: EdgeInsets.zero,
              ),
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: widget.draft.billetRequis
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Builder(builder: (_) {
                      final compagnies = _compagniesFor(transport);
                      return DropdownButtonFormField<String>(
                        value: compagnies.any(
                                (c) => c['nom'] == widget.draft.compagnie)
                            ? widget.draft.compagnie
                            : null,
                        decoration: InputDecoration(
                          labelText: transport == 'train'
                              ? 'Compagnie ferroviaire / Opérateur'
                              : 'Compagnie aérienne',
                          prefixIcon: Icon(
                            transport == 'train'
                                ? Icons.train_outlined
                                : Icons.flight_outlined,
                            size: 18,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: context.inputFill,
                        ),
                        hint: Text(transport == 'train'
                            ? 'Sélectionner un opérateur'
                            : 'Sélectionner une compagnie'),
                        isExpanded: true,
                        items: compagnies.map((c) {
                          final isConvention =
                              c['convention'] == 'true';
                          return DropdownMenuItem<String>(
                            value: c['nom'] as String,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(c['nom'] as String,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                if (isConvention) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ATColors.primary
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '✓ Convention AT',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: ATColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) =>
                            setState(() => widget.draft.compagnie = v),
                      );
                    }),
                    _buildConventionBadgeCompagnie(),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _numeroBilletCtrl,
                      onChanged: (v) => widget.draft.numeroBillet =
                          v.trim().isEmpty ? null : v.trim(),
                      decoration: InputDecoration(
                        labelText: 'Numéro de billet (optionnel)',
                        hintText: 'Sera complété après approbation',
                        prefixIcon:
                            const Icon(Icons.tag_outlined, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: context.inputFill,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '* Le numéro sera complété par l\'agent DML après approbation de votre mission.',
                      style: TextStyle(
                          fontSize: 11, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),

        // ── Navigation ────────────────────────────────────────────────────
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
                onPressed: _handleNext,
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
