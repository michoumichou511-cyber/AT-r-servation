<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AuditLog extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected static function boot()
    {
        parent::boot();

        // `timestamps=false` => Eloquent ne remplit pas created_at automatiquement.
        // On force donc created_at si absent pour éviter les null côté dashboard.
        static::creating(function ($model) {
            if (empty($model->created_at)) {
                $model->created_at = now();
            }
        });
    }

    protected $fillable = [
        'user_id',
        'action',
        'module',
        'description',
        'ip_address',
        'user_agent',
        'old_values',
        'new_values',
        'created_at',
    ];

    protected $casts = [
        'old_values' => 'array',
        'new_values' => 'array',
        'created_at' => 'datetime',
    ];

    // ========== RELATIONS ==========

    public function user()
    {
        // User n'utilise pas SoftDeletes : withTrashed() jetait un
        // BadMethodCallException sur tout endpoint chargeant cette relation.
        return $this->belongsTo(User::class);
    }

    // ========== METHODS ==========

    public static function log($action, $module, $description, $oldValues = null, $newValues = null)
    {
        return self::create([
            'user_id' => auth()->id(),
            'action' => $action,
            'module' => $module,
            'description' => $description,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'old_values' => $oldValues,
            'new_values' => $newValues,
        ]);
    }

    // ========== SCOPES ==========

    public function scopeParAction($query, $action)
    {
        return $query->where('action', $action);
    }

    public function scopeParModule($query, $module)
    {
        return $query->where('module', $module);
    }

    public function scopeParUser($query, $userId)
    {
        return $query->where('user_id', $userId);
    }

    public function scopeRecemment($query, $jours = 7)
    {
        return $query->where('created_at', '>=', now()->subDays($jours));
    }

    public function scopeAujourdhui($query)
    {
        return $query->whereDate('created_at', now()->toDateString());
    }

    // ========== ACCESSORS ==========

    public function getActionFormatteeAttribute()
    {
        return match ($this->action) {
            'login' => '🔑 Connexion',
            'create' => '✨ Création',
            'update' => '📝 Modification',
            'delete' => '🗑️ Suppression',
            'approve' => '✅ Approbation',
            'reject' => '❌ Rejet',
            'export' => '📤 Export',
            default => $this->action,
        };
    }

    public function getModuleFormatteeAttribute()
    {
        return match ($this->module) {
            'mission' => '📋 Mission',
            'reservation' => '✈️ Réservation',
            'validation' => '✅ Validation',
            'user' => '👤 Utilisateur',
            'budget' => '💰 Budget',
            default => $this->module,
        };
    }
}
