<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class UserController extends Controller
{
    /**
     * Utilisateurs groupés par structure_id (organigramme).
     *
     * @return JsonResponse array<string, array<int, array{id: int, name: string, email: string, role: string|null}>>
     */
    public function byStructure(): JsonResponse
    {
        $grouped = User::query()
            ->with('role:id,name')
            ->whereNotNull('structure_id')
            ->get(['id', 'nom', 'prenom', 'email', 'structure_id', 'role_id'])
            ->groupBy('structure_id')
            ->map(function ($users) {
                return $users->map(function (User $user) {
                    return [
                        'id' => $user->id,
                        'name' => trim(($user->prenom ?? '').' '.($user->nom ?? '')),
                        'email' => $user->email,
                        'role' => $user->role?->name,
                    ];
                })->values();
            });

        return response()->json($grouped);
    }

    /**
     * PATCH /api/user/presence
     * Met à jour le statut en ligne de l'utilisateur authentifié.
     */
    public function updatePresence(Request $request): JsonResponse
    {
        $request->validate([
            'is_online' => 'required|boolean',
        ]);

        $user = Auth::user();
        $user->update([
            'is_online' => $request->boolean('is_online'),
            'last_seen' => now(),
        ]);

        return response()->json(['message' => 'Présence mise à jour']);
    }

    /**
     * GET /api/users/{id}/presence
     * Retourne le statut de présence d'un utilisateur.
     */
    public function getPresence(int $id): JsonResponse
    {
        $user = User::select('id', 'is_online', 'last_seen')->findOrFail($id);

        return response()->json([
            'id'        => $user->id,
            'is_online' => (bool) $user->is_online,
            'last_seen' => $user->last_seen?->toIso8601String(),
        ]);
    }
}
