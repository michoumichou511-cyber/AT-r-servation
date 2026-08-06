<?php

namespace App\Services;

class LdapAuthService
{
    public function authenticate(string $username, string $password): bool
    {
        if (!extension_loaded('ldap')) {
            \Log::info('LDAP: extension ext-ldap non disponible -- fallback DB active');
            return false;
        }
        try {
            $host   = env('LDAP_HOST', 'ldap.algerietelecom.dz');
            $port   = (int) env('LDAP_PORT', 389);
            $baseDn = env('LDAP_BASE_DN', 'dc=algerietelecom,dc=dz');

            $conn = ldap_connect("ldap://{$host}:{$port}");
            if (!$conn) {
                return false;
            }

            ldap_set_option($conn, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($conn, LDAP_OPT_NETWORK_TIMEOUT, 3);
            ldap_set_option($conn, LDAP_OPT_TIMELIMIT, 3);
            ldap_set_option($conn, LDAP_OPT_REFERRALS, 0);

            $dn    = "uid={$username},{$baseDn}";
            $bound = @ldap_bind($conn, $dn, $password);
            ldap_close($conn);

            return $bound === true;
        } catch (\Throwable $e) {
            \Log::info('LDAP indisponible -- fallback DB : ' . $e->getMessage());
            return false;
        }
    }

    public function isAvailable(): bool
    {
        if (!extension_loaded('ldap')) {
            return false;
        }
        try {
            $conn = ldap_connect("ldap://" . env('LDAP_HOST') . ":" . env('LDAP_PORT', 389));
            if (!$conn) {
                return false;
            }
            ldap_set_option($conn, LDAP_OPT_NETWORK_TIMEOUT, 2);
            $result = @ldap_bind($conn);
            ldap_close($conn);
            return $result !== false;
        } catch (\Throwable $e) {
            return false;
        }
    }
}