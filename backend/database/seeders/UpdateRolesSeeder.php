<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class UpdateRolesSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Renommer "validateur" → "directeur" (users.role_id est FK donc la ligne reste intacte)
        $updated1 = DB::table('roles')
            ->where('name', 'validateur')
            ->update([
                'name'        => 'directeur',
                'description' => 'Directeur — approuve les missions de sa direction',
                'updated_at'  => now(),
            ]);
        $this->command->info($updated1 ? '✓ validateur → directeur' : '  (validateur déjà renommé ou absent)');

        // 2. Renommer "utilisateur" → "assistante"
        $updated2 = DB::table('roles')
            ->where('name', 'utilisateur')
            ->update([
                'name'        => 'assistante',
                'description' => 'Assistante — crée des missions pour les demandeurs',
                'updated_at'  => now(),
            ]);
        $this->command->info($updated2 ? '✓ utilisateur → assistante' : '  (utilisateur déjà renommé ou absent)');

        // 3. Ajouter "agent_dml" s'il n'existe pas encore
        $exists = DB::table('roles')->where('name', 'agent_dml')->exists();
        if (! $exists) {
            DB::table('roles')->insert([
                'name'        => 'agent_dml',
                'description' => 'Agent DML — traitement logistique après validation',
                'permissions' => json_encode(['view_missions_validees', 'traiter_mission']),
                'created_at'  => now(),
                'updated_at'  => now(),
            ]);
            $this->command->info('✓ Rôle agent_dml créé');
        } else {
            $this->command->info('  (agent_dml existe déjà)');
        }

        $this->command->info('');
        $this->command->info('Rôles finaux :');
        DB::table('roles')->orderBy('id')->get(['id', 'name', 'description'])
            ->each(fn ($r) => $this->command->line("  [{$r->id}] {$r->name} — {$r->description}"));
    }
}
