<?php

namespace App\Events;

use App\Models\Mission;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MissionSubmitted
{
    use Dispatchable, SerializesModels;

    public function __construct(public Mission $mission) {}
}
