<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Routing\Middleware\ThrottleRequests;
use Symfony\Component\HttpFoundation\Response;

class ThrottleRequestsByRole extends ThrottleRequests
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next, string $type = 'api', ?int $maxAttempts = null, ?int $decayMinutes = null, ?string $prefix = ''): Response
    {
        // Récupérer la configuration depuis config/throttling.php
        $config = config("throttling.{$type}", [
            'max_attempts' => $maxAttempts ?: 60,
            'decay_minutes' => $decayMinutes ?: 1,
        ]);

        $maxAttempts = $config['max_attempts'];
        $decayMinutes = $config['decay_minutes'];
        $prefix = $prefix ?: $type;

        // Générer une clé unique basée sur l'utilisateur et le type de throttling
        $key = $this->resolveRequestSignature($request, $maxAttempts, $decayMinutes, $prefix);

        // Vérifier si l'utilisateur est authentifié pour personnaliser la clé
        if ($request->user()) {
            $key .= '|'.$request->user()->id;
        }

        // Utiliser le middleware parent ThrottleRequests
        return parent::handle($request, $next, $maxAttempts, $decayMinutes, $prefix);
    }

    /**
     * Resolve request signature.
     */
    protected function resolveRequestSignature(Request $request, int $maxAttempts, int $decayMinutes, string $prefix): string
    {
        return sha1(
            $prefix.
            '|'.$request->ip().
            '|'.$request->route()?->getDomain().
            '|'.$request->path()
        );
    }
}
