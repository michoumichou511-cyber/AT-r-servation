<?php

namespace App\Services;

use App\Mail\MissionSoumise;
use App\Models\AuditLog;
use App\Models\CircuitValidation;
use App\Models\Mission;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

class MissionService
{
    /**
     * Soumettre une mission pour validation.
     */
    public function submit(Mission $mission)
    {
        if ($mission->statut !== 'brouillon' && $mission->statut !== 'rejete') {
            throw new \Exception('Seule une mission en brouillon ou rejetée peut être soumise.');
        }

        // Vérifier s'il y a au moins une réservation
        if ($mission->reservations()->count() === 0) {
            throw new \Exception('Ajoutez au moins une réservation avant de soumettre');
        }

        $mission->loadMissing('user');
        $direction = $mission->user?->direction;

        $validateurs = collect();

        if ($direction) {
            $validateurs = User::whereHas('role', fn ($q) => $q->where('name', 'validateur'))
                ->actif()
                ->where('direction', $direction)
                ->orderBy('id')
                ->limit(1)
                ->get();
        }

        if ($validateurs->isEmpty()) {
            $structureId = $mission->user?->structure_id;
            if ($structureId) {
                $validateurs = User::whereHas('role', fn ($q) => $q->where('name', 'validateur'))
                    ->actif()
                    ->where('structure_id', $structureId)
                    ->orderBy('id')
                    ->limit(1)
                    ->get();
            }
        }

        if ($validateurs->isEmpty()) {
            $validateurs = User::whereHas('role', fn ($q) => $q->where('name', 'validateur'))
                ->actif()
                ->orderBy('id')
                ->limit(1)
                ->get();
        }

        if ($validateurs->isEmpty()) {
            throw new \Exception('Aucun validateur configuré');
        }

        return DB::transaction(function () use ($mission, $validateurs) {
            CircuitValidation::where('mission_id', $mission->id)->delete();

            $mission->update([
                'statut' => 'soumis',
                'soumis_le' => now(),
            ]);

            $creatorId = $mission->user_id ?? $mission->created_by;
            $autoApproved = false;

            foreach ($validateurs as $index => $validateur) {
                $isCreator = (int) $validateur->id === (int) $creatorId;
                CircuitValidation::create([
                    'mission_id' => $mission->id,
                    'validateur_id' => $validateur->id,
                    'ordre_validation' => $index + 1,
                    'statut' => $isCreator ? 'approuve' : 'en_attente',
                    'commentaire' => $isCreator ? 'Auto-validé (directeur/créateur)' : null,
                    'date_validation' => $isCreator ? now() : null,
                ]);
                if ($isCreator) {
                    $autoApproved = true;
                }
            }

            if ($autoApproved) {
                $allApproved = CircuitValidation::where('mission_id', $mission->id)
                    ->where('statut', '!=', 'approuve')
                    ->doesntExist();

                if ($allApproved) {
                    $mission->update(['statut' => 'approuve']);
                }
            }

            if ($validateurs->isNotEmpty() && ! $autoApproved) {
                $mission->loadMissing('user');
                $demandeur = $mission->user;
                if ($demandeur) {
                    foreach ($validateurs as $v) {
                        try {
                            Mail::to($v->email)->queue((new MissionSoumise($mission, $demandeur))->onConnection('database'));
                        } catch (\Throwable $e) {
                            Log::warning('Envoi e-mail validateur échoué (soumission maintenue)', [
                                'mission_id' => $mission->id,
                                'erreur' => $e->getMessage(),
                            ]);
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
    public function cancel(Mission $mission, ?string $motif = null)
    {
        if ($mission->statut === 'termine' || $mission->statut === 'annule') {
            throw new \Exception('Cette mission ne peut plus être annulée.');
        }

        return DB::transaction(function () use ($mission, $motif) {
            $mission->update([
                'statut' => 'annule',
                'motif_annulation' => $motif,
            ]);

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
        $logs = AuditLog::where('description', 'LIKE', "%{$mission->numero_unique}%")
            ->orWhere('description', 'LIKE', "%Mission #{$mission->id}%")
            ->orderBy('created_at')
            ->get();

        $circuit = CircuitValidation::where('mission_id', $mission->id)->with('validateur')->get();
        $timeline = [];

        foreach ($logs as $log) {
            $timeline[] = [
                'date' => $log->created_at->format('d/m/Y H:i:s'),
                'action' => $log->action,
                'description' => $log->description,
                'par' => $log->user ? $log->user->nom_complet : 'Système',
                'icone' => 'activity',
                'couleur' => 'blue',
            ];
        }

        foreach ($circuit as $step) {
            $timeline[] = [
                'date' => $step->updated_at->format('d/m/Y H:i:s'),
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
