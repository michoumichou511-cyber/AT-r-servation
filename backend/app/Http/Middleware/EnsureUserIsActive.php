<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsActive
{
    /**
     * Vérifie que l'utilisateur authentifié est actif.
     * Si le compte est désactivé, révoque le token et retourne 403.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if ($user && ! $user->is_active) {
            // Révoquer le token actuel
            $user->currentAccessToken()->delete();

            return response()->json([
                'success' => false,
                'message' => 'Votre compte a été désactivé. Contactez un administrateur.',
            ], 403);
        }

        return $next($request);
    }
}
