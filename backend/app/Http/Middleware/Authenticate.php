<?php

namespace App\Http\Middleware;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Auth\Middleware\Authenticate as Middleware;

class Authenticate extends Middleware
{
    /**
     * Get the path the user should be redirected to when they are not authenticated.
     */
    protected function redirectTo($request)
    {
        // For API requests, don't redirect - return 401
        if ($request->expectsJson() || $request->is('api/*')) {
            throw new AuthenticationException;
        }

        return route('login');
    }
}
