<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Prestataire extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'nom',
        'type',
        'email',
        'telephone',
        'adresse',
        'ville',
        'pays',
        'site_web',
        'logo',
        'note_performance',
        'nombre_evaluations',
        'grille_tarifaire',
        'conditions_contrat',
        'is_active',
        'is_favori',
        'created_by',
    ];

    protected $casts = [
        'is_active' => 'boolean',
        'is_favori' => 'boolean',
        'grille_tarifaire' => 'array',
        'note_performance' => 'float',
    ];

    // ========== RELATIONS ==========

    public function createur()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    public function restaurations()
    {
        return $this->hasMany(Restauration::class);
    }

    public function evaluations()
    {
        return $this->hasMany(EvaluationPrestataire::class, 'prestataire_id');
    }

    // ========== SCOPES ==========

    public function scopeActif($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeInactif($query)
    {
        return $query->where('is_active', false);
    }

    public function scopeParType($query, $type)
    {
        return $query->where('type', $type);
    }

    public function scopeParVille($query, $ville)
    {
        return $query->where('ville', $ville);
    }

    // ========== ACCESSORS ==========

    public function getNoteFormatteeAttribute()
    {
        return number_format($this->note_performance, 2);
    }

    public function getTypeFormatteeAttribute()
    {
        return match ($this->type) {
            'compagnie_aerienne' => '✈️ Compagnie Aérienne',
            'hotel' => '🏨 Hôtel',
            'catering' => '🍽️ Catering',
            'agence_voyage' => '🏢 Agence de Voyage',
            'transport' => '🚗 Transport',
            default => $this->type,
        };
    }
}
