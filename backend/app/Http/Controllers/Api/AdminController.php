<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

/**
 * @deprecated Découpé en:
 * - AdminUserController
 * - AdminPrestataireController
 * - AdminBudgetController
 * - AdminAuditController
 */
class AdminController extends Controller {}

// Fichier déprécié : on arrête explicitement l'interprétation ici.
__halt_compiler();

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

/**
 * @deprecated Découpé en:
 * - AdminUserController
 * - AdminPrestataireController
 * - AdminBudgetController
 * - AdminAuditController
 */
class AdminController extends Controller
{
}

<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Helpers\ApiResponse;
use App\Models\User;
use App\Models\Budget;
use App\Models\Prestataire;
use App\Models\AuditLog;
use App\Models\EvaluationPrestataire;
use App\Models\NotificationCustom;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Schema;
use Laravel\Sanctum\PersonalAccessToken;
use App\Models\Reservation;

class AdminController extends Controller
{
    public function listeUtilisateurs(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $query = User::with('role');

        // Filtres
        if ($request->has('role') && $request->role) {
            $query->whereHas('role', function($q) use ($request) {
                $q->where('name', $request->role);
            });
        }

        if ($request->has('direction') && $request->direction) {
            $query->where('direction', $request->direction);
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        $utilisateurs = $query->select([
                'id', 'prenom', 'nom', 'email', 'matricule',
                'direction', 'service', 'is_active', 'last_login_at',
                'created_at'
            ])
            ->withCount(['missions', 'reservations'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return response()->json(['utilisateurs' => $utilisateurs]);
    }

    public function activerDesactiver(Request $request, $id)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $targetUser = User::findOrFail($id);

        // Ne pas pouvoir se désactiver soi-même
        if ($targetUser->id === $user->id) {
            return response()->json(['error' => 'Vous ne pouvez pas modifier votre propre statut'], 400);
        }

        $targetUser->is_active = !$targetUser->is_active;
        $targetUser->save();

        // Révoquer tous les tokens si désactivé
        if (!$targetUser->is_active) {
            $targetUser->tokens()->delete();
        }

        // Notifier l'utilisateur
        NotificationCustom::create([
            'user_id' => $targetUser->id,
            'type' => $targetUser->is_active ? 'success' : 'warning',
            'categorie' => 'compte',
            'titre' => $targetUser->is_active ? 'Compte activé' : 'Compte désactivé',
            'message' => $targetUser->is_active ?
                'Votre compte a été réactivé par un administrateur.' :
                'Votre compte a été désactivé par un administrateur.',
            'action_url' => '/profil'
        ]);

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => $targetUser->is_active ? 'user_activated' : 'user_deactivated',
            'module' => 'user',
            'description' => "Utilisateur {$targetUser->prenom} {$targetUser->nom} " .
                           ($targetUser->is_active ? 'activé' : 'désactivé'),
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Statut utilisateur modifié avec succès',
            'user' => $targetUser
        ]);
    }

    public function changerRole(Request $request, $id)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $request->validate([
            'role_id' => 'required|exists:roles,id'
        ]);

        $targetUser = User::findOrFail($id);

        // Ne pas pouvoir changer son propre rôle
        if ($targetUser->id === $user->id) {
            return response()->json(['error' => 'Vous ne pouvez pas modifier votre propre rôle'], 400);
        }

        $ancienRole = $targetUser->role->name ?? 'aucun';
        $targetUser->role_id = $request->role_id;
        $targetUser->save();
        $targetUser->load('role');

        // Notifier l'utilisateur
        NotificationCustom::create([
            'user_id' => $targetUser->id,
            'type' => 'info',
            'categorie' => 'compte',
            'titre' => 'Changement de rôle',
            'message' => "Votre rôle a été changé de '{$ancienRole}' à '{$targetUser->role->name}' par un administrateur.",
            'action_url' => '/profil'
        ]);

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'role_changed',
            'module' => 'user',
            'description' => "Rôle de {$targetUser->prenom} {$targetUser->nom} changé: {$ancienRole} → {$targetUser->role->name}",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Rôle utilisateur modifié avec succès',
            'user' => $targetUser
        ]);
    }

    public function listePrestataires(Request $request)
    {
        try {
            $query = Prestataire::query();

            // Filtres optionnels
            if ($request->filled('type')) {
                $query->where('type', $request->type);
            }
            if ($request->filled('search')) {
                $query->where(function ($q) use ($request) {
                    $q->where('nom', 'like', '%' . $request->search . '%')
                      ->orWhere('email', 'like', '%' . $request->search . '%');
                });
            }
            if ($request->filled('actif')) {
                $query->where('is_active', $request->boolean('actif'));
            }

            // Colonnes de base seulement (pas de colonne qui pourrait manquer)
            $colonnes = Schema::getColumnListing('prestataires');

            $prestataires = $query
                ->orderByDesc('created_at')
                ->paginate(15);

            return ApiResponse::paginated($prestataires);
        } catch (\Exception $e) {
            \Log::error('listePrestataires: ' . $e->getMessage());
            return ApiResponse::error('Erreur lors du chargement des prestataires: ' . $e->getMessage(), 500);
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
        $prestataire->is_favori = !$prestataire->is_favori;
        $prestataire->save();

        return ApiResponse::success([
            'is_favori' => $prestataire->is_favori,
            'message' => $prestataire->is_favori
                ? 'Ajouté aux favoris'
                : 'Retiré des favoris'
        ]);
    }

    public function evaluerPrestataire(Request $request, $id)
    {
        $user = $request->user();
        $prestataire = Prestataire::findOrFail($id);

        $validated = $request->validate([
            'reservation_id'       => 'nullable|exists:reservations,id',
            'ponctualite'          => 'required|numeric|min:0|max:5',
            'qualite_service'      => 'required|numeric|min:0|max:5',
            'rapport_qualite_prix' => 'required|numeric|min:0|max:5',
            'communication'        => 'required|numeric|min:0|max:5',
            'commentaire'          => 'nullable|string|max:1000',
        ]);

        // Vérifier doublons
        if (!empty($validated['reservation_id'])) {
            $existe = EvaluationPrestataire::where('user_id', $user->id)
                ->where('reservation_id', $validated['reservation_id'])
                ->exists();

            if ($existe) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous avez déjà évalué ce prestataire pour cette réservation.',
                ], 409);
            }
        } else {
            // MySQL UNIQUE accepte plusieurs NULL : on bloque en code
            $existe = EvaluationPrestataire::where('user_id', $user->id)
                ->where('prestataire_id', $prestataire->id)
                ->whereNull('reservation_id')
                ->exists();

            if ($existe) {
                return response()->json([
                    'success' => false,
                    'message' => 'Vous avez déjà évalué ce prestataire.',
                ], 409);
            }
        }

        // Contrôle éligibilité si reservation_id fourni :
        // on autorise seulement après confirmation globale OU confirmation du service.
        if (!empty($validated['reservation_id'])) {
            $reservation = Reservation::with(['billetAvion', 'hebergement', 'restauration'])
                ->findOrFail($validated['reservation_id']);

            if (!$user->hasRole('admin') && (int)$reservation->user_id !== (int)$user->id) {
                return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
            }

            if (!is_null($reservation->prestataire_id) && (int)$reservation->prestataire_id !== (int)$prestataire->id) {
                return response()->json([
                    'success' => false,
                    'message' => 'Ce prestataire ne correspond pas à la réservation sélectionnée.',
                ], 409);
            }

            $confirmed = $reservation->statut === 'confirme';

            if (!$confirmed) {
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

            if (!$confirmed) {
                return response()->json([
                    'success' => false,
                    'message' => 'La réservation n’est pas encore confirmée (impossible d’évaluer pour le moment).',
                ], 422);
            }
        }

        // Calcul note globale (moyenne des 4 critères)
        $noteGlobale = round(
            (
                $validated['ponctualite'] + $validated['qualite_service'] +
                $validated['rapport_qualite_prix'] + $validated['communication']
            ) / 4,
            2
        );

        $evaluation = EvaluationPrestataire::create([
            'prestataire_id'       => $prestataire->id,
            'user_id'              => $user->id,
            'reservation_id'       => $validated['reservation_id'] ?? null,
            'ponctualite'          => $validated['ponctualite'],
            'qualite_service'      => $validated['qualite_service'],
            'rapport_qualite_prix' => $validated['rapport_qualite_prix'],
            'communication'        => $validated['communication'],
            'note_globale'         => $noteGlobale,
            'commentaire'          => $validated['commentaire'] ?? null,
        ]);

        // Recalcule note_performance et nombre_evaluations sur le prestataire
        $stats = EvaluationPrestataire::where('prestataire_id', $prestataire->id)
            ->selectRaw('AVG(note_globale) as moyenne, COUNT(*) as total')
            ->first();

        $prestataire->update([
            'note_performance'   => round((float)($stats->moyenne ?? 0), 2),
            'nombre_evaluations' => (int)($stats->total ?? 0),
        ]);

        AuditLog::create([
            'user_id'     => $user->id,
            // audit_logs.action/module sont des ENUM (voir migration audit_logs)
            // On utilise donc des valeurs autorisées pour éviter une erreur 500.
            'action'      => 'create',
            'module'      => 'reservation',
            'description' => "Évaluation prestataire #{$prestataire->id} - Note: {$noteGlobale}/5",
            'ip_address'  => $request->ip(),
            'user_agent'  => $request->userAgent(),
        ]);

        return response()->json([
            'success'    => true,
            'message'    => 'Évaluation enregistrée avec succès.',
            'data'       => $evaluation,
            'prestataire' => [
                'id'                 => $prestataire->id,
                'note_performance'   => $prestataire->fresh()->note_performance,
                'nombre_evaluations' => $prestataire->fresh()->nombre_evaluations,
            ],
        ], 201);
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

        return response()->json([
            'success' => true,
            'data'    => $evaluations,
            'stats'   => [
                'ponctualite'          => round((float)($stats->moy_ponctualite ?? 0), 2),
                'qualite_service'      => round((float)($stats->moy_qualite_service ?? 0), 2),
                'rapport_qualite_prix' => round((float)($stats->moy_rapport_qualite_prix ?? 0), 2),
                'communication'        => round((float)($stats->moy_communication ?? 0), 2),
                'note_globale'         => round((float)($stats->note_globale ?? 0), 2),
                'total_evaluations'    => (int)($stats->total ?? 0),
            ],
        ]);
    }

    public function creerPrestataire(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $request->validate([
            'nom' => 'required|string|max:255',
            'type' => 'required|in:hotel,restaurant,compagnie_aerienne,transport,autre',
            'ville' => 'required|string|max:255',
            'adresse' => 'nullable|string',
            'telephone' => 'nullable|string|max:20',
            'email' => 'nullable|email',
            'site_web' => 'nullable|url',
            'note_performance' => 'nullable|numeric|min:0|max:5'
        ]);

        $prestataire = Prestataire::create($request->all());

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'prestataire_created',
            'module' => 'prestataire',
            'description' => "Prestataire '{$prestataire->nom}' créé",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Prestataire créé avec succès',
            'prestataire' => $prestataire
        ], 201);
    }

    public function modifierPrestataire(Request $request, $id)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $prestataire = Prestataire::findOrFail($id);

        $request->validate([
            'nom' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|in:hotel,restaurant,compagnie_aerienne,transport,autre',
            'ville' => 'sometimes|required|string|max:255',
            'adresse' => 'nullable|string',
            'telephone' => 'nullable|string|max:20',
            'email' => 'nullable|email',
            'site_web' => 'nullable|url',
            'note_performance' => 'nullable|numeric|min:0|max:5',
            'is_active' => 'sometimes|boolean'
        ]);

        $prestataire->update($request->all());

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'prestataire_updated',
            'module' => 'prestataire',
            'description' => "Prestataire '{$prestataire->nom}' modifié",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Prestataire modifié avec succès',
            'prestataire' => $prestataire
        ]);
    }

    public function supprimerPrestataire(Request $request, $id)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $prestataire = Prestataire::findOrFail($id);

        // Vérifier s'il a des réservations actives
        $hasActiveReservations = $prestataire->reservations()
            ->whereIn('statut', ['en_attente', 'confirme'])
            ->exists();

        if ($hasActiveReservations) {
            return response()->json([
                'error' => 'Impossible de supprimer ce prestataire car il a des réservations actives'
            ], 400);
        }

        $nom = $prestataire->nom;
        $prestataire->delete();

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'prestataire_deleted',
            'module' => 'prestataire',
            'description' => "Prestataire '{$nom}' supprimé",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Prestataire supprimé avec succès'
        ]);
    }

    public function gererBudgets(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $query = Budget::query();

        if ($request->has('direction') && $request->direction) {
            $query->where('direction', $request->direction);
        }

        if ($request->has('annee') && $request->annee) {
            $query->where('annee', $request->annee);
        } else {
            $query->where('annee', now()->year);
        }

        $budgets = $query->orderBy('direction')->get()->map(function ($budget) {
            return [
                'id' => $budget->id,
                'direction' => $budget->direction,
                'service' => $budget->service,
                'annee' => $budget->annee,
                'montant_alloue' => $budget->montant_alloue,
                'montant_consomme' => $budget->montant_consomme,
                'pourcentage' => $budget->montant_alloue > 0
                    ? round(($budget->montant_consomme / $budget->montant_alloue) * 100, 1)
                    : 0,
                'statut' => $budget->indicateur,
            ];
        });

        return response()->json(['budgets' => $budgets]);
    }

    public function creerBudget(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $request->validate([
            'direction' => 'required|string',
            'service' => 'required|string',
            'annee' => 'required|integer|min:2020|max:2030',
            'montant_alloue' => 'required|numeric|min:0'
        ]);

        $budget = Budget::create([
            'direction' => $request->direction,
            'service' => $request->service,
            'annee' => $request->annee,
            'montant_alloue' => $request->montant_alloue,
            'montant_consomme' => 0,
            'alerte_seuil' => 80,
        ]);

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'budget_created',
            'module' => 'budget',
            'description' => "Budget créé pour {$request->direction} - {$request->service} ({$request->annee})",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Budget créé avec succès',
            'budget' => $budget
        ], 201);
    }

    public function modifierBudget(Request $request, $id)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $request->validate([
            'montant_alloue' => 'sometimes|numeric|min:0',
            'alerte_seuil' => 'sometimes|numeric|min:0|max:100',
        ]);

        $budget = Budget::findOrFail($id);
        $budget->update($request->only(['montant_alloue', 'alerte_seuil']));

        // Logger l'action
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'budget_updated',
            'module' => 'budget',
            'description' => "Budget {$budget->direction} - {$budget->service} modifié",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent()
        ]);

        return response()->json([
            'message' => 'Budget modifié avec succès',
            'budget' => $budget->fresh()
        ]);
    }

    public function auditLogs(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (!$user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        // Important : on évite `with('user')` ici car la relation peut ne pas être
        // disponible au runtime et provoquer une 500 (RelationNotFoundException).
        $query = AuditLog::query();

        // Filtres
        if ($request->has('user_id') && $request->user_id) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('action') && $request->action) {
            $query->where('action', $request->action);
        }

        if ($request->has('module') && $request->module) {
            $query->where('module', $request->module);
        }

        if ($request->has('date_debut') && $request->date_debut) {
            $query->where('created_at', '>=', $request->date_debut);
        }

        if ($request->has('date_fin') && $request->date_fin) {
            $query->where('created_at', '<=', $request->date_fin . ' 23:59:59');
        }

        $logs = $query->orderBy('created_at', 'desc')
            ->paginate(50);

        // Enrichissement user_id -> user sans eager loading de relation Eloquent
        $userIds = $logs->getCollection()->pluck('user_id')->unique()->filter()->values();
        $usersById = $userIds->isNotEmpty()
            ? User::whereIn('id', $userIds)->get()->keyBy('id')
            : collect();

        $logs->getCollection()->transform(function ($log) use ($usersById) {
            $log->setRelation('user', $log->user_id && $usersById->has($log->user_id)
                ? $usersById->get($log->user_id)
                : null);
            return $log;
        });

        return response()->json(['audit_logs' => $logs]);
    }
}