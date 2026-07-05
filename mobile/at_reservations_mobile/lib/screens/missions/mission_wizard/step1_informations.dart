import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import 'mission_draft.dart';

// ─── 58 wilayas officielles d'Algérie (ordre numérique) ───────────────────
const List<String> _kWilayas = [
  'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna',
  'Béjaïa', 'Biskra', 'Béchar', 'Blida', 'Bouira',
  'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret', 'Tizi Ouzou',
  'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda',
  'Skikda', 'Sidi Bel Abbès', 'Annaba', 'Guelma', 'Constantine',
  'Médéa', 'Mostaganem', "M'Sila", 'Mascara', 'Ouargla',
  'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arréridj', 'Boumerdès',
  'El Tarf', 'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela',
  'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 'Naâma',
  'Aïn Témouchent', 'Ghardaïa', 'Relizane', 'Timimoun',
  'Bordj Badji Mokhtar', 'Ouled Djellal', 'Béni Abbès',
  'In Salah', 'In Guezzam', 'Touggourt', 'Djanet',
  "El M'Ghair", 'El Meniaa',
];

// ─── Types de mission ─────────────────────────────────────────────────────
const List<Map<String, String>> _kTypesMission = [
  {'value': 'formation',  'label': 'Formation'},
  {'value': 'conference', 'label': 'Conférence'},
  {'value': 'reunion',    'label': 'Réunion'},
  {'value': 'inspection', 'label': 'Inspection'},
  {'value': 'audit',      'label': 'Audit'},
  {'value': 'autre',      'label': 'Autre'},
];

const Map<String, IconData> _kTypeIcons = {
  'formation':  Icons.school_outlined,
  'conference': Icons.mic_outlined,
  'reunion':    Icons.groups_outlined,
  'inspection': Icons.search_outlined,
  'audit':      Icons.fact_check_outlined,
  'autre':      Icons.directions_car_outlined,
};

class Step1Informations extends StatefulWidget {
  final MissionDraft draft;
  final VoidCallback onNext;

  const Step1Informations({
    super.key,
    required this.draft,
    required this.onNext,
  });

  @override
  State<Step1Informations> createState() => _Step1InformationsState();
}

class _Step1InformationsState extends State<Step1Informations> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _objetCtrl;
  late TextEditingController _villeDepartCtrl;
  late TextEditingController _villeArriveeCtrl;

  @override
  void initState() {
    super.initState();
    _objetCtrl = TextEditingController(text: widget.draft.objetMission);
    _villeDepartCtrl = TextEditingController(text: widget.draft.villeDepart);
    _villeArriveeCtrl = TextEditingController(text: widget.draft.villeArrivee);
  }

  @override
  void dispose() {
    _objetCtrl.dispose();
    _villeDepartCtrl.dispose();
    _villeArriveeCtrl.dispose();
    super.dispose();
  }

  // ── Calcul durée mission ────────────────────────────────────────────────
  int? get _dureeJours {
    final d = widget.draft.dateDepart;
    final r = widget.draft.dateRetour;
    if (d == null || r == null) return null;
    return r.difference(d).inDays + 1;
  }

  Future<void> _pickDate(BuildContext ctx, bool isDepart) async {
    final now = DateTime.now();
    final initial = isDepart
        ? (widget.draft.dateDepart ?? now)
        : (widget.draft.dateRetour ?? now);
    final tomorrow = now.add(const Duration(days: 1));
    final first = isDepart
        ? tomorrow
        : (widget.draft.dateDepart?.add(const Duration(days: 1)) ?? tomorrow);

    final picked = await showDatePicker(
      context: ctx,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: ATColors.secondary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isDepart) {
          widget.draft.dateDepart = picked;
          if (widget.draft.dateRetour != null &&
              widget.draft.dateRetour!.isBefore(picked)) {
            widget.draft.dateRetour = null;
          }
        } else {
          widget.draft.dateRetour = picked;
        }
      });
    }
  }

  void _submit() {
    widget.draft.objetMission = _objetCtrl.text.trim();
    widget.draft.villeDepart = _villeDepartCtrl.text.trim();
    widget.draft.villeArrivee = _villeArriveeCtrl.text.trim();

    if (_formKey.currentState!.validate()) {
      widget.onNext();
    }
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: ATColors.secondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _dateRow(String label, DateTime? date, bool isDepart) {
    final fmt = DateFormat('dd/MM/yyyy');
    return InkWell(
      onTap: () => _pickDate(context, isDepart),
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          filled: true,
          fillColor: ATColors.background,
        ),
        child: Text(
          date != null ? fmt.format(date) : 'Sélectionner…',
          style: TextStyle(
            color:
                date != null ? ATColors.textPrimary : ATColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── Bandeau durée ────────────────────────────────────────────────────────
  Widget _buildDureeBanner() {
    final d = _dureeJours;
    if (d == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF003DA5).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF003DA5).withValues(alpha: 0.25),
        ),
      ),
      child: Row(children: [
        const Icon(Icons.event_available_outlined,
            color: Color(0xFF003DA5), size: 18),
        const SizedBox(width: 8),
        Text(
          'Durée : $d jour${d > 1 ? "s" : ""}',
          style: const TextStyle(
            color: Color(0xFF003DA5),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _sectionCard(
            title: 'OBJET & TYPE',
            children: [
              TextFormField(
                controller: _objetCtrl,
                maxLines: 3,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: 'Objet de la mission *',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              // Dropdown type mission avec 'conference' ajouté
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _kTypesMission.any((t) => t['value'] == widget.draft.typeMission)
                    ? widget.draft.typeMission
                    : 'autre',
                decoration: InputDecoration(
                  labelText: 'Type de mission',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
                items: _kTypesMission.map((t) {
                  final value = t['value']!;
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(children: [
                      Icon(
                        _kTypeIcons[value] ?? Icons.work_outline,
                        size: 18,
                        color: ATColors.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(t['label']!),
                    ]),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => widget.draft.typeMission = v ?? 'autre'),
              ),
            ],
          ),
          _sectionCard(
            title: 'LIEU DE DÉPART',
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: widget.draft.wilayaDepart.isEmpty
                    ? null
                    : widget.draft.wilayaDepart,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Wilaya de départ *',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
                items: _kWilayas
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
                onChanged: (v) =>
                    setState(() => widget.draft.wilayaDepart = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _villeDepartCtrl,
                decoration: InputDecoration(
                  labelText: 'Ville de départ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
              ),
            ],
          ),
          _sectionCard(
            title: "LIEU D'ARRIVÉE",
            children: [
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: widget.draft.wilayaArrivee.isEmpty
                    ? null
                    : widget.draft.wilayaArrivee,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: "Wilaya d'arrivée *",
                  prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
                items: _kWilayas
                    .map((w) => DropdownMenuItem(value: w, child: Text(w)))
                    .toList(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Champ requis' : null,
                onChanged: (v) =>
                    setState(() => widget.draft.wilayaArrivee = v ?? ''),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _villeArriveeCtrl,
                decoration: InputDecoration(
                  labelText: "Ville d'arrivée",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  filled: true,
                  fillColor: ATColors.background,
                ),
              ),
            ],
          ),
          _sectionCard(
            title: 'DATES',
            children: [
              _dateRow('Date de départ *', widget.draft.dateDepart, true),
              const SizedBox(height: 12),
              _dateRow('Date de retour *', widget.draft.dateRetour, false),
              if (widget.draft.dateDepart == null ||
                  widget.draft.dateRetour == null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Les deux dates sont requises',
                    style: TextStyle(
                        color: ATColors.error.withValues(alpha: 0.8),
                        fontSize: 12),
                  ),
                ),
              // ── Calcul durée automatique ─────────────────────────────────
              _buildDureeBanner(),
            ],
          ),
          _sectionCard(
            title: 'MOYEN DE TRANSPORT',
            children: [
              _transportTile('vehicule_service', 'Véhicule de service',
                  Icons.directions_car),
              _transportTile('train', 'Train', Icons.train),
              _transportTile('avion', 'Avion', Icons.flight),
              _transportTile('autre', 'Autre', Icons.commute),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                if (widget.draft.dateDepart == null ||
                    widget.draft.dateRetour == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Veuillez sélectionner les deux dates.')),
                  );
                  return;
                }
                _submit();
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Suivant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ATColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportTile(String value, String label, IconData icon) {
    final selected = widget.draft.moyenTransport == value;
    return RadioListTile<String>(
      value: value,
      // ignore: deprecated_member_use
      groupValue: widget.draft.moyenTransport,
      title: Row(
        children: [
          Icon(icon,
              size: 20,
              color: selected ? ATColors.secondary : ATColors.textSecondary),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color:
                      selected ? ATColors.textPrimary : ATColors.textSecondary,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      dense: true,
      // ignore: deprecated_member_use
      onChanged: (v) => setState(() => widget.draft.moyenTransport = v!),
    );
  }
}
