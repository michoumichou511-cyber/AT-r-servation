<?php

require 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Http\Kernel')
    ->handle(Illuminate\Http\Request::capture());

use App\Models\User;

echo "\n=== UTILISATEURS EN BASE ===\n";
$users = User::all(['id', 'email', 'nom', 'prenom', 'role_id']);
foreach ($users as $user) {
    echo $user->id.' => '.$user->email.' (Role ID: '.$user->role_id.")\n";
}
echo "\nTotal: ".count($users)." utilisateurs\n";
echo "\n";
