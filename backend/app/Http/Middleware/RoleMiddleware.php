<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RoleMiddleware
{
    /**
     * Accepte un ou plusieurs rôles (ex : role:admin  ou  role:directeur,admin).
     * L'utilisateur doit avoir l'un des rôles listés.
     */
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user     = $request->user();
        $userRole = $user?->role?->name;

        if (! $user || ! in_array($userRole, $roles, true)) {
            abort(403, 'Accès refusé.');
        }

        return $next($request);
    }
}
