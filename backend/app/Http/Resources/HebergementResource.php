<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class HebergementResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $chambreLabels = [
            'simple' => 'Simple',
            'double' => 'Double',
            'suite' => 'Suite',
            'appartement' => 'Appartement',
        ];

        $statutLabels = [
            'brouillon' => 'Brouillon',
            'confirme' => 'Confirmé',
            'annule' => 'Annulé',
        ];

        return [
            'id' => $this->id,
            'reservation_id' => $this->reservation_id,
            'hotel_nom' => $this->hotel_nom,
            'adresse_hotel' => $this->adresse_hotel,
            'ville' => $this->ville,
            'pays' => $this->pays,
            'localisation' => $this->ville.', '.$this->pays,
            'date_checkin' => $this->date_checkin?->format('d/m/Y'),
            'date_checkout' => $this->date_checkout?->format('d/m/Y'),
            'nombre_nuits' => $this->nombre_nuits,
            'type_chambre' => $this->type_chambre,
            'type_chambre_label' => $chambreLabels[$this->type_chambre] ?? $this->type_chambre,
            'prix_nuit' => number_format($this->prix_nuit ?? 0, 2, ',', ' ').' DA',
            'nombre_personnes' => $this->nombre_personnes,
            'petit_dejeuner' => $this->petit_dejeuner_inclus ? 'Inclus' : 'Non inclus',
            'prix_total' => number_format($this->prix_total ?? 0, 2, ',', ' ').' DA',
            'numero_confirmation' => $this->numero_confirmation,
            'statut' => $this->statut,
            'statut_label' => $statutLabels[$this->statut] ?? $this->statut,
            'created_at' => $this->created_at?->format('d/m/Y H:i:s'),
        ];
    }
}
