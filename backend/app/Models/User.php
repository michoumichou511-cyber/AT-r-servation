<?php

namespace App\Models;

use App\Traits\Loggable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Loggable, Notifiable;

    protected $fillable = [
        'nom',
        'prenom',
        'email',
        'password',
        'matricule',
        'service',
        'direction',
        'poste',
        'telephone',
        'avatar',
        'role_id',
        'structure_id',
        'is_active',
        'last_login_at',
        'preferences',
    ];

    protected $hidden = [
        'password',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'last_login_at' => 'datetime',
        'preferences' => 'array',
        'is_active' => 'boolean',
    ];

    // ========== RELATIONS ==========

    public function role()
    {
        return $this->belongsTo(Role::class);
    }

    public function missions()
    {
        return $this->hasMany(Mission::class);
    }

    public function reservations()
    {
        return $this->hasMany(Reservation::class);
    }

    public function documents()
    {
        return $this->hasMany(Document::class, 'uploaded_by');
    }

    public function documentsValides()
    {
        return $this->hasMany(Document::class, 'validated_by');
    }

    public function circuitsValidation()
    {
        return $this->hasMany(CircuitValidation::class, 'validateur_id');
    }

    // ========== SCOPES ==========

    public function scopeActif($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeInactif($query)
    {
        return $query->where('is_active', false);
    }

    public function scopeParRole($query, $roleName)
    {
        return $query->whereHas('role', fn ($q) => $q->where('name', $roleName));
    }

    public function scopeParDirection($query, $direction)
    {
        return $query->where('direction', $direction);
    }

    public function scopeParService($query, $service)
    {
        return $query->where('service', $service);
    }

    // ========== ACCESSORS ==========

    public function getNomCompletAttribute()
    {
        return trim($this->prenom.' '.$this->nom);
    }

    public function getInitialesAttribute()
    {
        return strtoupper(substr($this->prenom ?? '', 0, 1).substr($this->nom ?? '', 0, 1));
    }

    // ========== HELPERS ==========

    public function isAdmin()
    {
        return $this->role?->name === Role::ADMIN;
    }

    public function isDirecteur()
    {
        return $this->role?->name === Role::DIRECTEUR;
    }

    public function isAssistante()
    {
        return $this->role?->name === Role::ASSISTANTE;
    }

    public function isDemandeur()
    {
        return $this->role?->name === Role::DEMANDEUR;
    }

    public function isAgentDml()
    {
        return $this->role?->name === Role::AGENT_DML;
    }

    // Aliases rétro-compatibilité
    public function isValidateur()
    {
        return $this->isDirecteur();
    }

    public function isUtilisateur()
    {
        return $this->isAssistante();
    }

    public function hasRole(string $role): bool
    {
        return $this->role?->name === $role;
    }
}
