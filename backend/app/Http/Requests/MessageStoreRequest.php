<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class MessageStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->is_active ?? false;
    }

    public function rules(): array
    {
        return [
            'receiver_id' => ['required', 'integer', 'exists:users,id'],
            'contenu' => ['required', 'string', 'max:2000'],
        ];
    }

    public function messages(): array
    {
        return [
            'receiver_id.required' => 'Le destinataire est requis.',
            'receiver_id.exists' => 'Le destinataire n\'existe pas.',
            'contenu.required' => 'Le message ne peut pas être vide.',
            'contenu.max' => 'Le message ne peut pas dépasser 2000 caractères.',
        ];
    }
}
