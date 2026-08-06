<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\MissionResource;
use App\Mail\MissionLogistiqueOkMail;
use App\Models\HotelConvention;
use App\Models\Mission;
use App\Models\MissionTraitementDml;
use App\Models\Vehicule;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

/**
 * DmlController — traitement logistique des missions validées (agent_dml + admin).
 */
class DmlController extends Controller
{
    // ── LECTURE ────────────────────────────────────────────

    /**
     * GET /api/dml/missions-validees
     * Missions approuvées n'ayant pas encore de traitement DML logistique_ok.
     */
    public function missionsValidees(Request $request)
    {
        $perPage = (int) $request->get('per_page', 15);

        // Missions approuvées sans traitement terminé
        $missions = Mission::with([
                'user:id,nom,prenom,email,direction,telephone',
                'createurPar:id,nom,prenom,email',
                'reservations.prestataire',
                'documents',
                'circuitsValidation.validateur:id,nom,prenom',
                'traitementDml.agentDml:id,nom,prenom',
                'traitementDml.hotel',
                'traitementDml.vehicule',
            ])
            ->where('statut', 'approuve')
            ->whereDoesntHave('traitementDml', fn ($q) => $q->where('statut', 'logistique_ok'))
            ->orderBy('date_depart', 'asc')
            ->paginate($perPage);

        return \App\Helpers\ApiResponse::paginated(
            MissionResource::collection($missions),
            'Missions à traiter récupérées'
        );
    }

    /**
     * GET /api/dml/missions-en-traitement
     * Traitements DML en cours (statut != logistique_ok).
     */
    public function missionsEnTraitement(Request $request)
    {
        $perPage = (int) $request->get('per_page', 15);

        // Tous les statuts : le frontend répartit lui-même entre
        // "En traitement" et "Logistique OK" (l'onglet Terminées restait
        // vide quand on excluait logistique_ok ici).
        $traitements = MissionTraitementDml::with([
            'mission.user:id,nom,prenom,email,direction,telephone',
            'mission.createurPar:id,nom,prenom,email',
            'mission.reservations.prestataire',
            'mission.documents',
            'mission.circuitsValidation.validateur:id,nom,prenom',
            'hotel',
            'vehicule',
            'agentDml:id,nom,prenom',
        ])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return \App\Helpers\ApiResponse::paginated($traitements, 'Traitements en cours');
    }

    /**
     * GET /api/dml/hotels-conventions
     * Liste les hôtels en convention active.
     */
    public function hotelsConventions(Request $request)
    {
        $hotels = HotelConvention::actives()
            ->orderBy('ville')
            ->orderBy('nom')
            ->get([
                'id', 'nom', 'ville', 'wilaya', 'adresse', 'telephone',
                'tarif_chambre_simple', 'tarif_chambre_double',
                'date_debut_convention', 'date_fin_convention', 'statut',
            ]);

        return \App\Helpers\ApiResponse::success($hotels, 'Hôtels en convention');
    }

    /**
     * GET /api/dml/vehicules-disponibles
     * Liste les véhicules disponibles.
     */
    public function vehiculesDisponibles(Request $request)
    {
        $vehicules = Vehicule::disponibles()
            ->orderBy('type')
            ->orderBy('marque')
            ->get([
                'id', 'type', 'marque', 'modele', 'immatriculation',
                'annee', 'capacite', 'statut',
            ]);

        return \App\Helpers\ApiResponse::success($vehicules, 'Véhicules disponibles');
    }

    // ── ACTIONS ─────────────────────────────────────────────

    /**
     * POST /api/dml/missions/{id}/assigner-hotel
     * Crée ou met à jour le traitement DML — partie hébergement.
     */
    public function assignerHotel(Request $request, int $missionId)
    {
        $validated = $request->validate([
            'hotel_convention_id' => 'nullable|exists:hotels_conventions,id',
            'hotel_nom_libre'     => 'nullable|string|max:255',
            'observations'        => 'nullable|string|max:2000',
        ]);

        $mission = Mission::where('statut', 'approuve')->findOrFail($missionId);
        $agent   = $request->user();

        $traitement = MissionTraitementDml::updateOrCreate(
            ['mission_id' => $mission->id],
            array_merge($validated, [
                'agent_dml_id' => $agent->id,
                'statut'       => 'en_traitement',
            ])
        );

        return \App\Helpers\ApiResponse::success(
            $traitement->load(['mission', 'hotel']),
            'Hôtel assigné à la mission'
        );
    }

    /**
     * POST /api/dml/missions/{id}/assigner-vehicule
     * Met à jour le traitement DML — partie transport.
     */
    public function assignerVehicule(Request $request, int $missionId)
    {
        $validated = $request->validate([
            'vehicule_id'       => 'nullable|exists:vehicules,id',
            'type_transport'    => 'nullable|in:vehicule_service,avion,train,taxi,autre',
            'numero_bon'        => 'nullable|string|max:100',
            'observations'      => 'nullable|string|max:2000',
            'ticket_number'     => 'nullable|string|max:100',
            'ticket_scan'       => 'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',
            'transport_company' => 'nullable|string|max:255',
            'transport_date'    => 'nullable|date',
            'montant_transport' => 'nullable|numeric|min:0',
        ]);

        $mission = Mission::whereIn('statut', ['approuve', 'en_traitement_logistique'])
            ->findOrFail($missionId);

        $scanPath = null;
        if ($request->hasFile('ticket_scan')) {
            $scanPath = $request->file('ticket_scan')->store(
                'dml/ticket-scans/'.$mission->id,
                'public'
            );
        }

        $existing = MissionTraitementDml::where('mission_id', $mission->id)->first();

        $traitement = MissionTraitementDml::updateOrCreate(
            ['mission_id' => $mission->id],
            array_merge($validated, [
                'agent_dml_id'      => $request->user()->id,
                'statut'            => 'en_traitement',
                'ticket_number'     => $validated['ticket_number'] ?? null,
                'ticket_scan_path'  => $scanPath ?? ($existing->ticket_scan_path ?? null),
                'transport_company' => $validated['transport_company'] ?? 'Air Algérie',
                'transport_date'    => $validated['transport_date'] ?? null,
                'montant_transport' => $validated['montant_transport'] ?? null,
            ])
        );

        // Si véhicule de service : le marquer en_mission
        if (! empty($validated['vehicule_id'])) {
            Vehicule::where('id', $validated['vehicule_id'])
                ->update(['statut' => 'en_mission']);
        }

        return \App\Helpers\ApiResponse::success(
            $traitement->load(['mission', 'vehicule']),
            'Véhicule/transport assigné'
        );
    }

    /**
     * POST /api/dml/missions/{id}/logistique-ok
     * Finalise le traitement : statut logistique_ok, mission → en_traitement_logistique.
     */
    public function marquerLogistiqueOk(Request $request, int $missionId)
    {
        $mission = Mission::whereIn('statut', ['approuve', 'en_traitement_logistique'])
            ->findOrFail($missionId);

        $traitement = MissionTraitementDml::firstOrCreate(
            ['mission_id' => $mission->id],
            ['agent_dml_id' => $request->user()->id]
        );

        $traitement->update([
            'statut'    => 'logistique_ok',
            'traite_le' => now(),
        ]);

        $mission->update(['statut' => 'en_traitement_logistique']);

        // \Throwable (pas \Exception) : une classe/vue manquante lève une Error
        // fatale qui contournait le catch et faisait échouer toute la requête.
        try {
            $mission->loadMissing('user');
            if ($mission->user?->email) {
                Mail::to($mission->user->email)->queue((new MissionLogistiqueOkMail($mission, $traitement->load(['hotel', 'vehicule'])))->onConnection('database'));
            }
        } catch (\Throwable $e) {
            \Log::error('Email logistique OK failed: '.$e->getMessage());
        }

        // UX-07 fix : notification in-app pour le demandeur (complement email)
        try {
            \App\Models\NotificationCustom::create([
                'user_id'    => $mission->user_id,
                'titre'      => 'Logistique terminee',
                'message'    => "Votre mission '{$mission->titre}' a ete cloturee par le service DML. Vous pouvez consulter les details (hotel, transport) dans la fiche mission.",
                'type'       => 'success',
                'categorie'  => 'mission',
                'action_url' => "/missions/{$mission->id}",
            ]);
        } catch (\Exception $e) {
            \Log::error('Notification logistique OK failed: '.$e->getMessage());
        }

        return \App\Helpers\ApiResponse::success(
            [
                'mission'    => new MissionResource($mission->load('user')),
                'traitement' => $traitement->load(['agentDml', 'hotel', 'vehicule']),
            ],
            'Logistique marquée OK'
        );
    }

    // ── ADMIN — CRUD hôtels ──────────────────────────────────

    /**
     * GET /api/admin/dml/hotels
     */
    public function adminHotelsList(Request $request)
    {
        $hotels = HotelConvention::with('createur')
            ->orderBy('statut')
            ->orderBy('ville')
            ->paginate((int) $request->get('per_page', 20));

        return \App\Helpers\ApiResponse::paginated($hotels, 'Liste hôtels conventions');
    }

    /**
     * POST /api/admin/dml/hotels
     */
    public function adminHotelsCreate(Request $request)
    {
        $validated = $request->validate([
            'nom'                  => 'required|string|max:255',
            'ville'                => 'required|string|max:255',
            'wilaya'               => 'nullable|string|max:100',
            'adresse'              => 'nullable|string|max:500',
            'telephone'            => 'nullable|string|max:30',
            'email_contact'        => 'nullable|email|max:255',
            'date_debut_convention'=> 'nullable|date',
            'date_fin_convention'  => 'nullable|date|after_or_equal:date_debut_convention',
            'tarif_chambre_simple' => 'nullable|numeric|min:0',
            'tarif_chambre_double' => 'nullable|numeric|min:0',
            'statut'               => 'nullable|in:active,expiree,suspendue',
            'notes'                => 'nullable|string|max:2000',
        ]);

        $hotel = HotelConvention::create(array_merge($validated, [
            'created_by' => $request->user()->id,
        ]));

        return \App\Helpers\ApiResponse::success($hotel, 'Hôtel créé', 201);
    }

    // ── ADMIN — CRUD véhicules ───────────────────────────────

    /**
     * GET /api/admin/dml/vehicules
     */
    public function adminVehiculesList(Request $request)
    {
        $vehicules = Vehicule::orderBy('statut')
            ->orderBy('marque')
            ->paginate((int) $request->get('per_page', 20));

        return \App\Helpers\ApiResponse::paginated($vehicules, 'Liste véhicules');
    }

    /**
     * POST /api/admin/dml/vehicules
     */
    public function adminVehiculesCreate(Request $request)
    {
        $validated = $request->validate([
            'type'            => 'required|in:voiture_service,minibus,berline',
            'marque'          => 'required|string|max:100',
            'modele'          => 'required|string|max:100',
            'immatriculation' => 'required|string|max:20|unique:vehicules',
            'annee'           => 'nullable|integer|min:2000|max:' . (date('Y') + 1),
            'statut'          => 'nullable|in:disponible,en_mission,maintenance',
            'capacite'        => 'nullable|integer|min:1|max:50',
            'notes'           => 'nullable|string|max:1000',
        ]);

        $vehicule = Vehicule::create($validated);

        return \App\Helpers\ApiResponse::success($vehicule, 'Véhicule créé', 201);
    }
}
