<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CircuitValidationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'mission_id' => $this->mission_id,
            'ordre_validation' => $this->ordre_validation,
            'statut' => $this->statut,
            'commentaire' => $this->commentaire,
            'date_validation' => $this->date_validation,
            'validateur' => new UserResource($this->whenLoaded('validateur')),
            'updated_at' => $this->updated_at?->format('Y-m-d H:i:s'),
        ];
    }
}
