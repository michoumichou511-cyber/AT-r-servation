<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Reservation extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'mission_id',
        'user_id',
        'prestataire_id',
        'type',
        'statut',
        'date_reservation',
        'montant_estime',
        'montant_reel',
        'devise',
        'numero_confirmation',
        'notes',
        'metadata',
    ];

    protected $casts = [
        'date_reservation' => 'date',
        'metadata' => 'array',
        'montant_estime' => 'float',
        'montant_reel' => 'float',
    ];

    // ========== RELATIONS ==========

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function demandeur()
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    public function prestataire()
    {
        return $this->belongsTo(Prestataire::class);
    }

    public function billetAvion()
    {
        return $this->hasOne(BilletAvion::class);
    }

    public function hebergement()
    {
        return $this->hasOne(Hebergement::class);
    }

    public function restauration()
    {
        return $this->hasOne(Restauration::class);
    }

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }

    // ========== SCOPES ==========

    public function scopeParStatut($query, $statut)
    {
        return $query->where('statut', $statut);
    }

    public function scopeParType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeConfirmees($query)
    {
        return $query->where('statut', 'confirme');
    }

    public function scopeEnAttente($query)
    {
        return $query->where('statut', 'en_attente');
    }

    // ========== ACCESSORS ==========

    public function getTypeFormatteeAttribute()
    {
        return match ($this->type) {
            'billet_avion' => '✈️ Billet Avion',
            'hebergement' => '🏨 Hébergement',
            'restauration' => '🍽️ Restauration',
            'transport' => '🚗 Transport',
            'autre' => 'Autre',
            default => $this->type,
        };
    }

    public function getStatutFormatteeAttribute()
    {
        return match ($this->statut) {
            'en_attente' => '⏳ En Attente',
            'confirme' => '✅ Confirmé',
            'annule' => '❌ Annulé',
            'modifie' => '🔄 Modifié',
            default => $this->statut,
        };
    }
}
