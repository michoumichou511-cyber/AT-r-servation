import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import 'mission_draft.dart';

const List<Map<String, String>> _kCompagnies = [
  {'nom': 'Air Algérie',      'convention': 'true'},
  {'nom': 'Tassili Airlines', 'convention': 'true'},
  {'nom': 'Transavia',        'convention': 'false'},
  {'nom': 'Air France',       'convention': 'false'},
  {'nom': 'Turkish Airlines', 'convention': 'false'},
  {'nom': 'Autre',            'convention': 'false'},
];

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
  late TextEditingController _hotelCtrl;
  late TextEditingController _compagnieCtrl;
  late TextEditingController _numeroBilletCtrl;
  late TextEditingController _budgetCtrl;

  @override
  void initState() {
    super.initState();
    _hotelCtrl = TextEditingController(text: widget.draft.nomHotel ?? '');
    _compagnieCtrl = TextEditingController(text: widget.draft.compagnie ?? '');
    _numeroBilletCtrl =
        TextEditingController(text: widget.draft.numeroBillet ?? '');
    _budgetCtrl = TextEditingController(
      text: widget.draft.budgetRestauration?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _hotelCtrl.dispose();
    _compagnieCtrl.dispose();
    _numeroBilletCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext ctx, bool isCheckIn) async {
    final now = DateTime.now();
    final base = widget.draft.dateDepart ?? now;
    final initial = isCheckIn
        ? (widget.draft.checkIn ?? base)
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

  Widget _sectionCard(
      {required String title,
      required IconData icon,
      required Color iconColor,
      required List<Widget> children}) {
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        // HEBERGEMENT
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
                  TextField(
                    controller: _hotelCtrl,
                    onChanged: (v) => widget.draft.nomHotel = v,
                    decoration: InputDecoration(
                      labelText: 'Nom de l\'hôtel',
                      prefixIcon:
                          const Icon(Icons.business_outlined, size: 18),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: ATColors.background,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _dateField('Check-in', widget.draft.checkIn, true),
                  const SizedBox(height: 10),
                  _dateField('Check-out', widget.draft.checkOut, false),
                ],
              ),
            ),
          ],
        ),

        // RESTAURATION
        _sectionCard(
          title: 'RESTAURATION',
          icon: Icons.restaurant_outlined,
          iconColor: ATColors.warning,
          children: [
            SwitchListTile(
              value: widget.draft.restaurationRequise,
              onChanged: (v) =>
                  setState(() => widget.draft.restaurationRequise = v),
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
                          if (widget.draft.nombreRepas > 1) {
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
                          style: TextStyle(color: ATColors.textSecondary)),
                    ],
                  ),
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

        // BUG 3 — Section billet : visible UNIQUEMENT si transport = avion ou train
        if (widget.draft.moyenTransport == 'avion' ||
            widget.draft.moyenTransport == 'train')
          _sectionCard(
            title: 'BILLET DE TRANSPORT',
            icon: Icons.confirmation_number_outlined,
            iconColor: ATColors.primary,
            children: [
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

                    // BUG 4 — Dropdown compagnies avec badge Convention AT
                    DropdownButtonFormField<String>(
                      value: _kCompagnies
                              .any((c) => c['nom'] == widget.draft.compagnie)
                          ? widget.draft.compagnie
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Compagnie aérienne',
                        prefixIcon:
                            const Icon(Icons.flight_outlined, size: 18),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: ATColors.background,
                      ),
                      hint: const Text('Sélectionner une compagnie'),
                      items: _kCompagnies.map((c) {
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
                    ),
                    const SizedBox(height: 10),

                    // BUG 6 — Numéro de billet optionnel
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
