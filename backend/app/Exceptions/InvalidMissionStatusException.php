<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

class InvalidMissionStatusException extends HttpException
{
    public function __construct(string $currentStatus, string $attemptedAction)
    {
        parent::__construct(
            422,
            "Impossible de {$attemptedAction} une mission au statut « {$currentStatus} »."
        );
    }
}
