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
            'total_users' => User::count(),
            'total_missions' => Mission::count(),
            'total_reservations' => Reservation::count(),
        ];

        return response()->json([
            'status' => 'ok',
            'timestamp' => now()->format('d/m/Y H:i:s'),
            'version' => config('at-reservations.version', '1.0.0'),
            'project' => config('at-reservations.nom_projet', 'AT Réservations - Algérie Télécom'),
            'checks' => $checks,
            'stats' => $stats,
        ]);
    }
}
