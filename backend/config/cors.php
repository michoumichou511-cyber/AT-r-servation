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
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => array_values(array_unique(array_merge(
        $localOrigins,
        $extraOrigins,
        [
            // Production : frontend deploye sur Vercel
            'https://at-reservations.vercel.app',
        ]
    ))),
    /** Vite peut prendre n’importe quel port libre (5173+) +
     *  toutes les previews Vercel (*.vercel.app) + tunnels ngrok */
    'allowed_origins_patterns' => [
        '#^https?://(localhost|127\.0\.0\.1)(:\d+)?$#',
        '#^https://[a-z0-9-]+\.vercel\.app$#',
        '#^https://[a-z0-9-]+\.ngrok(-free)?\.(app|dev|io)$#',
    ],
    'allowed_headers' => [
        'Content-Type',
        'Authorization',
        'X-Requested-With',
        'Accept',
        'Origin',
    ],
    'exposed_headers' => [],
    'max_age' => 3600,
    'supports_credentials' => true,
];
