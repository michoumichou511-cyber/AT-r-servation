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

    // Constants
    const ADMIN = 'admin';

    const VALIDATEUR = 'validateur';

    const UTILISATEUR = 'utilisateur';

    const DEMANDEUR = 'demandeur';

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

    public function isValidateur()
    {
        return $this->name === self::VALIDATEUR;
    }

    public function isUtilisateur()
    {
        return $this->name === self::UTILISATEUR;
    }

    public function isDemandeur()
    {
        return $this->name === self::DEMANDEUR;
    }

    public function hasPermission($permission)
    {
        return in_array($permission, $this->permissions ?? []);
    }
}
