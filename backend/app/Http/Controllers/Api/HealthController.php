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
        $dbDiagnostic = null;
        try {
            DB::connection()->getPdo();
            $checks['database'] = 'ok';
        } catch (\Exception $e) {
            $dbDiagnostic = $this->diagnosticBase($e);
        }
        try {
            // Disque "public" (storage/app/public) : doit exister et être accessible en écriture
            $checks['storage'] = is_writable(Storage::disk('public')->path('')) ? 'ok' : 'error';
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
        // Statistiques métier : réservées à un admin authentifié (route publique sinon)
        $viewer = auth('sanctum')->user();
        if ($checks['database'] === 'ok' && $viewer?->isAdmin()) {
            try {
                $stats['total_users'] = User::count();
                $stats['total_missions'] = Mission::count();
                $stats['total_reservations'] = Reservation::count();
            } catch (\Throwable $e) {
                // Schéma incomplet ou erreur SQL : ne pas faire échouer le healthcheck HTTP.
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
        ] + ($dbDiagnostic ? ['database_diagnostic' => $dbDiagnostic] : []));
    }

    /**
     * Cause probable de l'échec MySQL, sans jamais exposer l'hôte, l'utilisateur ni le message brut.
     */
    private function diagnosticBase(\Throwable $e): array
    {
        $code = null;
        for ($x = $e; $x; $x = $x->getPrevious()) {
            if (preg_match('/SQLSTATE\[\w+\] \[(\d+)\]/', $x->getMessage(), $m)) {
                $code = (int) $m[1];
                break;
            }
            if (is_int($x->getCode()) && $x->getCode() > 0) {
                $code = $x->getCode();
            }
        }
        $ssl = stripos($e->getMessage(), 'ssl') !== false || stripos($e->getMessage(), 'certificate') !== false;

        $cause = match (true) {
            $ssl, in_array($code, [2026, 3159], true) => 'certificat SSL (variable MYSQL_CA_CERT)',
            $code === 2002 => 'serveur injoignable : hôte ou port faux, ou base éteinte',
            $code === 2005 => 'hôte inconnu : DB_HOST mal recopié',
            $code === 1045 => 'identifiant ou mot de passe refusé (DB_USERNAME / DB_PASSWORD)',
            $code === 1044 => 'utilisateur sans droit sur cette base',
            $code === 1049 => 'nom de base inconnu (DB_DATABASE)',
            $code === 2006, $code === 2013 => 'connexion coupée par le serveur (base éteinte ou surchargée)',
            default => 'autre erreur',
        };

        $host = (string) config('database.connections.mysql.host');

        return [
            'code_mysql' => $code,
            'cause_probable' => $cause,
            'driver' => config('database.default'),
            'hote_local' => in_array($host, ['', '127.0.0.1', 'localhost'], true),
            'certificat_ssl_configure' => (bool) config('database.connections.mysql.options.' . (PHP_VERSION_ID >= 80500 ? \Pdo\Mysql::ATTR_SSL_CA : \PDO::MYSQL_ATTR_SSL_CA)),
        ];
    }
}
