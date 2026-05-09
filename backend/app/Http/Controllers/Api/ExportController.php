<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Mission;
use App\Models\Prestataire;
use App\Services\ExportService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Maatwebsite\Excel\Facades\Excel;

class ExportController extends Controller
{
    protected $exportService;

    public function __construct(ExportService $exportService)
    {
        $this->exportService = $exportService;
    }

    public function exportMissionsExcel(Request $request)
    {
        return $this->exportService->exportMissionsExcel($request->all(), Auth::user());
    }

    public function exportMissionsPdf(Request $request)
    {
        return $this->exportService->exportMissionsPdf($request->all(), Auth::user());
    }

    public function exportDepensesExcel(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (! $user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        $anneeCourante = now()->year;
        // Sert uniquement au nom de fichier export (évite l'erreur "undefined variable")
        $date = now()->format('Y-m-d_H-i-s');

        // Colonnes missions : destination, type_mission, budget_previsionnel (pas direction/service/budget_max)
        $depenses = Mission::selectRaw('
                missions.destination,
                missions.type_mission,
                reservations.type,
                COUNT(DISTINCT missions.id) as nb_missions,
                SUM(COALESCE(missions.budget_previsionnel, 0)) as montant_prevu,
                SUM(COALESCE(reservations.montant_reel, reservations.montant_estime, 0)) as montant_reel
            ')
            ->join('reservations', 'missions.id', '=', 'reservations.mission_id')
            ->whereYear('missions.created_at', $anneeCourante)
            ->where('missions.statut', 'approuve')
            ->where('reservations.statut', 'confirme')
            ->groupBy('missions.destination', 'missions.type_mission', 'reservations.type')
            ->orderBy('missions.destination')
            ->orderBy('missions.type_mission')
            ->get();

        // Logger l'export (ne doit jamais bloquer l'export)
        // audit_logs.module est un ENUM limité (voir migration). On mappe "dépenses" -> "budget".
        try {
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'export',
                'module' => 'budget',
                'description' => 'Export Excel dépenses par direction',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);
        } catch (\Throwable $e) {
            // ignore : l'export doit continuer même si audit_logs échoue
        }

        // Stream the CSV response
        return response()->streamDownload(function () use ($depenses) {
            $file = fopen('php://output', 'w');
            // Add UTF-8 BOM so Excel reads French accents correctly
            fwrite($file, "\xEF\xBB\xBF");
            // CSV Headers
            fputcsv($file, ['Direction', 'Service', 'Type dépense', 'Nombre de missions', 'Montant prévu', 'Montant réel consommé'], ';');

            foreach ($depenses as $d) {
                fputcsv($file, [
                    $d->destination,
                    $d->type_mission,
                    $d->type,
                    $d->nb_missions,
                    $d->montant_prevu,
                    $d->montant_reel,
                ], ';');
            }
            fclose($file);
        }, "depenses_{$date}.csv", [
            'Content-Type' => 'text/csv',
        ]);
    }

    public function exportPrestatairesExcel(Request $request)
    {
        $user = Auth::user();

        // Admin seulement
        if (! $user->hasRole('admin')) {
            return response()->json(['error' => 'Accès non autorisé'], 403);
        }

        // Sert uniquement au nom de fichier export (évite l'erreur "undefined variable")
        $date = now()->format('Y-m-d_H-i-s');

        // Récupérer les prestataires avec stats (compatible ONLY_FULL_GROUP_BY)
        $prestataires = Prestataire::selectRaw('
                prestataires.id,
                prestataires.nom,
                prestataires.type,
                prestataires.ville,
                prestataires.note_performance,
                COUNT(reservations.id) as nb_reservations,
                COALESCE(AVG(COALESCE(reservations.montant_reel, reservations.montant_estime)), 0) as montant_moyen,
                MAX(reservations.created_at) as derniere_utilisation,
                SUM(COALESCE(reservations.montant_reel, reservations.montant_estime, 0)) as montant_total
            ')
            ->leftJoin('reservations', 'prestataires.id', '=', 'reservations.prestataire_id')
            ->where('reservations.statut', 'confirme')
            ->groupBy(
                'prestataires.id',
                'prestataires.nom',
                'prestataires.type',
                'prestataires.ville',
                'prestataires.note_performance'
            )
            ->orderBy('nb_reservations', 'desc')
            ->get()
            ->map(function ($prestataire) {
                return [
                    'nom' => $prestataire->nom,
                    'type' => $prestataire->type,
                    'ville' => $prestataire->ville,
                    'note_performance' => $prestataire->note_performance ?? 0,
                    'nb_reservations' => $prestataire->nb_reservations,
                    'montant_total' => $prestataire->montant_total,
                    'derniere_utilisation' => $prestataire->derniere_utilisation ?
                        Carbon::parse($prestataire->derniere_utilisation)->format('d/m/Y') : 'Jamais',
                ];
            });

        // Logger l'export (ne doit jamais bloquer l'export)
        // audit_logs.module est un ENUM limité. On mappe "prestataires" -> "reservation".
        try {
            AuditLog::create([
                'user_id' => $user->id,
                'action' => 'export',
                'module' => 'reservation',
                'description' => 'Export Excel prestataires - '.$prestataires->count().' enregistrements',
                'ip_address' => $request->ip(),
                'user_agent' => $request->userAgent(),
            ]);
        } catch (\Throwable $e) {
            // ignore : l'export doit continuer même si audit_logs échoue
        }

        // Stream the CSV response
        return response()->streamDownload(function () use ($prestataires) {
            $file = fopen('php://output', 'w');
            // Add UTF-8 BOM so Excel reads French accents correctly
            fwrite($file, "\xEF\xBB\xBF");
            // CSV Headers
            fputcsv($file, ['Nom', 'Type', 'Ville', 'Note performance', 'Nombre de réservations', 'Montant total (MAD)', 'Dernière utilisation'], ';');

            foreach ($prestataires as $p) {
                fputcsv($file, [
                    $p['nom'],
                    $p['type'],
                    $p['ville'],
                    $p['note_performance'].'/5',
                    $p['nb_reservations'],
                    $p['montant_total'],
                    $p['derniere_utilisation'],
                ], ';');
            }
            fclose($file);
        }, "prestataires_{$date}.csv", [
            'Content-Type' => 'text/csv',
        ]);
    }
}
