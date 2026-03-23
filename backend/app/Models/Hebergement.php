<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Hebergement extends Model
{
    use HasFactory;

    protected $fillable = [
        'reservation_id',
        'nom_etablissement',
        'type_etablissement',
        'adresse',
        'ville',
        'pays',
        'etoiles',
        'date_checkin',
        'heure_checkin',
        'date_checkout',
        'heure_checkout',
        'nombre_nuits',
        'nombre_chambres',
        'type_chambre',
        'petit_dejeuner_inclus',
        'prix_nuit',
        'prix_total',
        'numero_reservation',
        'contact_hotel',
        'statut',
    ];

    protected $casts = [
        'date_checkin' => 'date',
        'date_checkout' => 'date',
        'heure_checkin' => 'datetime',
        'heure_checkout' => 'datetime',
        'petit_dejeuner_inclus' => 'boolean',
        'prix_nuit' => 'float',
        'prix_total' => 'float',
        'etoiles' => 'integer',
        'nombre_chambres' => 'integer',
        'nombre_nuits' => 'integer',
    ];

    // ========== RELATIONS ==========

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }

    // ========== ACCESSORS ==========

    public function getNombreNuitsAttribute()
    {
        if ($this->date_checkout && $this->date_checkin) {
            return $this->date_checkout->diffInDays($this->date_checkin);
        }

        return 0;
    }

    public function getEtoilesFormatteeAttribute()
    {
        if (! $this->etoiles) {
            return 'N/A';
        }

        return str_repeat('⭐', $this->etoiles);
    }

    public function getTypeEtablissementFormatteeAttribute()
    {
        return match ($this->type_etablissement) {
            'hotel' => '🏨 Hôtel',
            'residence' => '🏠 Résidence',
            'auberge' => '🏘️ Auberge',
            'autre' => 'Autre',
            default => $this->type_etablissement,
        };
    }

    public function getTypeChambreFormatteeAttribute()
    {
        return match ($this->type_chambre) {
            'simple' => '🪑 Simple',
            'double' => '🛏️ Double',
            'suite' => '👑 Suite',
            'appartement' => '🏠 Appartement',
            default => $this->type_chambre,
        };
    }

    public function getStatutFormatteeAttribute()
    {
        return match ($this->statut) {
            'reserve' => '📅 Réservé',
            'confirme' => '✅ Confirmé',
            'checkin' => '🔑 Check-in',
            'checkout' => '📤 Check-out',
            'annule' => '❌ Annulé',
            default => $this->statut,
        };
    }
}
