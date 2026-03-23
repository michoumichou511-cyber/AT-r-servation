<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class RestaurationRequest extends FormRequest
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
            'prestataire_id' => ['required', 'exists:prestataires,id'],
            'date_repas' => ['required', 'date'],
            'type_repas' => ['required', 'in:petit_dejeuner,dejeuner,diner'],
            'lieu' => ['nullable', 'string', 'max:255'],
            'nombre_personnes' => ['required', 'integer', 'min:1'],
            'prix_par_personne' => ['required', 'numeric'],
            'prix_total' => ['required', 'numeric'],
            'statut' => ['nullable', 'string', 'max:255'],
        ];

        if ($this->isMethod('PUT') || $this->isMethod('PATCH')) {
            $rules['reservation_id'][0] = 'sometimes';
        }

        return $rules;
    }
}
