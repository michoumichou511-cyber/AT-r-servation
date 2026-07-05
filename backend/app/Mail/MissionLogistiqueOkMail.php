<?php

namespace App\Mail;

use App\Models\Mission;
use App\Models\MissionTraitementDml;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

/**
 * E-mail envoyé au demandeur quand le service DML a finalisé
 * la logistique de sa mission (hôtel, transport).
 */
class MissionLogistiqueOkMail extends Mailable
{
    use Queueable, SerializesModels;

    public Mission $mission;

    public MissionTraitementDml $traitement;

    public function __construct(Mission $mission, MissionTraitementDml $traitement)
    {
        $this->mission = $mission;
        $this->traitement = $traitement;
    }

    public function build()
    {
        $ref = $this->mission->numero_unique ?? (string) $this->mission->id;

        return $this
            ->subject('Logistique confirmée — '.$ref)
            ->view('emails.mission-logistique-ok');
    }
}
