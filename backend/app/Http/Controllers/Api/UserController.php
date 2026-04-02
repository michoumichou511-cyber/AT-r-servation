<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;

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
}
