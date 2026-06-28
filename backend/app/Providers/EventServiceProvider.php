<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        \App\Events\MissionSubmitted::class => [
            \App\Listeners\NotifyValidateursOnSubmission::class,
        ],
        \App\Events\MissionApproved::class => [
            \App\Listeners\NotifyOwnerOnApproval::class,
        ],
        \App\Events\MissionRejected::class => [
            \App\Listeners\NotifyOwnerOnRejection::class,
        ],
    ];
}
