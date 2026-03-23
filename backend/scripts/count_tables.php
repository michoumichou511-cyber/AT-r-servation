<?php

require __DIR__.'/../vendor/autoload.php';
$app = require __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

use App\Models\Budget;
use App\Models\Mission;
use App\Models\Prestataire;
use App\Models\Role;
use App\Models\User;

echo 'roles: '.Role::count().PHP_EOL;
echo 'users: '.User::count().PHP_EOL;
echo 'prestataires: '.Prestataire::withoutGlobalScopes()->count().PHP_EOL;
echo 'missions: '.Mission::count().PHP_EOL;
echo 'budgets: '.Budget::count().PHP_EOL;
