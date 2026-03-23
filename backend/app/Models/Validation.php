<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Validation extends Model
{
    use HasFactory;

    protected $fillable = [
        'mission_id',
        'validateur_id',
        'ordre_validation',
        'statut',
        'commentaire',
        'date_validation',
    ];

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function validateur()
    {
        return $this->belongsTo(User::class, 'validateur_id');
    }
}
