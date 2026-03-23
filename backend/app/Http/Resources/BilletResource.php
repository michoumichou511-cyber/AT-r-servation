<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BilletResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $classeLabels = [
            'economique' => 'Économique',
            'business' => 'Business',
            'premiere' => 'Première',
        ];

        $statutLabels = [
            'brouillon' => 'Brouillon',
            'confirme' => 'Confirmé',
            'annule' => 'Annulé',
        ];

        // Calculer durée du vol
        $dureeVol = null;
        if ($this->heure_depart && $this->heure_arrivee) {
            $depart = \Carbon\Carbon::createFromFormat('H:i', $this->heure_depart);
            $arrivee = \Carbon\Carbon::createFromFormat('H:i', $this->heure_arrivee);
            $dureeVol = $depart->diffInMinutes($arrivee);
        }

        return [
            'id' => $this->id,
            'reservation_id' => $this->reservation_id,
            'compagnie' => $this->compagnie,
            'numero_vol' => $this->numero_vol,
            'aeroport_depart' => $this->aeroport_depart,
            'aeroport_arrivee' => $this->aeroport_arrivee,
            'date_vol' => $this->date_vol?->format('d/m/Y'),
            'heure_depart' => $this->heure_depart,
            'heure_arrivee' => $this->heure_arrivee,
            'duree_vol_minutes' => $dureeVol,
            'classe' => $this->classe,
            'classe_label' => $classeLabels[$this->classe] ?? $this->classe,
            'numero_billet' => $this->numero_billet,
            'prix' => number_format($this->prix ?? 0, 2, ',', ' ').' DA',
            'statut' => $this->statut,
            'statut_label' => $statutLabels[$this->statut] ?? $this->statut,
            'created_at' => $this->created_at?->format('d/m/Y H:i:s'),
        ];
    }
}
