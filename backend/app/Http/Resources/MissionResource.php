<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class MissionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $dateDepart = $this->date_depart;
        $dateRetour = $this->date_retour;

        // Handle both Carbon and string dates
        if (is_string($dateDepart)) {
            $dateDepart = \Carbon\Carbon::parse($dateDepart);
        }
        if (is_string($dateRetour)) {
            $dateRetour = \Carbon\Carbon::parse($dateRetour);
        }

        return [
            'id' => $this->id,
            'numero_unique' => $this->numero_unique,
            'titre' => $this->titre,
            'objet_mission' => $this->objet_mission,
            'destination' => $this->destination,
            'destination_ville' => $this->destination_ville,
            'destination_pays' => $this->destination_pays,
            'dates' => [
                'depart' => $dateDepart->format('d/m/Y'),
                'retour' => $dateRetour->format('d/m/Y'),
            ],
            'type_mission' => $this->type_mission,
            'priorite' => $this->priorite ?? 'normale',
            'statut' => $this->statut,
            'motif_annulation' => $this->motif_annulation,
            'transport_type' => $this->transport_type,
            'budget_previsionnel' => (float) ($this->budget_previsionnel ?? 0),
            'budget_mode' => $this->budget_mode,
            'demande_avance' => (bool) $this->demande_avance,
            'montant_avance' => $this->montant_avance ? (float) $this->montant_avance : null,
            'budget_reel' => (float) ($this->reservations->where('statut', 'confirme')->sum('montant_reel')),
            'user' => new UserResource($this->whenLoaded('user')),
            'reservations' => ReservationResource::collection($this->whenLoaded('reservations')),
            'validations' => CircuitValidationResource::collection($this->whenLoaded('circuitsValidation')),
            'documentation' => DocumentResource::collection($this->whenLoaded('documents')),
            'description' => $this->description,
            'soumis_le' => $this->soumis_le,
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}
