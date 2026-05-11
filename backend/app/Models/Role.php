<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Role extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'permissions',
    ];

    protected $casts = [
        'permissions' => 'array',
    ];

    // Constants — 5 rôles officiels
    const ADMIN      = 'admin';
    const DIRECTEUR  = 'directeur';   // ex-validateur
    const ASSISTANTE = 'assistante';  // ex-utilisateur
    const DEMANDEUR  = 'demandeur';
    const AGENT_DML  = 'agent_dml';

    // Aliases de rétro-compatibilité (à supprimer quand tout le code est migré)
    const VALIDATEUR  = 'directeur';
    const UTILISATEUR = 'assistante';

    // ========== RELATIONS ==========

    public function users()
    {
        return $this->hasMany(User::class);
    }

    // ========== HELPERS ==========

    public function isAdmin()
    {
        return $this->name === self::ADMIN;
    }

    public function isDirecteur()
    {
        return $this->name === self::DIRECTEUR;
    }

    public function isAssistante()
    {
        return $this->name === self::ASSISTANTE;
    }

    public function isDemandeur()
    {
        return $this->name === self::DEMANDEUR;
    }

    public function isAgentDml()
    {
        return $this->name === self::AGENT_DML;
    }

    // Alias rétro-compatibilité
    public function isValidateur()
    {
        return $this->isDirecteur();
    }

    public function isUtilisateur()
    {
        return $this->isAssistante();
    }

    public function hasPermission($permission)
    {
        return in_array($permission, $this->permissions ?? []);
    }
}
