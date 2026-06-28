<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthCheckTest extends TestCase
{
    public function test_health_endpoint_returns_ok(): void
    {
        $response = $this->getJson('/api/health');

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'timestamp',
                'version',
                'project',
                'checks' => ['database', 'storage', 'cache'],
                'stats',
            ]);
    }

    public function test_laravel_health_route_returns_ok(): void
    {
        $response = $this->get('/up');

        $response->assertStatus(200);
    }
}
