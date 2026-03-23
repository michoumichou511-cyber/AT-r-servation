<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Throttle Configuration
    |--------------------------------------------------------------------------
    |
    | Define the throttle configurations for different types of requests.
    | These configurations are used by the throttle middleware.
    |
    */

    'login' => [
        'max_attempts' => 5,
        'decay_minutes' => 1,
        'lockout_duration' => 15, // minutes
    ],

    'api' => [
        'max_attempts' => 60,
        'decay_minutes' => 1,
    ],

    'export' => [
        'max_attempts' => 10,
        'decay_minutes' => 60, // 1 hour
    ],

    'admin' => [
        'max_attempts' => 30,
        'decay_minutes' => 1,
    ],

];
