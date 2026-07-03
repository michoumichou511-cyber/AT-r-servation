<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/**
 * Hôtel conventionné Algérie Télécom (tarifs négociés pour les missions).
 */
class HotelConvention extends Model
{
    protected $table = 'hotels_conventions';

    protected $fillable = [
        'nom',
        'ville',
        'wilaya',
        'adresse',
        'telephone',
        'email_contact',
        'date_debut_convention',
        'date_fin_convention',
        'tarif_chambre_simple',
        'tarif_chambre_double',
        'statut',
        'notes',
        'created_by',
    ];

    protected $casts = [
        'date_debut_convention' => 'date',
        'date_fin_convention' => 'date',
        'tarif_chambre_simple' => 'decimal:2',
        'tarif_chambre_double' => 'decimal:2',
    ];

    /** Conventions actives et non expirées. */
    public function scopeActives($query)
    {
        return $query->where('statut', 'active')
            ->whereDate('date_fin_convention', '>=', now());
    }

    public function traitements()
    {
        return $this->hasMany(MissionTraitementDml::class, 'hotel_convention_id');
    }
}
