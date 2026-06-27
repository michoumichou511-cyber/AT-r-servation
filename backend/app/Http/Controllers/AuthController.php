<?php

namespace App\Http\Controllers;

use App\Helpers\ApiResponse;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\UpdateProfileRequest;
use App\Http\Resources\UserResource;
use App\Mail\WelcomeMail;
use App\Models\AuditLog;
use App\Models\Mission;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Cookie;
use Intervention\Image\ImageManager;

class AuthController extends Controller
{
    private function authCookie(string $token): \Symfony\Component\HttpFoundation\Cookie
    {
        $minutes = (int) config('sanctum.expiration', 480);
        $secure = app()->environment('production');

        return cookie('at_auth_token', $token, $minutes, '/', null, $secure, true, false, 'Lax');
    }

    private function forgetAuthCookie(): \Symfony\Component\HttpFoundation\Cookie
    {
        return cookie()->forget('at_auth_token');
    }

    public function register(RegisterRequest $request)
    {
        $validated = $request->validated();

        // Get default role 'utilisateur'
        $role = Role::where('name', 'utilisateur')->first();

        // Create user
        $user = User::create([
            'nom' => $validated['nom'],
            'prenom' => $validated['prenom'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'matricule' => $validated['matricule'] ?? null,
            'service' => $validated['service'] ?? null,
            'direction' => $validated['direction'] ?? null,
            'structure_id' => $validated['structure_id'] ?? null,
            'telephone' => $validated['telephone'] ?? null,
            'poste' => $validated['poste'] ?? null,
            'role_id' => $role?->id,
        ]);

        // Create Sanctum token
        $token = $user->createToken('auth_token')->plainTextToken;

        // Log to AuditLog
        AuditLog::log('create', 'user', 'Nouvelle inscription : '.$user->email);

        // Send welcome email
        try {
            Mail::to($user->email)->send(new WelcomeMail($user));
        } catch (\Exception $e) {
            // Log error but don't fail registration
            \Log::error('Welcome email failed: '.$e->getMessage());
        }

        return response()->json([
            'success' => true,
            'message' => 'Inscription réussie',
            'data' => [
                'user' => new UserResource($user),
                'token' => $token,
            ],
        ], 201)->withCookie($this->authCookie($token));
    }

    public function login(LoginRequest $request)
    {
        $validated = $request->validated();
        $key = 'login_attempts_'.$request->email;
        $attempts = \Cache::get($key, 0);
        if ($attempts >= 5) {
            return \App\Helpers\ApiResponse::error(
                'Compte temporairement bloqué après 5 tentatives. Réessayez dans 15 minutes.',
                429
            );
        }
        if (! Auth::attempt($validated)) {
            \Cache::put($key, $attempts + 1, 900); // 15 minutes

            return \App\Helpers\ApiResponse::error('Identifiants invalides.', 401);
        }
        \Cache::forget($key);
        $user = Auth::user();

        if (! $user->is_active) {
            Auth::logout();

            return response()->json([
                'success' => false,
                'message' => 'Votre compte a été désactivé',
            ], 403);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'data' => [
                'token' => $token,
                'user' => new UserResource($user),
            ],
        ])->withCookie($this->authCookie($token));
    }

    public function logout(Request $request)
    {
        // Revoke current token
        $request->user()->currentAccessToken()->delete();

        // Log to AuditLog
        AuditLog::log('login', 'user', 'Déconnexion');

        return response()->json([
            'success' => true,
            'message' => 'Déconnexion réussie',
        ], 200)->withCookie($this->forgetAuthCookie());
    }

    public function me(Request $request)
    {
        $user = $request->user()->load('role');

        // Stats réelles depuis la base de données
        $statsRow = Mission::where('user_id', $user->id)
            ->selectRaw("
                COUNT(*) as total_missions,
                SUM(statut IN ('soumis','en_validation')) as missions_en_cours,
                SUM(statut = 'approuve') as missions_approuvees,
                SUM(statut = 'brouillon') as missions_brouillon
            ")
            ->first();

        $stats = [
            'total_missions' => (int) ($statsRow->total_missions ?? 0),
            'missions_en_cours' => (int) ($statsRow->missions_en_cours ?? 0),
            'missions_approuvees' => (int) ($statsRow->missions_approuvees ?? 0),
            'missions_brouillon' => (int) ($statsRow->missions_brouillon ?? 0),
        ];

        return response()->json([
            'success' => true,
            'message' => 'Utilisateur connecté',
            'data' => [
                'user' => new UserResource($user),
                'stats' => $stats,
            ],
        ], 200);
    }

    public function updateProfile(UpdateProfileRequest $request)
    {
        $user = $request->user();

        $validated = $request->validated();

        // Store old values for audit
        $oldValues = $user->only(['nom', 'prenom', 'telephone', 'service', 'direction']);

        // Update user
        if (isset($validated['nom'])) {
            $user->nom = $validated['nom'];
        }
        if (isset($validated['prenom'])) {
            $user->prenom = $validated['prenom'];
        }
        if (isset($validated['telephone'])) {
            $user->telephone = $validated['telephone'];
        }
        if (isset($validated['service'])) {
            $user->service = $validated['service'];
        }
        if (isset($validated['direction'])) {
            $user->direction = $validated['direction'];
        }
        if (isset($validated['poste'])) {
            $user->poste = $validated['poste'];
        }
        if (isset($validated['preferences'])) {
            $user->preferences = $validated['preferences'];
        }

        $user->save();

        // Log to AuditLog
        AuditLog::log('update', 'user', 'Profil modifié', $oldValues, $user->only(['nom', 'prenom', 'telephone', 'service', 'direction']));

        return response()->json([
            'success' => true,
            'message' => 'Profil mis à jour',
            'data' => new UserResource($user->load('role')),
        ], 200);
    }

    public function changePassword(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'current_password' => 'required',
            'new_password' => 'required|min:8|regex:/^(?=.*[A-Z])(?=.*[0-9])(?=.*[^A-Za-z0-9]).+$/',
            'new_password_confirmation' => 'required|same:new_password',
        ], [
            'new_password.regex' => 'Le mot de passe doit contenir au moins une majuscule, un chiffre et un caractère spécial.',
        ]);

        // Verify current password
        if (! Hash::check($validated['current_password'], $user->password)) {
            return response()->json([
                'success' => false,
                'message' => 'Ancien mot de passe incorrect',
            ], 400);
        }

        // Update password
        $user->update(['password' => Hash::make($validated['new_password'])]);

        // Revoke ALL tokens
        $user->tokens()->delete();

        // Log to AuditLog
        AuditLog::log('update', 'user', 'Mot de passe modifié');

        return response()->json([
            'success' => true,
            'message' => 'Mot de passe modifié. Veuillez vous reconnecter.',
        ], 200)->withCookie($this->forgetAuthCookie());
    }

    public function uploadAvatar(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        // Delete old avatar if exists
        if ($user->avatar && Storage::disk('public')->exists($user->avatar)) {
            Storage::disk('public')->delete($user->avatar);
        }

        // Store in avatars/{user_id}/
        $directory = "avatars/{$user->id}";
        if (! Storage::disk('public')->exists($directory)) {
            Storage::disk('public')->makeDirectory($directory);
        }

        $filename = "avatar_{$user->id}_".now()->timestamp.'.jpg';
        $path = "{$directory}/{$filename}";

        // Resize using Intervention Image
        $image = ImageManager::gd()->read($request->file('avatar'));
        $image->scale(200, 200);

        // Save
        Storage::disk('public')->put($path, (string) $image->toJpeg());

        // Update user
        $user->update(['avatar' => $path]);

        // Log to AuditLog
        AuditLog::log('update', 'user', 'Avatar mise à jour');

        return response()->json([
            'success' => true,
            'message' => 'Avatar téléchargé',
            'data' => [
                'avatar_url' => Storage::url($path),
            ],
        ], 200);
    }

    public function statistiques(Request $request)
    {
        try {
            $user = auth()->user();

            $totalMissions = Mission::where('user_id', $user->id)->count();

            $approuvees = Mission::where('user_id', $user->id)
                ->where('statut', 'approuve')->count();

            $rejetees = Mission::where('user_id', $user->id)
                ->where('statut', 'rejete')->count();

            $taux = $totalMissions > 0
                ? round(($approuvees / $totalMissions) * 100)
                : 0;

            $budgetTotal = Mission::where('user_id', $user->id)
                ->where('statut', 'approuve')
                ->sum('budget_previsionnel');

            // Missions par mois (6 derniers mois)
            $parMois = Mission::where('user_id', $user->id)
                ->where('created_at', '>=', now()->subMonths(6))
                ->selectRaw("DATE_FORMAT(created_at, '%b %Y') as mois,
                             DATE_FORMAT(created_at, '%Y-%m') as tri,
                             COUNT(*) as count")
                ->groupByRaw("DATE_FORMAT(created_at, '%b %Y'), DATE_FORMAT(created_at, '%Y-%m')")
                ->orderByRaw("DATE_FORMAT(created_at, '%Y-%m')")
                ->get()
                ->map(fn ($r) => ['mois' => $r->mois, 'count' => $r->count]);

            // Missions par type
            $parType = Mission::where('user_id', $user->id)
                ->selectRaw('type_mission as type, COUNT(*) as count')
                ->groupBy('type_mission')
                ->get();

            // Destination favorite
            $destFavorite = Mission::where('user_id', $user->id)
                ->whereNotNull('destination_ville')
                ->selectRaw('destination_ville, COUNT(*) as count')
                ->groupBy('destination_ville')
                ->orderByDesc('count')
                ->first();

            // 5 dernières missions
            $dernieres = Mission::where('user_id', $user->id)
                ->orderByDesc('created_at')
                ->limit(5)
                ->get(['id', 'titre', 'statut', 'destination_ville',
                    'type_mission', 'budget_previsionnel',
                    'date_depart', 'created_at']);

            return ApiResponse::success([
                'total_missions' => $totalMissions,
                'approuvees' => $approuvees,
                'rejetees' => $rejetees,
                'taux_approbation' => $taux,
                'budget_total' => $budgetTotal,
                'destination_favorite' => $destFavorite?->destination_ville ?? 'Aucune',
                'par_mois' => $parMois,
                'par_type' => $parType,
                'dernieres_missions' => $dernieres,
            ]);
        } catch (\Exception $e) {
            \Log::error('statistiques profil: '.$e->getMessage());

            return ApiResponse::error('Erreur statistiques: '.$e->getMessage(), 500);
        }
    }

    public function refreshToken(Request $request)
    {
        $user = $request->user();
        $request->user()->currentAccessToken()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Token renouvelé',
            'data' => ['user' => new UserResource($user->load('role'))],
        ])->withCookie($this->authCookie($token));
    }
}
