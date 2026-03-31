<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Document extends Model
{
    use HasFactory;

    protected $fillable = [
        'documentable_type',
        'documentable_id',
        'nom_fichier',
        'chemin',
        'type_document',
        'taille',
        'uploaded_by',
        'uploaded_at',
    ];

    // ========== RELATIONS ==========

    public function documentable()
    {
        return $this->morphTo();
    }

    public function uploadeur()
    {
        return $this->belongsTo(User::class, 'uploaded_by');
    }

    public function validateur()
    {
        return $this->belongsTo(User::class, 'validated_by');
    }

    // ========== SCOPES ==========

    public function scopeValide($query)
    {
        return $query->where('is_validated', true);
    }

    public function scopeEnAttente($query)
    {
        return $query->where('is_validated', false);
    }

    public function scopeParType($query, $type)
    {
        return $query->where('type_document', $type);
    }

    // ========== ACCESSORS ==========

    public function getTailleFormatteeAttribute()
    {
        $taille = $this->taille ?? 0;
        if ($taille >= 1048576) {
            return number_format($taille / 1048576, 2).' MB';
        }
        if ($taille >= 1024) {
            return number_format($taille / 1024, 2).' KB';
        }

        return $taille.' o';
    }

    public function getTypeDocumentFormatteeAttribute()
    {
        return match ($this->type_document) {
            'ordre_mission' => '📋 Ordre de Mission',
            'formulaire' => '📝 Formulaire de demande',
            'formulaire_reservation' => '📝 Formulaire Réservation',
            'autorisation' => '🔐 Autorisation',
            'facture' => '💳 Facture',
            'billet' => '🎫 Billet',
            'bon_commande' => '📦 Bon de Commande',
            'autre' => 'Autre',
            default => $this->type_document,
        };
    }

    public function getExtensionAttribute()
    {
        return pathinfo($this->nom_fichier ?? '', PATHINFO_EXTENSION);
    }
}
