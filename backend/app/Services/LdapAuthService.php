<?php

namespace App\Services;

/**
 * LdapAuthService — Authentification Active Directory via ext-ldap natif PHP.
 * Si ext-ldap n'est pas chargé ou si le serveur est inaccessible,
 * isAvailable() retourne false et le AuthController bascule en fallback DB.
 *
 * Architecture dual-mode :
 *   1. LDAP (Active Directory) — prioritaire
 *   2. Bcrypt DB              — fallback automatique
 */
class LdapAuthService
{
    /**
     * Tente d'authentifier un utilisateur via LDAP (bind DN + mot de passe).
     * Retourne false immédiatement si ext-ldap absent ou serveur injoignable.
     */
    public function authenticate(string $username, string $password): bool
    {
        if (! extension_loaded('ldap')) {
            \Log::info('LDAP: extension ext-ldap non disponible — fallback DB activé');
            return false;
        }

        try {
            $host   = env('LDAP_HOST', 'ldap.algerietelecom.dz');
            $port   = (int) env('LDAP_PORT', 389);
            $baseDn = env('LDAP_BASE_DN', 'dc=algerietelecom,dc=dz');

            $conn = ldap_connect("ldap://{$host}:{$port}");
            if (! $conn) {
                \Log::info('LDAP: impossible de créer la connexion — fallback DB');
                return false;
            }

            ldap_set_option($conn, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($conn, LDAP_OPT_NETWORK_TIMEOUT, 3);
            ldap_set_option($conn, LDAP_OPT_TIMELIMIT, 3);
            ldap_set_option($conn, LDAP_OPT_REFERRALS, 0);

            // Construit le DN selon la convention Algérie Télécom AD
            $dn     = "uid={$username},{$baseDn}";
            $bound  = @ldap_bind($conn, $dn, $password);

            ldap_close($conn);
            return $bound === true;

        } catch (\Throwable $e) {
            \Log::info('LDAP indisponible — fallback DB : ' . $e->getMessage());
            return false;
        }
    }

    /**
     * Vérifie si le serveur LDAP est joignable (bind anonyme).
     * Timeout court (2 s) pour ne pas bloquer la connexion.
     */
    public function isAvailable(): bool
    {
        if (! extension_loaded('ldap')) {
            return false;
        }

        try {
            $host = env('LDAP_HOST', 'ldap.algerietelecom.dz');
            $port = (int) env('LDAP_PORT', 389);

            $conn = ldap_connect("ldap://{$host}:{$port}");
            if (! $conn) {
                return false;
            }

            ldap_set_option($conn, LDAP_OPT_PROTOCOL_VERSION, 3);
            ldap_set_option($conn, LDAP_OPT_NETWORK_TIMEOUT, 2);
            ldap_set_option($conn, LDAP_OPT_TIMELIMIT, 2);

            // Bind anonyme pour tester la disponibilité
            $result = @ldap_bind($conn);
            ldap_close($conn);

            return $result !== false;

        } catch (\Throwable $e) {
            return false;
        }
    }
}
