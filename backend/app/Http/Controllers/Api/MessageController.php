<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\Conversation;
use App\Models\Message;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;

class MessageController extends Controller
{
    public function conversations(Request $request)
    {
        $userId = auth()->id();
        $conversations = Conversation::where('participant_1_id', $userId)
            ->orWhere('participant_2_id', $userId)
            ->with(['participant1', 'participant2'])
            ->withCount(['messages as non_lus' => function ($q) use ($userId) {
                $q->where('lu', false)->where('receiver_id', $userId);
            }])
            ->orderByDesc('dernier_message_at')
            ->get()
            ->map(function ($conv) use ($userId) {
                $interlocuteur = $conv->participant_1_id == $userId
                    ? $conv->participant2
                    : $conv->participant1;

                return [
                    'id' => $conv->id,
                    'interlocuteur' => [
                        'id' => $interlocuteur?->id,
                        'name' => $interlocuteur?->nom_complet ?? '',
                        'role' => $interlocuteur?->role?->name ?? null,
                    ],
                    'dernier_message' => $conv->dernier_message,
                    'dernier_message_at' => $conv->dernier_message_at?->toIso8601String(),
                    'non_lus' => $conv->non_lus ?? 0,
                    'mission_id' => $conv->mission_id,
                ];
            });

        return ApiResponse::success(['conversations' => $conversations]);
    }

    public function messages(Request $request, $id)
    {
        $userId = auth()->id();
        $conversation = Conversation::where('id', $id)
            ->where(function ($q) use ($userId) {
                $q->where('participant_1_id', $userId)
                    ->orWhere('participant_2_id', $userId);
            })
            ->firstOrFail();

        Message::where('conversation_id', $id)
            ->where('receiver_id', $userId)
            ->where('lu', false)
            ->update(['lu' => true, 'lu_at' => now()]);

        Cache::forget('msg_count_'.$userId);

        $messages = Message::where('conversation_id', $id)
            ->with('sender')
            ->orderBy('created_at')
            ->get()
            ->map(fn ($m) => [
                'id' => $m->id,
                'contenu' => $m->contenu,
                'sender_id' => $m->sender_id,
                'sender_name' => $m->sender?->nom_complet ?? '',
                'est_moi' => $m->sender_id == $userId,
                'lu' => $m->lu,
                'created_at' => $m->created_at?->toIso8601String(),
            ]);

        return ApiResponse::success(['messages' => $messages]);
    }

    public function envoyer(Request $request)
    {
        $request->validate([
            'receiver_id' => 'required|exists:users,id',
            'contenu' => 'required|string|max:2000',
            'mission_id' => 'nullable|exists:missions,id',
        ]);

        $senderId = auth()->id();
        $receiverId = $request->receiver_id;
        $missionId = $request->mission_id;

        $conversation = Conversation::where(function ($q) use ($senderId, $receiverId, $missionId) {
            $q->where('participant_1_id', $senderId)
                ->where('participant_2_id', $receiverId)
                ->where(function ($q2) use ($missionId) {
                    $q2->where('mission_id', $missionId)->orWhereNull('mission_id');
                });
        })->orWhere(function ($q) use ($senderId, $receiverId, $missionId) {
            $q->where('participant_1_id', $receiverId)
                ->where('participant_2_id', $senderId)
                ->where(function ($q2) use ($missionId) {
                    $q2->where('mission_id', $missionId)->orWhereNull('mission_id');
                });
        })->first();

        if (! $conversation) {
            $conversation = Conversation::create([
                'participant_1_id' => $senderId,
                'participant_2_id' => $receiverId,
                'mission_id' => $missionId,
            ]);
        }

        $message = Message::create([
            'conversation_id' => $conversation->id,
            'sender_id' => $senderId,
            'receiver_id' => $receiverId,
            'contenu' => $request->contenu,
        ]);

        $conversation->update([
            'dernier_message' => substr($request->contenu, 0, 100),
            'dernier_message_at' => now(),
        ]);

        return ApiResponse::success([
            'message' => [
                'id' => $message->id,
                'contenu' => $message->contenu,
                'sender_id' => $senderId,
                'created_at' => $message->created_at?->toIso8601String(),
            ],
        ], 'Message envoyé');
    }

    public function marquerLu(Request $request, $id)
    {
        $message = Message::where('id', $id)
            ->where('receiver_id', auth()->id())
            ->firstOrFail();
        $message->update(['lu' => true, 'lu_at' => now()]);
        Cache::forget('msg_count_'.Auth::id());

        return ApiResponse::success([], 'Message lu');
    }

    public function nonLusCount(Request $request)
    {
        $userId = Auth::id();
        $count = Cache::remember(
            'msg_count_'.$userId,
            30,
            function () use ($userId) {
                return Message::where('receiver_id', $userId)
                    ->where('lu', false)
                    ->count();
            }
        );

        return ApiResponse::success(['count' => $count]);
    }
}
