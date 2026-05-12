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
        'priorite',
        'statut',
        'approuve_par',
        'approuve_le',
        'numero_unique',
        'budget_previsionnel',
        'soumis_le',
    ];

    protected $casts = [
        'date_depart' => 'datetime:Y-m-d',
        'date_retour' => 'datetime:Y-m-d',
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

    public function traitementDml()
    {
        return $this->hasOne(MissionTraitementDml::class);
    }
}
