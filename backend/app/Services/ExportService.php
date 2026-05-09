<?php

namespace App\Services;

use App\Models\AuditLog;
use App\Models\Mission;
use Barryvdh\DomPDF\Facade\Pdf;

class ExportService
{
    public function exportMissionsExcel($filters, $user)
    {
        $query = $this->getFilteredMissionsQuery($filters, $user);
        $missions = $query->get();

        $this->logExport('mission', "Export Excel missions - {$missions->count()} enregistrements", $user);

        $date = now()->format('Y-m-d');

        return \Maatwebsite\Excel\Facades\Excel::download(
            new \App\Exports\MissionsExport($missions),
            "missions_{$date}.xlsx"
        );
    }

    public function exportMissionsPdf($filters, $user)
    {
        $query = $this->getFilteredMissionsQuery($filters, $user);
        $missions = $query->get();

        $totalBudgetPrevu = $missions->sum('budget_previsionnel');
        $totalBudgetReel = $missions->sum(function ($mission) {
            return $mission->reservations->where('statut', 'confirme')->sum('montant_estime');
        });

        $this->logExport('mission', "Export PDF missions - {$missions->count()} enregistrements", $user);

        return Pdf::loadView('pdf.rapport_missions', [
            'missions' => $missions,
            'date_debut' => $filters['date_debut'] ?? null,
            'date_fin' => $filters['date_fin'] ?? null,
            'total_budget_prevu' => $totalBudgetPrevu,
            'total_budget_reel' => $totalBudgetReel,
            'date_generation' => now()->format('d/m/Y H:i'),
            'user' => $user,
        ])->download('rapport_missions_'.now()->format('Y-m-d').'.pdf');
    }

    private function getFilteredMissionsQuery($filters, $user)
    {
        $query = Mission::with(['user', 'reservations']);

        if (! empty($filters['statut'])) {
            $query->where('statut', $filters['statut']);
        }
        if (! empty($filters['direction'])) {
            $query->where('destination', $filters['direction']);
        }
        if (! empty($filters['date_debut'])) {
            $query->where('date_depart', '>=', $filters['date_debut']);
        }
        if (! empty($filters['date_fin'])) {
            $query->where('date_retour', '<=', $filters['date_fin']);
        }

        if (! $user->hasRole('admin')) {
            $query->where('user_id', $user->id);
        }

        return $query;
    }

    private function logExport($module, $description, $user)
    {
        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'export',
            'module' => $module,
            'description' => $description,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
        ]);
    }
}
