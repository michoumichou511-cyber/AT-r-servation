#!/usr/bin/env php
<?php

chdir(__DIR__);
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Role;
use App\Models\User;

echo "\n=== VÉRIFICATION COMPLÈTE ===\n\n";

echo "👤 UTILISATEURS:\n";
$users = User::with('role')->get();
foreach ($users as $user) {
    $roleName = $user->role ? $user->role->name : 'AUCUN';
    echo '  • '.$user->email.' => Rôle: '.$roleName."\n";
}

echo "\n🔐 RÔLES:\n";
$roles = Role::all();
foreach ($roles as $role) {
    $userCount = $role->users()->count();
    echo '  • '.$role->name.' => '.$userCount." utilisateur(s)\n";
}

echo "\n✅ VÉRIFICATION:\n";
echo '  • Total utilisateurs: '.User::count()."/4\n";
echo '  • Total rôles: '.Role::count()."/4\n";
echo '  • Admin existe: '.(User::whereHas('role', fn ($q) => $q->where('name', 'admin'))->exists() ? '✅' : '❌')."\n";
echo '  • Validateur existe: '.(User::whereHas('role', fn ($q) => $q->where('name', 'validateur'))->exists() ? '✅' : '❌')."\n";
echo '  • Utilisateur existe: '.(User::whereHas('role', fn ($q) => $q->where('name', 'utilisateur'))->exists() ? '✅' : '❌')."\n";
echo '  • Demandeur existe: '.(User::whereHas('role', fn ($q) => $q->where('name', 'demandeur'))->exists() ? '✅' : '❌')."\n";

echo "\n";
