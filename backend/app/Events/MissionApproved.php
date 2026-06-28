<?php

namespace App\Events;

use App\Models\Mission;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MissionApproved
{
    use Dispatchable, SerializesModels;

    public function __construct(public Mission $mission, public string $commentaire = '') {}
}
