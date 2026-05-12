<?php

namespace App\Mail;

use App\Models\Mission;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class MissionModificationDemandee extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public Mission $mission,
        public string  $commentaire = ''
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '🔄 Modification demandée pour votre mission — AT Réservations',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.mission_modification_demandee',
            with: [
                'mission'      => $this->mission,
                'commentaire'  => $this->commentaire,
                'appUrl'       => config('app.url'),
                'nomComplet'   => trim(($this->mission->user?->prenom ?? '') . ' ' . ($this->mission->user?->nom ?? '')),
            ],
        );
    }
}
