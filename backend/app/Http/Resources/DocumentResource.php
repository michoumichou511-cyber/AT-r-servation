<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Support\Facades\Storage;

class DocumentResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'nom_fichier' => $this->nom_fichier,
            'nom' => $this->nom_fichier,
            'type' => $this->type_document ?? $this->type,
            'mime_type' => $this->mime_type,
            'url' => $this->chemin ? Storage::url($this->chemin) : ($this->file_path ? Storage::url($this->file_path) : null),
            'created_at' => $this->created_at?->format('Y-m-d H:i:s'),
        ];
    }
}
