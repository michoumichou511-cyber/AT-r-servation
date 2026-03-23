<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MissionUpdateRequest extends FormRequest
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
            'titre' => ['nullable', 'string', 'max:255'],
            'objet_mission' => ['nullable', 'string'],
            'destination_ville' => ['nullable', 'string', 'max:255'],
            'destination_pays' => ['nullable', 'string', 'max:255'],
            'date_depart' => ['nullable', 'date', 'after:today'],
            'date_retour' => ['nullable', 'date'],
            'type_mission' => ['nullable', 'in:formation,conference,reunion,inspection,audit,autre'],
            'priorite' => ['nullable', 'in:normale,urgente,tres_urgente'],
            'budget_previsionnel' => ['nullable', 'numeric', 'min:0'],
            'description' => ['nullable', 'string'],
        ];
    }
}
