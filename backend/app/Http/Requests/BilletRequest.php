<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class BilletRequest extends FormRequest
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
            'compagnie' => ['required', 'string', 'max:255'],
            'numero_vol' => ['required', 'string', 'max:255'],
            'aeroport_depart' => ['required', 'string', 'max:255'],
            'aeroport_arrivee' => ['required', 'string', 'max:255'],
            'date_vol' => ['required', 'date'],
            'heure_depart' => ['required'],
            'heure_arrivee' => ['required'],
            'classe' => ['required', 'in:economique,business'],
            'numero_billet' => ['nullable', 'string', 'max:255'],
            'prix' => ['required', 'numeric'],
            'statut' => ['nullable', 'string', 'max:255'],
        ];

        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['reservation_id'][0] = 'sometimes';
        }

        return $rules;
    }
}
