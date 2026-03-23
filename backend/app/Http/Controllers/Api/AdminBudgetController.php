<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Models\Budget;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AdminBudgetController extends Controller
{
    public function gererBudgets(Request $request)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $query = Budget::query();

        if ($request->has('direction') && $request->direction) {
            $query->where('direction', $request->direction);
        }

        if ($request->has('annee') && $request->annee) {
            $query->where('annee', $request->annee);
        } else {
            $query->where('annee', now()->year);
        }

        $budgets = $query->orderBy('direction')->get()->map(function ($budget) {
            return [
                'id' => $budget->id,
                'direction' => $budget->direction,
                'service' => $budget->service,
                'annee' => $budget->annee,
                'montant_alloue' => $budget->montant_alloue,
                'montant_consomme' => $budget->montant_consomme,
                'pourcentage' => $budget->montant_alloue > 0
                    ? round(($budget->montant_consomme / $budget->montant_alloue) * 100, 1)
                    : 0,
                'statut' => $budget->indicateur,
            ];
        });

        return ApiResponse::success(['budgets' => $budgets]);
    }

    public function creerBudget(Request $request)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $request->validate([
            'direction' => 'required|string',
            'service' => 'required|string',
            'annee' => 'required|integer|min:2020|max:2030',
            'montant_alloue' => 'required|numeric|min:0',
        ]);

        $budget = Budget::create([
            'direction' => $request->direction,
            'service' => $request->service,
            'annee' => $request->annee,
            'montant_alloue' => $request->montant_alloue,
            'montant_consomme' => 0,
            'alerte_seuil' => 80,
        ]);

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'create',
            'module' => 'budget',
            'description' => "Budget créé pour {$request->direction} - {$request->service} ({$request->annee})",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::created(['budget' => $budget], 'Budget créé avec succès');
    }

    public function modifierBudget(Request $request, $id)
    {
        $user = Auth::user();

        if (! $user->hasRole('admin')) {
            return ApiResponse::forbidden();
        }

        $request->validate([
            'montant_alloue' => 'sometimes|numeric|min:0',
            'alerte_seuil' => 'sometimes|numeric|min:0|max:100',
        ]);

        $budget = Budget::findOrFail($id);
        $budget->update($request->only(['montant_alloue', 'alerte_seuil']));

        AuditLog::create([
            'user_id' => $user->id,
            'action' => 'update',
            'module' => 'budget',
            'description' => "Budget {$budget->direction} - {$budget->service} modifié",
            'ip_address' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        return ApiResponse::success(['budget' => $budget->fresh()], 'Budget modifié avec succès');
    }
}
