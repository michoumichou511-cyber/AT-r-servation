<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Services\DashboardService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Schema;

class DashboardController extends Controller
{
    protected $dashboardService;

    public function __construct(DashboardService $dashboardService)
    {
        $this->dashboardService = $dashboardService;
    }

    public function stats()
    {
        $user = Auth::user();
        $userId = $user->id;
        // Cache 60 secondes par utilisateur : évite les 11+ requêtes à chaque rechargement
        $cacheKey = 'dash_stats_'.$userId;
        $data = Cache::remember($cacheKey, 60, fn () => $this->dashboardService->getStats($user));

        return response()->json($data);
    }

    public function missionsDuMois(Request $request)
    {
        $user = auth()->user();
        $userId = $user->id;
        $mois = now()->month;
        $annee = now()->year;
        $cacheKey = "dash_mois_{$userId}_{$annee}_{$mois}";

        $payload = Cache::remember($cacheKey, 300, function () use ($user, $mois, $annee) {
            $query = Mission::whereMonth('created_at', $mois)
                ->whereYear('created_at', $annee);

            if ($user->hasRole('validateur')) {
                $query->whereHas('circuitsValidation', fn ($q) => $q->where('validateur_id', $user->id));
            } elseif (! $user->hasRole('admin')) {
                $query->where('user_id', $user->id);
            }

            $missions = $query->with(['user', 'reservations'])->get();

            return [
                'total' => $missions->count(),
                'par_statut' => $missions->groupBy('statut')
                    ->map->count(),
                'missions' => $missions->map(fn ($m) => [
                    'id' => $m->id,
                    'reference' => $m->reference ?? $m->numero_unique,
                    'titre' => $m->titre,
                    'statut' => $m->statut,
                    'destination' => $m->destination_ville ?? $m->destination,
                    'date_depart' => $m->date_depart,
                    'budget' => $m->budget_previsionnel,
                ]),
            ];
        });

        return ApiResponse::success($payload);
    }

    public function depensesParDirection(Request $request)
    {
        $userId = Auth::id();
        $annee = $request->get('annee', now()->year);
        $cacheKey = "dash_dir_{$userId}_{$annee}";

        $payload = Cache::remember($cacheKey, 300, function () use ($annee) {
            try {
                $colonnes = Schema::getColumnListing('users');

                if (in_array('direction', $colonnes)) {
                    $depenses = Mission::where('missions.statut', 'approuve')
                        ->whereYear('missions.created_at', $annee)
                        ->join('users', 'missions.user_id', '=', 'users.id')
                        ->selectRaw('
                        COALESCE(users.direction, "Non défini") as direction,
                        SUM(missions.budget_previsionnel) as total,
                        COUNT(missions.id) as nb_missions
                    ')
                        ->groupBy('users.direction')
                        ->orderByDesc('total')
                        ->get();

                    return [
                        'annee' => $annee,
                        'depenses' => $depenses,
                    ];
                }

                return [
                    'annee' => $annee,
                    'depenses' => collect([
                        ['direction' => 'Non configuré', 'total' => 0, 'nb_missions' => 0],
                    ]),
                ];
            } catch (\Exception $e) {
                \Log::error('depensesParDirection: '.$e->getMessage());

                return [
                    'annee' => $annee,
                    'depenses' => [],
                ];
            }
        });

        return ApiResponse::success($payload);
    }

    public function alertes(Request $request)
    {
        $userId = Auth::id();
        $cacheKey = 'dash_alertes_'.$userId;

        $payload = Cache::remember($cacheKey, 120, function () {
            $alertes = [];

            $budgets = Budget::whereRaw('montant_alloue > 0')
                ->whereRaw('(montant_consomme / montant_alloue) * 100 >= COALESCE(alerte_seuil, 80)')
                ->select(['direction', 'montant_alloue', 'montant_consomme', 'alerte_seuil'])
                ->get();

            foreach ($budgets as $b) {
                $pct = round(($b->montant_consomme / $b->montant_alloue) * 100, 1);
                $alertes[] = [
                    'type' => 'budget',
                    'niveau' => $pct >= 95 ? 'critique' : 'attention',
                    'message' => "Budget {$b->direction} à {$pct}% consommé",
                    'direction' => $b->direction,
                    'pourcentage' => $pct,
                ];
            }

            $urgentes = Mission::where('statut', 'en_validation')
                ->where('date_depart', '>=', now())
                ->where('date_depart', '<=', now()->addDays(7))
                ->count();

            if ($urgentes > 0) {
                $alertes[] = [
                    'type' => 'validation_urgente',
                    'niveau' => 'attention',
                    'message' => "{$urgentes} mission(s) urgente(s) en attente",
                    'count' => $urgentes,
                ];
            }

            return ['alertes' => $alertes];
        });

        return ApiResponse::success($payload);
    }

    public function dashboardValidateur(Request $request)
    {
        $user = auth()->user();

        $enAttente = CircuitValidation::where('validateur_id', $user->id)
            ->where('statut', 'en_attente')
            ->with(['mission.user', 'mission.reservations'])
            ->get();

        $approuvees = CircuitValidation::where('validateur_id', $user->id)
            ->where('statut', 'approuve')
            ->count();

        $rejetees = CircuitValidation::where('validateur_id', $user->id)
            ->where('statut', 'rejete')
            ->count();

        $total = $approuvees + $rejetees;
        $taux = $total > 0 ? round(($approuvees / $total) * 100) : 0;

        return ApiResponse::success([
            'en_attente' => $enAttente->count(),
            'approuvees' => $approuvees,
            'rejetees' => $rejetees,
            'taux_approbation' => $taux,
            'missions_urgentes' => $enAttente->filter(fn ($cv) => $cv->mission &&
                $cv->mission->date_depart <= now()->addDays(7)
            )->count(),
            'liste_en_attente' => $enAttente->take(5)->map(fn ($cv) => [
                'id' => $cv->mission->id,
                'reference' => $cv->mission->reference ?? $cv->mission->numero_unique,
                'titre' => $cv->mission->titre,
                'demandeur' => $cv->mission->user ? ($cv->mission->user->nom_complet ?? '') : '',
                'date_depart' => $cv->mission->date_depart,
                'budget' => $cv->mission->budget_previsionnel,
                'urgente' => $cv->mission->date_depart <= now()->addDays(7),
            ]),
        ]);
    }
}
