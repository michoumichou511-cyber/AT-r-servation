<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MissionStoreRequest extends FormRequest
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
            // FIX-4 : titre min 3 caracteres (1 char etait accepte = absurde)
            'titre' => ['required', 'string', 'min:3', 'max:255'],
            'objet_mission' => ['required', 'string', 'min:5'],
            'destination_ville' => ['required', 'string', 'max:255'],
            'destination_pays' => ['required', 'string', 'max:255'],
            'ville_depart' => ['nullable', 'string', 'max:100'],
            'date_depart' => ['required', 'date', 'after:today'],
            'date_retour' => ['required', 'date', 'after:date_depart'],
            'type_mission' => ['required', 'in:formation,conference,reunion,inspection,audit,autre'],
            'transport_type' => ['required', 'in:avion,terrestre,train,autre'],
            'priorite' => ['nullable', 'in:normale,urgente,tres_urgente'],
            'budget_previsionnel' => ['nullable', 'numeric', 'min:0'],
            'budget_mode' => ['required', 'in:avance,remboursement'],
            'demande_avance' => ['nullable', 'boolean'],
            'montant_avance' => ['nullable', 'numeric', 'min:0'],
            'description' => ['nullable', 'string'],
        ];
    }
}
