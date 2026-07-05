import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import 'mission_draft.dart';

// ─── Compagnies aériennes ─────────────────────────────────────────────────
const List<Map<String, String>> _kCompagniesAvion = [
  {'nom': 'Air Algérie',      'convention': 'true'},
  {'nom': 'Tassili Airlines', 'convention': 'true'},
  {'nom': 'Transavia',        'convention': 'false'},
  {'nom': 'Air France',       'convention': 'false'},
  {'nom': 'Turkish Airlines', 'convention': 'false'},
  {'nom': 'Autre',            'convention': 'false'},
];

// ─── Opérateurs ferroviaires ──────────────────────────────────────────────
const List<Map<String, String>> _kCompagniesTrain = [
  {'nom': 'SNTF',  'convention': 'true'},
  {'nom': 'Autre', 'convention': 'false'},
];

// Helper : retourne la liste appropriée selon le moyen de transport
List<Map<String, String>> _compagniesFor(String transport) {
  return transport == 'train' ? _kCompagniesTrain : _kCompagniesAvion;
}

// ─── Hôtels par wilaya ─────────────────────────────────────────────────────
const Map<String, List<Map<String, String>>> _kHotelsByWilaya = {
  'Alger': [
    {'nom': 'Hôtel El Aurassi',    'etoiles': '5', 'convention': 'true'},
    {'nom': 'Hôtel Sofitel Alger', 'etoiles': '5', 'convention': 'false'},
    {'nom': 'Hôtel El Djazair',    'etoiles': '5', 'convention': 'true'},
    {'nom': 'Hôtel Mercure Alger', 'etoiles': '4', 'convention': 'false'},
    {'nom': 'Autre hôtel',         'etoiles': '0', 'convention': 'false'},
  ],
  'Oran': [
    {'nom': 'Hôtel Les Zianides',    'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Royal Oran',      'etoiles': '4', 'convention': 'false'},
    {'nom': 'Hôtel Le Méridien Oran','etoiles': '5', 'convention': 'false'},
    {'nom': 'Autre hôtel',           'etoiles': '0', 'convention': 'false'},
  ],
  'Constantine': [
    {'nom': 'Hôtel Marriott Constantine', 'etoiles': '5', 'convention': 'true'},
    {'nom': 'Hôtel Novotel Constantine',  'etoiles': '4', 'convention': 'false'},
    {'nom': 'Autre hôtel',                'etoiles': '0', 'convention': 'false'},
  ],
  'Annaba': [
    {'nom': 'Hôtel Seybouse International', 'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Juba Annaba',            'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',                  'etoiles': '0', 'convention': 'false'},
  ],
  'Blida': [
    {'nom': 'Hôtel Chréa Blida',    'etoiles': '3', 'convention': 'true'},
    {'nom': 'Hôtel Mitidja Blida',  'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',          'etoiles': '0', 'convention': 'false'},
  ],
  'Tizi Ouzou': [
    {'nom': 'Hôtel Lalla Khedidja', 'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Belloua',        'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',          'etoiles': '0', 'convention': 'false'},
  ],
  'Béjaïa': [
    {'nom': 'Hôtel Gouraya Béjaïa', 'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Yemma Gouraya',  'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',          'etoiles': '0', 'convention': 'false'},
  ],
  'Sétif': [
    {'nom': 'Hôtel El Hana Sétif',  'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Djurdjura Sétif','etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',          'etoiles': '0', 'convention': 'false'},
  ],
  'Batna': [
    {'nom': 'Hôtel Chelia Batna',   'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Timgad Batna',   'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',          'etoiles': '0', 'convention': 'false'},
  ],
  'Ouargla': [
    {'nom': 'Hôtel Transatlantique Ouargla', 'etoiles': '4', 'convention': 'true'},
    {'nom': 'Hôtel Ouargla Palace',          'etoiles': '3', 'convention': 'false'},
    {'nom': 'Autre hôtel',                   'etoiles': '0', 'convention': 'false'},
  ],
};

// Helper : génère la chaîne d'étoiles ★
String _starStr(String etoiles) {
  final n = int.tryParse(etoiles) ?? 0;
  if (n <= 0) return '';
  return '★' * n;
}

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
  // Hôtel : soit choix dans la liste, soit texte libre si "Autre hôtel"
  String? _selectedHotelNom;
  late TextEditingController _hotelManuelCtrl;

  late TextEditingController _numeroBilletCtrl;
  late TextEditingController _budgetCtrl;

  @override
  void initState() {
    super.initState();

    // Initialise depuis le draft
    final currentHotel = widget.draft.nomHotel ?? '';
    final hotels = _hotelsForCurrentWilaya();
    final inList = hotels.any((h) => h['nom'] == currentHotel);
    if (inList) {
      _selectedHotelNom = currentHotel;
      _hotelManuelCtrl  = TextEditingController();
    } else {
      _selectedHotelNom = currentHotel.isNotEmpty ? 'Autre hôtel' : null;
      _hotelManuelCtrl  = TextEditingController(text: currentHotel);
    }

    _numeroBilletCtrl =
        TextEditingController(text: widget.draft.numeroBillet ?? '');
    _budgetCtrl = TextEditingController(
      text: widget.draft.budgetRestauration?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _hotelManuelCtrl.dispose();
    _numeroBilletCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  // Retourne la liste d'hôtels pour la wilaya d'arrivée du draft
  List<Map<String, String>> _hotelsForCurrentWilaya() {
    final wilaya = widget.draft.wilayaArrivee;
    return _kHotelsByWilaya[wilaya] ?? [];
  }

  // Validation enrichie + confirmation si aucune option cochée
  Future<void> _handleNext() async {
    // Validation hébergement
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
    // Validation billet
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

    // Avertissement si aucune réservation cochée
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

  Future<void> _pickDate(BuildContext ctx, bool isCheckIn) async {
    final now  = DateTime.now();
    final base = widget.draft.dateDepart ?? now;
    final initial = isCheckIn
        ? (widget.draft.checkIn  ?? base)
        : (widget.draft.checkOut ?? base);
    final first = isCheckIn ? base : (widget.draft.checkIn ?? base);

    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
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
          // Reset checkOut si elle est avant le nouveau checkIn
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

  Widget _dateField(String label, DateTime? date, bool isCheckIn) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => _pickDate(context, isCheckIn),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              const Icon(Icons.calendar_today_outlined, size: 18),
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: ATColors.background,
        ),
        child: Text(
          date != null ? fmt.format(date) : 'Sélectionner…',
          style: TextStyle(
            color: date != null
                ? ATColors.textPrimary
                : ATColors.textSecondary,
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

  // ── Widget dropdown hôtels par wilaya ───────────────────────────────────
  Widget _buildHotelSelector() {
    final hotels = _hotelsForCurrentWilaya();
    final wilaya = widget.draft.wilayaArrivee;

    // Pas de liste pour cette wilaya → texte libre
    if (hotels.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _hotelManuelCtrl,
            onChanged: (v) => widget.draft.nomHotel = v.trim().isEmpty ? null : v.trim(),
            decoration: InputDecoration(
              labelText: 'Nom de l\'hôtel',
              prefixIcon: const Icon(Icons.business_outlined, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: ATColors.background,
            ),
          ),
          const SizedBox(height: 6),
          _noteInfo('💡 L\'agent DML peut modifier ce choix après approbation.'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre wilaya
        if (wilaya.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Hôtels disponibles à $wilaya',
              style: const TextStyle(
                  fontSize: 12,
                  color: ATColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ),
        // Dropdown hôtels
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
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
            fillColor: ATColors.background,
          ),
          hint: const Text('Sélectionner un hôtel…'),
          isExpanded: true,
          items: hotels.map((h) {
            final isConvention = h['convention'] == 'true';
            final stars        = _starStr(h['etoiles'] ?? '0');
            final isAutre      = h['nom'] == 'Autre hôtel';
            return DropdownMenuItem<String>(
              value: h['nom'],
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isAutre ? '✏️ Autre hôtel (saisie manuelle)' : h['nom']!,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontStyle: isAutre
                              ? FontStyle.italic
                              : FontStyle.normal),
                    ),
                  ),
                  if (stars.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(stars,
                        style: const TextStyle(
                            fontSize: 10,
                            color: ATColors.warning)),
                  ],
                  if (isConvention) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A650).withValues(alpha: 0.12),
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

        // Si "Autre hôtel" → saisie manuelle
        if (_selectedHotelNom == 'Autre hôtel') ...[
          const SizedBox(height: 10),
          TextField(
            controller: _hotelManuelCtrl,
            onChanged: (v) =>
                widget.draft.nomHotel = v.trim().isEmpty ? null : v.trim(),
            decoration: InputDecoration(
              labelText: 'Nom de l\'hôtel (saisie manuelle)',
              prefixIcon: const Icon(Icons.edit_outlined, size: 18),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: ATColors.background,
            ),
          ),
        ],
        const SizedBox(height: 6),
        _noteInfo('💡 L\'agent DML peut modifier ce choix après approbation.'),
      ],
    );
  }

  // ── Badge convention compagnie (sous le dropdown) ───────────────────────
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
            style: TextStyle(color: Color(0xFF00A650), fontSize: 12, fontWeight: FontWeight.w600),
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

  // ── Helpers notes ───────────────────────────────────────────────────────
  Widget _noteInfo(String text) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ATColors.info.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11, color: ATColors.textSecondary)),
      );

  Widget _noteWarning(String text) => Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
      );

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
                  // Correction 1 : dropdown hôtels par wilaya
                  _buildHotelSelector(),
                  const SizedBox(height: 10),
                  _dateField('Check-in',  widget.draft.checkIn,  true),
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
                // Auto-suggestion : 3 repas/jour à l'activation si compteur à 0
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
                  const Text('Nombre de repas',
                      style: TextStyle(
                          fontSize: 13, color: ATColors.textSecondary)),
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
                      const Text('repas / jour',
                          style:
                              TextStyle(color: ATColors.textSecondary)),
                    ],
                  ),
                  // Calcul automatique si dates connues
                  if (widget.draft.dateDepart != null &&
                      widget.draft.dateRetour != null) ...[
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final jours = widget.draft.dateRetour!
                              .difference(widget.draft.dateDepart!)
                              .inDays +
                          1;
                      final total = jours * widget.draft.nombreRepas;
                      return _noteInfo(
                          '📊 Estimation : $total repas sur $jours jour${jours > 1 ? "s" : ""} (${widget.draft.nombreRepas} repas/jour) — modifiable manuellement');
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
                      prefixIcon:
                          const Icon(Icons.payments_outlined, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: ATColors.background,
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
              // Note informative en haut de la section
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

                    // Dropdown compagnies / opérateurs (selon transport)
                    Builder(builder: (_) {
                      final compagnies = _compagniesFor(transport);
                      return DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: compagnies
                              .any((c) => c['nom'] == widget.draft.compagnie)
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
                        fillColor: ATColors.background,
                      ),
                      hint: Text(transport == 'train'
                          ? 'Sélectionner un opérateur'
                          : 'Sélectionner une compagnie'),
                      isExpanded: true,
                      items: compagnies.map((c) {
                        final isConvention = c['convention'] == 'true';
                        return DropdownMenuItem<String>(
                          value: c['nom'],
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(c['nom']!,
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
                                    borderRadius: BorderRadius.circular(8),
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

                    // Correction 2 : badge convention/hors-convention sous le dropdown
                    _buildConventionBadgeCompagnie(),

                    const SizedBox(height: 10),

                    // Numéro de billet optionnel
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
                        fillColor: ATColors.background,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '* Le numéro sera complété par l\'agent DML après approbation de votre mission.',
                      style: TextStyle(
                          fontSize: 11, color: ATColors.textSecondary),
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
