<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Budget extends Model
{
    use HasFactory;

    protected $fillable = [
        'direction',
        'service',
        'annee',
        'trimestre',
        'type_depense',
        'montant_alloue',
        'montant_engage',
        'montant_consomme',
        'pourcentage_consomme',
        'alerte_seuil',
    ];

    protected $casts = [
        'montant_alloue' => 'float',
        'montant_engage' => 'float',
        'montant_consomme' => 'float',
        'pourcentage_consomme' => 'float',
        'annee' => 'integer',
        'trimestre' => 'integer',
    ];

    // ========== SCOPES ==========

    public function scopeParDirection($query, $direction)
    {
        return $query->where('direction', $direction);
    }

    public function scopeParService($query, $service)
    {
        return $query->where('service', $service);
    }

    public function scopeParAnnee($query, $annee)
    {
        return $query->where('annee', $annee);
    }

    public function scopeParType($query, $type)
    {
        return $query->where('type_depense', $type);
    }

    public function scopeEnAlerte($query)
    {
        return $query->whereRaw('pourcentage_consomme >= alerte_seuil');
    }

    public function scopeNonEnAlerte($query)
    {
        return $query->whereRaw('pourcentage_consomme < alerte_seuil');
    }

    // ========== ACCESSORS ==========

    public function getPourcentageConsommeAttribute()
    {
        if ($this->montant_alloue > 0) {
            return ($this->montant_consomme / $this->montant_alloue) * 100;
        }

        return 0;
    }

    public function getPourcentageFormatteeAttribute()
    {
        return number_format($this->pourcentage_consomme, 2).'%';
    }

    public function getMontantRestantAttribute()
    {
        return $this->montant_alloue - $this->montant_consomme;
    }

    public function getIndicateurAttribute()
    {
        $pourcentage = $this->pourcentage_consomme;

        if ($pourcentage >= 100) {
            return '🔴 Dépassé';
        }
        if ($pourcentage >= $this->alerte_seuil) {
            return '🟠 Alerte';
        }
        if ($pourcentage >= 50) {
            return '🟡 Attention';
        }

        return '🟢 Normal';
    }

    // ========== METHODES ==========

    public function isEnAlerte()
    {
        return $this->pourcentage_consomme >= $this->alerte_seuil;
    }

    public function isEnSurbudget()
    {
        return $this->montant_consomme > $this->montant_alloue;
    }

    public function calculerMontantDisponible()
    {
        return max(0, $this->montant_alloue - $this->montant_consomme);
    }
}
