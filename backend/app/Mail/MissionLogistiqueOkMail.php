<?php

namespace App\Mail;

use App\Models\Mission;
use App\Models\MissionTraitementDml;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class MissionLogistiqueOkMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Mission              $mission,
        public ?MissionTraitementDml $traitement = null
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '🚀 Logistique confirmée — Votre mission est prête',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.mission_logistique_ok',
            with: [
                'mission'    => $this->mission,
                'traitement' => $this->traitement,
                'appUrl'     => config('app.url'),
                'nomComplet' => trim(($this->mission->user?->prenom ?? '') . ' ' . ($this->mission->user?->nom ?? '')),
            ],
        );
    }
}
