<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class MissionTraitementDml extends Model
{
    use HasFactory;

    protected $table = 'mission_traitements_dml';

    protected $fillable = [
        'mission_id',
        'agent_dml_id',
        'hotel_convention_id',
        'hotel_nom_libre',
        'vehicule_id',
        'type_transport',
        'numero_bon',
        'observations',
        'statut',
        'traite_le',
    ];

    protected $casts = [
        'traite_le' => 'datetime',
    ];

    // ── Relations ────────────────────────────────────────────

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }

    public function agentDml()
    {
        return $this->belongsTo(User::class, 'agent_dml_id');
    }

    public function hotel()
    {
        return $this->belongsTo(HotelConvention::class, 'hotel_convention_id');
    }

    public function vehicule()
    {
        return $this->belongsTo(Vehicule::class);
    }

    // ── Scopes ───────────────────────────────────────────────

    public function scopeEnCours($query)
    {
        return $query->whereIn('statut', ['en_attente', 'en_traitement']);
    }

    public function scopeTermines($query)
    {
        return $query->where('statut', 'logistique_ok');
    }

    // ── Helpers ──────────────────────────────────────────────

    public function isLogistiqueOk(): bool
    {
        return $this->statut === 'logistique_ok';
    }
}
