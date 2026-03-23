<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BilletAvion extends Model
{
    use HasFactory;

    protected $table = 'billets';

    protected $fillable = [
        'reservation_id',
        'compagnie',
        'numero_vol',
        'aeroport_depart',
        'aeroport_arrivee',
        'date_vol',
        'heure_depart',
        'heure_arrivee',
        'classe',
        'numero_billet',
        'prix',
        'statut',
    ];

    protected $casts = [
        'date_vol' => 'date',
        'prix' => 'float',
    ];

    // ========== RELATIONS ==========

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }

    // ========== ACCESSORS ==========

    public function getClasseFormatteeAttribute()
    {
        return match ($this->classe ?? '') {
            'economique' => '🪑 Économique',
            'business' => '💼 Affaires',
            'premiere' => '👑 Première',
            default => $this->classe ?? 'N/A',
        };
    }

    public function getStatutFormatteeAttribute()
    {
        return match ($this->statut) {
            'reserve' => '📅 Réservé',
            'confirme' => '✅ Confirmé',
            'embarque' => '🛫 Embarqué',
            'annule' => '❌ Annulé',
            'rembourse' => '💰 Remboursé',
            default => $this->statut,
        };
    }
}
