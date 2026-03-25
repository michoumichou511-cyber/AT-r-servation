<?php

namespace Database\Migrations\Concerns;

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Détection d’index compatible MySQL, PostgreSQL et SQLite (évite SHOW INDEX sur pgsql).
 */
trait DetectsMigrationIndex
{
    protected function indexExists(string $table, string $indexName): bool
    {
        return match (Schema::getConnection()->getDriverName()) {
            'pgsql' => $this->indexExistsPgsql($table, $indexName),
            'mysql' => $this->indexExistsMysql($table, $indexName),
            'sqlite' => $this->indexExistsSqlite($table, $indexName),
            default => false,
        };
    }

    protected function indexExistsPgsql(string $table, string $indexName): bool
    {
        $schema = Schema::getConnection()->getConfig('schema') ?? 'public';

        $row = DB::selectOne(
            'select 1 from pg_catalog.pg_indexes where schemaname = ? and tablename = ? and indexname = ? limit 1',
            [$schema, $table, $indexName]
        );

        return $row !== null;
    }

    protected function indexExistsMysql(string $table, string $indexName): bool
    {
        $safeTable = str_replace('`', '``', $table);

        return count(DB::select(
            "SHOW INDEX FROM `{$safeTable}` WHERE Key_name = ?",
            [$indexName]
        )) > 0;
    }

    protected function indexExistsSqlite(string $table, string $indexName): bool
    {
        $row = DB::selectOne(
            'select 1 from sqlite_master where type = ? and name = ? and tbl_name = ? limit 1',
            ['index', $indexName, $table]
        );

        return $row !== null;
    }
}
