<?php

use App\Http\Controllers\Api\AdminAuditController;
use App\Http\Controllers\Api\AdminBudgetController;
use App\Http\Controllers\Api\AdminPrestataireController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\BilletController;
use App\Http\Controllers\Api\BonCommandeController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\DocumentController;
use App\Http\Controllers\Api\ExportController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\HebergementController;
use App\Http\Controllers\Api\MessageController;
use App\Http\Controllers\Api\MissionController;
use App\Http\Controllers\Api\NotificationController;
use App\Http\Controllers\Api\ReservationController;
use App\Http\Controllers\Api\RestaurationController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\ValidationController;
use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Route;

// ROUTES PUBLIQUES (sans auth) + THROTTLE ANTI-BRUTE FORCE
Route::get('/health', [HealthController::class, 'check']);

/** Route de test SMTP (à retirer en production) */
Route::get('/test-email', function () {
    Mail::raw(
        'Test email AT Réservations',
        function ($message) {
            $message->to(config('mail.from.address'))
                ->subject('Test AT Réservations');
        }
    );

    return response('Email envoyé !');
});

Route::middleware('throttle:5,1')->group(function () {
    Route::post('/auth/login', [AuthController::class, 'login']);
    Route::post('/auth/register', [AuthController::class, 'register']);
});

// GROUPE PRINCIPAL auth:sanctum + active + throttle:60,1
Route::middleware(['auth:sanctum', 'active', 'throttle:60,1'])->group(function () {
    // AUTH
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/users/by-structure', [UserController::class, 'byStructure']);

    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::put('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::post('/auth/change-password', [AuthController::class, 'changePassword']);
    Route::post('/auth/avatar', [AuthController::class, 'uploadAvatar']);
    Route::get('/profil/statistiques', [AuthController::class, 'statistiques']);

    // MISSIONS
    Route::get('/missions', [MissionController::class, 'index']);
    Route::post('/missions', [MissionController::class, 'store']);
    Route::get('/missions/export', [MissionController::class, 'export']);
    Route::get('/missions/{id}', [MissionController::class, 'show']);
    Route::put('/missions/{id}', [MissionController::class, 'update']);
    Route::delete('/missions/{id}', [MissionController::class, 'destroy']);
    Route::post('/missions/{id}/submit', [MissionController::class, 'submit']);
    Route::post('/missions/{id}/cancel', [MissionController::class, 'cancel']);
    Route::post('/missions/{id}/duplicate', [MissionController::class, 'duplicate']);
    Route::get('/missions/{id}/export/pdf', [MissionController::class, 'exportPdf']);
    Route::get('/missions/{id}/historique', [MissionController::class, 'historique']);
    Route::get('/missions/{id}/bons-commande', [BonCommandeController::class, 'parMission']);
    Route::put('/bons-commande/{id}/envoyer', [BonCommandeController::class, 'marquerEnvoye']);

    // RÉSERVATIONS
    Route::get('/missions/{mission_id}/reservations', [ReservationController::class, 'index']);
    Route::post('/missions/{mission_id}/reservations', [ReservationController::class, 'store']);
    Route::get('/reservations/{id}', [ReservationController::class, 'show']);
    Route::put('/reservations/{id}', [ReservationController::class, 'update']);
    Route::delete('/reservations/{id}', [ReservationController::class, 'destroy']);

    // BILLETS
    Route::post('/reservations/{reservation_id}/billet', [BilletController::class, 'store']);
    Route::put('/billets/{id}', [BilletController::class, 'update']);
    Route::delete('/billets/{id}', [BilletController::class, 'destroy']);
    Route::post('/billets/{id}/confirmer', [BilletController::class, 'confirmer']);

    // HÉBERGEMENTS
    Route::post('/reservations/{reservation_id}/hebergement', [HebergementController::class, 'store']);
    Route::put('/hebergements/{id}', [HebergementController::class, 'update']);
    Route::delete('/hebergements/{id}', [HebergementController::class, 'destroy']);
    Route::post('/hebergements/{id}/confirmer', [HebergementController::class, 'confirmer']);

    // RESTAURATIONS
    Route::post('/reservations/{reservation_id}/restauration', [RestaurationController::class, 'store']);
    Route::put('/restaurations/{id}', [RestaurationController::class, 'update']);
    Route::delete('/restaurations/{id}', [RestaurationController::class, 'destroy']);
    Route::post('/restaurations/{id}/confirmer', [RestaurationController::class, 'confirmer']);

    // VALIDATIONS
    Route::get('/validations', [ValidationController::class, 'index']);
    Route::get('/validations/mes-validations', [ValidationController::class, 'mesValidations']);
    Route::get('/validations/{id}', [ValidationController::class, 'show']);
    Route::post('/validations/{id}/approuver', [ValidationController::class, 'approuver']);
    Route::post('/validations/{id}/rejeter', [ValidationController::class, 'rejeter']);
    Route::post('/validations/{id}/modifier', [ValidationController::class, 'demanderModification']);

    // NOTIFICATIONS
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/non-lues/count', [NotificationController::class, 'nombreNonLues']);
    Route::put('/notifications/tout-lire', [NotificationController::class, 'marquerToutLu']);
    Route::put('/notifications/{id}/lire', [NotificationController::class, 'marquerLu']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'supprimer']);

    // MESSAGERIE
    Route::get('/conversations', [MessageController::class, 'conversations']);
    Route::get('/conversations/{id}/messages', [MessageController::class, 'messages']);
    Route::post('/messages', [MessageController::class, 'envoyer']);
    Route::put('/messages/{id}/lire', [MessageController::class, 'marquerLu']);
    Route::get('/messages/non-lus/count', [MessageController::class, 'nonLusCount']);

    // DOCUMENTS
    Route::get('/missions/{mission_id}/documents', [DocumentController::class, 'index']);
    Route::post('/missions/{mission_id}/documents', [DocumentController::class, 'store']);
    Route::delete('/documents/{id}', [DocumentController::class, 'destroy']);
    Route::get('/documents/{id}/telecharger', [DocumentController::class, 'telecharger']);

    // DASHBOARD
    Route::get('/dashboard/stats', [DashboardController::class, 'stats']);
    Route::get('/dashboard/missions-du-mois', [DashboardController::class, 'missionsDuMois']);
    Route::get('/dashboard/depenses-par-direction', [DashboardController::class, 'depensesParDirection']);
    Route::get('/dashboard/alertes', [DashboardController::class, 'alertes']);
    Route::get('/dashboard/validateur', [DashboardController::class, 'dashboardValidateur']);

    // SEARCH
    Route::get('/search', [SearchController::class, 'search']);

    // CALENDRIER
    Route::get('/calendrier', [MissionController::class, 'calendrier']);

    // CONTACTS (liste utilisateurs actifs pour la messagerie)
    Route::get('/utilisateurs/contacts', [AdminUserController::class, 'listeContacts']);

    // PRESTATAIRES
    Route::get('/prestataires', [AdminPrestataireController::class, 'listePrestataires']);
    Route::get('/prestataires/favoris', [AdminPrestataireController::class, 'prestaFavoris']);
    Route::get('/prestataires/{id}', [AdminPrestataireController::class, 'show']);
    Route::post('/prestataires/{id}/favori', [AdminPrestataireController::class, 'toggleFavori']);
    Route::post('/prestataires/{id}/evaluer', [AdminPrestataireController::class, 'evaluerPrestataire']);
    Route::get('/prestataires/{id}/evaluations', [AdminPrestataireController::class, 'evaluationsPrestataire']);

    // EXPORTS (throttle spécial : 10/heure)
    Route::middleware('throttle:10,60')->group(function () {
        Route::get('/export/missions/excel', [ExportController::class, 'exportMissionsExcel']);
        Route::get('/export/missions/pdf', [ExportController::class, 'exportMissionsPdf']);
        Route::get('/export/depenses/excel', [ExportController::class, 'exportDepensesExcel']);
        Route::get('/export/prestataires/excel', [ExportController::class, 'exportPrestatairesExcel']);
    });

    // ADMIN (role:admin uniquement)
    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/utilisateurs', [AdminUserController::class, 'listeUtilisateurs']);
        Route::put('/utilisateurs/{id}/toggle-active', [AdminUserController::class, 'activerDesactiver']);
        Route::put('/utilisateurs/{id}/role', [AdminUserController::class, 'changerRole']);
        Route::post('/prestataires', [AdminPrestataireController::class, 'creerPrestataire']);
        Route::get('/prestataires/{id}', [AdminPrestataireController::class, 'show']);
        Route::put('/prestataires/{id}', [AdminPrestataireController::class, 'modifierPrestataire']);
        Route::delete('/prestataires/{id}', [AdminPrestataireController::class, 'supprimerPrestataire']);
        Route::get('/budgets', [AdminBudgetController::class, 'gererBudgets']);
        Route::post('/budgets', [AdminBudgetController::class, 'creerBudget']);
        Route::put('/budgets/{id}', [AdminBudgetController::class, 'modifierBudget']);
        Route::get('/audit-logs', [AdminAuditController::class, 'auditLogs']);
        Route::get('/statistiques', [DashboardController::class, 'adminStatistiques']);
    });
});
