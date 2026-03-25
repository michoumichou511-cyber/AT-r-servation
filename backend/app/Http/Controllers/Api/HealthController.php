<?php

namespace App\Http\Controllers\Api;

use App\Models\Mission;
use App\Models\Reservation;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class HealthController extends Controller
{
    /**
     * Santé applicative (JSON). Pour un healthcheck minimal sans logique métier, Laravel expose aussi GET /up (voir bootstrap/app.php).
     */
    public function check(Request $request)
    {
        $checks = [
            'database' => 'error',
            'storage' => 'error',
            'cache' => 'error',
        ];
        try {
            DB::connection()->getPdo();
            $checks['database'] = 'ok';
        } catch (\Exception $e) {
        }
        try {
            $checks['storage'] = Storage::exists('public') ? 'ok' : 'error';
        } catch (\Exception $e) {
        }
        try {
            Cache::put('health_test', 'ok', 1);
            $checks['cache'] = Cache::get('health_test') === 'ok' ? 'ok' : 'error';
        } catch (\Exception $e) {
        }

        $stats = [
            'total_users' => null,
            'total_missions' => null,
            'total_reservations' => null,
        ];
        if ($checks['database'] === 'ok') {
            try {
                $stats['total_users'] = User::count();
                $stats['total_missions'] = Mission::count();
                $stats['total_reservations'] = Reservation::count();
            } catch (\Throwable $e) {
                // Schéma incomplet ou erreur SQL : ne pas faire échouer le healthcheck HTTP (ex. Railway).
            }
        }

        $overall = $checks['database'] === 'ok' ? 'ok' : 'degraded';

        return response()->json([
            'status' => $overall,
            'timestamp' => now()->format('d/m/Y H:i:s'),
            'version' => config('at-reservations.version', '1.0.0'),
            'project' => config('at-reservations.nom_projet', 'AT Réservations - Algérie Télécom'),
            'checks' => $checks,
            'stats' => $stats,
        ]);
    }
}
