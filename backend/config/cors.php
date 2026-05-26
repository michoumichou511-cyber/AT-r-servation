<?php

$localOrigins = [
    'http://localhost:3000',
    'http://localhost:5173',
    'http://localhost:5174',
    'http://localhost:5175',
    'http://localhost:5176',
    'http://localhost:5177',
    'http://localhost:5178',
    'http://127.0.0.1:3000',
    'http://127.0.0.1:5173',
    'http://127.0.0.1:5174',
    'http://127.0.0.1:5175',
    'http://127.0.0.1:5176',
    'http://127.0.0.1:5177',
    'http://127.0.0.1:5178',
    'http://192.168.1.12:8000',
    'http://192.168.1.12:19000',
];

$fromEnv = env('FRONTEND_URL');
$extraOrigins = [];
if (is_string($fromEnv) && $fromEnv !== '') {
    foreach (explode(',', $fromEnv) as $origin) {
        $origin = trim($origin);
        if ($origin !== '') {
            $extraOrigins[] = $origin;
        }
    }
}

return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'PATCH'],
    'allowed_origins' => array_values(array_unique(array_merge($localOrigins, $extraOrigins))),
    'allowed_origins_patterns' => [
        '#^https?://(localhost|127\.0\.0\.1)(:\d+)?$#',
    ],
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
        'X-Client-Type',
    ],
    'exposed_headers' => [],
    'max_age' => 3600,
    'supports_credentials' => true,
];