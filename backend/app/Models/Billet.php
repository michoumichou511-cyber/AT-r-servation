<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Billet extends Model
{
    use HasFactory;

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

    public function reservation()
    {
        return $this->belongsTo(Reservation::class);
    }
}
