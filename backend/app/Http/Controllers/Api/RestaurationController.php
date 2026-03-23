<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\RestaurationResource;
use App\Models\AuditLog;
use App\Models\NotificationCustom;
use App\Models\Reservation;
use App\Models\Restauration;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RestaurationController extends Controller
{
    public function store(Request $request, $reservation_id)
    {
        $reservation = Reservation::findOrFail($reservation_id);
        $mission = $reservation->mission;

        if ($reservation->type !== 'restauration') {
            return ApiResponse::error('La réservation doit être de type restauration', 400);
        }

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $validated = $request->validate([
            'prestataire_id' => 'nullable|exists:prestataires,id',
            'date_repas' => 'required|date',
            'type_repas' => 'required|in:petit_dejeuner,dejeuner,diner,cocktail',
            'lieu' => 'nullable|string',
            'nombre_personnes' => 'required|integer|min:1',
            'prix_par_personne' => 'required|numeric|min:0',
            'menu_description' => 'nullable|string',
            'allergies_notes' => 'nullable|string',
        ]);

        $prix_total = $validated['nombre_personnes'] * $validated['prix_par_personne'];

        $restauration = Restauration::create([
            'reservation_id' => $reservation_id,
            'prestataire_id' => $validated['prestataire_id'] ?? null,
            'date_repas' => $validated['date_repas'],
            'type_repas' => $validated['type_repas'],
            'lieu' => $validated['lieu'] ?? null,
            'nombre_personnes' => $validated['nombre_personnes'],
            'prix_par_personne' => $validated['prix_par_personne'],
            'prix_total' => $prix_total,
            'menu_description' => $validated['menu_description'] ?? null,
            'allergies_notes' => $validated['allergies_notes'] ?? null,
            'statut' => 'brouillon',
        ]);

        $reservation->update(['montant_estime' => $prix_total]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'create',
            'module' => 'restauration',
            'description' => "Restauration créée pour réservation {$reservation_id}",
            'old_values' => null,
            'new_values' => $restauration->toArray(),
        ]);

        return new RestaurationResource($restauration);
    }

    public function update(Request $request, $id)
    {
        $restauration = Restauration::findOrFail($id);
        $reservation = $restauration->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $oldValues = $restauration->only(['nombre_personnes', 'prix_par_personne', 'prix_total']);

        $validated = $request->validate([
            'prestataire_id' => 'nullable|exists:prestataires,id',
            'date_repas' => 'nullable|date',
            'type_repas' => 'nullable|in:petit_dejeuner,dejeuner,diner,cocktail',
            'lieu' => 'nullable|string',
            'nombre_personnes' => 'nullable|integer|min:1',
            'prix_par_personne' => 'nullable|numeric|min:0',
            'menu_description' => 'nullable|string',
            'allergies_notes' => 'nullable|string',
        ]);

        $restauration->update(array_filter($validated));

        if (isset($validated['nombre_personnes']) || isset($validated['prix_par_personne'])) {
            $prix_total = $restauration->nombre_personnes * $restauration->prix_par_personne;
            $restauration->update(['prix_total' => $prix_total]);
            $reservation->update(['montant_estime' => $prix_total]);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'restauration',
            'description' => "Restauration modifiée pour réservation {$reservation->id}",
            'old_values' => $oldValues,
            'new_values' => $restauration->only(['nombre_personnes', 'prix_par_personne', 'prix_total']),
        ]);

        return new RestaurationResource($restauration);
    }

    public function destroy(Request $request, $id)
    {
        $restauration = Restauration::findOrFail($id);
        $reservation = $restauration->reservation;
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'delete',
            'module' => 'restauration',
            'description' => "Restauration supprimée pour réservation {$reservation->id}",
            'old_values' => $restauration->toArray(),
            'new_values' => null,
        ]);

        $restauration->delete();

        return ApiResponse::success(null, 'Restauration supprimée');
    }

    public function confirmer(Request $request, $id)
    {
        if (Auth::user()->role->name !== 'admin') {
            return ApiResponse::forbidden();
        }

        $restauration = Restauration::findOrFail($id);
        $reservation = $restauration->reservation;
        $mission = $reservation->mission;

        $restauration->update(['statut' => 'confirme']);

        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => 'Restauration confirmée',
            'message' => "Votre réservation de restauration pour {$restauration->type_repas} a été confirmée",
            'type' => 'success',
        ]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'reservation',
            'description' => "Restauration confirmée (ID {$restauration->id})",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(null, 'Restauration confirmée');
    }
}
