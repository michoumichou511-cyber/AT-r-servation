<?php

namespace App\Providers;

use App\Models\Mission;
use App\Models\Reservation;
use App\Observers\MissionObserver;
use App\Observers\ReservationObserver;
use Illuminate\Support\Facades\App;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // H-04 fix : force la locale FR pour les messages de validation Laravel
        // (les fichiers de traduction se trouvent dans backend/lang/fr/)
        App::setLocale('fr');

        Mission::observe(MissionObserver::class);
        Reservation::observe(ReservationObserver::class);
    }
}
