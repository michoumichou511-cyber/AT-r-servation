<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Mission extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'created_by',
        'pour_user_id',
        'titre',
        'objet_mission',
        'description',
        'destination',
        'destination_ville',
        'destination_pays',
        'date_depart',
        'date_retour',
        'type_mission',
        'transport_type',
        'priorite',
        'statut',
        'approuve_par',
        'approuve_le',
        'numero_unique',
        'budget_previsionnel',
        'budget_mode',
        'demande_avance',
        'montant_avance',
        'soumis_le',
        'motif_annulation',
    ];

    protected $casts = [
        'date_depart' => 'datetime:Y-m-d',
        'date_retour' => 'datetime:Y-m-d',
        'demande_avance' => 'boolean',
        'montant_avance' => 'decimal:2',
    ];

    protected static function boot()
    {
        parent::boot();

        static::creating(function ($mission) {
            if (! $mission->numero_unique) {
                $year = now()->year;
                $count = static::whereYear('created_at', $year)->count() + 1;
                $mission->numero_unique = 'OM-'.$year.'-'.str_pad($count, 5, '0', STR_PAD_LEFT);
            }
        });
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function createurPar()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    /**
     * @deprecated Use circuitsValidation()
     */
    public function validations()
    {
        return $this->hasMany(CircuitValidation::class);
    }

    public function circuitsValidation()
    {
        return $this->hasMany(CircuitValidation::class);
    }

    public function documents()
    {
        return $this->morphMany(Document::class, 'documentable');
    }

    /** Traitement logistique DML (hôtel, transport) — un par mission. */
    public function traitementDml()
    {
        return $this->hasOne(MissionTraitementDml::class);
    }

    public function scopeForUser($query, User $user)
    {
        return $query->where(function ($q) use ($user) {
            $q->where('user_id', $user->id)
                ->orWhere('pour_user_id', $user->id)
                ->orWhere('created_by', $user->id);
        });
    }

    public function scopeStatut($query, string $statut)
    {
        return $query->where('statut', $statut);
    }

    public function scopeSearch($query, ?string $search)
    {
        if (! $search) {
            return $query;
        }

        return $query->where(function ($q) use ($search) {
            $q->where('titre', 'like', "%{$search}%")
                ->orWhere('destination', 'like', "%{$search}%")
                ->orWhere('numero_unique', 'like', "%{$search}%");
        });
    }

    public function isPending(): bool
    {
        return in_array($this->statut, ['soumis', 'en_validation']);
    }

    public function isEditable(): bool
    {
        return $this->statut === 'brouillon';
    }
}
