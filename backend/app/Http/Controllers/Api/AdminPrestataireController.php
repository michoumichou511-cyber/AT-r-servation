<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\EvaluationPrestataire;
use App\Models\Prestataire;
use App\Models\Reservation;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;

class AdminPrestataireController extends Controller
{
    public function show(Request $request, $id)
    {
        $prestataire = Prestataire::withCount([
            'reservations',
            'reservations as reservations_confirmees_count' => fn ($q) => $q->where('statut', 'confirme'),
        ])->findOrFail($id);

        $stats = \App\Models\EvaluationPrestataire::where('prestataire_id', $prestataire->id)
            ->selectRaw('
                AVG(ponctualite) as moy_ponctualite,
                AVG(qualite_service) as moy_qualite_service,
                AVG(rapport_qualite_prix) as moy_rapport_qualite_prix,
                AVG(communication) as moy_communication,
                AVG(note_globale) as note_globale,
                COUNT(*) as total
            ')
            ->first();

        return ApiResponse::success([
            'prestataire' => $prestataire,
            'evaluations_stats' => [
                'ponctualite' => round((float) ($stats->moy_ponctualite ?? 0), 2),
                'qualite_service' => round((float) ($stats->moy_qualite_service ?? 0), 2),
                'rapport_qualite_prix' => round((float) ($stats->moy_rapport_qualite_prix ?? 0), 2),
                'communication' => round((float) ($stats->moy_communication ?? 0), 2),
                'note_globale' => round((float) ($stats->note_globale ?? 0), 2),
                'total_evaluations' => (int) ($stats->total ?? 0),
            ],
        ]);
    }

    public function listePrestataires(Request $request)
    {
        try {
            $query = Prestataire::query();

            if ($request->filled('type')) {
                $query->where('type', $request->type);
            }

            if ($request->filled('search')) {
                $query->where(function ($q) use ($request) {
                    $q->where('nom', 'like', '%'.$request->search.'%')
                        ->orWhere('email', 'like', '%'.$request->search.'%');
                });
            }

            if ($request->filled('actif')) {
                $query->where('is_active', $request->boolean('actif'));
            }

            $prestataires = $query->orderByDesc('created_at')->paginate(15);

            return ApiResponse::paginated($prestataires);
        } catch (\Exception $e) {
            Log::error('listePrestataires: '.$e->getMessage());

            return ApiResponse::error('Erreur lors du chargement des prestataires: '.$e->getMessage(), 500);
        }
    }

    public function prestaFavoris(Request $request)
    {
        $favoris = Prestataire::where('is_favori', true)
            ->where('is_active', true)
            ->orderBy('note_performance', 'desc')
            ->get();

        return ApiResponse::success(['prestataires' => $favoris]);
    }

    public function toggleFavori(Request $request, $id)
    {
        $prestataire = Prestataire::findOrFail($id);
        $prestataire->is_favori = ! $prestataire->is_favori;
        $prestataire->save();

        return ApiResponse::success([
            'is_favori' => $prestataire->is_favori,
            'message' => $prestataire->is_favori ? 'Ajouté aux favoris' : 'Retiré des favoris',
        ]);
    }

    public function evaluerPrestataire(Request $request, $id)
    {
        $user = $request->user();
        $prestataire = Prestataire::findOrFail($id);

        $validated = $request->validate([
            'reservation_id' => 'nullable|exists:reservations,id',
            'ponctualite' => 'required|numeric|min:0|max:5',
            'qualite_service' => 'required|numeric|min:0|max:5',
            'rapport_qualite_prix' => 'required|numeric|min:0|max:5',
            'communication' => 'required|numeric|min:0|max:5',
            'commentaire' => 'nullable|string|max:1000',
        ]);

        // Vérification anti-doublons
        if (! empty($validated['reservation_id'])) {
            if (EvaluationPrestataire::where('user_id', $user->id)->where('reservation_id', $validated['reservation_id'])->exists()) {
                return ApiResponse::error('Vous avez déjà évalué ce prestataire pour cette réservation.', 409);
            }
        } else {
            // MySQL UNIQUE accepte plusieurs NULL : on bloque en PHP
            if (EvaluationPrestataire::where('user_id', $user->id)->where('prestataire_id', $prestataire->id)->whereNull('reservation_id')->exists()) {
                return ApiResponse::error('Vous avez déjà évalué ce prestataire.', 409);
            }
        }

        // Contrôle éligibilité si reservation_id fourni
        if (! empty($validated['reservation_id'])) {
            $reservation = Reservation::with(['billetAvion', 'hebergement', 'restauration'])
                ->findOrFail($validated['reservation_id']);

            if (! $user->hasRole('admin') && (int) $reservation->user_id !== (int) $user->id) {
                return ApiResponse::forbidden();
            }

            if (! is_null($reservation->prestataire_id) && (int) $reservation->prestataire_id !== (int) $prestataire->id) {
                return ApiResponse::error('Ce prestataire ne correspond pas à la réservation sélectionnée.', 409);
            }

            $confirmed = $reservation->statut === 'confirme';

            if (! $confirmed) {
                if ($reservation->type === 'billet' && $reservation->billetAvion && $reservation->billetAvion->statut === 'confirme') {
                    $confirmed = true;
                }
                if ($reservation->type === 'hebergement' && $reservation->hebergement && $reservation->hebergement->statut === 'confirme') {
                    $confirmed = true;
                }
                if ($reservation->type === 'restauration' && $reservation->restauration && $reservation->restauration->statut === 'confirme') {
                    $confirmed = true;
                }
            }

            if (! $confirmed) {
                return ApiResponse::error("La réservation n'est pas encore confirmée (impossible d'évaluer pour le moment).", 422);
            }
        }

        // Calcul note globale (moyenne des 4 critères)
        $noteGlobale = round(
            ($validated['ponctualite'] + $validated['qualite_service'] +
                $validated['rapport_qualite_prix'] + $validated['communication']) / 4,
            2
        );

        $evaluation = EvaluationPrestataire::create([
            'prestataire_id' => $prestataire->id,
            'user_id' => $user->id,
            'reservation_id' => $validated['reservation_id'] ?? null,
            'ponctualite' => $validated['ponctualite'],
            'qualite_service' => $validated['qualite_service'],
            'rapport_qualite_prix' => $validated['rapport_qualite_prix'],
            'communication' => $validated['communication'],
            'note_globale' => $noteGlobale,
            'commentaire' => $validated['commentaire'] ?? null,
        ]);

        // Recalcul note_performance et nombre_evaluations
        $stats = EvaluationPrestataire::where('prestataire_id', $prestataire->id)
            ->selectRaw('AVG(note_globale) as moyenne, COUNT(*) as total')
            ->first();

        $prestataire->update([
            'note_performance' => round((float) ($stats->moyenne ?? 0), 2),
            'nombre_evaluations' => (int) ($stats->total ?? 0),
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'create',
            'module' => 'reservation',
            'description' => "Évaluation prestataire #{$prestataire->id} - Note: {$noteGlobale}/5",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $fresh = $prestataire->fresh();

        return ApiResponse::created([
            'evaluation' => $evaluation,
            'prestataire' => [
                'id' => $fresh->id,
                'note_performance' => $fresh->note_performance,
                'nombre_evaluations' => $fresh->nombre_evaluations,
            ],
        ], 'Évaluation enregistrée avec succès.');
    }

    public function evaluationsPrestataire(Request $request, $id)
    {
        $prestataire = Prestataire::findOrFail($id);

        $evaluations = EvaluationPrestataire::with('user:id,prenom,nom,email')
            ->where('prestataire_id', $prestataire->id)
            ->orderByDesc('created_at')
            ->paginate(10);

        $stats = EvaluationPrestataire::where('prestataire_id', $prestataire->id)
            ->selectRaw('
                AVG(ponctualite) as moy_ponctualite,
                AVG(qualite_service) as moy_qualite_service,
                AVG(rapport_qualite_prix) as moy_rapport_qualite_prix,
                AVG(communication) as moy_communication,
                AVG(note_globale) as note_globale,
                COUNT(*) as total
            ')
            ->first();

        return ApiResponse::success([
            'evaluations' => $evaluations,
            'stats' => [
                'ponctualite' => round((float) ($stats->moy_ponctualite ?? 0), 2),
                'qualite_service' => round((float) ($stats->moy_qualite_service ?? 0), 2),
                'rapport_qualite_prix' => round((float) ($stats->moy_rapport_qualite_prix ?? 0), 2),
                'communication' => round((float) ($stats->moy_communication ?? 0), 2),
                'note_globale' => round((float) ($stats->note_globale ?? 0), 2),
                'total_evaluations' => (int) ($stats->total ?? 0),
            ],
        ]);
    }

    public function creerPrestataire(Request $request)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $request->validate([
            'nom' => 'required|string|max:255',
            'type' => 'required|in:hotel,catering,compagnie_aerienne,agence_voyage',
            'ville' => 'required|string|max:255',
            'pays' => 'nullable|string|max:255',
            'adresse' => 'nullable|string',
            'telephone' => 'nullable|string|max:20',
            'email' => 'nullable|email',
            'site_web' => 'nullable|url',
            'note_performance' => 'nullable|numeric|min:0|max:5',
        ]);

        $prestataire = Prestataire::create($request->validated());

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'create',
            'module' => 'user',
            'description' => "Prestataire '{$prestataire->nom}' créé",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::created(['prestataire' => $prestataire], 'Prestataire créé avec succès');
    }

    public function modifierPrestataire(Request $request, $id)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $prestataire = Prestataire::findOrFail($id);

        $request->validate([
            'nom' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|in:hotel,catering,compagnie_aerienne,agence_voyage',
            'ville' => 'sometimes|required|string|max:255',
            'pays' => 'nullable|string|max:255',
            'adresse' => 'nullable|string',
            'telephone' => 'nullable|string|max:20',
            'email' => 'nullable|email',
            'site_web' => 'nullable|url',
            'note_performance' => 'nullable|numeric|min:0|max:5',
            'is_active' => 'sometimes|boolean',
        ]);

        $prestataire->update($request->validated());

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'update',
            'module' => 'user',
            'description' => "Prestataire '{$prestataire->nom}' modifié",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(['prestataire' => $prestataire], 'Prestataire modifié avec succès');
    }

    public function supprimerPrestataire(Request $request, $id)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $prestataire = Prestataire::findOrFail($id);

        $hasActiveReservations = $prestataire->reservations()
            ->whereIn('statut', ['en_attente', 'confirme'])
            ->exists();

        if ($hasActiveReservations) {
            return ApiResponse::error('Impossible de supprimer ce prestataire car il a des réservations actives', 400);
        }

        $nom = $prestataire->nom;
        $prestataire->delete();

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'delete',
            'module' => 'user',
            'description' => "Prestataire '{$nom}' supprimé",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(null, 'Prestataire supprimé avec succès');
    }
}
