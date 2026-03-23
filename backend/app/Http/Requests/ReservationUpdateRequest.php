<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReservationUpdateRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->is_active ?? false;
    }

    /**
     * @return array<string, mixed>
     */
    public function rules(): array
    {
        return [
            'prestataire_id' => ['nullable', 'exists:prestataires,id'],
            'montant_estime' => ['nullable', 'numeric'],
            'montant_reel' => ['nullable', 'numeric'],
            'notes' => ['nullable', 'string'],
            'statut' => ['nullable', 'string', 'max:255'],
        ];
    }
}
