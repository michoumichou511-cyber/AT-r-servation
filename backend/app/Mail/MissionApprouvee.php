<?php

namespace App\Mail;

use App\Models\Mission;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class MissionApprouvee extends Mailable
{
    use Queueable, SerializesModels;

    public Mission $mission;

    public function __construct(Mission $mission)
    {
        $this->mission = $mission;
    }

    public function build()
    {
        $ref = $this->mission->numero_unique ?? $this->mission->reference ?? (string) $this->mission->id;

        return $this
            ->subject('Mission approuvée — '.$ref)
            ->view('emails.mission-approuvee');
    }
}
