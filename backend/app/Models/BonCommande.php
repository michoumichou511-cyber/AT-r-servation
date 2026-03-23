<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BonCommande extends Model
{
    use HasFactory;

    protected $table = 'bons_commande';

    protected $fillable = [
        'numero',
        'mission_id',
        'type',
        'prestataire_nom',
        'montant_total',
        'statut',
        'pdf_path',
        'genere_par',
    ];

    protected $casts = [
        'montant_total' => 'float',
    ];

    public static function genererNumero(): string
    {
        $annee = date('Y');
        $dernier = static::whereYear('created_at', $annee)->count() + 1;

        return 'BC-'.$annee.'-'.str_pad($dernier, 5, '0', STR_PAD_LEFT);
    }

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function generateurPar()
    {
        return $this->belongsTo(User::class, 'genere_par');
    }
}
