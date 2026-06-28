<?php

namespace App\Events;

use App\Models\Mission;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class MissionRejected
{
    use Dispatchable, SerializesModels;

    public function __construct(public Mission $mission, public string $motif = '') {}
}
