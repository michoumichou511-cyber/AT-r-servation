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

        // Handle both Carbon and string dates — null-safe
        if (is_string($dateDepart) && $dateDepart !== '') {
            try { $dateDepart = \Carbon\Carbon::parse($dateDepart); } catch (\Exception $e) { $dateDepart = null; }
        } elseif (!($dateDepart instanceof \Carbon\Carbon)) {
            $dateDepart = null;
        }
        if (is_string($dateRetour) && $dateRetour !== '') {
            try { $dateRetour = \Carbon\Carbon::parse($dateRetour); } catch (\Exception $e) { $dateRetour = null; }
        } elseif (!($dateRetour instanceof \Carbon\Carbon)) {
            $dateRetour = null;
        }

        return [
            'id' => $this->id,
            'numero_unique' => $this->numero_unique,
            'titre' => $this->titre,
            'objet_mission' => $this->objet_mission,
            'destination' => $this->destination,
            'dates' => [
                'depart' => $dateDepart?->format('d/m/Y'),
                'retour' => $dateRetour?->format('d/m/Y'),
            ],
            'type_mission' => $this->type_mission,
            'priorite' => $this->priorite ?? 'normale',
            'statut' => $this->statut,
            'budget_previsionnel' => (float) ($this->budget_previsionnel ?? 0),
            'budget_reel' => (float) ($this->reservations->where('statut', 'confirme')->sum('montant_reel')),
            'user' => new UserResource($this->whenLoaded('user')),
            'reservations' => ReservationResource::collection($this->whenLoaded('reservations')),
            'validations' => CircuitValidationResource::collection($this->whenLoaded('circuitsValidation')),
            'documentation' => DocumentResource::collection($this->whenLoaded('documents')),
            'description' => $this->description,
            'soumis_le' => $this->soumis_le,
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}
