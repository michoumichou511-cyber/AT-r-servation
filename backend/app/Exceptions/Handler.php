<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });

        // Gestion des exceptions API
        $this->renderable(function (Throwable $e, $request) {
            // Vérifier si c'est une requête API
            if ($request->is('api/*') || $request->expectsJson()) {
                return $this->handleApiException($e);
            }
        });
    }

    /**
     * Handle API exceptions and return JSON responses.
     */
    private function handleApiException(Throwable $e)
    {
        // AuthenticationException → 401
        if ($e instanceof \Illuminate\Auth\AuthenticationException) {
            return response()->json([
                'success' => false,
                'message' => 'Non authentifié. Veuillez vous connecter.',
            ], 401);
        }

        // AuthorizationException → 403
        if ($e instanceof \Illuminate\Auth\Access\AuthorizationException) {
            return response()->json([
                'success' => false,
                'message' => 'Accès refusé. Permissions insuffisantes.',
            ], 403);
        }

        // ModelNotFoundException → 404
        if ($e instanceof \Illuminate\Database\Eloquent\ModelNotFoundException) {
            return response()->json([
                'success' => false,
                'message' => 'Ressource introuvable.',
            ], 404);
        }
        // ValidationException → 422
        if ($e instanceof \Illuminate\Validation\ValidationException) {
            return response()->json([
                'success' => false,
                'message' => 'Validation échouée.',
                'errors' => $e->errors(),
            ], 422);
        }
        // ThrottleRequestsException → 429
        if ($e instanceof \Illuminate\Http\Exceptions\ThrottleRequestsException) {
            return response()->json([
                'success' => false,
                'message' => 'Trop de requêtes. Veuillez patienter.',
            ], 429);
        }

        // Exception générale → 500
        return response()->json([
            'success' => false,
            'message' => 'Erreur interne du serveur.',
        ], 500);
    }

    /**
     * Handle an unauthenticated user.
     */
    protected function unauthenticated($request, AuthenticationException $exception)
    {
        // Always return JSON for API requests
        return response()->json(['message' => 'Unauthenticated.'], 401);
    }
}
