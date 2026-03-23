<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RestaurationResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $repasLabels = [
            'petit_dejeuner' => 'Petit-déjeuner',
            'dejeuner' => 'Déjeuner',
            'diner' => 'Dîner',
            'cocktail' => 'Cocktail',
        ];

        $statutLabels = [
            'brouillon' => 'Brouillon',
            'confirme' => 'Confirmé',
            'annule' => 'Annulé',
        ];

        return [
            'id' => $this->id,
            'reservation_id' => $this->reservation_id,
            'prestataire_id' => $this->prestataire_id,
            'prestataire_nom' => $this->prestataire?->nom,
            'date_repas' => $this->date_repas?->format('d/m/Y'),
            'type_repas' => $this->type_repas,
            'type_repas_label' => $repasLabels[$this->type_repas] ?? $this->type_repas,
            'lieu' => $this->lieu,
            'nombre_personnes' => $this->nombre_personnes,
            'prix_par_personne' => number_format($this->prix_par_personne ?? 0, 2, ',', ' ').' DA',
            'prix_total' => number_format($this->prix_total ?? 0, 2, ',', ' ').' DA',
            'menu_description' => $this->menu_description,
            'allergies_notes' => $this->allergies_notes,
            'statut' => $this->statut,
            'statut_label' => $statutLabels[$this->statut] ?? $this->statut,
            'created_at' => $this->created_at?->format('d/m/Y H:i:s'),
        ];
    }
}
