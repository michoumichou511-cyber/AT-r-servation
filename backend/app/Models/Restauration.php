<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Restauration extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_id',
        'prestataire_id',
        'nom_restaurant',
        'adresse',
        'ville',
        'date_repas',
        'heure_repas',
        'type_repas',
        'nombre_personnes',
        'menu_type',
        'preferences_alimentaires',
        'prix_par_personne',
        'prix_total',
        'numero_reservation',
        'statut',
    ];

    protected $casts = [
        'date_repas' => 'date',
        'heure_repas' => 'datetime',
        'nombre_personnes' => 'integer',
        'prix_par_personne' => 'float',
        'prix_total' => 'float',
    ];

    // ========== RELATIONS ==========

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }

    public function prestataire()
    {
        return $this->belongsTo(Prestataire::class);
    }

    // ========== ACCESSORS ==========

    public function getTypeRepasFormatteeAttribute()
    {
        return match ($this->type_repas) {
            'petit_dejeuner' => '☕ Petit-Déjeuner',
            'dejeuner' => '🍽️ Déjeuner',
            'diner' => '🍴 Dîner',
            'cocktail' => '🍸 Cocktail',
            'autre' => 'Autre',
            default => $this->type_repas,
        };
    }

    public function getMenuTypeFormatteeAttribute()
    {
        return match ($this->menu_type) {
            'standard' => 'Standard',
            'vegetarien' => '🥬 Végétarien',
            'halal' => '🕌 Halal',
            'special' => '⭐ Spécial',
            default => $this->menu_type,
        };
    }

    public function getStatutFormatteeAttribute()
    {
        return match ($this->statut) {
            'reserve' => '📅 Réservé',
            'confirme' => '✅ Confirmé',
            'consomme' => '✔️ Consommé',
            'annule' => '❌ Annulé',
            default => $this->statut,
        };
    }
}
