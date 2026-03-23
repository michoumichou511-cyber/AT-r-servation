<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Http\Resources\ReservationResource;
use App\Models\AuditLog;
use App\Models\Mission;
use App\Models\Reservation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class ReservationController extends Controller
{
    public function index(Request $request, $mission_id)
    {
        $user = Auth::user();
        $mission = Mission::findOrFail($mission_id);

        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return ApiResponse::forbidden();
        }

        $query = Reservation::where('mission_id', $mission_id)
            ->with(['billetAvion', 'hebergement', 'restauration', 'prestataire']);

        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }

        return ReservationResource::collection($query->get());
    }

    public function store(Request $request, $mission_id)
    {
        $user = Auth::user();
        $mission = Mission::findOrFail($mission_id);

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        if ($user->role->name !== 'admin' && $mission->user_id !== $user->id) {
            return ApiResponse::forbidden();
        }

        $validated = $request->validate([
            'type' => 'required|in:billet,hebergement,restauration',
            'prestataire_id' => 'nullable|exists:prestataires,id',
            'montant_estime' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $reservation = Reservation::create([
            'mission_id' => $mission_id,
            'user_id' => $user->id,
            'type' => $validated['type'],
            'prestataire_id' => $validated['prestataire_id'] ?? null,
            'montant_estime' => $validated['montant_estime'] ?? 0,
            'notes' => $validated['notes'] ?? null,
            'statut' => 'brouillon',
        ]);

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'create',
            'module' => 'reservation',
            'description' => "Réservation créée pour mission {$mission->numero_unique}",
            'old_values' => null,
            'new_values' => $reservation->toArray(),
        ]);

        return new ReservationResource($reservation);
    }

    public function show(Request $request, $id)
    {
        $reservation = Reservation::with([
            'billetAvion', 'hebergement', 'restauration', 'prestataire',
        ])->findOrFail($id);

        $user = Auth::user();
        $mission = $reservation->mission;

        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return ApiResponse::forbidden();
        }

        return new ReservationResource($reservation);
    }

    public function update(Request $request, $id)
    {
        $reservation = Reservation::findOrFail($id);
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $user = Auth::user();
        if ($user->role->name !== 'admin' && $mission->user_id !== $user->id) {
            return ApiResponse::forbidden();
        }

        $oldValues = $reservation->only(['type', 'prestataire_id', 'montant_estime', 'notes']);

        $validated = $request->validate([
            'type' => 'nullable|in:billet,hebergement,restauration',
            'prestataire_id' => 'nullable|exists:prestataires,id',
            'montant_estime' => 'nullable|numeric|min:0',
            'notes' => 'nullable|string',
        ]);

        $reservation->update(array_filter($validated));

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'update',
            'module' => 'reservation',
            'description' => "Réservation modifiée pour mission {$mission->numero_unique}",
            'old_values' => $oldValues,
            'new_values' => $reservation->only(['type', 'prestataire_id', 'montant_estime', 'notes']),
        ]);

        return new ReservationResource($reservation);
    }

    public function destroy(Request $request, $id)
    {
        $reservation = Reservation::findOrFail($id);
        $mission = $reservation->mission;

        if ($mission->statut !== 'brouillon') {
            return ApiResponse::error('Mission doit être en brouillon', 400);
        }

        $user = Auth::user();
        if ($user->role->name !== 'admin' && $mission->user_id !== $user->id) {
            return ApiResponse::forbidden();
        }

        $reservation->billetAvion?->delete();
        $reservation->hebergement?->delete();
        $reservation->restauration?->delete();

        AuditLog::create([
            'user_id' => Auth::id(),
            'action' => 'delete',
            'module' => 'reservation',
            'description' => "Réservation supprimée pour mission {$mission->numero_unique}",
            'old_values' => $reservation->toArray(),
            'new_values' => null,
        ]);

        $reservation->delete();

        return ApiResponse::success(null, 'Réservation supprimée');
    }
}
