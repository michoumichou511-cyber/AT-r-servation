<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReservationStoreRequest extends FormRequest
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
            'mission_id' => ['required', 'exists:missions,id'],
            'type' => ['required', 'in:billet,hebergement,restauration'],
            'prestataire_id' => ['nullable', 'exists:prestataires,id'],
            'montant_estime' => ['nullable', 'numeric'],
            'notes' => ['nullable', 'string'],
        ];
    }
}
