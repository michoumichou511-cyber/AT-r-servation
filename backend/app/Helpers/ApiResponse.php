<?php

namespace App\Helpers;

class ApiResponse
{
    /**
     * Return a successful JSON response.
     */
    public static function success($data = null, $message = 'Succès', $code = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    /**
     * Return an error JSON response.
     */
    public static function error($message = 'Erreur', $code = 400, $errors = null)
    {
        $response = [
            'success' => false,
            'message' => $message,
        ];
        if ($errors) {
            $response['errors'] = $errors;
        }

        return response()->json($response, $code);
    }

    /**
     * Return a paginated JSON response.
     */
    public static function paginated($data, $message = 'Succès')
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data->items(),
            'pagination' => [
                'total' => $data->total(),
                'per_page' => $data->perPage(),
                'current_page' => $data->currentPage(),
                'last_page' => $data->lastPage(),
            ],
        ]);
    }

    /**
     * Return a 404 not found response.
     */
    public static function notFound($message = 'Ressource introuvable')
    {
        return self::error($message, 404);
    }

    /**
     * Return a 403 forbidden response.
     */
    public static function forbidden($message = 'Accès refusé')
    {
        return self::error($message, 403);
    }

    /**
     * Return a 401 unauthorized response.
     */
    public static function unauthorized($message = 'Non authentifié')
    {
        return self::error($message, 401);
    }

    /**
     * Return a validation error response.
     */
    public static function validationError($errors, $message = 'Données invalides')
    {
        return self::error($message, 422, $errors);
    }

    /**
     * Return a created response.
     */
    public static function created($data = null, $message = 'Ressource créée avec succès')
    {
        return self::success($data, $message, 201);
    }

    /**
     * Return a no content response.
     */
    public static function noContent($message = 'Opération réussie')
    {
        return response()->json([
            'success' => true,
            'message' => $message,
        ], 204);
    }
}
