<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\MissionStoreRequest;
use App\Http\Requests\MissionUpdateRequest;
use App\Http\Resources\MissionResource;
use App\Models\Budget;
use App\Models\Mission;
use App\Models\NotificationCustom;
use App\Models\User;
use App\Services\MissionService;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\Request;

class MissionController extends Controller
{
    protected $missionService;

    public function __construct(MissionService $missionService)
    {
        $this->missionService = $missionService;
    }

    public function index(Request $request)
    {
        $user = $request->user()->load('role');
        $query = Mission::query();

        $roleName = strtolower($user->role->name ?? '');

        // Accès par rôle : admin = tout ; validateur = ses missions + à valider ; autres = leurs missions
        if ($roleName === 'admin') {
            // pas de filtre utilisateur
        } elseif (str_contains($roleName, 'validateur')) {
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                    ->orWhere('pour_user_id', $user->id)
                    ->orWhere('created_by', $user->id)
                    ->orWhereHas('circuitsValidation', function ($cv) use ($user) {
                        $cv->where('validateur_id', $user->id);
                    });
            });
        } else {
            // demandeur, utilisateur, etc. : uniquement missions liées à l'utilisateur
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                    ->orWhere('pour_user_id', $user->id)
                    ->orWhere('created_by', $user->id);
            });
        }

        // Filters
        if ($request->has('statut')) {
            $query->where('statut', $request->statut);
        }
        if ($request->has('direction')) {
            $query->whereHas('user', function ($q) {
                $q->where('direction', request('direction'));
            });
        }
        if ($request->has('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->has('date_debut')) {
            $query->where('date_depart', '>=', $request->date_debut);
        }
        if ($request->has('date_fin')) {
            $query->where('date_retour', '<=', $request->date_fin);
        }
        if ($request->has('priorite')) {
            $query->where('priorite', $request->priorite);
        }
        if ($request->has('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('titre', 'like', "%$search%")
                    ->orWhere('destination', 'like', "%$search%");
            });
        }

        // Eager load
        $perPage = $request->get('per_page', 15);
        $missions = $query->with(['user', 'reservations', 'circuitsValidation'])
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return \App\Helpers\ApiResponse::paginated(
            \App\Http\Resources\MissionResource::collection($missions),
            'Liste des missions récupérée avec succès'
        );
    }

    public function store(MissionStoreRequest $request)
    {
        $validated = $request->validated();

        $user = $request->user();

        // Generate numero_unique
        $count = Mission::whereYear('created_at', now()->year)->count() + 1;
        $numero = 'OM-'.now()->year.'-'.str_pad($count, 5, '0', STR_PAD_LEFT);

        // Check budget
        $budgetWarning = null;
        if (isset($validated['budget_previsionnel'])) {
            $budget = Budget::where('direction', $user->direction)
                ->where('annee', now()->year)
                ->first();

            if ($budget) {
                $available = $budget->montant_alloue - $budget->montant_consomme;
                if ($available < $validated['budget_previsionnel']) {
                    $budgetWarning = 'Budget insuffisant. Disponible : '.$available.' DA';
                }
            }
        }

        $missionData = array_merge($validated, [
            'created_by' => $user->id,
            'numero_unique' => $numero,
            'statut' => 'brouillon',
            'destination' => ($validated['destination_ville'] ?? '').', '.($validated['destination_pays'] ?? ''),
        ]);
        if ($request->has('pour_user_id') && $request->pour_user_id) {
            $missionData['user_id'] = $request->pour_user_id;
            $missionData['pour_user_id'] = $request->pour_user_id;
        } else {
            $missionData['user_id'] = $user->id;
        }
        $mission = Mission::create($missionData);

        // INSERT en masse pour notifier tous les admins (1 seule requête au lieu de N)
        $adminIds = User::whereHas('role', fn ($q) => $q->where('name', 'admin'))->pluck('id');
        if ($adminIds->isNotEmpty()) {
            $now = now();
            NotificationCustom::insert($adminIds->map(fn ($adminId) => [
                'user_id' => $adminId,
                'titre' => 'Nouvelle mission',
                'message' => "Mission {$numero} créée par {$user->prenom} {$user->nom}",
                'type' => 'info',
                'lue' => false,
                'is_read' => false,
                'created_at' => $now,
                'updated_at' => $now,
            ])->all());
        }

        return \App\Helpers\ApiResponse::success(
            [
                'id' => $mission->id,
                'reference' => $mission->numero_unique ?? $mission->reference ?? null,
                'titre' => $mission->titre,
                'statut' => $mission->statut,
                'mission' => $mission->load(['user', 'reservations']),
            ],
            'Mission créée avec succès',
            201
        );
    }

    public function show(Request $request, $id)
    {
        $user = $request->user();
        $mission = Mission::with([
            'user',
            'reservations.prestataire',
            'circuitsValidation.validateur',
            'documents',
        ])->findOrFail($id);

        // Check access
        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $budgetConsomme = $mission->reservations->sum('montant_reel');

        return response()->json([
            'success' => true,
            'data' => MissionResource::make($mission),
            'budget_consomme' => $budgetConsomme,
        ], 200);
    }

    public function update(MissionUpdateRequest $request, $id)
    {
        $mission = Mission::findOrFail($id);
        $user = $request->user();

        // Check status
        if ($mission->statut !== 'brouillon') {
            return response()->json([
                'success' => false,
                'message' => 'Seules les missions en brouillon peuvent être modifiées',
            ], 403);
        }

        // Check creator or admin
        if ($user->role->name !== 'admin' && $mission->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $oldValues = $mission->only(['titre', 'objet_mission', 'destination_ville', 'destination_pays', 'date_depart', 'date_retour', 'type_mission', 'priorite', 'budget_previsionnel']);

        $validated = $request->validated();

        $mission->update(array_filter($validated));

        return response()->json([
            'success' => true,
            'message' => 'Mission mise à jour',
            'data' => new MissionResource($mission->load('user')),
        ], 200);
    }

    public function destroy(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);
        $user = $request->user();

        if ($user->role->name !== 'admin' && $mission->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $numero = $mission->numero_unique;
        $mission->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mission supprimée',
        ], 200);
    }

    public function submit(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);
        $user = $request->user();

        try {
            $mission = $this->missionService->submit($mission);

            return response()->json([
                'success' => true,
                'message' => 'Mission soumise pour validation',
                'data' => new MissionResource($mission->load('user', 'circuitsValidation')),
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    public function cancel(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);

        try {
            $this->missionService->cancel($mission);

            return response()->json([
                'success' => true,
                'message' => 'Mission annulée',
            ], 200);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    public function duplicate(Request $request, $id)
    {
        $mission = Mission::findOrFail($id);

        try {
            $copy = $this->missionService->duplicate($mission);

            return response()->json([
                'success' => true,
                'message' => 'Mission dupliquée',
                'data' => new MissionResource($copy->load('user')),
            ], 201);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    public function exportPdf(Request $request, $id)
    {
        $mission = Mission::with([
            'user',
            'reservations.prestataire',
            'circuitsValidation.validateur',
        ])->findOrFail($id);

        $user = $request->user();
        if ($user->role->name === 'utilisateur' && $mission->user_id !== $user->id) {
            return response()->json(['success' => false, 'message' => 'Non autorisé'], 403);
        }

        $budgetConsomme = $mission->reservations->sum('montant_reel');

        $pdf = Pdf::loadView('pdf.ordre_mission', [
            'mission' => $mission,
            'budgetConsomme' => $budgetConsomme,
        ]);

        return $pdf->download('ordre_mission_'.$mission->numero_unique.'.pdf');
    }

    public function historique($id)
    {
        $mission = Mission::findOrFail($id);
        $timeline = $this->missionService->getTimeline($mission);

        return response()->json($timeline);
    }

    public function calendrier(Request $request)
    {
        $mois = $request->input('mois');
        $annee = $request->input('annee');
        $user = $request->user();
        $query = Mission::query();
        if (! $user->hasRole('admin')) {
            $query->where('user_id', $user->id);
        }
        $missions = $query->whereMonth('date_depart', $mois)
            ->whereYear('date_depart', $annee)
            ->get();
        $events = [];
        foreach ($missions as $mission) {
            $events[] = [
                'id' => $mission->id,
                'title' => $mission->numero_unique.' - '.$mission->destination_ville,
                'start' => $mission->date_depart->format('Y-m-d'),
                'end' => $mission->date_retour->format('Y-m-d'),
                'color' => config('at-reservations.couleur_principale'),
                'backgroundColor' => config('at-reservations.couleur_principale'),
                'status' => $mission->statut,
                'url' => '/missions/'.$mission->id,
            ];
        }

        return response()->json(['events' => $events]);
    }
}
