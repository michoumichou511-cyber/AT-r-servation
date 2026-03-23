<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class HebergementRequest extends FormRequest
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
        $rules = [
            'reservation_id' => ['required', 'exists:reservations,id'],
            'hotel_nom' => ['required', 'string', 'max:255'],
            'adresse_hotel' => ['nullable', 'string', 'max:255'],
            'ville' => ['required', 'string', 'max:255'],
            'pays' => ['nullable', 'string', 'max:255'],
            'date_checkin' => ['required', 'date'],
            'date_checkout' => ['required', 'date', 'after_or_equal:date_checkin'],
            'nombre_nuits' => ['required', 'integer', 'min:1'],
            'type_chambre' => ['nullable', 'string', 'max:255'],
            'prix_nuit' => ['required', 'numeric'],
            'prix_total' => ['required', 'numeric'],
            'statut' => ['nullable', 'string', 'max:255'],
        ];

        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['reservation_id'][0] = 'sometimes';
        }

        return $rules;
    }
}
