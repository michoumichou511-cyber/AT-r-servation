<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\NotificationCustom;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $user = Auth::user();
        $query = NotificationCustom::where('user_id', $user->id);

        // Filtres optionnels
        if ($request->has('is_read')) {
            $isRead = filter_var($request->is_read, FILTER_VALIDATE_BOOLEAN);
            $query->where('lue', $isRead);
        }
        if ($request->has('type')) {
            $query->where('type', $request->type);
        }
        if ($request->has('categorie')) {
            $query->where('categorie', $request->categorie);
        }

        $notifications = $query->orderBy('created_at', 'desc')
            ->paginate(20);

        // Transformer les données
        $notifications->getCollection()->transform(function ($notif) {
            return [
                'id' => $notif->id,
                'titre' => $notif->titre,
                'message' => $notif->message,
                'type' => $notif->type,
                'categorie' => $notif->categorie ?? null,
                'is_read' => (bool) $notif->lue,
                'read_at' => $notif->read_at ? $notif->read_at->format('d/m/Y H:i:s') : null,
                'action_url' => $notif->action_url ?? null,
                'created_at' => $notif->created_at->format('d/m/Y H:i:s'),
            ];
        });

        return response()->json($notifications);
    }

    public function marquerLu(Request $request, $id)
    {
        $user = Auth::user();
        $notification = NotificationCustom::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $notification->update([
            'lue' => true,
            'is_read' => true,
            'read_at' => now(),
        ]);

        Cache::forget('notif_count_'.Auth::id());

        return response()->json(['message' => 'Notification marquée comme lue']);
    }

    public function marquerToutLu(Request $request)
    {
        $user = Auth::user();

        $count = NotificationCustom::where('user_id', $user->id)
            ->where(function ($q) {
                $q->where('lue', false)->orWhereNull('lue');
            })
            ->update([
                'lue' => true,
                'is_read' => true,
                'read_at' => now(),
            ]);

        Cache::forget('notif_count_'.Auth::id());

        return response()->json(['message' => "Marqé $count notifications comme lues", 'count' => $count]);
    }

    public function nombreNonLues(Request $request)
    {
        $userId = Auth::id();
        $count = Cache::remember(
            'notif_count_'.$userId,
            30,
            function () use ($userId) {
                return NotificationCustom::where('user_id', $userId)
                    ->where(function ($q) {
                        $q->where('lue', false)->orWhereNull('lue');
                    })
                    ->count();
            }
        );

        return ApiResponse::success(['count' => $count]);
    }

    public function supprimer(Request $request, $id)
    {
        $user = Auth::user();
        $notification = NotificationCustom::where('id', $id)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $notification->delete();

        Cache::forget('notif_count_'.Auth::id());

        return response()->json(['message' => 'Notification supprimée']);
    }
}
