<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class DelegationValidation extends Model
{
    protected $table = 'delegations_validation';

    protected $fillable = [
        'delegant_id',
        'delegue_id',
        'date_debut',
        'date_fin',
        'motif',
        'active',
    ];

    protected $casts = [
        'date_debut' => 'date',
        'date_fin' => 'date',
        'active' => 'boolean',
    ];

    public function delegant()
    {
        return $this->belongsTo(User::class, 'delegant_id');
    }

    public function delegue()
    {
        return $this->belongsTo(User::class, 'delegue_id');
    }
}
