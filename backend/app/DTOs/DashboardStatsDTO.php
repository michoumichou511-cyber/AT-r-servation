<?php

namespace App\DTOs;

class DashboardStatsDTO
{
    public function __construct(
        public readonly int $totalMissions,
        public readonly int $missionsEnCours,
        public readonly int $missionsApprouvees,
        public readonly int $missionsRejetees,
        public readonly float $budgetTotal,
        public readonly float $budgetConsomme,
        public readonly int $totalReservations,
        public readonly int $notificationsNonLues,
    ) {}

    public function toArray(): array
    {
        return [
            'total_missions' => $this->totalMissions,
            'missions_en_cours' => $this->missionsEnCours,
            'missions_approuvees' => $this->missionsApprouvees,
            'missions_rejetees' => $this->missionsRejetees,
            'budget_total' => $this->budgetTotal,
            'budget_consomme' => $this->budgetConsomme,
            'taux_consommation' => $this->budgetTotal > 0
                ? round(($this->budgetConsomme / $this->budgetTotal) * 100, 1)
                : 0,
            'total_reservations' => $this->totalReservations,
            'notifications_non_lues' => $this->notificationsNonLues,
        ];
    }
}
