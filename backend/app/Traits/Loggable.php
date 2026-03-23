<?php

namespace App\Traits;

use App\Models\AuditLog;

trait Loggable
{
    /**
     * Enregistrer une action dans les logs d'audit
     *
     * @param  string  $action  (login, create, update, delete, approve, reject, export)
     * @param  string  $module  (mission, reservation, validation, user, budget)
     * @param  string  $description  Description de l'action
     * @param  array|null  $oldValues  Valeurs avant modification
     * @param  array|null  $newValues  Valeurs après modification
     * @return AuditLog
     */
    public static function log($action, $module, $description, $oldValues = null, $newValues = null)
    {
        return AuditLog::create([
            'user_id' => auth()->id(),
            'action' => $action,
            'module' => $module,
            'description' => $description,
            'ip_address' => request()->ip(),
            'user_agent' => request()->userAgent(),
            'old_values' => $oldValues,
            'new_values' => $newValues,
        ]);
    }

    /**
     * Boot du trait - enregistre les modifications
     */
    protected static function bootLoggable()
    {
        static::updating(function ($model) {
            if (auth()->check()) {
                $oldValues = $model->getOriginal();
                $newValues = $model->getDirty();

                $moduleName = \Illuminate\Support\Str::snake(class_basename($model));
                static::log(
                    'update',
                    $moduleName,
                    class_basename($model).' #'.$model->id.' modifié',
                    $oldValues,
                    $newValues
                );
            }
        });

        static::deleted(function ($model) {
            if (auth()->check()) {
                $moduleName = \Illuminate\Support\Str::snake(class_basename($model));
                static::log(
                    'delete',
                    $moduleName,
                    class_basename($model).' #'.$model->id.' supprimé',
                    $model->getAttributes(),
                    null
                );
            }
        });
    }
}
