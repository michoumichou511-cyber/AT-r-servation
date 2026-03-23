<?php

namespace App\Console\Commands;

use App\Models\AuditLog;
use App\Models\Budget;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\PersonalAccessToken;

class MaintenanceSystem extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'maintenance:run {--dry-run : Exécuter en mode test sans modifications}';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Système de maintenance automatisé - Nettoyage et surveillance';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        $dryRun = $this->option('dry-run');
        $this->info($dryRun ? '🔍 MODE TEST - Aucune modification ne sera effectuée' : '🛠️  MAINTENANCE SYSTÈME - Démarrage...');

        $report = [
            'timestamp' => now()->toDateTimeString(),
            'mode' => $dryRun ? 'test' : 'production',
            'operations' => [],
        ];

        // 1. Nettoyer les tokens Sanctum expirés
        $this->info('1️⃣ Nettoyage des tokens Sanctum expirés...');
        $expiredTokens = PersonalAccessToken::where('expires_at', '<', now())->count();
        if (! $dryRun) {
            PersonalAccessToken::where('expires_at', '<', now())->delete();
        }
        $report['operations'][] = [
            'operation' => 'Tokens Sanctum expirés supprimés',
            'count' => $expiredTokens,
        ];
        $this->info("   ✅ {$expiredTokens} tokens expirés supprimés");

        // 2. Supprimer les anciennes notifications (30+ jours et lues)
        $this->info('2️⃣ Nettoyage des anciennes notifications...');
        $oldNotificationsCustom = \App\Models\NotificationCustom::where('created_at', '<', now()->subDays(30))
            ->where('is_read', true)
            ->count();

        if (! $dryRun) {
            \App\Models\NotificationCustom::where('created_at', '<', now()->subDays(30))
                ->where('is_read', true)
                ->delete();
        }

        $totalOldNotifications = $oldNotificationsCustom;
        $report['operations'][] = [
            'operation' => 'Anciennes notifications supprimées (30+ jours, lues)',
            'count' => $totalOldNotifications,
            'details' => "Custom: {$oldNotificationsCustom}",
        ];
        $this->info("   ✅ {$totalOldNotifications} anciennes notifications supprimées");

        // 3. Supprimer les anciens logs d'audit (90+ jours)
        $this->info('3️⃣ Nettoyage des anciens logs d\'audit...');
        $oldAuditLogs = AuditLog::where('created_at', '<', now()->subDays(90))->count();
        if (! $dryRun) {
            AuditLog::where('created_at', '<', now()->subDays(90))->delete();
        }
        $report['operations'][] = [
            'operation' => 'Anciens logs d\'audit supprimés (90+ jours)',
            'count' => $oldAuditLogs,
        ];
        $this->info("   ✅ {$oldAuditLogs} anciens logs d'audit supprimés");

        // 4. Vérifier les validations en retard (48+ heures)
        $this->info('4️⃣ Vérification des validations en retard...');
        $overdueValidations = DB::table('validations')
            ->join('missions', 'validations.mission_id', '=', 'missions.id')
            ->where('validations.created_at', '<', now()->subHours(48))
            ->where('validations.statut', 'en_attente')
            ->select('validations.*', 'missions.titre as mission_titre', 'missions.user_id')
            ->get();

        $overdueCount = $overdueValidations->count();
        $report['operations'][] = [
            'operation' => 'Validations en retard détectées (48+ heures)',
            'count' => $overdueCount,
            'alerts' => $overdueCount > 0 ? 'OUI' : 'NON',
        ];

        if ($overdueCount > 0) {
            $this->warn("   ⚠️  {$overdueCount} validations en retard détectées:");
            foreach ($overdueValidations->take(5) as $validation) {
                $this->warn("      - Mission: {$validation->mission_titre} (ID: {$validation->mission_id})");
            }
            if ($overdueCount > 5) {
                $this->warn('      ... et '.($overdueCount - 5).' autres');
            }
        } else {
            $this->info('   ✅ Aucune validation en retard');
        }

        // 5. Vérifier les budgets critiques (85%+ d'utilisation)
        $this->info('5️⃣ Vérification des budgets critiques...');
        $criticalBudgets = Budget::whereRaw('(montant_consomme / montant_alloue) >= 0.85')
            ->with('user')
            ->get();

        $criticalCount = $criticalBudgets->count();
        $report['operations'][] = [
            'operation' => 'Budgets critiques détectés (85%+ utilisation)',
            'count' => $criticalCount,
            'alerts' => $criticalCount > 0 ? 'OUI' : 'NON',
        ];

        if ($criticalCount > 0) {
            $this->warn("   ⚠️  {$criticalCount} budgets critiques détectés:");
            foreach ($criticalBudgets as $budget) {
                $percentage = round(($budget->montant_consomme / $budget->montant_alloue) * 100, 1);
                $this->warn("      - Budget: {$budget->user->name} - {$percentage}% utilisé");
            }
        } else {
            $this->info('   ✅ Aucun budget critique');
        }

        // 6. Générer le rapport
        $this->info('6️⃣ Génération du rapport de maintenance...');
        $this->generateReport($report);

        $this->info('');
        $this->info('🎉 Maintenance terminée avec succès!');
        $this->info('📊 Rapport sauvegardé dans storage/logs/maintenance/');

        return Command::SUCCESS;
    }

    /**
     * Génère et sauvegarde le rapport de maintenance
     */
    private function generateReport(array $report)
    {
        $logPath = storage_path('logs/maintenance');
        if (! is_dir($logPath)) {
            mkdir($logPath, 0755, true);
        }

        $filename = 'maintenance_'.date('Y-m-d_H-i-s').'.json';
        $filepath = $logPath.'/'.$filename;

        file_put_contents($filepath, json_encode($report, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $this->info("   📄 Rapport généré: {$filename}");

        // Afficher un résumé
        $this->info('');
        $this->info('📊 RÉSUMÉ DE MAINTENANCE:');
        $this->info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        foreach ($report['operations'] as $operation) {
            $count = $operation['count'];
            $alert = isset($operation['alerts']) && $operation['alerts'] === 'OUI' ? ' ⚠️' : '';
            $this->info("• {$operation['operation']}: {$count}{$alert}");
            if (isset($operation['details'])) {
                $this->info("  └─ {$operation['details']}");
            }
        }
        $this->info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
}
