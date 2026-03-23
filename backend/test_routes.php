<?php

require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\Http;

echo "=== TEST BACKEND AT RESERVATIONS ===\n\n";

// Test login tous les roles
$comptes = [
    'admin' => ['email' => 'admin@at.dz',      'password' => 'Password@123'],
    'validateur' => ['email' => 'validateur@at.dz',  'password' => 'Password@123'],
    'utilisateur' => ['email' => 'user@at.dz',        'password' => 'Password@123'],
    'demandeur' => ['email' => 'demandeur@at.dz',   'password' => 'Password@123'],
];

$tokens = [];
echo "--- LOGIN ---\n";
foreach ($comptes as $role => $creds) {
    $attempt = 0;
    do {
        $attempt++;
        $r = Http::acceptJson()->post('http://127.0.0.1:8000/api/auth/login', $creds);
        if ($r->status() !== 429) {
            break;
        }
        sleep(2); // évite le flakiness dû au throttle Laravel
    } while ($attempt < 3);

    $body = $r->json();
    $token = $body['data']['token'] ?? $body['token'] ?? null;
    $tokens[$role] = $token;
    $icon = $token ? 'OK' : 'ECHEC';
    echo $icon.'  '.$r->status().'  ->  login '.$role."\n";
    if (! $token) {
        echo '     Reponse: '.json_encode($body)."\n";
    }
}

$token = $tokens['admin'];
if (! $token) {
    echo "\nImpossible de continuer sans token admin.\n";
    exit(1);
}

// Routes a tester avec admin
$routes = [
    '/auth/me',
    '/missions',
    '/dashboard/stats',
    '/dashboard/alertes',
    '/dashboard/missions-du-mois',
    '/dashboard/depenses-par-direction',
    '/dashboard/validateur',
    '/notifications',
    '/notifications/non-lues/count',
    '/conversations',
    '/messages/non-lus/count',
    '/prestataires',
    '/prestataires/favoris',
    '/admin/utilisateurs',
    '/admin/budgets',
    '/admin/audit-logs',
    '/health',
    '/calendrier',
    '/profil/statistiques',
    '/search?q=test',
];

echo "\n--- ROUTES ADMIN ---\n";
foreach ($routes as $path) {
    $r = Http::withToken($token)->acceptJson()->get('http://127.0.0.1:8000/api'.$path);
    $s = $r->status();
    $icon = $s === 200 ? 'OK' : ($s === 429 ? 'THROTTLED' : ($s === 404 ? 'MANQUANT' : 'ERREUR'));
    echo $icon.'  '.$s.'  ->  /api'.$path."\n";
}

// Vérification dédiée export Excel missions (.xlsx réel)
echo "\n--- VÉRIF EXPORT EXCEL (MISSIONS) ---\n";
$exportUrl = 'http://127.0.0.1:8000/api/export/missions/excel';
$exportOk = false;
$exportAttempt = 0;
do {
    $exportAttempt++;
    $rExport = Http::withToken($token)->get($exportUrl);
    $sExport = $rExport->status();
    if ($sExport === 429) {
        echo "THROTTLED  429  -> GET /api/export/missions/excel (retry)\n";
        sleep(20);

        continue;
    }

    $contentType = (string) $rExport->header('content-type');
    $contentDisp = (string) $rExport->header('content-disposition');
    $body = $rExport->body();
    // Un fichier .xlsx est un zip : le contenu commence par "PK"
    $hasPkHeader = is_string($body) && str_starts_with($body, 'PK');
    $isXlsx = str_contains(strtolower($contentType), 'spreadsheetml') || str_contains(strtolower($contentDisp), '.xlsx');

    if ($sExport === 200 && ($isXlsx || $hasPkHeader)) {
        $exportOk = true;
        echo "OK  200  -> GET /api/export/missions/excel (xlsx)\n";
        break;
    }

    echo "ERREUR  {$sExport}  -> GET /api/export/missions/excel\n";
    echo "          content-type: {$contentType}\n";
    echo "          content-disposition: {$contentDisp}\n";
    // En cas d'erreur, on affiche aussi un extrait de la body (utile si HTML/JSON erreur)
    $bodyPreview = $body;
    if (is_string($bodyPreview) && strlen($bodyPreview) > 500) {
        $bodyPreview = substr($bodyPreview, 0, 500).'...';
    }
    echo '          body (preview): '.(is_string($bodyPreview) ? $bodyPreview : json_encode($bodyPreview))."\n";
    break;
} while ($exportAttempt < 6);

if (! $exportOk) {
    echo "\nTEST INTERROMPU : l’export Excel missions n’est pas un .xlsx valide.\n";
    exit(1);
}

// Vérification dédiée évaluation prestataires
echo "\n--- VÉRIF ÉVALUATIONS PRESTATAIRES ---\n";
$prestatairesResp = Http::withToken($token)->acceptJson()->get('http://127.0.0.1:8000/api/prestataires');
$prestatairesJson = $prestatairesResp->json();
$prestatairesItems = $prestatairesJson['data'] ?? [];

// Cherche un prestataire jamais évalué (pour éviter 409 lors de relances du script)
$prestataireId = null;
foreach ($prestatairesItems as $item) {
    $candidateId = $item['id'] ?? null;
    if (! $candidateId) {
        continue;
    }

    $tmpListResp = Http::withToken($token)->acceptJson()->get('http://127.0.0.1:8000/api/prestataires/'.$candidateId.'/evaluations');
    if ($tmpListResp->status() !== 200) {
        continue;
    }

    $tmpJson = $tmpListResp->json();
    // Support ancien format {stats:...} et nouveau format ApiResponse {data:{stats:...}}
    $total = $tmpJson['data']['stats']['total_evaluations'] ?? $tmpJson['stats']['total_evaluations'] ?? 0;
    if ((int) $total === 0) {
        $prestataireId = $candidateId;
        break;
    }
}

// Si aucun prestataire n'existe, on en crée un (sinon l'évaluation ne peut pas être testée)
if (! $prestataireId) {
    echo "INFO : aucun prestataire éligible (non évalué) trouvé, création via /api/admin/prestataires...\n";
    $createResp = Http::withToken($token)->acceptJson()->post('http://127.0.0.1:8000/api/admin/prestataires', [
        'nom' => 'Prestataire test auto',
        'type' => 'hotel',
        'ville' => 'Alger',
        'adresse' => 'Test',
        'telephone' => null,
        'email' => null,
        'site_web' => null,
        'note_performance' => 0,
    ]);
    if ($createResp->status() !== 201) {
        echo 'ERREUR : création prestataire échouée: '.$createResp->status()."\n";
        echo json_encode($createResp->json())."\n";
        exit(1);
    }

    // Support ancien format {prestataire:...} et nouveau format ApiResponse {data:{prestataire:...}}
    $prestataireId = $createResp->json()['data']['prestataire']['id'] ?? $createResp->json()['prestataire']['id'] ?? null;
}

if (! $prestataireId) {
    echo "ERREUR : impossible de récupérer un prestataire pour tester l'évaluation.\n";
    exit(1);
}

$evalResp = Http::withToken($token)->acceptJson()->post('http://127.0.0.1:8000/api/prestataires/'.$prestataireId.'/evaluer', [
    'reservation_id' => null,
    'ponctualite' => 4,
    'qualite_service' => 5,
    'rapport_qualite_prix' => 4,
    'communication' => 3,
    'commentaire' => 'Test évaluation prestataire (script)',
]);

$evalStatus = $evalResp->status();
echo (($evalStatus === 201) ? 'OK' : 'ERREUR').'  '.$evalStatus.'  -> POST /api/prestataires/'.$prestataireId.'/evaluer'."\n";
if ($evalStatus !== 201) {
    echo '   réponse: '.json_encode($evalResp->json())."\n";
    exit(1);
}

$evalJson = $evalResp->json();
// Support ancien format {data:{note_globale:...}} et nouveau {data:{evaluation:{note_globale:...}}}
$noteGlobale = $evalJson['data']['evaluation']['note_globale'] ?? $evalJson['data']['note_globale'] ?? null;
if ($noteGlobale === null) {
    echo "ERREUR : champ note_globale absent dans la réponse évaluation.\n";
    echo '   réponse: '.json_encode($evalJson)."\n";
    exit(1);
}

$listResp = Http::withToken($token)->acceptJson()->get('http://127.0.0.1:8000/api/prestataires/'.$prestataireId.'/evaluations');
$listStatus = $listResp->status();
echo (($listStatus === 200) ? 'OK' : 'ERREUR').'  '.$listStatus.'  -> GET /api/prestataires/'.$prestataireId.'/evaluations'."\n";
if ($listStatus !== 200) {
    echo '   réponse: '.json_encode($listResp->json())."\n";
    exit(1);
}

$listJson = $listResp->json();
// Support ancien format {stats:{note_globale:...}} et nouveau ApiResponse {data:{stats:{note_globale:...}}}
$noteGlobaleList = $listJson['data']['stats']['note_globale'] ?? $listJson['stats']['note_globale'] ?? null;
if ($noteGlobaleList === null) {
    echo "ERREUR : champ stats.note_globale absent dans la réponse GET évaluations.\n";
    echo '   réponse: '.json_encode($listJson)."\n";
    exit(1);
}

echo "OK : évaluation prestataire testée (note_globale={$noteGlobale}).\n";

// Test creation mission
echo "\n--- TEST CREATION MISSION ---\n";
$tokenU = $tokens['utilisateur'];
if ($tokenU) {
    $m = Http::withToken($tokenU)->acceptJson()->post('http://127.0.0.1:8000/api/missions', [
        'titre' => 'Mission test backend',
        'objet_mission' => 'Objet de la mission (test)',
        'type_mission' => 'formation',
        'destination_ville' => 'Paris',
        'destination_pays' => 'France',
        'date_depart' => '2026-04-10',
        'date_retour' => '2026-04-15',
        'priorite' => 'normale',
        'budget_previsionnel' => 150000,
        'objectif' => 'Tester la creation de mission',
    ]);
    $s = $m->status();
    echo ($s === 201 || $s === 200 ? 'OK' : 'ERREUR').'  '.$s.'  ->  POST /api/missions'."\n";
    if ($s === 201 || $s === 200) {
        $json = $m->json();
        $missionId = $json['data']['id'] ?? $json['id'] ?? null;
        echo '     Mission ID cree: '.$missionId."\n";
        if ($missionId) {
            $bc = Http::withToken($token)->get('http://127.0.0.1:8000/api/missions/'.$missionId.'/bons-commande');
            echo ($bc->status() === 200 ? 'OK' : 'ERREUR').'  '.$bc->status().'  ->  GET /api/missions/'.$missionId.'/bons-commande'."\n";
        }
        if (! $missionId) {
            echo '     Debug réponse mission: '.(is_string($m->body()) ? $m->body() : json_encode($json))."\n";
        }
    } else {
        echo '     Erreur: '.json_encode($m->json())."\n";
    }
} else {
    echo "ECHEC  token utilisateur manquant\n";
}

// Test messagerie
echo "\n--- TEST MESSAGERIE ---\n";
$tokenD = $tokens['demandeur'];
if ($tokenD) {
    // Envoyer un message
    $msg = Http::withToken($tokenD)->acceptJson()->post('http://127.0.0.1:8000/api/messages', [
        'receiver_id' => 1,
        'contenu' => 'Message de test depuis le script',
    ]);
    $s = $msg->status();
    echo ($s === 200 || $s === 201 ? 'OK' : 'ERREUR').'  '.$s.'  ->  POST /api/messages'."\n";
    if ($s !== 200 && $s !== 201) {
        echo '     Erreur: '.json_encode($msg->json())."\n";
    }

    // Voir les conversations
    $convs = Http::withToken($tokenD)->acceptJson()->get('http://127.0.0.1:8000/api/conversations');
    echo ($convs->status() === 200 ? 'OK' : 'ERREUR').'  '.$convs->status().'  ->  GET /api/conversations'."\n";
} else {
    echo "ECHEC  token demandeur manquant\n";
}

// Routes demandeur - visibilite
echo "\n--- VISIBILITE DEMANDEUR ---\n";
if ($tokenD) {
    $routesD = ['/missions', '/dashboard/stats', '/notifications', '/conversations'];
    foreach ($routesD as $path) {
        $r = Http::withToken($tokenD)->acceptJson()->get('http://127.0.0.1:8000/api'.$path);
        $s = $r->status();
        $icon = $s === 200 ? 'OK' : ($s === 403 ? 'REFUSE' : 'ERREUR');
        echo $icon.'  '.$s.'  ->  /api'.$path."\n";
    }
    // Test que le demandeur ne peut PAS acceder a admin
    $r = Http::withToken($tokenD)->acceptJson()->get('http://127.0.0.1:8000/api/admin/utilisateurs');
    $s = $r->status();
    echo ($s === 403 ? 'OK BLOQUE' : 'DANGER NON BLOQUE').'  '.$s.'  ->  /api/admin/utilisateurs (doit etre 403)'."\n";
}

echo "\n=== FIN DES TESTS ===\n";
