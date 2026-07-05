<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Mail\MissionApprouvee;
use App\Mail\MissionRejetee;
use App\Models\AuditLog;
use App\Models\BonCommande;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\NotificationCustom;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Mail;

class ValidationController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();

        // Seulement validateur et admin
        if (! in_array($user->role->name, ['validateur', 'admin'])) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $query = CircuitValidation::where('statut', 'en_attente')
            ->with(['mission' => function ($q) {
                $q->with(['user', 'reservations']);
            }, 'validateur']);

        // Si validateur: voir UNIQUEMENT ses validations
        if ($user->role->name === 'validateur') {
            $query->where('validateur_id', $user->id);
        }
        // Si admin: voir toutes les validations

        // Filtres optionnels
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        if ($request->has('direction')) {
            $query->whereHas('mission.user', function ($q) {
                $q->where('direction', $request->direction);
            });
        }
        if ($request->has('date_debut')) {
            $query->whereHas('mission', function ($q) {
                $q->where('date_depart', '>=', $request->date_debut);
            });
        }
        if ($request->has('date_fin')) {
            $query->whereHas('mission', function ($q) {
                $q->where('date_retour', '<=', $request->date_fin);
            });
        }

        // Tri par ordre_validation et created_at
        $validations = $query->orderBy('ordre_validation', 'asc')
            ->orderBy('created_at', 'asc')
            ->paginate(15);

        // Enrichir les données
        $validations->getCollection()->transform(function ($validation) {
            $jours_en_attente = $validation->created_at->diffInDays(now());

            return [
                'id' => $validation->id,
                'mission' => [
                    'numero_unique' => $validation->mission->numero_unique,
                    'titre' => $validation->mission->titre,
                    'destination' => $validation->mission->destination,
                    'dates' => [
                        'depart' => $validation->mission->date_depart->format('d/m/Y'),
                        'retour' => $validation->mission->date_retour->format('d/m/Y'),
                    ],
                    'budget_previsionnel' => number_format($validation->mission->budget_previsionnel ?? 0, 2, ',', ' ').' DA',
                ],
                'demandeur' => [
                    'nom_complet' => $validation->mission->user->prenom.' '.$validation->mission->user->nom,
                    'matricule' => $validation->mission->user->matricule,
                    'service' => $validation->mission->user->service,
                    'direction' => $validation->mission->user->direction,
                ],
                'ordre_validation' => $validation->ordre_validation,
                'statut' => $validation->statut,
                'jours_en_attente' => $jours_en_attente,
                'created_at' => $validation->created_at->format('d/m/Y H:i:s'),
            ];
        });

        return \App\Helpers\ApiResponse::paginated($validations, 'Liste des validations à traiter');
    }

    public function show(Request $request, $id)
    {
        $validation = CircuitValidation::with([
            'mission' => function ($q) {
                $q->with(['user', 'reservations', 'circuitsValidation.validateur', 'documents']);
            },
            'validateur',
        ])->findOrFail($id);

        // Vérifier accès
        $user = Auth::user();
        if ($user->role->name !== 'admin' && $validation->mission->user_id !== $user->id && $validation->validateur_id !== $user->id) {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        return response()->json([
            'id' => $validation->id,
            'mission' => $validation->mission,
            'validateur' => $validation->validateur,
            'ordre_validation' => $validation->ordre_validation,
            'statut' => $validation->statut,
            'commentaire' => $validation->commentaire,
            'date_validation' => $validation->date_validation?->format('d/m/Y H:i:s'),
            'created_at' => $validation->created_at->format('d/m/Y H:i:s'),
        ]);
    }

    public function approuver(Request $request, $id)
    {
        $validation = CircuitValidation::with('mission')->findOrFail($id);
        $user = Auth::user();

        // Vérifier que c'est ce validateur qui doit agir
        if ($validation->validateur_id !== $user->id && $user->role->name !== 'admin') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Vérifier statut
        if ($validation->statut !== 'en_attente') {
            return response()->json(['error' => 'Cette validation n\'est pas en attente'], 400);
        }

        $request->validate([
            'commentaire' => 'sometimes|nullable|string|max:65535',
        ]);

        $mission = $validation->mission;

        // Mettre à jour validation
        $validation->update([
            'statut' => 'approuve',
            'date_validation' => now(),
            'commentaire' => $request->commentaire,
        ]);

        // Chercher prochaine étape
        $prochaine = CircuitValidation::where('mission_id', $mission->id)
            ->where('ordre_validation', '>', $validation->ordre_validation)
            ->orderBy('ordre_validation')
            ->first();

        if ($prochaine) {
            // Il y a une prochaine étape
            $prochaine->update(['statut' => 'en_attente']);
            $mission->update(['statut' => 'en_validation']);

            // Notifier le prochain validateur
            NotificationCustom::create([
                'user_id' => $prochaine->validateur_id,
                'titre' => 'Mission à valider',
                'message' => "Mission {$mission->numero_unique} en attente de votre validation",
                'type' => 'warning',
            ]);
        } else {
            // Dernière validation
            $mission->update([
                'statut' => 'approuve',
                'approuve_par' => $user->id,
                'approuve_le' => now(),
            ]);

            // Générer les bons de commande automatiquement
            $mission->load(['reservations.billetAvion', 'reservations.hebergement', 'reservations.restauration.prestataire']);
            foreach ($mission->reservations as $reservation) {
                if ($reservation->billetAvion) {
                    BonCommande::create([
                        'numero' => BonCommande::genererNumero(),
                        'mission_id' => $mission->id,
                        'type' => 'billet',
                        'prestataire_nom' => $reservation->billetAvion->compagnie ?? 'Non défini',
                        'montant_total' => $reservation->billetAvion->prix ?? 0,
                        'statut' => 'genere',
                        'genere_par' => $user->id,
                    ]);
                }
                if ($reservation->hebergement) {
                    BonCommande::create([
                        'numero' => BonCommande::genererNumero(),
                        'mission_id' => $mission->id,
                        'type' => 'hebergement',
                        'prestataire_nom' => $reservation->hebergement->hotel_nom ?? 'Non défini',
                        'montant_total' => $reservation->hebergement->prix_total ?? 0,
                        'statut' => 'genere',
                        'genere_par' => $user->id,
                    ]);
                }
                if ($reservation->restauration) {
                    $prestataireNom = $reservation->restauration->prestataire?->nom
                        ?? $reservation->restauration->lieu
                        ?? 'Non défini';
                    BonCommande::create([
                        'numero' => BonCommande::genererNumero(),
                        'mission_id' => $mission->id,
                        'type' => 'restauration',
                        'prestataire_nom' => $prestataireNom,
                        'montant_total' => $reservation->restauration->prix_total ?? 0,
                        'statut' => 'genere',
                        'genere_par' => $user->id,
                    ]);
                }
            }

            // Notifier le demandeur
            NotificationCustom::create([
                'user_id' => $mission->user_id,
                'titre' => '✅ Mission approuvée',
                'message' => 'Votre mission a été approuvée !',
                'type' => 'success',
            ]);

            try {
                $mission->loadMissing('user');
                if ($mission->user?->email) {
                    Mail::to($mission->user->email)->queue((new MissionApprouvee($mission))->onConnection('database'));
                }
            } catch (\Exception $e) {
                \Log::error('Email approval failed: '.$e->getMessage());
            }
        }

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'approve',
            'module' => 'validation',
            'description' => "Validation approuvée pour mission {$mission->numero_unique}",
            'old_values' => ['statut' => 'en_attente'],
            'new_values' => ['statut' => 'approuve'],
        ]);

        return response()->json(['message' => 'Validation approuvée']);
    }

    public function rejeter(Request $request, $id)
    {
        $validation = CircuitValidation::with('mission')->findOrFail($id);
        $user = Auth::user();

        // Vérifier que c'est ce validateur qui doit agir
        if ($validation->validateur_id !== $user->id && $user->role->name !== 'admin') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        // Vérifier statut
        if ($validation->statut !== 'en_attente') {
            return response()->json(['error' => 'Cette validation n\'est pas en attente'], 400);
        }

        $request->validate([
            'commentaire' => 'required|string|min:10',
        ]);

        $mission = $validation->mission;

        // Mettre à jour validation
        $validation->update([
            'statut' => 'rejete',
            'date_validation' => now(),
            'commentaire' => $request->commentaire,
        ]);

        // Mettre à jour mission
        $mission->update(['statut' => 'rejete']);

        // Annuler toutes les autres étapes
        CircuitValidation::where('mission_id', $mission->id)
            ->where('statut', 'en_attente')
            ->update(['statut' => 'rejete']);

        // Notifier le demandeur
        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => '❌ Mission rejetée',
            'message' => 'Votre mission a été rejetée. Motif: '.substr($request->commentaire, 0, 50).'...',
            'type' => 'danger',
        ]);

        try {
            $mission->loadMissing('user');
            $motif = $request->commentaire;
            if ($mission->user?->email) {
                Mail::to($mission->user->email)->queue((new MissionRejetee($mission, $motif))->onConnection('database'));
            }
        } catch (\Exception $e) {
            \Log::error('Email rejection failed: '.$e->getMessage());
        }

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'reject',
            'module' => 'validation',
            'description' => "Validation rejetée pour mission {$mission->numero_unique}",
            'old_values' => ['statut' => 'en_attente'],
            'new_values' => ['statut' => 'rejete'],
        ]);

        return response()->json(['message' => 'Validation rejetée']);
    }

    public function demanderModification(Request $request, $id)
    {
        $validation = CircuitValidation::with('mission')->findOrFail($id);
        $user = Auth::user();

        // Vérifier que c'est ce validateur qui doit agir
        if ($validation->validateur_id !== $user->id && $user->role->name !== 'admin') {
            return response()->json(['error' => 'Non autorisé'], 403);
        }

        $request->validate([
            'commentaire' => 'required|string|min:10',
        ]);

        $mission = $validation->mission;

        // Mettre à jour validation et mission
        $validation->update([
            'commentaire' => $request->commentaire,
            'date_validation' => now(),
        ]);

        $mission->update(['statut' => 'brouillon']);

        // Notifier le demandeur
        NotificationCustom::create([
            'user_id' => $mission->user_id,
            'titre' => '📝 Modifications demandées',
            'message' => 'Des modifications sont demandées pour votre mission',
            'type' => 'warning',
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'request_modification',
            'module' => 'validation',
            'description' => "Modifications demandées pour mission {$mission->numero_unique}",
            'old_values' => ['statut' => 'en_validation'],
            'new_values' => ['statut' => 'brouillon'],
        ]);

        return response()->json(['message' => 'Modifications demandées']);
    }

    public function mesValidations(Request $request)
    {
        $user = Auth::user();

        $validations = CircuitValidation::where('validateur_id', $user->id)
            ->with(['mission', 'validateur'])
            ->where('statut', '!=', 'en_attente')
            ->orderBy('date_validation', 'desc')
            ->paginate(20);

        return response()->json($validations);
    }
}
