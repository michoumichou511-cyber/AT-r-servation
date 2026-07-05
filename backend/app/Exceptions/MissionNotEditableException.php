<?php

namespace App\Exceptions;

use Symfony\Component\HttpKernel\Exception\HttpException;

class MissionNotEditableException extends HttpException
{
    public function __construct()
    {
        parent::__construct(
            403,
            'Seules les missions en brouillon peuvent être modifiées.'
        );
    }
}
