<?php

namespace Tests\Feature;

use App\Models\AuditLog;
use App\Models\Role;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuditLogCreatedAtTest extends TestCase
{
    use RefreshDatabase;

    public function test_audit_log_created_at_is_filled_when_missing(): void
    {
        $role = Role::firstOrCreate(['name' => 'admin']);
        $user = User::factory()->create(['role_id' => $role->id]);

        $log = AuditLog::create([
            'user_id' => $user->id,
            'action' => 'create',
            'module' => 'user',
            'description' => 'Test created_at',
            'ip_address' => '127.0.0.1',
            'user_agent' => 'PHPUnit',
            'created_at' => null,
        ]);

        $this->assertNotNull($log->created_at);
    }
}
