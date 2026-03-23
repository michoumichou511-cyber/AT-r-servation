<?php

namespace App\Mail;

use App\Models\Mission;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class MissionSoumise extends Mailable
{
    use Queueable, SerializesModels;

    public Mission $mission;

    public User $demandeur;

    public function __construct(Mission $mission, User $demandeur)
    {
        $this->mission = $mission;
        $this->demandeur = $demandeur;
    }

    public function build()
    {
        $ref = $this->mission->numero_unique ?? $this->mission->reference ?? (string) $this->mission->id;

        return $this
            ->subject('Nouvelle mission à valider — '.$ref)
            ->view('emails.mission-soumise');
    }
}
