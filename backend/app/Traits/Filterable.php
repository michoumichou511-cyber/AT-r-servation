<?php

namespace App\Traits;

use Illuminate\Database\Eloquent\Builder;

trait Filterable
{
    public function scopeFilter(Builder $query, array $filters): Builder
    {
        foreach ($filters as $field => $value) {
            if ($value === null || $value === '') {
                continue;
            }

            match (true) {
                str_ends_with($field, '_like') => $query->where(
                    str_replace('_like', '', $field),
                    'like',
                    "%{$value}%"
                ),
                str_ends_with($field, '_gte') => $query->where(
                    str_replace('_gte', '', $field),
                    '>=',
                    $value
                ),
                str_ends_with($field, '_lte') => $query->where(
                    str_replace('_lte', '', $field),
                    '<=',
                    $value
                ),
                default => $query->where($field, $value),
            };
        }

        return $query;
    }
}
