# Contexte du projet - Sondage CIUSS Est de Montréal

## Vue d'ensemble

**Client final:** Comité des usagers du CIUSS de l'Est de Montréal  
**Partenaire:** Médaillon Groupe Conseils (sous-traitance à Opubliq)  
**Période:** Février 2026 - Juin 2026  
**Budget total:** 15 000$ (contribution Opubliq au contrat de 25k de Médaillon)

## Objectif du projet

Consultation en deux volets pour comprendre comment le CIUSS peut mieux accompagner les organismes communautaires et la population de l'Est de Montréal dans la défense des droits et l'accès aux services de santé.

Contexte: Élections à travers le Québec pour représenter les usagers des CIUSS.

## Structure du projet

### Volet 1: Sondage organismes communautaires
- **Cible:** ~100 organismes de l'Est de Montréal
- **Méthode:** Questionnaire en ligne + téléphonistes
- **Niveau:** Organisationnel (non individuel)

### Volet 2: Sondage population
- **Cible:** Population générale de l'Est de Montréal
- **Méthode:** Multi-canal (codes QR, service CRA Postes Canada, intervieweurs)
- **Niveau:** Individuel

**Note:** Deux questionnaires distincts adaptés à chaque volet.

## Livrables et budget Opubliq

| Livrable | Responsable | Montant |
|----------|-------------|---------|
| Constitution liste organismes | Hubert | 750$ |
| Programmation 2 questionnaires SurveyJS | Hubert | 1 000$ |
| Stratégie d'échantillonnage volet population | Alexandre | 2 500$ |
| Soutien application stratégie échantillonnage | Alexandre | 2 500$ |
| Nettoyage et livraison données (CSV) | Hubert | 750$ |
| Application pondération | Alexandre | 500$ |
| PowerPoint avec graphiques modifiables | Hubert | 1 500$ |
| Prototype plateforme self-service | Hubert | 5 500$ |
| **TOTAL** | | **15 000$** |

### Répartition interne
- Hubert: 9 500$
- Alexandre: 5 500$
- Marge Opubliq: 0$ (réinvestie dans développement plateforme)

## Architecture technique

### Infrastructure de collecte
- **Frontend:** SurveyJS (2 questionnaires distincts)
- **Hébergement:** AWS CloudFront + S3
- **Stockage:** S3 buckets avec organisation par volet
- **Configuration:** CORS, IAM, intégrations

### Plateforme self-service (nouveau produit)
Développement d'un prototype permettant à Médaillon de:
- Programmer leurs sondages dans SurveyJS (téléverser JSON)
- Héberger et déployer automatiquement via interface web
- Gérer plusieurs sondages simultanément
- Télécharger les données brutes (CSV)
- Documentation et formation incluses

**Note:** Ce projet CIUSS sert de cas d'usage initial pour valider le concept de plateforme réutilisable.

## Échéancier clé

- **17 février 2026:** Liste organismes (version initiale)
- **Février-Mars:** Conception questionnaires + stratégie échantillonnage
- **Mars-Mai:** Collecte de données
- **Mai-Juin:** Analyse, pondération, livrables finaux
- **1er juin 2026:** Livraison finale

## Répartition des responsabilités

### Opubliq (Hubert)
- Infrastructure technique AWS
- Programmation des questionnaires
- Constitution liste organismes communautaires
- Nettoyage des données
- Visualisations PowerPoint
- Développement plateforme self-service

### Opubliq (Alexandre)
- Conception stratégie d'échantillonnage
- Définition quotas et méthodologie
- Coordination collecte (téléphonistes, CRA, etc.)
- Application de la pondération
- Assurance qualité échantillon

### Médaillon
- Relations client (CIUSS)
- Équipe de téléphonistes
- Intervieweurs terrain
- Rapport final au client
- Facturation client final

## Particularités du mandat

- **Langue:** Entièrement en français (CIUSS le plus francophone)
- **Géographie:** Est de Montréal uniquement
- **Population:** Mixte (organismes + citoyens)
- **Innovation:** Premier projet utilisant la nouvelle plateforme self-service

## Ressources et références

- Liste initiale organismes: https://ville.montreal-est.qc.ca/vie-communautaire/organismes/
- Architecture technique: Inspirée du projet Repensons Lévis (voir repo `vision_opubliq_repensons_levis`)
- Service CRA: Postes Canada (890$ base + 1,04$/retour)

## Repositories liés

- **Ce repo:** Travail spécifique au contrat (scripts, questionnaires, analyses)
- **survey-platform:** Plateforme self-service réutilisable (produit SaaS)

## Contacts

**Médaillon:**
- Nathalie (contact principal)
- Nicolas Ebnoether-Noël (liaison Opubliq-Médaillon)

**Opubliq:**
- Hubert Cadieux (tech lead)
- Alexandre Bouillon (échantillonnage lead)
