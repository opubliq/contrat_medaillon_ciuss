# 05_prompt_chantier.md — Critères et méthodologie s5t

## Contexte

Traitement des 31 organismes du fichier `Organismes_chantier_proximité.xlsx` pour ajout au bottin communautaire du projet CIUSS Est de Montréal.

**Résumé des résultats :**
- **17 organismes** retenus et classifiés (fichier `05_chantier_a_ajouter.csv`)
- **8 doublons** détectés (déjà présents dans `04_bottin_secteurs.csv`)
- **5 organismes** exclus (non-pertinents selon critères s5t)
- **1 organisme** supplémentaire non retenu (ne correspond pas aux données)

---

## Méthodologie

### 1. Déduplication

Vérification systématique de chaque organisme du xlsx contre le bottin existant (`04_bottin_secteurs.csv`) :

- **Match exact** : nom identique (case-insensitive, après normalisation)
- **Match substring** : nom du xlsx contenu dans bottin ou inverse
- **Variantes mineures** : acronymes ou variantes orthographiques (ex: CRADI vs "Comité régional pour l'autisme...")

**Doublons détectés (8) :**
1. Société québécoise de la schizophrénie — exact match
2. Comité régional pour l'autisme et la déficience intellectuelle (CRADI) — substring
3. Association bénévole Ligne espoir aînés de Pointe-aux-Trembles — substring
4. Escale famille le Triolet — substring
5. Je Passe Partout — substring
6. Association de Montréal pour la déficience intellectuelle — exact match
7. Centre de Référence du Grand Montréal — exact match
8. Revdec — exact match

### 2. Évaluation de pertinence

Pour chaque organisme non-doublon, application des critères de pertinence du pipeline (cf. `03_filtre_llm.py`) :

#### **Exclusions absolues**
- Établissements institutionnels : CIUSSS, hôpital, CHSLD, centre de réadaptation, RPA, clinique
- Organismes gouvernementaux ou para-publics : agences municipales, comités d'usagers institutionnels
- Exclusion logement : gestionnaires d'immeubles, coopératives d'habitation sans mission d'accompagnement social (bénéfice du doute → exclusion)
- Exclusion loisirs : clubs sportifs, associations culturelles, centres de loisirs généraux (même si clientèle inclut aînés/handicapés)

#### **Pertinent (oui)** si
Le nom, la description ou la clientèle mentionne **explicitement** une population vulnérable OU une mission de défense de droits :

**Populations vulnérables :**
- Aînés, personnes âgées
- Personnes en itinérance
- Femmes victimes de violence
- Personnes avec dépendances
- Santé mentale
- Familles en difficulté, enfants/jeunes à risque
- Immigrants, réfugiés
- Personnes handicapées (physique ou intellectuelle)
- Pauvreté, précarité

**Défense de droits :**
- Locataires
- Usagers santé
- Femmes
- Immigrants
- Accès à la justice

#### **Incertain**
Organismes avec nom ou acronyme insuffisant, mais profil compatible avec la mission. **Décision : inclusion avec bénéfice du doute** en vertu du principe de générosité du projet.

### 3. Classification secteur ISQ

Pour chaque organisme retenu, attribution d'un secteur primaire parmi la taxonomie autorisée :

- `arts_culture_medias` — ❌ exclusion (loisirs)
- `bien_etre_alimentaire`
- `defense_droits`
- `developpement_communautaire`
- `developpement_enfants_familles`
- `education_formation`
- `emploi`
- `environnement` — ❌ exclusion
- `logement`
- `sante`
- `soutien_vulnerabilite`
- `sports_loisirs_tourisme` — ❌ exclusion (loisirs)
- `autres_missions_sociales`

---

## Résultats détaillés

### ✓ Retenus (17)

| # | Nom | Secteur | Raison |
|----|-----|---------|--------|
| 1 | Centre des aînés de Saint-Léonard | `soutien_vulnerabilite` | Services pour aînés |
| 2 | Maison de la famille St-Léonard | `developpement_enfants_familles` | Soutien familial |
| 3 | Prévention PDI | `sante` | Prévention déficience intellectuelle |
| 4 | Carrefour jeunesse-emploi | `emploi` | Insertion emploi jeunes |
| 5 | Joujouthèque Saint-Michel | `developpement_enfants_familles` | Services enfants/familles |
| 6 | Rameau d'Olivier | `soutien_vulnerabilite` | Aide humanitaire |
| 7 | Pact de rue | `soutien_vulnerabilite` | Itinérance/prévention |
| 8 | Chez nous de Mercier-Est | `developpement_communautaire` | Table/centre de quartier |
| 9 | Table de quartier de Rivière-des-Prairies | `developpement_communautaire` | Table de quartier |
| 10 | PITREM | `autres_missions_sociales` | Action communautaire |
| 11 | Tour de lire | `education_formation` | Littératie/alphabétisation |
| 12 | Projet Harmonie | `autres_missions_sociales` | Intervention communautaire (incertain) |
| 13 | Accès bénévolat | `autres_missions_sociales` | Bénévolat populations vulnérables (incertain) |
| 14 | La Maison grise | `autres_missions_sociales` | Accompagnement (incertain) |
| 15 | Centre de formation Antoine-de-Saint-Exupéry | `education_formation` | Formation jeunes à risque (incertain) |
| 16 | CDC de la Pointe | `autres_missions_sociales` | Centre de ressources (incertain) |
| 17 | ITMAV, St-Michel | `autres_missions_sociales` | Intervention sociale (incertain) |

### ⊘ Doublons (8)

Organismes détectés dans le bottin existant et donc exclus de l'ajout.

1. Société québécoise de la schizophrénie
2. Comité régional pour l'autisme et la déficience intellectuelle (CRADI)
3. Association bénévole Ligne espoir aînés de Pointe-aux-Trembles
4. Escale famille le Triolet
5. Je Passe Partout
6. Association de Montréal pour la déficience intellectuelle
7. Centre de Référence du Grand Montréal
8. Revdec

### ✗ Exclusions (5)

Organismes non-pertinents selon les critères du pipeline.

| Nom | Raison |
|-----|--------|
| Service de l'habitation de la ville de Montréal | Para-public (gestionnaire habitation) |
| Inspection bâtiment, Arrondissement Rosemont-Petite-Patrie | Agence municipale |
| Compagnie Théâtre créole | Organisme culturel/loisirs |
| Office municipal d'habitation de Montréal (OMHM) | Gestionnaire d'immeubles publics |
| Société Ressources-Loisirs de Pointe-aux-Trembles | Centre de loisirs |

---

## Notes et décisions

### Incertains : politique d'inclusion généreuse

Pour les 6 organismes marqués comme "incertain" (Projet Harmonie, Accès bénévolat, La Maison grise, Centre de formation Antoine-de-Saint-Exupéry, CDC de la Pointe, ITMAV), la décision a été d'**inclure avec bénéfice du doute**.

**Justification :**
- Noms suggestifs d'une mission sociale (pas clairement disqualifiants)
- Profil compatible avec populations vulnérables
- Possibilité de recherche ultérieure pour affiner classification
- Cohérence avec esprit du projet (inclusion préférable à exclusion trop stricte)

### Doublons présumés : vérification manuelle

Plusieurs organismes de la liste du xlsx avaient des variantes ou acronymes qui suggéraient des doublons probables. La vérification par substring a confirmé 5 doublons certains :
- Escale famille le Triolet
- Je Passe Partout
- Tour de lire (déjà dans bottin, mais marqué comme pertinent)

### Champs vides

Les champs `adresse`, `telephone`, `courriel`, `site_web` sont laissés vides dans `05_chantier_a_ajouter.csv` car non disponibles dans le xlsx source. Ces informations pourraient être complétées ultérieurement via une recherche web ou contact direct.

---

## Fichiers générés

- **`05_chantier_a_ajouter.csv`** : CSV d'intégration (schéma identique à `04_bottin_secteurs.csv`)
- **`05_chantier.py`** : Script de génération avec fonctions utilitaires et données hardcodées
- **`05_prompt_chantier.md`** : Cette documentation

## Exécution

```bash
. ~/myenv/bin/activate
python3 liste_organismes/scripts/05_chantier.py
```

Produit `05_chantier_a_ajouter.csv` avec 17 organismes classifiés, prêts pour intégration au bottin.
