# CLAUDE.md - Contrat Médaillon / CIUSS Est de Montréal

## Projet

Consultation en deux volets pour le Comité des usagers du CIUSS de l'Est de Montréal, sous-traitée par Médaillon Groupe Conseils à Opubliq. Budget Opubliq : 15 000$. Livraison finale : 1er juin 2026.

## Volets

1. **Sondage organismes communautaires** (~100 organismes, questionnaire en ligne + téléphonistes)
2. **Sondage population** (citoyens de l'Est de Montréal, multi-canal : QR, poste CRA, intervieweurs)

Deux questionnaires distincts, entièrement en français.

## Stack technique

- **Questionnaires :** SurveyJS (JSON)
- **Hébergement :** AWS CloudFront + S3
- **Stockage réponses :** S3 buckets par volet
- **Langages :** R, Python
- **Plateforme self-service :** Prototype pour que Médaillon gère ses propres sondages (produit réutilisable)

## Équipe Opubliq

- **Hubert Cadieux** — tech lead (infra AWS, programmation questionnaires, liste organismes, nettoyage données, visualisations PPT, plateforme self-service)
- **Alexandre Bouillon** — échantillonnage lead (stratégie, quotas, pondération, coordination collecte)
- **Nicolas Ebnoether-Noël** — liaison Opubliq-Médaillon

## Structure du repo

```
docs/           # Documentation projet (contexte, notes de rencontres, grille tarifs)
```

## Livrables Opubliq

| Livrable | Responsable | Montant |
|----------|-------------|---------|
| Liste organismes communautaires | Hubert | 750$ |
| Programmation 2 questionnaires SurveyJS | Hubert | 1 000$ |
| Stratégie échantillonnage volet population | Alexandre | 2 500$ |
| Soutien application stratégie échantillonnage | Alexandre | 2 500$ |
| Nettoyage et livraison données (CSV) | Hubert | 750$ |
| Application pondération | Alexandre | 500$ |
| PowerPoint graphiques modifiables | Hubert | 1 500$ |
| Prototype plateforme self-service | Hubert | 5 500$ |

## Conventions

- Tout le contenu projet est en **français**
- Architecture inspirée du repo `vision_opubliq_repensons_levis`
- Repo lié : `opubliq-platform` (plateforme SaaS réutilisable)

## Contacts

- **Médaillon :** Nathalie (contact principal), Nicolas Ebnoether-Noël
- **Opubliq :** Hubert Cadieux, Alexandre Bouillon
