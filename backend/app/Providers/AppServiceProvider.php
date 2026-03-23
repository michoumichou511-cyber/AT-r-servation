<?php

namespace App\Providers;

use App\Models\Mission;
use App\Models\Reservation;
use App\Observers\MissionObserver;
use App\Observers\ReservationObserver;
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
        Mission::observe(MissionObserver::class);
        Reservation::observe(ReservationObserver::class);
    }
}
