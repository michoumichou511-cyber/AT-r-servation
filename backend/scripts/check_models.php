<?php

require __DIR__.'/../vendor/autoload.php';
$app = require_once __DIR__.'/../bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$files = glob(__DIR__.'/../app/Models/*.php');
$results = [];

foreach ($files as $file) {
    $name = basename($file, '.php');
    $class = "App\\Models\\$name";

    try {
        if (! class_exists($class)) {
            $results[$class] = ['status' => 'missing_class'];

            continue;
        }

        // Try to instantiate the model; catch any boot-time exceptions
        try {
            $inst = new $class;
            $results[$class] = ['status' => 'ok'];
        } catch (Throwable $e) {
            $results[$class] = ['status' => 'error', 'message' => $e->getMessage()];
        }
    } catch (Throwable $e) {
        $results[$class] = ['status' => 'error', 'message' => $e->getMessage()];
    }
}

echo json_encode($results, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE).PHP_EOL;
