<?php

namespace App\Enums;

enum MissionStatut: string
{
    case BROUILLON = 'brouillon';
    case SOUMIS = 'soumis';
    case EN_VALIDATION = 'en_validation';
    case APPROUVE = 'approuve';
    case REJETE = 'rejete';
    case ANNULE = 'annule';

    public function label(): string
    {
        return match ($this) {
            self::BROUILLON => 'Brouillon',
            self::SOUMIS => 'Soumis',
            self::EN_VALIDATION => 'En validation',
            self::APPROUVE => 'Approuvé',
            self::REJETE => 'Rejeté',
            self::ANNULE => 'Annulé',
        };
    }

    public function isEditable(): bool
    {
        return $this === self::BROUILLON;
    }

    public function canSubmit(): bool
    {
        return in_array($this, [self::BROUILLON, self::REJETE]);
    }

    public function isFinal(): bool
    {
        return in_array($this, [self::APPROUVE, self::ANNULE]);
    }
}
