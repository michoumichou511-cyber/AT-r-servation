<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class TokenFromCookie
{
    public function handle(Request $request, Closure $next): Response
    {
        if (! $request->bearerToken() && $request->cookie('at_auth_token')) {
            $request->headers->set('Authorization', 'Bearer '.$request->cookie('at_auth_token'));
        }

        return $next($request);
    }
}
