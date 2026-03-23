<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\HebergementResource;
use App\Models\AuditLog;
use App\Models\Hebergement;
use App\Models\NotificationCustom;
use App\Models\Reservation;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class HebergementController extends Controller
{
    public function store(Request $request, $reservation_id)
    {
        $reservation = Reservation::findOrFail($reservation_id);
        $mission = $reservation->mission;

        if ($reservation->type !== 'hebergement') {
            return ApiResponse::error('La réservation doit être de type hebergement', 400);
        }

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $validated = $request->validate([
            'hotel_nom' => 'required|string',
            'adresse_hotel' => 'nullable|string',
            'ville' => 'required|string',
            'pays' => 'required|string',
            'date_checkin' => 'required|date',
            'date_checkout' => 'required|date|after:date_checkin',
            'type_chambre' => 'required|in:simple,double,suite,appartement',
            'prix_nuit' => 'required|numeric|min:0',
            'petit_dejeuner_inclus' => 'nullable|boolean',
            'nombre_personnes' => 'nullable|integer|min:1',
        ]);

        $checkin = Carbon::parse($validated['date_checkin']);
        $checkout = Carbon::parse($validated['date_checkout']);
        $nombre_nuits = $checkout->diffInDays($checkin);
        $prix_total = $nombre_nuits * $validated['prix_nuit'];

        $hebergement = Hebergement::create([
            'reservation_id' => $reservation_id,
            'hotel_nom' => $validated['hotel_nom'],
            'adresse_hotel' => $validated['adresse_hotel'] ?? null,
            'ville' => $validated['ville'],
            'pays' => $validated['pays'],
            'date_checkin' => $validated['date_checkin'],
            'date_checkout' => $validated['date_checkout'],
            'nombre_nuits' => $nombre_nuits,
            'type_chambre' => $validated['type_chambre'],
            'prix_nuit' => $validated['prix_nuit'],
            'prix_total' => $prix_total,
            'petit_dejeuner_inclus' => $validated['petit_dejeuner_inclus'] ?? false,
            'nombre_personnes' => $validated['nombre_personnes'] ?? 1,
            'statut' => 'brouillon',
        ]);

        $reservation->update(['montant_estime' => $prix_total]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'create',
            'module' => 'hebergement',
            'description' => "Hébergement créé pour réservation {$reservation_id}",
            'old_values' => null,
            'new_values' => $hebergement->toArray(),
        ]);

        return new HebergementResource($hebergement);
    }

    public function update(Request $request, $id)
    {
        $hebergement = Hebergement::findOrFail($id);
        $reservation = $hebergement->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $oldValues = $hebergement->only([
            'hotel_nom', 'date_checkin', 'date_checkout', 'prix_nuit', 'prix_total',
        ]);

        $validated = $request->validate([
            'hotel_nom' => 'nullable|string',
            'adresse_hotel' => 'nullable|string',
            'ville' => 'nullable|string',
            'pays' => 'nullable|string',
            'date_checkin' => 'nullable|date',
            'date_checkout' => 'nullable|date',
            'type_chambre' => 'nullable|in:simple,double,suite,appartement',
            'prix_nuit' => 'nullable|numeric|min:0',
            'petit_dejeuner_inclus' => 'nullable|boolean',
            'nombre_personnes' => 'nullable|integer|min:1',
        ]);

        $hebergement->update(array_filter($validated));

        if (isset($validated['date_checkin']) || isset($validated['date_checkout']) || isset($validated['prix_nuit'])) {
            $checkin = Carbon::parse($hebergement->date_checkin);
            $checkout = Carbon::parse($hebergement->date_checkout);
            $nombre_nuits = $checkout->diffInDays($checkin);
            $prix_total = $nombre_nuits * $hebergement->prix_nuit;

            $hebergement->update(['nombre_nuits' => $nombre_nuits, 'prix_total' => $prix_total]);
            $reservation->update(['montant_estime' => $prix_total]);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'hebergement',
            'description' => "Hébergement modifié pour réservation {$reservation->id}",
            'old_values' => $oldValues,
            'new_values' => $hebergement->only([
                'hotel_nom', 'date_checkin', 'date_checkout', 'prix_nuit', 'prix_total',
            ]),
        ]);

        return new HebergementResource($hebergement);
    }

    public function destroy(Request $request, $id)
    {
        $hebergement = Hebergement::findOrFail($id);
        $reservation = $hebergement->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'delete',
            'module' => 'hebergement',
            'description' => "Hébergement supprimé pour réservation {$reservation->id}",
            'old_values' => $hebergement->toArray(),
            'new_values' => null,
        ]);

        $hebergement->delete();

        return ApiResponse::success(null, 'Hébergement supprimé');
    }

    public function confirmer(Request $request, $id)
    {
        if (Auth::user()->role->name !== 'admin') {
            return ApiResponse::forbidden();
        }

        $hebergement = Hebergement::findOrFail($id);
        $reservation = $hebergement->reservation;
        $mission = $reservation->mission;

        $request->validate([
            'numero_confirmation' => 'required|string',
        ]);

        $hebergement->update([
            'numero_confirmation' => $request->numero_confirmation,
            'statut' => 'confirme',
            'date_confirmation' => now(),
        ]);

        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => 'Hébergement confirmé',
            'message' => "Votre réservation à {$hebergement->hotel_nom} a été confirmée",
            'type' => 'success',
        ]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'hebergement',
            'description' => "Hébergement confirmé : {$request->numero_confirmation}",
            'old_values' => ['statut' => 'brouillon'],
            'new_values' => ['statut' => 'confirme'],
        ]);

        return ApiResponse::success(null, 'Hébergement confirmé');
    }
}
