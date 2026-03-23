<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ApiResponse;
use App\Http\Controllers\Controller;
use App\Models\BonCommande;
use Illuminate\Http\Request;

class BonCommandeController extends Controller
{
    public function parMission(Request $request, $missionId)
    {
        $bons = BonCommande::where('mission_id', $missionId)
            ->orderBy('type')
            ->get();

        return ApiResponse::success(['bons' => $bons]);
    }

    public function marquerEnvoye(Request $request, $id)
    {
        $bon = BonCommande::findOrFail($id);
        $bon->update(['statut' => 'envoye']);

        return ApiResponse::success(['bon' => $bon]);
    }
}
