<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Budget;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\Prestataire;
use App\Models\Reservation;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

/**
 * H-03 fix : statistiques admin globales
 * Endpoints :
 *   GET /admin/statistiques            agrégat dashboard
 *   GET /admin/statistiques/missions   detail par statut + direction + evolution
 *   GET /admin/statistiques/prestataires  top + utilisation par type
 */
class AdminStatistiquesController extends Controller
{
    private function ensureAdmin()
    {
        $user = Auth::user();
        if (! $user || ! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }
        return null;
    }

    public function index(Request $request)
    {
        if ($block = $this->ensureAdmin()) {
            return $block;
        }

        // Compteurs missions par statut (1 seule requete)
        $mc = Mission::selectRaw(
            "COUNT(*) as total,
             SUM(statut = 'brouillon') as brouillon,
             SUM(statut = 'soumis') as soumises,
             SUM(statut = 'en_validation') as en_validation,
             SUM(statut = 'approuve') as approuvees,
             SUM(statut = 'rejete') as rejetees,
             SUM(statut = 'en_traitement_logistique') as en_traitement_logistique,
             SUM(statut = 'termine') as terminees,
             SUM(statut = 'annule') as annulees"
        )->first();

        // Budget total demandé vs approuvé
        $budgets = Budget::where('annee', now()->year)->get();
        $totalAlloue = (float) $budgets->sum('montant_alloue');
        $totalConsomme = (float) $budgets->sum('montant_consomme');

        // Missions du mois en cours
        $missionsMois = Mission::whereYear('created_at', now()->year)
            ->whereMonth('created_at', now()->month)
            ->count();

        // Temps moyen de validation (jours entre soumission et 1ere approbation)
        $tempsValidation = CircuitValidation::where('statut', 'approuve')
            ->whereNotNull('date_validation')
            ->selectRaw('AVG(TIMESTAMPDIFF(HOUR, created_at, date_validation)) as heures')
            ->value('heures');
        $tempsValidationJours = $tempsValidation
            ? round($tempsValidation / 24, 1)
            : null;

        return ApiResponse::success([
            'missions' => [
                'total' => (int) ($mc->total ?? 0),
                'brouillon' => (int) ($mc->brouillon ?? 0),
                'soumises' => (int) ($mc->soumises ?? 0),
                'en_validation' => (int) ($mc->en_validation ?? 0),
                'approuvees' => (int) ($mc->approuvees ?? 0),
                'rejetees' => (int) ($mc->rejetees ?? 0),
                'en_traitement_logistique' => (int) ($mc->en_traitement_logistique ?? 0),
                'terminees' => (int) ($mc->terminees ?? 0),
                'annulees' => (int) ($mc->annulees ?? 0),
                'mois_en_cours' => $missionsMois,
            ],
            'budgets' => [
                'total_alloue' => $totalAlloue,
                'total_consomme' => $totalConsomme,
                'total_restant' => $totalAlloue - $totalConsomme,
                'pourcentage' => $totalAlloue > 0
                    ? round(($totalConsomme / $totalAlloue) * 100, 1)
                    : 0,
                'nombre_budgets' => $budgets->count(),
            ],
            'utilisateurs' => [
                'total' => \App\Models\User::count(),
                'actifs' => \App\Models\User::where('is_active', true)->count(),
            ],
            'workflow' => [
                'temps_validation_moyen_jours' => $tempsValidationJours,
            ],
        ]);
    }

    public function missions(Request $request)
    {
        if ($block = $this->ensureAdmin()) {
            return $block;
        }

        // Missions par direction
        $parDirection = Mission::join('users', 'missions.user_id', '=', 'users.id')
            ->selectRaw('users.direction as direction, COUNT(*) as total')
            ->groupBy('users.direction')
            ->orderByDesc('total')
            ->get()
            ->map(fn ($r) => [
                'direction' => $r->direction ?: 'Non assignée',
                'total' => (int) $r->total,
            ]);

        // Top 5 destinations
        $topDestinations = Mission::selectRaw('destination_ville as ville, COUNT(*) as total')
            ->whereNotNull('destination_ville')
            ->groupBy('destination_ville')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn ($r) => [
                'ville' => $r->ville,
                'total' => (int) $r->total,
            ]);

        // Évolution mensuelle sur 12 derniers mois
        $evolution = Mission::selectRaw(
            'YEAR(created_at) as annee,
             MONTH(created_at) as mois,
             COUNT(*) as total,
             SUM(statut = "approuve") as approuvees,
             SUM(statut = "rejete") as rejetees'
        )
            ->where('created_at', '>=', now()->subYear())
            ->groupBy('annee', 'mois')
            ->orderBy('annee')
            ->orderBy('mois')
            ->get()
            ->map(function ($r) {
                $date = Carbon::create((int) $r->annee, (int) $r->mois, 1);
                return [
                    'mois' => $date->format('M Y'),
                    'total' => (int) $r->total,
                    'approuvees' => (int) $r->approuvees,
                    'rejetees' => (int) $r->rejetees,
                ];
            });

        return ApiResponse::success([
            'par_direction' => $parDirection,
            'top_destinations' => $topDestinations,
            'evolution_mensuelle' => $evolution,
        ]);
    }

    public function prestataires(Request $request)
    {
        if ($block = $this->ensureAdmin()) {
            return $block;
        }

        $top = Prestataire::withCount(['reservations' => function ($q) {
            $q->where('statut', 'confirme');
        }])
            ->orderByDesc('reservations_count')
            ->limit(5)
            ->get()
            ->map(fn ($p) => [
                'id' => $p->id,
                'nom' => $p->nom,
                'type' => $p->type ?? null,
                'nb_reservations' => (int) $p->reservations_count,
            ]);

        $parType = Reservation::selectRaw('type, COUNT(*) as total, SUM(montant_estime) as montant')
            ->groupBy('type')
            ->get()
            ->map(fn ($r) => [
                'type' => $r->type,
                'total' => (int) $r->total,
                'montant_total' => (float) $r->montant,
            ]);

        return ApiResponse::success([
            'top_prestataires' => $top,
            'reservations_par_type' => $parType,
            'total_prestataires' => Prestataire::count(),
        ]);
    }
}
