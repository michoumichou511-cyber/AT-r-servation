<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReservationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $typeLabels = [
            'billet' => 'Billet d\'avion',
            'hebergement' => 'Hébergement',
            'restauration' => 'Restauration',
        ];

        $statutLabels = [
            'brouillon' => 'Brouillon',
            'en_cours' => 'En cours',
            'confirme' => 'Confirmé',
            'annule' => 'Annulé',
        ];

        return [
            'id' => $this->id,
            'mission_id' => $this->mission_id,
            'user_id' => $this->user_id,
            'type' => $this->type,
            'type_label' => $typeLabels[$this->type] ?? $this->type,
            'statut' => $this->statut,
            'statut_label' => $statutLabels[$this->statut] ?? $this->statut,
            'montant_estime' => number_format($this->montant_estime ?? 0, 2, ',', ' ').' DA',
            'montant_reel' => number_format($this->montant_reel ?? 0, 2, ',', ' ').' DA',
            'prestataire' => [
                'id' => $this->prestataire?->id,
                'nom' => $this->prestataire?->nom,
                'type' => $this->prestataire?->type,
            ],
            'billet' => new BilletResource($this->billetAvion),
            'hebergement' => new HebergementResource($this->hebergement),
            'restauration' => new RestaurationResource($this->restauration),
            'notes' => $this->notes,
            'created_at' => $this->created_at?->format('d/m/Y H:i:s'),
        ];
    }
}
