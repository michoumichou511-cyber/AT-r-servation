<?php

namespace App\Constants;

class MissionStatut
{
    const BROUILLON = 'brouillon';

    const SOUMIS = 'soumis';

    const EN_VALIDATION = 'en_validation';

    const APPROUVE = 'approuve';

    const REJETE = 'rejete';

    const ANNULE = 'annule';

    const TERMINE = 'termine';

    const COULEURS = [
        'brouillon' => '#9E9E9E',
        'soumis' => '#2196F3',
        'en_validation' => '#FF9800',
        'approuve' => '#00A650',
        'rejete' => '#F44336',
        'annule' => '#607D8B',
        'termine' => '#4CAF50',
    ];

    const LABELS = [
        'brouillon' => 'Brouillon',
        'soumis' => 'Soumis',
        'en_validation' => 'En validation',
        'approuve' => 'Approuvé',
        'rejete' => 'Rejeté',
        'annule' => 'Annulé',
        'termine' => 'Terminé',
    ];
}
