<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Vehicule extends Model
{
    use HasFactory;

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

    protected $casts = [
        'annee'    => 'integer',
        'capacite' => 'integer',
    ];

    // ── Scopes ──────────────────────────────────────────────

    public function scopeDisponibles($query)
    {
        return $query->where('statut', 'disponible');
    }

    public function scopeEnMission($query)
    {
        return $query->where('statut', 'en_mission');
    }

    // ── Accessors ────────────────────────────────────────────

    public function getLabelAttribute(): string
    {
        return "{$this->marque} {$this->modele} ({$this->immatriculation})";
    }

    // ── Relations ────────────────────────────────────────────

    public function traitementsDml()
    {
        return $this->hasMany(MissionTraitementDml::class, 'vehicule_id');
    }
}
