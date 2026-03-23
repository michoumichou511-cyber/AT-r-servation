<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class EvaluationPrestataire extends Model
{
    protected $table = 'evaluations_prestataires';

    protected $fillable = [
        'prestataire_id', 'user_id', 'reservation_id',
        'ponctualite', 'qualite_service', 'rapport_qualite_prix',
        'communication', 'note_globale', 'commentaire',
    ];

    protected $casts = [
        'ponctualite' => 'float',
        'qualite_service' => 'float',
        'rapport_qualite_prix' => 'float',
        'communication' => 'float',
        'note_globale' => 'float',
    ];

    public function prestataire()
    {
        return $this->belongsTo(Prestataire::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }
}
