<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Models\Mission;
use App\Models\Prestataire;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;

class SearchController extends Controller
{
    public function search(Request $request)
    {
        $q = $request->input('q');
        if (! $q || strlen($q) < 3) {
            return ApiResponse::error('La recherche doit contenir au moins 3 caractères.', 422);
        }
        $user = Auth::user();
        $missions = Mission::where(function ($query) use ($q) {
            $query->where('titre', 'LIKE', "%{$q}%")
                ->orWhere('numero_unique', 'LIKE', "%{$q}%")
                ->orWhere('destination_ville', 'LIKE', "%{$q}%");
        });
        if (! $user->hasRole('admin')) {
            $missions = $missions->where('user_id', $user->id);
        }
        $missions = $missions->limit(5)->get();
        $prestataires = Prestataire::where('nom', 'LIKE', "%{$q}%")
            ->where('is_active', true)
            ->limit(5)->get();
        $utilisateurs = [];
        if ($user->hasRole('admin')) {
            $utilisateurs = User::where(function ($query) use ($q) {
                $query->where('nom', 'LIKE', "%{$q}%")
                    ->orWhere('prenom', 'LIKE', "%{$q}%")
                    ->orWhere('matricule', 'LIKE', "%{$q}%");
            })->limit(5)->get();
        }
        $total = count($missions) + count($prestataires) + count($utilisateurs);

        return ApiResponse::success([
            'missions' => $missions,
            'prestataires' => $prestataires,
            'utilisateurs' => $utilisateurs,
            'total' => $total,
        ]);
    }
}
