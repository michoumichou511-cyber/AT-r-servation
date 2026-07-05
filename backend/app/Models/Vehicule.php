<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Véhicule de service assignable aux missions par le service DML.
 */
class Vehicule extends Model
{
    protected $table = 'vehicules';

    protected $fillable = [
        'type',
        'marque',
        'modele',
        'immatriculation',
        'annee',
        'statut',
        'capacite',
        'notes',
    ];

    /** Véhicules libres (ni en mission, ni en maintenance). */
    public function scopeDisponibles($query)
    {
        return $query->where('statut', 'disponible');
    }

    public function traitements()
    {
        return $this->hasMany(MissionTraitementDml::class);
    }
}
