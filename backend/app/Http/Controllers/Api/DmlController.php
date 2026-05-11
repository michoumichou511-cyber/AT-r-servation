<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\MissionResource;
use App\Models\Mission;
use Illuminate\Http\Request;

/**
 * DmlController — traitement logistique des missions validées (agent_dml).
 */
class DmlController extends Controller
{
    /**
     * GET /api/dml/missions-validees
     * Liste toutes les missions approuvées (statut = approuve).
     */
    public function missionsValidees(Request $request)
    {
        $perPage = (int) $request->get('per_page', 20);

        $missions = Mission::with(['user', 'reservations.prestataire'])
            ->where('statut', 'approuve')
            ->orderBy('date_depart', 'asc')
            ->paginate($perPage);

        return \App\Helpers\ApiResponse::paginated(
            MissionResource::collection($missions),
            'Missions validées récupérées'
        );
    }

    /**
     * POST /api/dml/missions/{id}/traiter
     * L'agent DML marque la mission comme traitée (statut → termine)
     * et peut ajouter une note logistique.
     */
    public function traiter(Request $request, int $id)
    {
        $validated = $request->validate([
            'note_logistique' => 'nullable|string|max:1000',
        ]);

        $mission = Mission::where('statut', 'approuve')->findOrFail($id);

        $mission->update([
            'statut'          => 'termine',
            'note_logistique' => $validated['note_logistique'] ?? null,
        ]);

        return \App\Helpers\ApiResponse::success(
            new MissionResource($mission->load('user')),
            'Mission marquée comme traitée (terminée)'
        );
    }
}
