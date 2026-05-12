<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class HotelConvention extends Model
{
    use HasFactory;

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
        'date_fin_convention'   => 'date',
        'tarif_chambre_simple'  => 'decimal:2',
        'tarif_chambre_double'  => 'decimal:2',
    ];

    // ── Scopes ──────────────────────────────────────────────

    public function scopeActives($query)
    {
        return $query->where('statut', 'active');
    }

    public function scopeNonExpirees($query)
    {
        return $query->where(function ($q) {
            $q->whereNull('date_fin_convention')
              ->orWhere('date_fin_convention', '>=', now()->toDateString());
        });
    }

    // ── Relations ────────────────────────────────────────────

    public function createur()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function traitementsDml()
    {
        return $this->hasMany(MissionTraitementDml::class, 'hotel_convention_id');
    }
}
