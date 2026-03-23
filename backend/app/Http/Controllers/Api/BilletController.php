<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\BilletResource;
use App\Models\AuditLog;
use App\Models\BilletAvion;
use App\Models\NotificationCustom;
use App\Models\Reservation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class BilletController extends Controller
{
    public function store(Request $request, $reservation_id)
    {
        $reservation = Reservation::findOrFail($reservation_id);
        $mission = $reservation->mission;

        if ($reservation->type !== 'billet') {
            return ApiResponse::error('La réservation doit être de type billet', 400);
        }

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $validated = $request->validate([
            'compagnie' => 'required|string',
            'numero_vol' => 'nullable|string',
            'aeroport_depart' => 'required|string',
            'aeroport_arrivee' => 'required|string',
            'date_vol' => 'required|date',
            'heure_depart' => 'required|string',
            'heure_arrivee' => 'required|string',
            'classe' => 'required|in:economique,business',
            'prix' => 'required|numeric|min:0',
        ]);

        $billet = BilletAvion::create([
            'reservation_id' => $reservation_id,
            'compagnie' => $validated['compagnie'],
            'numero_vol' => $validated['numero_vol'] ?? '',
            'aeroport_depart' => $validated['aeroport_depart'],
            'aeroport_arrivee' => $validated['aeroport_arrivee'],
            'date_vol' => $validated['date_vol'],
            'heure_depart' => $validated['heure_depart'],
            'heure_arrivee' => $validated['heure_arrivee'],
            'classe' => $validated['classe'],
            'prix' => $validated['prix'],
            'statut' => 'brouillon',
        ]);

        $reservation->update(['montant_estime' => $validated['prix']]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'create',
            'module' => 'billet',
            'description' => "Billet créé pour réservation {$reservation_id}",
            'old_values' => null,
            'new_values' => $billet->toArray(),
        ]);

        return new BilletResource($billet);
    }

    public function update(Request $request, $id)
    {
        $billet = BilletAvion::findOrFail($id);
        $reservation = $billet->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $oldValues = $billet->only([
            'compagnie', 'numero_vol', 'aeroport_depart',
            'aeroport_arrivee', 'date_vol', 'heure_depart',
            'heure_arrivee', 'classe', 'prix',
        ]);

        $validated = $request->validate([
            'compagnie' => 'nullable|string',
            'numero_vol' => 'nullable|string',
            'aeroport_depart' => 'nullable|string',
            'aeroport_arrivee' => 'nullable|string',
            'date_vol' => 'nullable|date',
            'heure_depart' => 'nullable|string',
            'heure_arrivee' => 'nullable|string',
            'classe' => 'nullable|in:economique,business',
            'prix' => 'nullable|numeric|min:0',
        ]);

        $billet->update(array_filter($validated));

        if (isset($validated['prix'])) {
            $reservation->update(['montant_estime' => $validated['prix']]);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'billet',
            'description' => "Billet modifié pour réservation {$reservation->id}",
            'old_values' => $oldValues,
            'new_values' => $billet->only([
                'compagnie', 'numero_vol', 'aeroport_depart',
                'aeroport_arrivee', 'date_vol', 'heure_depart',
                'heure_arrivee', 'classe', 'prix',
            ]),
        ]);

        return new BilletResource($billet);
    }

    public function destroy(Request $request, $id)
    {
        $billet = BilletAvion::findOrFail($id);
        $reservation = $billet->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'delete',
            'module' => 'billet',
            'description' => "Billet supprimé pour réservation {$reservation->id}",
            'old_values' => $billet->toArray(),
            'new_values' => null,
        ]);

        $billet->delete();

        return ApiResponse::success(null, 'Billet supprimé');
    }

    public function confirmer(Request $request, $id)
    {
        if (Auth::user()->role->name !== 'admin') {
            return ApiResponse::forbidden();
        }

        $billet = BilletAvion::findOrFail($id);
        $reservation = $billet->reservation;
        $mission = $reservation->mission;

        $request->validate([
            'numero_billet' => 'required|string',
        ]);

        $billet->update([
            'numero_billet' => $request->numero_billet,
            'statut' => 'confirme',
        ]);

        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => 'Billet confirmé',
            'message' => "Votre billet pour {$billet->compagnie} a été confirmé",
            'type' => 'success',
        ]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'billet',
            'description' => "Billet confirmé : {$request->numero_billet}",
            'old_values' => ['statut' => 'brouillon'],
            'new_values' => ['statut' => 'confirme'],
        ]);

        return ApiResponse::success(null, 'Billet confirmé');
    }
}
