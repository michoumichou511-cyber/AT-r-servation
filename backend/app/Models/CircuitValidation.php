<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class CircuitValidation extends Model
{
    use HasFactory;

    protected $table = 'validations';

    protected $fillable = [
        'mission_id',
        'validateur_id',
        'ordre_validation',
        'statut',
        'commentaire',
        'date_validation',
    ];

    protected $casts = [
        'date_validation' => 'datetime',
        'ordre_validation' => 'integer',
    ];

    // ========== RELATIONS ==========

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function validateur()
    {
        return $this->belongsTo(User::class, 'validateur_id');
    }

    // ========== SCOPES ==========

    public function scopeEnAttente($query)
    {
        return $query->where('statut', 'en_attente');
    }

    public function scopeApprouve($query)
    {
        return $query->where('statut', 'approuve');
    }

    public function scopeRejete($query)
    {
        return $query->where('statut', 'rejete');
    }

    public function scopePourValidateur($query, $validateurId)
    {
        return $query->where('validateur_id', $validateurId);
    }

    // ========== ACCESSORS ==========

    public function getStatutFormatteeAttribute()
    {
        return match ($this->statut) {
            'en_attente' => '⏳ En Attente',
            'approuve' => '✅ Approuvé',
            'rejete' => '❌ Rejeté',
            'ignore' => '⏭️ Ignoré',
            default => $this->statut,
        };
    }

    public function getDelaiRespectAttribute()
    {
        // Cette logique sera implémentée une fois les délais configurés
        return true;
    }
}
