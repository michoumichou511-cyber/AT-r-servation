<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\NotificationCustom;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Laravel\Sanctum\PersonalAccessToken;

class AdminUserController extends Controller
{
    /**
     * Liste légère des utilisateurs actifs — accessible à tous les connectés.
     * Utilisée par la messagerie pour choisir un destinataire.
     */
    public function listeContacts(Request $request)
    {
        $user = Auth::user();

        $contacts = User::where('is_active', true)
            ->where('id', '!=', $user->id)
            ->when($request->filled('search'), function ($q) use ($request) {
                $s = $request->search;
                $q->where(function ($sub) use ($s) {
                    $sub->where('prenom', 'like', "%{$s}%")
                        ->orWhere('nom', 'like', "%{$s}%")
                        ->orWhere('email', 'like', "%{$s}%")
                        ->orWhere('matricule', 'like', "%{$s}%");
                });
            })
            ->select(['id', 'prenom', 'nom', 'email', 'matricule', 'direction', 'service', 'avatar'])
            ->with('role:id,name')
            ->orderBy('prenom')
            ->limit(50)
            ->get()
            ->map(fn ($u) => [
                'id' => $u->id,
                'nom_complet' => "{$u->prenom} {$u->nom}",
                'email' => $u->email,
                'matricule' => $u->matricule,
                'direction' => $u->direction,
                'service' => $u->service,
                'role' => $u->role?->name,
                'avatar' => $u->avatar,
            ]);

        return ApiResponse::success(['contacts' => $contacts]);
    }

    public function listeUtilisateurs(Request $request)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $query = User::with('role');

        if ($request->has('role') && $request->role) {
            $query->whereHas('role', function ($q) use ($request) {
                $q->where('name', $request->role);
            });
        }

        if ($request->has('direction') && $request->direction) {
            $query->where('direction', $request->direction);
        }

        if ($request->filled('is_active')) {
            $query->where('is_active', $request->boolean('is_active'));
        }

        $utilisateurs = $query->select([
            'id', 'prenom', 'nom', 'email', 'matricule',
            'direction', 'service', 'is_active', 'last_login_at',
            'created_at',
        ])
            ->withCount(['missions', 'reservations'])
            ->orderBy('created_at', 'desc')
            ->paginate(20);

        return ApiResponse::paginated($utilisateurs, 'Liste des utilisateurs');
    }

    public function activerDesactiver(Request $request, $id)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $targetUser = User::findOrFail($id);

        if ($targetUser->id === $user->id) {
            return ApiResponse::error('Vous ne pouvez pas modifier votre propre statut', 400);
        }

        $targetUser->is_active = ! $targetUser->is_active;
        $targetUser->save();

        if (! $targetUser->is_active) {
            $targetUser->tokens()->delete();
        }

        NotificationCustom::create([
            'user_id' => $targetUser->id,
            'type' => $targetUser->is_active ? 'success' : 'warning',
            'categorie' => 'compte',
            'titre' => $targetUser->is_active ? 'Compte activé' : 'Compte désactivé',
            'message' => $targetUser->is_active
                ? 'Votre compte a été réactivé par un administrateur.'
                : 'Votre compte a été désactivé par un administrateur.',
            'action_url' => '/profil',
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'update',
            'module' => 'user',
            'description' => "Utilisateur {$targetUser->prenom} {$targetUser->nom} ".
                ($targetUser->is_active ? 'activé' : 'désactivé'),
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(
            ['user' => $targetUser],
            'Statut utilisateur modifié avec succès'
        );
    }

    public function changerRole(Request $request, $id)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $request->validate([
            'role' => 'required|in:admin,validateur,utilisateur,demandeur',
        ]);

        $targetUser = User::findOrFail($id);

        if ($targetUser->id === $user->id) {
            return ApiResponse::error('Vous ne pouvez pas modifier votre propre rôle', 400);
        }

        $oldRole = $targetUser->role->name;
        $newRole = $request->role;

        if ($oldRole === $newRole) {
            return ApiResponse::success(['user' => $targetUser], "L'utilisateur a déjà ce rôle");
        }

        $role = Role::where('name', $newRole)->firstOrFail();
        $targetUser->role_id = $role->id;
        $targetUser->save();

        PersonalAccessToken::where('tokenable_id', $targetUser->id)
            ->where('tokenable_type', User::class)
            ->delete();

        NotificationCustom::create([
            'user_id' => $targetUser->id,
            'type' => 'info',
            'categorie' => 'compte',
            'titre' => 'Rôle modifié',
            'message' => "Votre rôle a été changé de '{$oldRole}' vers '{$newRole}'",
            'action_url' => '/profil',
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'update',
            'module' => 'user',
            'description' => "Rôle de {$targetUser->prenom} {$targetUser->nom} changé de {$oldRole} vers {$newRole}",
            'old_values' => ['role' => $oldRole],
            'new_values' => ['role' => $newRole],
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(
            ['user' => $targetUser->load('role')],
            'Rôle modifié avec succès'
        );
    }
}
