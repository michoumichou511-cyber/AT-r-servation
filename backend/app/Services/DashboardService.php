<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\Budget;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\NotificationCustom;
use App\Models\Prestataire;
use App\Models\Reservation;
use App\Models\User;
use Carbon\Carbon;

class DashboardService
{
    /**
     * Récupérer les statistiques globales selon le rôle de l'utilisateur.
     */
    public function getStats($user)
    {
        $isAdmin = $user->hasRole('admin');
        $isValidateur = $user->hasRole('validateur');

        $stats = [];

        // 1. Chiffres clés
        $missionsQuery = $this->getMissionsQueryForUser($user);
        $reservationsQuery = $this->getReservationsQueryForUser($user);
        $notificationsQuery = NotificationCustom::where('user_id', $user->id);

        // 1 seule requête pour tous les compteurs missions (au lieu de 7 COUNT séparés).
        // "Approuvées" inclut les états POST-approbation (traitement logistique,
        // terminé) : une mission approuvée puis traitée par la DML restait
        // approuvée aux yeux du demandeur — le compteur retombait à 0 sinon.
        $mc = (clone $missionsQuery)->selectRaw("
            COUNT(*) as total,
            SUM(statut = 'brouillon') as brouillon,
            SUM(statut = 'soumis') as soumises,
            SUM(statut = 'en_validation') as en_validation,
            SUM(statut IN ('approuve', 'en_traitement_logistique', 'termine')) as approuvees,
            SUM(statut = 'rejete') as rejetees,
            SUM(statut = 'termine') as terminees
        ")->first();

        $stats['missions'] = [
            'total' => (int) ($mc->total ?? 0),
            'brouillon' => (int) ($mc->brouillon ?? 0),
            'soumises' => (int) ($mc->soumises ?? 0),
            'en_validation' => (int) ($mc->en_validation ?? 0),
            'approuvees' => (int) ($mc->approuvees ?? 0),
            'rejetees' => (int) ($mc->rejetees ?? 0),
            'terminees' => (int) ($mc->terminees ?? 0),
        ];

        // 1 seule requête pour les compteurs réservations (au lieu de 2 COUNT séparés)
        $rc = (clone $reservationsQuery)->selectRaw("
            COUNT(*) as total,
            SUM(statut = 'confirme') as confirmees
        ")->first();

        $stats['reservations'] = [
            'total' => (int) ($rc->total ?? 0),
            'confirmees' => (int) ($rc->confirmees ?? 0),
        ];

        $stats['notifications_non_lues'] = $notificationsQuery->where('lue', false)->count();

        // 2. Missions par mois
        $stats['missions_par_mois'] = $this->getMissionsParMois($user, $isAdmin, $isValidateur);

        // 3. Dépenses par type
        $stats['depenses_par_type'] = $this->getDepensesParType($user, $isAdmin, $isValidateur);

        // 4. Top 5 prestataires
        $stats['top_prestataires'] = $this->getTopPrestataires();

        // 5. Budgets ou Stats Validateur
        $stats['budgets'] = $this->getBudgetsOrValidatorStats($user, $isAdmin, $isValidateur);

        // 6. Activité récente
        $stats['activite_recente'] = $this->getActiviteRecente($user, $isAdmin);

        return $stats;
    }

    private function getMissionsQueryForUser($user)
    {
        if ($user->hasRole('admin')) {
            return Mission::query();
        }
        if ($user->hasRole('validateur')) {
            return Mission::whereHas('circuitsValidation', function ($q) use ($user) {
                $q->where('validateur_id', $user->id);
            });
        }

        return Mission::where('user_id', $user->id);
    }

    private function getReservationsQueryForUser($user)
    {
        if ($user->hasRole('admin')) {
            return Reservation::query();
        }

        return Reservation::whereHas('mission', function ($q) use ($user) {
            if ($user->hasRole('validateur')) {
                $q->whereHas('circuitsValidation', function ($cq) use ($user) {
                    $cq->where('validateur_id', $user->id);
                });
            } else {
                $q->where('user_id', $user->id);
            }
        });
    }

    private function getMissionsParMois($user, $isAdmin, $isValidateur)
    {
        return Mission::selectRaw('MONTH(created_at) as mois, YEAR(created_at) as annee, COUNT(*) as total')
            ->selectRaw('SUM(CASE WHEN statut = "approuve" THEN 1 ELSE 0 END) as approuvees')
            ->selectRaw('SUM(CASE WHEN statut = "rejete" THEN 1 ELSE 0 END) as rejetees')
            ->where('created_at', '>=', now()->subYear())
            ->when(! $isAdmin, function ($q) use ($user, $isValidateur) {
                if ($isValidateur) {
                    return $q->whereHas('circuitsValidation', function ($mq) use ($user) {
                        $mq->where('validateur_id', $user->id);
                    });
                } else {
                    return $q->where('user_id', $user->id);
                }
            })
            ->groupBy('annee', 'mois')
            ->orderBy('annee')
            ->orderBy('mois')
            ->get()
            ->map(function ($item) {
                $date = Carbon::create($item->annee, $item->mois, 1);

                return [
                    'mois' => $date->format('M Y'),
                    'total' => $item->total,
                    'approuvees' => $item->approuvees,
                    'rejetees' => $item->rejetees,
                ];
            });
    }

    private function getDepensesParType($user, $isAdmin, $isValidateur)
    {
        $depenses = Reservation::selectRaw('type, SUM(montant_reel) as montant')
            ->where('statut', 'confirme')
            ->when(! $isAdmin, function ($q) use ($user, $isValidateur) {
                if ($isValidateur) {
                    return $q->whereHas('mission.circuitsValidation', function ($mq) use ($user) {
                        $mq->where('validateur_id', $user->id);
                    });
                } else {
                    return $q->whereHas('mission', function ($mq) use ($user) {
                        $mq->where('user_id', $user->id);
                    });
                }
            })
            ->groupBy('type')
            ->get();

        $total = $depenses->sum('montant');

        return $depenses->map(function ($item) use ($total) {
            return [
                'type' => $item->type,
                'montant' => $item->montant,
                'pourcentage' => $total > 0 ? round(($item->montant / $total) * 100, 1) : 0,
            ];
        });
    }

    private function getTopPrestataires()
    {
        return Prestataire::withCount(['reservations' => function ($q) {
            $q->where('statut', 'confirme');
        }])
            ->orderBy('reservations_count', 'desc')
            ->limit(5)
            ->get()
            ->map(function ($p) {
                return [
                    'nom' => $p->nom,
                    'nb_reservations' => $p->reservations_count,
                ];
            });
    }

    private function getBudgetsOrValidatorStats($user, $isAdmin, $isValidateur)
    {
        if ($isAdmin) {
            return Budget::where('annee', now()->year)->get();
        }

        if ($isValidateur) {
            return [
                'en_attente' => CircuitValidation::where('validateur_id', $user->id)->where('statut', 'en_attente')->count(),
                'approuvees' => CircuitValidation::where('validateur_id', $user->id)->where('statut', 'approuve')->count(),
                'rejetees' => CircuitValidation::where('validateur_id', $user->id)->where('statut', 'rejete')->count(),
            ];
        }

        return null;
    }

    private function mapAuditActionToType($action, $module)
    {
        if ($module === 'mission') {
            return match ($action) {
                'create' => 'mission_creee',
                'update' => 'mission_maj',
                'delete' => 'mission_supprimee',
                default => 'activite'
            };
        }

        if ($module === 'reservation') {
            return match ($action) {
                'create' => 'reservation_creee',
                'update' => 'reservation_maj',
                default => 'activite'
            };
        }

        return $action;
    }

    private function getActiviteRecente($user, $isAdmin)
    {
        $query = AuditLog::query()->orderBy('created_at', 'desc')->limit(10);
        if (! $isAdmin) {
            $query->where('user_id', $user->id);
        }

        $logs = $query->get();
        $userIds = $logs->pluck('user_id')->unique()->filter()->values();
        $usersById = $userIds->isNotEmpty()
            ? User::whereIn('id', $userIds)->get()->keyBy('id')
            : collect();

        return $logs->map(function ($log) use ($usersById) {
            $type = $this->mapAuditActionToType($log->action, $log->module);
            $u = $log->user_id ? ($usersById->get($log->user_id)) : null;

            return [
                'type' => $type,
                'description' => $log->description,
                // created_at peut être NULL si les inserts ne le renseignent pas.
                'date' => $log->created_at ? $log->created_at->diffForHumans() : 'N/A',
                'icon' => $this->getActivityIcon($type),
                'par' => $u ? ($u->nom_complet ?? 'Utilisateur') : 'Système',
            ];
        });
    }

    private function getActivityIcon($type)
    {
        return match ($type) {
            'mission_creee' => 'plus-circle',
            'mission_maj' => 'edit-3',
            'mission_supprimee' => 'trash-2',
            'reservation_creee' => 'briefcase',
            default => 'activity'
        };
    }
}
