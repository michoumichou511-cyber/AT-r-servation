<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class BudgetsSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Aucune ligne insérée : les montants par direction seront saisis
     * via l’administration (données réelles, pas de démo).
     */
    public function run(): void
    {
        // Table budgets vide après migrate:fresh
    }
}
