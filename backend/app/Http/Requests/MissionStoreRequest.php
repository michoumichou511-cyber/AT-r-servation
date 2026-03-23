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
            'titre' => ['required', 'string', 'max:255'],
            'objet_mission' => ['required', 'string'],
            'destination_ville' => ['required', 'string', 'max:255'],
            'destination_pays' => ['required', 'string', 'max:255'],
            'date_depart' => ['required', 'date', 'after:today'],
            'date_retour' => ['required', 'date', 'after:date_depart'],
            'type_mission' => ['required', 'in:formation,conference,reunion,inspection,audit,autre'],
            'priorite' => ['nullable', 'in:normale,urgente,tres_urgente'],
            'budget_previsionnel' => ['nullable', 'numeric', 'min:0'],
            'description' => ['nullable', 'string'],
        ];
    }
}
