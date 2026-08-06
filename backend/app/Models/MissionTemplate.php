<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MissionTemplate extends Model
{
    protected $fillable = [
        'user_id',
        'nom_template',
        'mission_data',
        'is_public',
    ];

    protected $casts = [
        'mission_data' => 'array',
        'is_public' => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
