<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class UserResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nom' => $this->nom,
            'prenom' => $this->prenom,
            'nom_complet' => $this->prenom.' '.$this->nom,
            'email' => $this->email,
            'matricule' => $this->matricule,
            'service' => $this->service,
            'direction' => $this->direction,
            'poste' => $this->poste,
            'telephone' => $this->telephone,
            'avatar_url' => $this->avatar ? Storage::url($this->avatar) : null,
            'role' => $this->whenLoaded('role', function () {
                return [
                    'id' => $this->role->id,
                    'name' => $this->role->name,
                    'description' => $this->role->description ?? null,
                    'permissions' => $this->role->permissions,
                ];
            }),
            'is_active' => $this->is_active,
            'last_login_at' => $this->last_login_at
                ? $this->last_login_at->format('d/m/Y H:i')
                : null,
            'created_at' => $this->created_at->format('d/m/Y'),
        ];
    }
}
