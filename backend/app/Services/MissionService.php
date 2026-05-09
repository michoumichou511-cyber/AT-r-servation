<?php

namespace App\Services;

use App\Mail\MissionSoumise;
use App\Models\AuditLog;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;

class MissionService
{
    /**
     * Soumettre une mission pour validation.
     */
    public function submit(Mission $mission)
    {
        set_time_limit(30);

        if ($mission->statut !== 'brouillon' && $mission->statut !== 'rejete') {
            throw new \Exception('Seule une mission en brouillon ou rejetée peut être soumise.');
        }

        // Vérifier s'il y a au moins une réservation
        if ($mission->reservations()->count() === 0) {
            throw new \Exception('Ajoutez au moins une réservation avant de soumettre');
        }

        // Vérifier s'il y a des validateurs
        $validateurs = User::whereHas('role', function ($q) {
            $q->where('name', 'validateur');
        })->get();

        if ($validateurs->isEmpty()) {
            throw new \Exception('Aucun validateur configuré');
        }

        return DB::transaction(function () use ($mission) {
            // 1. Mettre à jour le statut
            $mission->update([
                'statut' => 'soumis',
                'soumis_le' => now(),
            ]);

            // 2. Créer le circuit de validation
            // On récupère les validateurs (selon service/direction ou rôle spécifique)
            // Pour cet exemple, on prend tous les utilisateurs avec le rôle 'validateur'
            $validateurs = User::whereHas('role', function ($q) {
                $q->where('name', 'validateur');
            })->get();

            foreach ($validateurs as $index => $validateur) {
                CircuitValidation::create([
                    'mission_id' => $mission->id,
                    'validateur_id' => $validateur->id,
                    'ordre_validation' => $index + 1,
                    'statut' => 'en_attente',
                ]);
            }

            if ($validateurs->isNotEmpty()) {
                $mission->loadMissing('user');
                $demandeur = $mission->user;
                if ($demandeur) {
                    foreach ($validateurs as $v) {
                        try {
                            // En local, éviter les blocages SMTP (timeouts) qui cassent la soumission.
                            // Le mail est journalisé via le mailer "log" (pas d'appel réseau).
                            Mail::mailer('log')->to($v->email)->queue(new MissionSoumise($mission, $demandeur));
                        } catch (\Exception $e) {
                            \Log::error($e->getMessage());
                        }
                    }
                }
            }

            return $mission;
        });
    }

    /**
     * Annuler une mission.
     */
    public function cancel(Mission $mission)
    {
        if ($mission->statut === 'termine' || $mission->statut === 'annule') {
            throw new \Exception('Cette mission ne peut plus être annulée.');
        }

        return DB::transaction(function () use ($mission) {
            $mission->update(['statut' => 'annule']);

            // Annuler le circuit de validation en cours
            CircuitValidation::where('mission_id', $mission->id)
                ->where('statut', 'en_attente')
                ->update(['statut' => 'rejete', 'commentaire' => 'Mission annulée par le demandeur']);

            return $mission;
        });
    }

    /**
     * Dupliquer une mission existante.
     */
    public function duplicate(Mission $mission)
    {
        return DB::transaction(function () use ($mission) {
            $newMission = $mission->replicate();
            $newMission->statut = 'brouillon';
            $newMission->numero_unique = null; // Sera généré par boot model
            $newMission->soumis_le = null;
            $newMission->titre = 'Copie de '.$mission->titre;
            $newMission->save();

            // Dupliquer les réservations si nécessaire
            foreach ($mission->reservations as $reservation) {
                $newRes = $reservation->replicate();
                $newRes->mission_id = $newMission->id;
                $newRes->statut = 'en_attente';
                $newRes->save();
            }

            return $newMission;
        });
    }

    /**
     * Récupérer la timeline d'une mission.
     */
    public function getTimeline(Mission $mission)
    {
        $logs = AuditLog::with('user')
            ->where(function ($q) use ($mission) {
                $q->where('description', 'LIKE', "%{$mission->numero_unique}%")
                  ->orWhere('description', 'LIKE', "%Mission #{$mission->id}%");
            })
            ->orderBy('created_at')
            ->get();

        $circuit = CircuitValidation::where('mission_id', $mission->id)->with('validateur')->get();
        $timeline = [];

        foreach ($logs as $log) {
            $timeline[] = [
                'date' => $log->created_at
                    ? $log->created_at->format('d/m/Y H:i:s')
                    : now()->format('d/m/Y H:i:s'),
                'action' => $log->action ?? '',
                'description' => $log->description ?? '',
                'par' => $log->user ? $log->user->nom_complet : 'Système',
                'icone' => 'activity',
                'couleur' => 'blue',
            ];
        }

        foreach ($circuit as $step) {
            $timeline[] = [
                'date' => $step->updated_at
                    ? $step->updated_at->format('d/m/Y H:i:s')
                    : now()->format('d/m/Y H:i:s'),
                'action' => 'Validation '.$step->statut.' - Étape '.$step->ordre_validation,
                'par' => $step->validateur
                    ? ($step->validateur->prenom.' '.$step->validateur->nom)
                    : 'Système',
                'icone' => $step->statut === 'approuve' ? 'check' : 'send',
                'couleur' => $step->statut === 'approuve' ? 'green' : 'orange',
                'commentaire' => $step->commentaire,
            ];
        }

        // Trier par date
        usort($timeline, function ($a, $b) {
            return strtotime($a['date']) - strtotime($b['date']);
        });

        return $timeline;
    }
}
