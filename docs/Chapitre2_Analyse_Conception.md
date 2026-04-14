---
title: "Chapitre 2 — Analyse et conception"
subtitle: "Projet de fin de formation — AT Réservations"
author: "Algérie Télécom — Plateforme de gestion des missions"
lang: fr-FR
---

# Chapitre 2 — Analyse et conception

Ce chapitre présente l'analyse fonctionnelle et la conception du système d'information **AT Réservations**, plateforme web de gestion des missions et déplacements professionnels pour **Algérie Télécom**. La stack technique retenue est **React 18** (interface), **Laravel 12** (API et logique métier) et **MySQL** (persistance). Quatre rôles métier structurent les droits : **administrateur**, **validateur**, **demandeur** et **utilisateur**.

Les diagrammes UML formalisés ci-dessous sont fournis au format **PlantUML** dans le fichier joint `diagrammes.puml`, ce qui permet de les régénérer ou les modifier sans perte de qualité (vectoriel, impression nette).

---

## 2.1 Diagramme de cas d'utilisation

**Objectif :** représenter les interactions entre les acteurs et le système pour les fonctions majeures.

**Acteurs :** Administrateur, Validateur, Demandeur, Utilisateur.

**Cas d'utilisation principaux :** s'authentifier ; créer une demande de mission ; soumettre la demande ; valider ou rejeter une demande ; consulter ses missions ; gérer les utilisateurs (administration) ; consulter le tableau de bord ; exporter un rapport ; envoyer un message interne ; consulter l'organigramme.

La relation **include** entre « Créer demande de mission » et « Soumettre demande » illustre que la soumission complète le cycle de création lorsque le demandeur valide son dossier.

*Source diagramme : bloc `diagramme_cas_utilisation` dans `diagrammes.puml`.*

---

## 2.2 Diagramme de classes

**Objectif :** modéliser les entités métier et leurs associations avec cardinalités.

Les classes **Utilisateur**, **Mission**, **Validation**, **Document**, **Message** et **Notification** couvrent respectivement l'identité des acteurs, le cœur métier des déplacements, la trace des décisions hiérarchiques, les pièces jointes, la messagerie interne et les alertes utilisateur.

* Un utilisateur crée **plusieurs** missions (`created_by`).
* Une mission peut avoir **plusieurs** validations dans le temps (historique ou étapes).
* Une mission peut porter **plusieurs** documents.
* Les messages lient expéditeur et destinataire ; les notifications ciblent un utilisateur.

*Source diagramme : bloc `diagramme_classes` dans `diagrammes.puml`.*

---

## 2.3 Diagramme de séquence — Création et validation d'une mission

**Objectif :** décrire le scénario nominal de bout en bout.

**Participants :** Demandeur, Frontend React, API Laravel, base MySQL, Validateur.

**Enchaînement résumé :** authentification (ex. Sanctum) ; création ou mise à jour de mission ; passage au statut « soumis » ; notification du validateur ; consultation et décision ; mise à jour de la mission et de l'historique de validation ; notification du demandeur ; état final « mission approuvée ».

*Source diagramme : bloc `diagramme_sequence_mission` dans `diagrammes.puml`.*

---

## 2.4 Diagramme d'activités — Circuit de validation hiérarchique

**Objectif :** modéliser les décisions (approuver, rejeter, retour pour modification) et l'archivage.

Le flux part de la création ou modification d'une demande, distingue le **brouillon** et la **soumission**, puis intègre la **validation hiérarchique**. Les branches « approuvé », « rejeté » et « retour pour modification » déterminent les notifications et la possibilité de resoumission. L'**archivage** intervient en fin de cycle lorsque la mission est approuvée et clôturée.

*Source diagramme : bloc `diagramme_activite_validation` dans `diagrammes.puml`.*

---

## 2.5 Diagramme de déploiement

**Objectif :** situer les composants sur l'infrastructure cible.

Le **client** exécute un navigateur web qui charge le **bundle React** produit par le build **Vite** (`npm run build`). Les appels HTTP/HTTPS ciblent l'**API Laravel** hébergée derrière un **serveur web** (Apache ou Nginx avec PHP-FPM). La persistance est assurée par **MySQL**.

*Source diagramme : bloc `diagramme_deploiement` dans `diagrammes.puml`.*

---

## Annexe — Fichiers et outils

| Fichier | Rôle |
|---------|------|
| `diagrammes.puml` | Source unique de tous les diagrammes PlantUML |
| `GENERER_DIAGRAMMES.sh` | Exemple de commande pour export PNG (PlantUML) |

Pour obtenir des images à insérer dans un traitement de texte : installer **PlantUML** et exécuter la commande documentée dans `GENERER_DIAGRAMMES.sh`. Les exports **SVG** conviennent aussi à Word (Insertion > Images) avec une netteté adaptée à l'impression.
