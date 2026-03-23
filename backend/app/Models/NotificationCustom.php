<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class NotificationCustom extends Model
{
    use HasFactory;

    protected $table = 'notifications_custom';

    protected $fillable = [
        'user_id',
        'titre',
        'message',
        'type',
        'is_read',
        'lue',
        'read_at',
        'action_url',
        'categorie',
        'notifiable_type',
        'notifiable_id',
    ];

    protected $casts = [
        'read_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function notifiable()
    {
        return $this->morphTo();
    }
}
