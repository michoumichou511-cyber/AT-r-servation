<?php

namespace App\Mail;

use App\Models\Mission;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class MissionApprouvee extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(public Mission $mission) {}

    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '✅ Mission approuvée — AT Réservations',
        );
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.mission_validee',
            with: [
                'mission'    => $this->mission,
                'appUrl'     => config('app.url'),
                'nomComplet' => trim(($this->mission->user?->prenom ?? '') . ' ' . ($this->mission->user?->nom ?? '')),
            ],
        );
    }
}
