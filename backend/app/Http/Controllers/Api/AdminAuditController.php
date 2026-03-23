<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminAuditController extends Controller
{
    public function auditLogs(Request $request)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $query = AuditLog::query();

        if ($request->has('user_id') && $request->user_id) {
            $query->where('user_id', $request->user_id);
        }

        if ($request->has('action') && $request->action) {
            $query->where('action', $request->action);
        }

        if ($request->has('module') && $request->module) {
            $query->where('module', $request->module);
        }

        if ($request->has('date_debut') && $request->date_debut) {
            $query->where('created_at', '>=', $request->date_debut);
        }

        if ($request->has('date_fin') && $request->date_fin) {
            $query->where('created_at', '<=', $request->date_fin.' 23:59:59');
        }

        $logs = $query->orderBy('created_at', 'desc')->paginate(50);

        // Enrichissement user_id -> user sans eager loading de relation Eloquent
        $userIds = $logs->getCollection()->pluck('user_id')->unique()->filter()->values();
        $usersById = $userIds->isNotEmpty()
            ? User::whereIn('id', $userIds)->get()->keyBy('id')
            : collect();

        $logs->getCollection()->transform(function ($log) use ($usersById) {
            $log->setRelation('user', $log->user_id && $usersById->has($log->user_id)
                ? $usersById->get($log->user_id)
                : null);

            return $log;
        });

        return ApiResponse::success(['audit_logs' => $logs]);
    }
}
