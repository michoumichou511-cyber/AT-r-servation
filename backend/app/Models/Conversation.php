<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Conversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'participant_1_id',
        'participant_2_id',
        'mission_id',
        'dernier_message',
        'dernier_message_at',
    ];

    protected $casts = [
        'dernier_message_at' => 'datetime',
    ];

    public function participant1()
    {
        return $this->belongsTo(User::class, 'participant_1_id');
    }

    public function participant2()
    {
        return $this->belongsTo(User::class, 'participant_2_id');
    }

    public function messages()
    {
        return $this->hasMany(Message::class);
    }

    public function mission()
    {
        return $this->belongsTo(Mission::class);
    }
}
