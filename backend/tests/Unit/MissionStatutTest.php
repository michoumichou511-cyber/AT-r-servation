<?php

namespace Tests\Unit;

use App\Enums\MissionStatut;
use PHPUnit\Framework\TestCase;

class MissionStatutTest extends TestCase
{
    public function test_brouillon_is_editable(): void
    {
        $this->assertTrue(MissionStatut::BROUILLON->isEditable());
        $this->assertFalse(MissionStatut::SOUMIS->isEditable());
        $this->assertFalse(MissionStatut::APPROUVE->isEditable());
    }

    public function test_can_submit_from_brouillon_or_rejete(): void
    {
        $this->assertTrue(MissionStatut::BROUILLON->canSubmit());
        $this->assertTrue(MissionStatut::REJETE->canSubmit());
        $this->assertFalse(MissionStatut::SOUMIS->canSubmit());
        $this->assertFalse(MissionStatut::APPROUVE->canSubmit());
    }

    public function test_approuve_and_annule_are_final(): void
    {
        $this->assertTrue(MissionStatut::APPROUVE->isFinal());
        $this->assertTrue(MissionStatut::ANNULE->isFinal());
        $this->assertFalse(MissionStatut::BROUILLON->isFinal());
        $this->assertFalse(MissionStatut::SOUMIS->isFinal());
    }

    public function test_labels_are_french(): void
    {
        $this->assertEquals('Brouillon', MissionStatut::BROUILLON->label());
        $this->assertEquals('Approuvé', MissionStatut::APPROUVE->label());
        $this->assertEquals('Rejeté', MissionStatut::REJETE->label());
    }

    public function test_all_statuts_have_values(): void
    {
        $cases = MissionStatut::cases();
        $this->assertCount(6, $cases);

        foreach ($cases as $case) {
            $this->assertNotEmpty($case->value);
            $this->assertNotEmpty($case->label());
        }
    }
}
