<?php

namespace App\Mail;

use App\Models\Mission;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class MissionRejetee extends Mailable
{
    use Queueable, SerializesModels;

    public Mission $mission;

    public ?string $motif;

    public function __construct(Mission $mission, ?string $motif = null)
    {
        $this->mission = $mission;
        $this->motif = $motif;
    }

    public function build()
    {
        $ref = $this->mission->numero_unique ?? $this->mission->reference ?? (string) $this->mission->id;

        return $this
            ->subject('Mission rejetée — '.$ref)
            ->view('emails.mission-rejetee');
    }
}
