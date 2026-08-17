# Mémoire du projet — Consultation droits des usagers (CIUSSS Est-de-l'Île-de-Montréal)

## Contexte général

Ce projet analyse les résultats d'une consultation menée par les comités des usagers du
CIUSSS de l'Est-de-l'Île-de-Montréal sur les droits des usagers du système de santé et
des services sociaux.

Deux volets de données au total (le deuxième arrivera plus tard) :

1. **Volet organismes communautaires** (disponible) — un même questionnaire administré
   selon deux modes :
   - **Internet** (auto-administré en ligne) — n = 105 répondants
   - **Téléphone** (avec intervieweur) — n = 25 répondants
2. **Volet usagers** (à venir) — réponses directes des usagers du système de santé,
   pas encore reçues. Le dossier `data/usagers/` existe déjà en prévision.

## Structure du dossier

```
data/
  organismes/
    questionnaire_organismes.json              # schéma SurveyJS du questionnaire — mode internet
    questionnaire_organismes_telephones.json   # schéma SurveyJS du questionnaire — mode téléphone
    sondage_c4504161-..._reponses.xlsx         # réponses brutes — mode internet (n=105, 58 col.)
    sondage_1bf3ef5c-..._reponses.xlsx         # réponses brutes — mode téléphone (n=25, 50 col.)
    clean/                                     # sorties nettoyées (générées par les scripts R)
      organismes_combined.csv                  # jeu de données fusionné (internet + téléphone)
      organismes_quantitatif.csv               # variables fermées uniquement
      organismes_qualitatif.csv                # variables ouvertes (texte libre) uniquement
      dictionnaire_variables.csv               # codebook: code, section, texte, type
  usagers/                                     # vide pour l'instant — réponses usagers à venir
scripts/
  organismes_cleaning.R   # lecture brute -> harmonisation -> fusion -> organismes_combined.csv
  organismes_eta.R        # combined -> split quantitatif/qualitatif + statistiques descriptives
```

## Le questionnaire (volet organismes)

Le questionnaire est structuré en 9 sections (A à I), les deux modes (internet/téléphone)
sont quasi-identiques question pour question (mêmes codes `qN`). Pas de véritable échelle
de Likert numérique : les questions fermées sont catégorielles/ordinales à 2-4 modalités
(ex. q5 : très/assez/peu/pas du tout respectés). Voir
`data/organismes/clean/dictionnaire_variables.csv` pour le détail complet par variable.

Sections : A. Raisons de fréquenter un organisme communautaire · B. Connaissance des droits ·
C. Respect des droits · D. Défense des droits · E. Plaintes et insatisfaction ·
F. Collaboration et concertation · G. Connaissance des comités des usagers ·
H. Suggestions pour les comités des usagers · I. Profil de l'organisme.

### Répartition quantitatif vs qualitatif (volet organismes)

46 questions au total (+ 14 colonnes de métadonnées : email, date, mode, etc.) :

- **17 variables quantitatives (fermées)**
  - 10 radiogroup (choix unique) : q0, q2, q3, q5, q11, q14, q14_1, q15, q16, q17
  - 7 checkbox (choix multiples) : q1, q10, q12, q21, q22, q23, q24
- **29 variables qualitatives (ouvertes)**, dont :
  - 23 vraies questions ouvertes (`comment`) : q1_1, q2_1, q2_2, q4, q5_1, q5_2, q5_3,
    q6, q7, q8, q9, q11_1, q11_2, q13, q17_1, q18_1 à q18_6, q19, q20
  - 6 champs "Autre" en texte libre rattachés à une question fermée à choix multiples
    (pas des questions à part entière) : q10-Comment, q12-Comment, q16-Comment,
    q21-Comment, q23-Comment, q24-Comment

Le questionnaire est donc nettement orienté qualitatif (près de 2x plus de champs
ouverts que fermés), cohérent avec sa nature de consultation exploratoire plutôt
qu'un sondage à échelle standardisée. Détail ligne par ligne dans
`data/organismes/clean/dictionnaire_variables.csv`.

## Décisions prises avec l'utilisateur (2026-07-07)

- **Outil d'analyse : R.** R 4.6.0 est installé dans `C:\Program Files\R\R-4.6.0` mais
  n'est pas dans le PATH — l'invoquer via le chemin complet
  (`"/c/Program Files/R/R-4.6.0/bin/Rscript.exe"` en bash) plutôt que `Rscript` seul.
  Packages confirmés installés : readxl, jsonlite, dplyr, tidyr, stringr, purrr, writexl, readr.
- **Fusion des deux modes.** Les réponses internet et téléphone sont fusionnées dans un
  seul jeu de données (`organismes_combined.csv`, n=130) avec une colonne `mode`
  (`internet` / `telephone`) pour permettre de comparer ou filtrer par mode plus tard.
- **q0 (l'organisme dessert-il le territoire de l'Est de Montréal ?) — ne PAS filtrer.**
  Une question de recherche explicite du client est de savoir combien d'organismes
  répondants ne desservent pas le territoire. Les 15 réponses "Non" (internet) sont
  **conservées** dans le jeu de données ; q0 reste une variable descriptive/filtrable.
  **Mise à jour (2026-07-07)** : les 10 valeurs manquantes côté téléphone sont
  recodées **2 = Non**, sur hypothèse du client que l'intervieweur.e ne posait/notait
  cette question que lorsque la réponse était "Oui" (donc un q0 non renseigné en
  téléphone reflète une réponse implicite "Non"). C'est une hypothèse, pas une
  certitude confirmée — une note explicite l'accompagne dans le rapport client
  (`rapports/comparaison_internet_telephone.pdf`).
- **Recodage numérique des variables fermées, demandé par le client (2026-07-07).**
  Toutes les variables binaires et les échelles à 4 niveaux sont recodées en valeurs
  numériques dans `organismes_combined.csv` / `organismes_quantitatif.csv` (le texte
  d'origine n'est conservé que dans le codebook) :
  - **Oui/Non → 1/2** : q0, q14, q15, q17
  - **Oui/Non + 3e valeur → 1/2/9** (9 = Ne sais pas / NSP / Autre) : q14_1, q16
  - **Échelles à 4 niveaux, 1 = le plus négatif/faible → 4 = le plus positif/élevé** :
    q3 (connaissance : Pas du tout=1…Très grande=4), q5 (respect des droits :
    pas_du_tout=1…tres_respectes=4), q11 (facilité de plainte : tres_difficile=1…
    tres_facile=4), q2 (fréquence : jamais=1…tres_souvent=4)
  - **Non recodées** : les questions à choix multiples (checkbox) q1, q10, q12, q21,
    q22, q23, q24 — plusieurs réponses possibles par répondant, un code 1/2 unique ne
    s'applique pas ; elles restent en texte lisible (`"valeur1 | valeur2"`).
  Légende complète dans la colonne `codage` de
  `data/organismes/clean/dictionnaire_variables.csv`.

## Particularités et anomalies des données brutes repérées

- **Casing incohérent entre modes sur plusieurs variables fermées** : `q16` (internet
  `Oui`/`Non`/`NSP`/`other` vs téléphone `OUI`/`NON`/`other`), `q14_1` et `q15`
  (`Oui`/`Non` vs `OUI`/`NON`). Harmonisé vers une casse unique (`Oui`/`Non`/`NSP`/
  `Ne sais pas`) dans `organismes_cleaning.R`.
- **q12 (checkbox), préfixes de lettre côté téléphone** : le mode téléphone stocke les
  choix préfixés (`a. Commissaire aux plaintes`, `b. Comité des usagers du CIUSSS`,
  `c. CLSC`) alors que le mode internet ne les préfixe pas. Préfixes retirés au nettoyage.
- **Colonnes checkbox = chaînes JSON brutes** : `q1, q10, q12, q21, q22, q23, q24` sont
  exportées par la plateforme de sondage comme des chaînes façon
  `["besoin_services", "les_deux"]` (parfois une valeur nue hors crochets, ex. `other`).
  Décodées et reformatées en `"valeur1 | valeur2"` dans `organismes_cleaning.R` pour
  rester lisibles/triables dans Excel.
- **Colonnes absentes côté téléphone** : `q18_2`, `q18_4`, `q18_5` (3 des 6 sous-questions
  ouvertes de la section H) n'existent pas du tout dans le fichier réponses téléphone —
  pas juste vides, la colonne n'a jamais été créée. À signaler dans toute analyse de q18
  (comparaisons internet/téléphone biaisées pour ces 3 sous-items).
  Colonnes de métadonnées présentes seulement côté internet : `Description`,
  `secteur_activite`, `Téléphone`, `Site_web`, `source_sheet`, `__token`
  (proviennent probablement d'un export d'annuaire/CRM utilisé pour l'envoi des invitations).
  Le mode téléphone a en échange une colonne `q25` (texte) qui recopie manuellement le
  secteur depuis un fichier Excel — à traiter comme métadonnée, pas une vraie question
  de contenu.
- **2 doublons de soumission confirmés (mode internet)** : `direction@mhanjou.ca`
  (soumis les 2026-05-13 et 2026-05-26) et `info@hopefordementia.org`
  (soumis les 2026-05-22 et 2026-06-01), soit 4 lignes au total. Flagués dans le
  nettoyage (colonne `doublon_email`). **Décision (2026-07-07) : on les garde tous les
  deux pour l'instant**, à revisiter plus tard si besoin.
  **Vérification (2026-07-23)** : comparaison colonne par colonne des paires de
  soumissions (hors métadonnées) — ce ne sont PAS des resoumissions identiques
  (erreur/doublon technique). `direction@mhanjou.ca` : 23/48 colonnes diffèrent
  entre les deux soumissions, avec des réponses ouvertes non redondantes (chaque
  soumission remplit des champs que l'autre laisse vides). `info@hopefordementia.org` :
  26/48 colonnes diffèrent, et même **q0 diffère** (Oui vs Non sur le territoire
  desservi) — signe fort de deux répondants distincts au sein du même organisme,
  pas d'une resoumission par la même personne. **Décision confirmée : les 4 lignes
  sont conservées**, traitées comme 4 répondants légitimes (et non 2 organismes
  distincts comptés en double) pour l'analyse de contenu.
- ⚠️ Un premier comptage naïf (`.duplicated().sum()` en Python) avait donné 21 "emails
  dupliqués" côté internet — c'était un artefact : ce comptage traite les valeurs
  manquantes (`NaN`) comme des doublons entre elles, or 20 organismes sur 105 n'ont
  simplement pas renseigné d'email. Le vrai chiffre, en ne comptant que les emails
  réels apparaissant plus d'une fois, est bien **2 organismes / 4 lignes** (ci-dessus).
  Le script R exclut correctement les `NA` de la détection.
- Encodage des accents : correct dans les fichiers sources (UTF-8) ; un affichage
  mojibake observé dans le terminal git-bash est uniquement un problème de codepage
  console, pas une corruption des données.

## Résultats de l'ETA — comparaison internet vs téléphone (2026-07-07)

Script : `scripts/organismes_comparaison_modes.R` (sorties dans
`data/organismes/clean/comparaison_modes_*.csv`). Wilcoxon pour les échelles 1-4,
Fisher exact pour les variables binaires/checkbox. ⚠️ n=25 côté téléphone (et souvent
moins pour les sous-questions conditionnelles) → puissance statistique faible et ~40
tests réalisés au total, donc les p-valeurs proches de .05 (q2, q3, q11) sont à
interpréter avec prudence (pas de correction pour tests multiples appliquée).

**Même tendance générale** sur la plupart des variables d'opinion : q5 (respect des
droits, p=.87), q16 (connaissance des CU, p=.63 implicite), q17 (recours récent, ns) ne
diffèrent pas entre modes.

**Différences significatives repérées, avec deux origines distinctes probables :**

1. **Composition d'échantillon (probablement pas un effet du mode en soi)**
   - `q14` (en relation avec un.e organisateur communautaire du CIUSSS) : 28 % internet
     vs **72 % téléphone** (p=.0001) — écart énorme. Suggère que les organismes
     recrutés par téléphone sont un sous-groupe distinct, déjà bien connecté au
     réseau du CIUSSS (probablement recrutés via le carnet de contacts des
     organisateurs communautaires), pas un échantillon aléatoire équivalent.
   - Cohérent avec cette hypothèse : `q2` (fréquence de référence au CIUSSS) plus
     élevée en téléphone (moyenne 3.04 vs 2.56, p=.018) — des organismes plus
     connectés réfèrent davantage.
   - `q3` (connaissance des droits perçue chez les usagers) plus **basse** en
     téléphone (2.04 vs 2.36, p=.03) et `q11` (facilité de porter plainte) aussi plus
     **basse/négative** en téléphone (1.58 vs 1.97, p=.03) — des organismes plus
     engagés/expérimentés avec le réseau semblent porter un regard plus critique,
     pas plus complaisant : ceci va à l'encontre d'un biais de désirabilité sociale
     classique envers l'institution.
   - Profil de l'organisme (`q21` secteur, `q22` quartiers, `q23` clientèle) : très
     significativement différent entre modes (ex. "Action communautaire" 42.6 %
     internet vs 4 % téléphone) — confirme que ce sont des organismes différents,
     pas juste un mode de réponse différent pour les mêmes types d'organismes.

2. **Effet probable du mode de collecte lui-même (à surveiller, possible artefact)**
   - Sur les checkbox d'attitude/action (`q1`, `q10`, `q12`), les répondants
     téléphone cochent **systématiquement plus d'options en moyenne** que
     l'internet (ex. q10 : 3.68 vs 2.57 choix en moyenne, p<.0001) — cohérent avec
     un biais d'acquiescement classique en entretien oral (on dit "oui, ça
     s'applique aussi" plus souvent quand chaque option est lue à voix haute par
     un.e intervieweur.e, vs cocher soi-même en ligne).
   - **La catégorie "Autre" est démesurément plus fréquente en téléphone sur
     TOUTES les checkbox** (q10 : 44 % vs 6 %, q12 : 52 % vs 13 %, q21 : 68 % vs
     33 %, q24 : 84 % vs 53 %) — plausiblement un artefact de saisie/codage de
     l'intervieweur.e (verbatims classés par défaut en "Autre") plutôt qu'une vraie
     différence de contenu. À examiner qualitativement via les colonnes
     `*-Comment` correspondantes avant de tirer des conclusions.
   - À l'inverse, sur `q22` (quartiers desservis) et `q23` (clientèles), les
     répondants téléphone cochent **beaucoup moins** d'options en moyenne
     (q22 : médiane 1 vs 6.5 choix, p<.0001) — pourrait refléter des organismes
     plus petits/spécialisés (composition, point 1) OU une administration où
     l'intervieweur.e n'a noté que la réponse "principale" plutôt que de lire
     toute la liste. À valider si possible avec l'équipe qui a mené les entretiens
     téléphoniques.

**Conclusion provisoire** : l'essentiel des différences significatives sur le fond
(q14, q2, q3, q11, profil d'organisme) reflète probablement une **différence de
composition** entre les deux sous-échantillons (les organismes joints par téléphone
ne sont pas un sous-ensemble aléatoire des mêmes répondants internet) plutôt qu'un
effet de désirabilité sociale lié à la présence d'un.e intervieweur.e. En revanche, le
pattern "plus d'items cochés + plus de 'Autre'" sur les checkbox d'attitude ressemble
bien à un effet de collecte (acquiescement / codage à l'oral) et justifie de la
prudence dans l'agrégation directe internet+téléphone pour ces variables précises.

## Prochaines étapes

- Analyse qualitative (codage thématique) des variables ouvertes une fois
  `organismes_qualitatif.csv` disponible.
- Examiner qualitativement les verbatims "Autre" du mode téléphone (colonnes
  `*-Comment`) pour confirmer/infirmer l'hypothèse d'un artefact de codage.

## Variable de zone territoriale (2026-07-23)

Demande client (`notes_rencontre_13juillet.md`) : distribution des répondants
par zone (provincial / grand Montréal / local=Hochelaga). Deux tentatives :

1. **Proxy simplifié à partir de q22** (`scripts/organismes_zone_locale.R`) —
   q22 n'offrant que les 10 quartiers CIUSSS-Est comme choix (pas d'option
   grand Montréal/provincial), seule une distinction "local (1 ou 2+ quartiers
   cochés)" vs "hors zone locale (q22 vide)" est possible. Résultat : 22 % hors
   zone locale, 28 % local-1 quartier, 50 % local-2+ quartiers (n=130).
   Sortie : `organismes_zone_locale.csv` / `distribution_zone_locale_organismes.png`.

2. **Jointure à la classification d'Hubert** (`scripts/organismes_zone_territoire.R`),
   dès que `liste_organismes/data/04_bottin_secteurs.csv` a été poussé par Hubert
   (commit `0d87d25`, 2026-07-23) — colonne `categorie_territoire`
   (local/hochelaga-maisonneuve/montreal/grand_montreal/provincial), jointure par
   nom d'organisme (`participant_name`). **Deux limites importantes identifiées :**
   - **Mode téléphone injoignable** : `participant_name` ET `participant_email`
     sont 100 % vides dans le fichier brut des 25 entrevues téléphoniques
     (vérifié 2026-07-23) — aucune clé pour joindre ces répondants au bottin.
     C'est justement le sous-groupe que le client veut mettre de l'avant.
     **Action décidée avec l'utilisateur : demander à Hubert/Nicolas une liste
     externe (fichier de suivi des appels) associant les 25 entrevues à un nom
     d'organisme.**
   - **`categorie_territoire` mesure le territoire AUTO-DÉCRIT dans l'annuaire
     211/CartesHM (étendue de couverture déclarée), pas la localisation
     physique dans le secteur CIUSSS-Est.** Ex. "Maison d'hébergement Anjou"
     est classée `grand_montreal` parce que son champ `territoire` dit
     littéralement "Grand Montréal", malgré un nom très local. Cohérent avec
     `0 %` des 85 répondants appariés classés `local`/`hochelaga-maisonneuve`
     (alors que q22 montre au contraire un fort ancrage local, ex. 84 %
     cochent Hochelaga) : les 17 organismes tagués `local` dans
     `liste_organismes/scripts/05_chantier.py` viennent du chantier
     "proximité" (commit `265a9dd`, ajouté après la collecte du sondage) et ne
     faisaient probablement pas partie de la population invitée à l'origine.
     **À clarifier avec Hubert avant d'utiliser cette variable dans un livrable
     client** — elle ne répond pas exactement à la question "est-ce un
     organisme du secteur CIUSSS-Est ?".
   - Sur les 85 appariés (mode internet uniquement, tous en correspondance
     exacte de nom) : 38 % grand_montreal (n=32), 33 % montreal (n=28), 29 %
     provincial (n=25). 20 répondants internet supplémentaires ont un
     `participant_name` vide et ne sont pas non plus appariés — piste possible :
     les rattacher par email à `sondage/listes_organismes/*.csv` (liste
     d'invitation) pour récupérer leur nom.
   Sorties : `organismes_zone_territoire.csv` (avec `methode_appariement` par
   ligne) / `distribution_zone_territoire_organismes.png`.

### Taux de réponse local vs global (2026-07-23)

> ⚠️ **Section historique — remplacée par « Taux de réponse par zone territoriale
> (2026-07-27) » plus bas.** Le calcul ci-dessous reste valide dans sa logique
> (et sa conclusion est confirmée), mais son dénominateur (la liste `organismes_locaux`)
> a été remplacé par une classification territoriale de la population invitée
> complète, et son numérateur mélangeait des canaux de recrutement différents.

Vérification directe : `sondage/listes_organismes/organismes_locaux.csv` (65
lignes, 58 emails uniques / 59 noms uniques) est la liste d'organismes ajoutée
spécifiquement pour compléter le scraping 211 avec des organismes locaux
absents de ce dernier (cf. description dans `PROJECT_MEMORY.md` plus haut,
section "Résultats de l'ETA"). Matché contre les 130 lignes de
`organismes_combined.csv` par email ET par nom (normalisés) :

- **Seulement 2 organismes distincts de cette liste ont répondu** :
  "anonyme (l')" (matché par email) et "entre mamans et papas" (matché par
  nom seul — email différent de celui sur la liste d'invitation, possible
  changement d'adresse courriel).
- **Taux de réponse local : 2/58 = 3,45 %**, vs **taux de réponse global :
  128/853 = 15,0 %** (population valide, voir section taux de réponse
  ci-dessus). Le taux local est environ **4,3x plus faible** que le taux
  global.

**Limites de ce calcul (à garder en tête avant de le présenter au client) :**
- Le dénominateur local (58) **n'exclut pas les échecs d'envoi spécifiques**
  à cette liste — non identifiés à ce jour. C'est justement l'action en
  attente listée dans `notes_rencontre_13juillet.md` ("Taux de réponse pour
  le local, il faut identifier les échecs d'envois locaux (Nicolas)"). Si
  plusieurs de ces 58 emails ont bondi, le vrai taux de réponse (sur invitations
  effectivement délivrées) serait plus élevé que 3,45 %, mais probablement
  toujours sous le taux global.
- **Les 25 entrevues téléphoniques ne peuvent pas être vérifiées** contre
  cette liste (aucun nom/email enregistré, voir plus haut) — il est possible
  qu'une partie des appels téléphoniques ait justement ciblé des organismes
  locaux pour compenser leur faible taux de réponse en ligne. Hypothèse à
  valider avec l'équipe qui a mené les entretiens téléphoniques.
- 20 répondants internet supplémentaires sans nom renseigné restent aussi non
  vérifiables contre cette liste.

**Conclusion provisoire** : même avec ces limites, l'écart (3,45 % vs 15,0 %)
est assez large pour suggérer un vrai sous-taux de réponse chez les organismes
spécifiquement locaux — cohérent avec le `0 %` classé "local"/"hochelaga-maisonneuve"
trouvé via `categorie_territoire` plus haut. Les deux constats se corroborent
mutuellement, malgré leurs limites individuelles.

## Taux de réponse par zone territoriale (2026-07-27)

Reprise du dossier « taux de réponse par zone de service desservie ». **Correction de
méthode par rapport aux deux tentatives du 2026-07-23** : un taux de réponse se calcule
sur la **population invitée**, pas sur les répondants. Il faut donc attribuer la zone au
**dénominateur** (les 946 organismes invités) et non au numérateur. Les deux tentatives
précédentes classaient les répondants — ce qui produit une *distribution*, pas un taux.

### Le dénominateur est complet et propre (nouveau)

- Les 7 fichiers `sondage/listes_organismes/*.csv` donnent **946 courriels uniques**
  (888 issus du scraping 211, 41 exclusifs à `organismes_locaux.csv`, 17 présents dans
  les deux). Cohérent avec le `n_population_brute = 946` déjà codé en dur dans
  `rapports/comparaison_internet_telephone.Rmd`.
- Ces 946 courriels s'apparient à **`liste_organismes/data/02_bottin_territoire.csv`**
  (colonne `categorie_territoire`) à **946/946 = 100 %**, par jointure exacte sur le
  courriel normalisé. Aucun appariement flou, aucune perte.
- ⚠️ **Utiliser le bottin `02`, pas le `04`.** `04_bottin_secteurs.csv` est filtré par
  secteur d'activité (1 257 lignes contre 2 460) et ne couvre pas toute la population
  invitée. C'est une des causes du résultat aberrant « 0 % local » obtenu le 2026-07-23
  dans `scripts/organismes_zone_territoire.R`.

Répartition de la population invitée : provincial 341, grand_montreal 293, montreal 272,
hochelaga-maisonneuve 23, local 17.

### Le numérateur est le vrai point faible

Sur les 130 répondants, **seuls 85 portent une clé d'identification** (83 courriels
distincts ; 84 organismes une fois l'appariement par nom ajouté en second recours) :

- **25 entrevues téléphoniques** — `participant_name` / `participant_email` 100 % vides
  (déjà documenté plus haut).
- **20 réponses internet issues d'un lien générique** — voir section dédiée ci-dessous.

### Les 20 réponses sans identifiant ne sont PAS des saisies manuelles (vérifié 2026-07-27)

Question posée par l'utilisateur, par analogie avec le signal trouvé sur le sous-groupe
`interviewer` du volet usagers. **Réponse : non**, le profil est à l'opposé.

⚠️ **Piège de lecture** : la colonne `submitted_at` perd l'heure au chargement (`read_excel`
ne conserve que la date, tous les horodatages tombent à 00:00). L'horodatage complet est
dans le **`response_id`** lui-même (format `2026-05-06T18-15-14-472Z`) — c'est de là qu'il
faut le reconstruire. Un premier examen basé sur `submitted_at` ne montre rien du tout.

Une fois l'heure récupérée (heure de Montréal, UTC-4) :

| | 20 lien générique | 85 invitation |
|---|---|---|
| Étalement | 6 mai → 23 juin, 12 jours distincts | 5 mai → 17 juin |
| Écart médian entre soumissions | **~25 h** | 105 min |
| Écart minimum | **12,4 min** | 1,4 min |
| Soumissions à moins de 10 min d'écart | **0** | 7 |
| Caractères de verbatim (médiane) | **1 230** | 833 |
| Questions renseignées (médiane, /46) | **28,5** | 26 |
| q22 (quartiers) rempli | **19/20** | 57/85 |

Aucune rafale, aucune séance de saisie, aucun horaire aberrant. Ce sont au contraire les
réponses *légitimes* (groupe invitation) qui présentent les écarts très courts — simple
effet de volume après un envoi de courriel. Et les 20 sont **plus complets et plus
loquaces** que la moyenne, alors qu'une retranscription de formulaires papier abrège
plutôt qu'elle n'enrichit. Enfin, toutes les métadonnées d'annuaire (`__token`,
`Description`, `secteur_activite`, `source_sheet`, `Téléphone`, `Site_web`) sont absentes
**ensemble** sur ces 20 lignes (0/20 pour chacune) — cohérent avec « n'est jamais passé
par un lien personnalisé », pas avec une perte technique partielle de jeton.

**Lecture retenue** : le lien du sondage a circulé hors de la liste d'envoi (transfert
entre collègues, infolettre, relais par un organisme partenaire ou par le CIUSSS). Vrais
répondants, engagés, mais **hors du cadre d'échantillonnage**.

**Réserve invérifiable** : certains de ces 20 pourraient appartenir à un organisme
bel et bien invité, dont la personne destinataire a transféré le lien à un collègue. Ils
seraient alors légitimement dans le dénominateur sans qu'on puisse le détecter.

### Conséquence sur le taux global — à corriger avant livraison

Le **15,0 % actuellement écrit dans `rapports/comparaison_internet_telephone.pdf`
(128/853) mélange trois canaux de recrutement au numérateur avec un dénominateur qui n'en
couvre qu'un** (l'invitation courriel). Il surestime le taux.

Taux de réponse à l'invitation courriel, numérateur et dénominateur sur la même base :
**83 / 853 = 9,7 %**. Les 20 génériques et les 25 entrevues téléphoniques sortent du
calcul — ce sont deux autres canaux, à décrire séparément.

### Résultat par zone (local et hochelaga-maisonneuve regroupés)

⚠️ **Ce n'est pas une fusion arbitraire de deux zones distinctes.** `hochelaga-maisonneuve`
et `local` sont **la même zone** (Est-de-Montréal) ; la distinction dans
`categorie_territoire` est un artefact de la chaîne de classification d'Hubert, pas une
vraie différence géographique. La colonne `territoire` d'origine vient de deux sources de
scraping différentes (`liste_organismes/scripts/01_scrape_211.py` et
`01b_scrape_carteshm.py`) ; la source CartesHM tague littéralement certains organismes
`"territoire": "Hochelaga-Maisonneuve"` (`01b_scrape_carteshm.py` L50), et
`02_filtre_territoire.py` (L108-109) préserve ce libellé tel quel comme catégorie séparée
plutôt que de le regrouper avec `local`. Hubert lui-même les traite déjà comme une seule
zone ailleurs dans le pipeline : `generate_livrable.py` (L6, L49) fusionne explicitement
`["local", "hochelaga-maisonneuve"]` sous **« Local »**. Le calcul ci-dessous ne fait donc
que réaligner le taux de réponse sur cette convention déjà établie.

⚠️ **Table invalidée le 2026-08-10 — voir section « `categorie_territoire` n'est pas la
localisation physique » plus bas.** Le « 0 % / 2,5 % local » ci-dessous mesure un proxy
(territoire auto-déclaré) qui s'avère quasi déconnecté de la vraie localisation physique
des organismes. Ne pas citer ces chiffres sans le caveat de la section dédiée.

⚠️ **Table invalidée le 2026-08-10 — voir section « `categorie_territoire` n'est pas la
localisation physique » plus bas.** Le « 0 % / 2,5 % local » ci-dessous mesure un proxy
(territoire auto-déclaré) qui s'avère quasi déconnecté de la vraie localisation physique
des organismes. Ne pas citer ces chiffres sans le caveat de la section dédiée.

Dénominateur = invités classés par zone, **sans retrait des échecs d'envoi** (non
identifiés nominativement) ; numérateur = répondants appariés par courriel puis par nom.

| Zone | Invités | Répondants | Taux |
|---|---|---|---|
| **Est-de-Montréal (local + Hochelaga-Maisonneuve)** | **40** | **1** | **2,5 %** |
| Montréal (hors Est) | 272 | 27 | 9,9 % |
| Grand Montréal (banlieues) | 293 | 31 | 10,6 % |
| Provincial / hors Grand Montréal | 341 | 25 | 7,3 % |

Détail par catégorie brute (avant regroupement) : hochelaga-maisonneuve 1/23 = 4,3 %,
local 0/17 = 0 %.

**Le sous-taux de réponse des organismes locaux est maintenant confirmé par trois
méthodes indépendantes** : 3,45 % via la liste `organismes_locaux` (2026-07-23), 0 %
via le bottin 04 par nom (2026-07-23), 2,5 % via le bottin 02 par courriel sur la
population invitée (2026-07-27). Constat robuste, malgré les limites propres à chacune.

### Ce qui manque encore (par ordre d'importance)

1. ~~**La liste nominative des 93 échecs d'envoi**~~ **Reçue et réconciliée le
   2026-08-10 — voir section dédiée plus bas (45 organismes retenus, pas 93/55/54/48).**
   Ventilés par zone, taux calculés (voir sections dédiées plus bas).
   C'était critique pour la zone locale : sur un dénominateur de 40, deux ou trois
   adresses mortes déplacent sensiblement le 2,5 %.
2. **Le fichier de suivi des 25 appels téléphoniques** (Hubert / Nicolas), pour rattacher
   ces entrevues à un nom d'organisme. Hypothèse à valider : les appels auraient ciblé des
   organismes locaux justement pour compenser leur non-réponse en ligne — auquel cas la
   couverture réelle du territoire local est bien meilleure que ne le suggère le taux.
3. Rien à récupérer côté 20 réponses génériques : aucune métadonnée n'existe dans le
   fichier brut (vérifié). Les traiter comme un canal distinct, documenté comme tel.

### Angle complémentaire, sans dénominateur

`q22` (quartiers desservis) est renseigné pour **101 des 130 répondants**, dont les
**25 du téléphone** (100 % côté téléphone, 76/105 côté internet), et `q0` (dessert l'Est
de Montréal) pour les 130. Ça ne produit pas un taux de réponse, mais ça donne la
**couverture territoriale auto-déclarée de l'échantillon final**, y compris les entrevues
téléphoniques que le taux de réponse ne peut pas atteindre. Les deux se complètent dans
un livrable : le taux dit qui a répondu à l'invitation, q22 dit qui l'échantillon couvre.

## ⚠️ `categorie_territoire` n'est pas la localisation physique (2026-08-10)

Remise en question majeure de tout le calcul de taux de réponse par zone ci-dessus,
déclenchée par une question de l'utilisateur (« est-ce réellement les locaux physiques
qu'on regarde ? »).

### Le problème de fond

`categorie_territoire` (`liste_organismes/data/02_bottin_territoire.csv`, et par
extension `04_bottin_secteurs.csv`) est dérivée **uniquement** du champ texte libre
`territoire` — le « territoire desservi » que l'organisme déclare lui-même sur 211qc.ca
ou CartesHM — via une correspondance de mots-clés (`02_filtre_territoire.py`, fonction
`categorize()`). **Le champ `adresse` (localisation physique réelle) n'est jamais utilisé
dans cette classification**, vérifié en lisant le code : aucune référence à `adresse`
dans `categorize()`.

Un organisme est classé « local » ou « hochelaga-maisonneuve » ⟺ son texte `territoire`
contient un des mots-clés de `LOCAL_TERMS`. Rien à voir, en soi, avec où sont ses locaux.

### Preuve empirique — biais dans les deux sens

**Faux positifs (sur-comptage du dénominateur) :** sur les 9 organismes dont le texte
`territoire` contient « rosemont », 4 ont une adresse physique **hors de l'Est de
Montréal** : Centre de soir Denise-Massé (Ville-Marie), Alternative Naissance (Villeray),
Option Consommateurs (Ville-Marie), et **Réseau Accorderie, basé à Québec** — classés
« local » simplement parce que « Rosemont » apparaît dans une longue liste
d'arrondissements desservis par un programme spécifique.

**Faux négatifs (sous-comptage du numérateur, plus grave) :** en croisant l'adresse
réelle des 85 répondants identifiés avec les 10 quartiers CIUSSS-Est, **23/85 (27 %) ont
leurs locaux physiquement dans l'Est de Montréal** — vérifié ligne par ligne, le nom de
l'arrondissement apparaît littéralement dans le champ `adresse` (ex. « Rosemont—La
Petite-Patrie Montréal QC », « Mercier—Hochelaga-Maisonneuve Montréal QC »). Aucun de ces
23 n'est classé « local »/« hochelaga-maisonneuve » par `categorie_territoire` — ils sont
éparpillés en montreal (11), grand_montreal (9), provincial (3). Cas ironique : « Oasis
des enfants de Rosemont », adresse à Rosemont, classé **provincial**.

**Conclusion : le « 0 % à 2,5 % local » de la section précédente ne mesure pas ce qu'on
pense mesurer.** Le vrai taux de réponse des organismes physiquement dans l'Est de
Montréal est probablement **beaucoup plus élevé** — au moins 23/85 côté identifiés, sans
compter les 45 non identifiés (téléphone + lien générique) qu'on ne peut pas encore
localiser. La « confirmation par trois méthodes indépendantes » de la section précédente
est invalidée : les trois méthodes utilisaient toutes, directement ou indirectement, le
même proxy `categorie_territoire`/`territoire` — donc le même biais, pas trois preuves
indépendantes.

### Liste officielle des 10 quartiers locaux (confirmée avec l'utilisateur, 2026-08-10)

Rivière-des-Prairies, Anjou, Mercier-Est, Pointe-aux-Trembles, Montréal-Est,
Saint-Léonard, Saint-Michel, Hochelaga, Mercier-Ouest, Rosemont — la même liste que celle
utilisée dans les deux questionnaires (q22 organismes, q9_1 usagers), vraisemblablement la
définition officielle du client pour le territoire CIUSSS-Est.

**`LOCAL_TERMS` dans `liste_organismes/scripts/02_filtre_territoire.py` diverge de cette
liste officielle, sur deux points non documentés/expliqués dans le code :**
- **Anjou est complètement absent** de `LOCAL_TERMS` : un organisme dont le territoire dit
  « Anjou » ne sera jamais classé local par ce script.
- **Montréal-Nord y est inclus**, mais Montréal-Nord relève du CIUSSS **du Nord**-de-
  l'Île-de-Montréal, pas de l'Est — hors du territoire à mesurer.

### Tension définitionnelle à trancher (soulevée par l'utilisateur)

« Local » peut vouloir dire deux choses distinctes, et un organisme peut être vrai sur une
seule des deux :
- **Localisation physique** : siège social/locaux dans un des 10 quartiers de l'Est.
- **Desserte déclarée** : dessert majoritairement ou exclusivement l'Est de Montréal,
  peu importe où sont ses locaux (ex. Maison d'hébergement Anjou : locaux à Anjou, mais
  dessert « Grand Montréal » selon son texte).

**Décision : ne pas trancher entre les deux dans une seule case « local ».** Capturer les
deux comme variables indépendantes pour chaque organisme (dénominateur ET répondants) :
1. Adresse dans un des 10 quartiers → oui/non (fiable, dérivable de `adresse`).
2. Texte `territoire` indique une desserte majoritaire/exclusive de l'Est → oui/non/partiel
   (jugement d'interprétation sur texte libre, plus flou).

### Prochaine étape

Aucun script versionné pour l'instant — tout ce qui précède vient de vérifications
manuelles ad hoc (session du 2026-08-10). À écrire : une classification reproductible par
adresse (les 10 quartiers, sur les 946 invités ET les répondants identifiés), croisée avec
la classification par desserte déclarée existante, avant de refaire le tableau de taux de
réponse par zone pour le client.

## Volet usagers (2026-07-12)

Données reçues dans `data/usagers/` : deux fichiers de réponses brutes +
`questionnaire_usagers.json` (en ligne) et `questionnaire_usagers_papier.json` (papier).

**Mapping fichier -> mode** (confirmé par diff des deux JSON : seule différence,
`hasOther` activé sur q3/q4 côté papier) :
- `sondage_65050b17-..._reponses.xlsx` (n = 2892) = **papier**, pas de colonne `source`.
- `sondage_bf820e5c-..._reponses.xlsx` (n = 366) = **en ligne**, colonne `source` avec
  deux sous-groupes : `repondant` (n = 141, auto-administré/QR) et `interviewer`
  (n = 225, saisi sur place par un.e intervieweur.e).

**Décision de regroupement des modes (avec l'utilisateur, 2026-07-12)** : `interviewer`
est traité comme la **même catégorie** que `papier` ("en personne" — un tiers consigne
la réponse), par opposition à `repondant` ("en ligne" — auto-administré). Donc :
- **en_ligne** = repondant seul (n = 141)
- **en_personne** = interviewer + papier (n = 3117)
La distinction fine reste disponible dans la colonne `sous_mode` de
`usagers_combined.csv` si besoin d'une analyse plus fine plus tard.

**⚠️ Point de vigilance — saisie du sous-groupe `interviewer` (non résolu)** : demande
initiale de l'utilisateur de vérifier une hypothèse d'un collègue (un employé aurait pu
saisir manuellement des formulaires papier dans le système en ligne). Aucune adresse IP
n'est disponible dans les exports de réponses (colonne absente des deux fichiers) — donc
impossible de trancher par ce biais. Proxy utilisé : horodatage `submitted_at`. Résultat :
les 225 réponses `interviewer` se concentrent en **5 séances** (17, 23, 24, 25, 30 juin),
au rythme d'~1 réponse/30-90s (trop rapide pour de vraies entrevues), dont une séance le
**23 juin de 22h01 à 23h56** — horaire incompatible avec des entrevues en salle d'attente.
Comparativement, les 141 réponses `repondant` sont étalées naturellement sur 2 mois
(écart médian ~3h). Malgré ce signal, décision de l'utilisateur : garder `interviewer`
regroupé avec `papier` sous "en_personne" (voir ci-dessus). **Mise à jour (2026-07-13)** :
la note méthodologique documentant ce signal a été retirée du rapport client
(`rapports/comparaison_ligne_personne_usagers.pdf`) à la demande de l'utilisateur — le
constat reste consigné ici (mémoire interne du projet) mais n'apparaît plus dans le
livrable. À valider éventuellement avec l'équipe terrain si le client soulève la question.

**Particularité des données** : q11 (communauté culturelle, question `text`) n'existe pas
du tout côté papier (colonne jamais créée), comme q18_2/4/5 pour le volet organismes.

**Pipeline construit** (même structure que le volet organismes) :
- `scripts/usagers_cleaning.R` -> `data/usagers/clean/usagers_combined.csv`
  (⚠️ nécessite `read_excel(..., guess_max = Inf)` : q9_1/quartier est vide pour la
  plupart des lignes, readxl devine sinon le type "logical" à partir d'un échantillon
  de lignes vides et corrompt silencieusement les vraies valeurs texte plus loin dans
  le fichier — repéré et corrigé le 2026-07-12).
- `scripts/usagers_dictionnaire.R` -> `data/usagers/clean/dictionnaire_variables.csv`
- `scripts/usagers_comparaison_modes.R` -> `comparaison_modes_ordinales.csv` (q10, âge,
  Wilcoxon), `comparaison_modes_binaires.csv` (q1-q8 Oui/Non/NSP, Fisher),
  `comparaison_modes_q9.csv` (lieu de résidence, Chi-carré), `comparaison_modes_checkbox.csv`
  (q7_1, Fisher par choix).
- `rapports/comparaison_ligne_personne_usagers.Rmd` -> rapport client, même gabarit que
  `comparaison_internet_telephone.Rmd`.
  (⚠️ piège rencontré : `read.csv` sans `na.strings = c("NA", "")` lit les valeurs
  manquantes de colonnes texte non recodées — ex. q9 — comme chaîne vide plutôt que NA,
  ce qui crée une fausse catégorie "NA" dans les graphiques à barres. Corrigé en
  ajoutant `na.strings` à la lecture de `usagers_combined.csv`.)

**Résultats — différences significatives (p < .05)** : q3 (connaissance des droits, plus
souvent "Non" en ligne), q4 (respect des droits, plus souvent "Oui" en personne), q5
(situation problématique vécue, plus souvent "Oui" en ligne), q8 (fréquente un organisme
communautaire, plus souvent "Oui" en ligne), q9 (lieu de résidence, plus concentré sur
l'Est de Montréal en ligne), q7_1 (s'adresser à l'intervenant.e ou à un organisme, plus
fréquent en ligne). Aucune correction pour tests multiples appliquée (même limite que le
volet organismes) — à interpréter avec prudence, surtout que le mode "en personne" agrège
deux sous-populations elles-mêmes potentiellement différentes (papier vs interviewer).

## Annotation qualitative — variable `mode` (2026-07-26)

Les 29 exports de la plateforme d'annotation
(`data/organismes/clean/annotation_quali/opubliq-annotations-*.csv`, une question
ouverte par fichier, 1 615 annotations au total) ne conservent que
`respondent_id` : rien n'y indique si le verbatim vient du questionnaire en ligne
ou d'une entrevue téléphonique. La colonne `mode` (internet/telephone) a été
ajoutée aux 28 fichiers qui ne l'avaient pas encore (q1_1 avait été traité lors
d'une session précédente), insérée juste après `respondent_id`.

Script : `scripts/organismes_annotation_mode.R` (idempotent — relancer ne fait
que revalider les fichiers déjà traités). Sortie récapitulative :
`data/organismes/clean/annotation_quali_resume_modes.csv`.

- **Clé de jointure : `respondent_id` est un index de ligne commençant à 0**,
  donc `ligne = respondent_id + 1` dans `organismes_qualitatif.csv` (n=130,
  lignes 1-105 = internet, 106-130 = téléphone). ⚠️ Piège rencontré : une
  hypothèse d'index commençant à 1 donne quand même une concordance **parfaite
  sur `mode`** (les deux modes forment des blocs contigus, un décalage de 1 reste
  presque toujours dans le bon bloc) — c'est la comparaison du **verbatim**
  (`text` de l'annotation vs colonne source) qui révèle le décalage. Le script
  valide donc systématiquement les verbatims, pas le mode, et s'arrête si un
  seul ne concorde pas. Concordance actuelle : 1 615/1 615.
- Fidélité de réécriture vérifiée : hors ajout de `mode`, les fichiers réécrits
  sont identiques colonne par colonne à l'original (BOM UTF-8, accents et
  guillemets préservés ; seule différence octet : un saut de ligne final que les
  exports d'origine n'avaient pas).

### Contrôle de couverture des 29 fichiers (2026-07-26)

Vérification distincte de celle du script (qui ne valide que verbatims + mode) :
couverture, doublons, labels vides.

- **Couverture quasi totale : 1 615 annotations pour 1 626 réponses non vides.**
  Les **11 réponses non annotées sont toutes littéralement `N/A` / `n/a`**
  (3 caractères, toutes en mode internet), réparties sur q13 (2), q6 (3),
  q18_3, q18_5, q18_6, q20, q7, q8 (1 chacune). Non-réponses écartées à juste
  titre par la plateforme — **aucune perte de matériau réel**.
- **0 doublon de `respondent_id`, 0 label vide, 0 annotation sans réponse
  source**, sur les 29 fichiers. q1_1 : 53/53, couverture 100 % (39/39 internet,
  14/14 téléphone).
- 157 labels distincts au total, 3 à 7 par question. Aucun quasi-doublon
  (aucune paire de labels identiques une fois accents/casse/ponctuation
  neutralisés). ⚠️ **Une coquille à corriger avant livraison : « Besoins
  matériels immediats »** (q1_1, 5 occurrences) — accent manquant à *immédiats*,
  et ce libellé apparaîtra tel quel dans les tableaux/graphiques client.

**Label « non classable » : 113 annotations (7,0 %), très inégalement réparti —
8,6 % en internet vs 1,4 % en téléphone** (Fisher p = 1,2e‑07, OR = 0,15). Les
verbatims « non classable » sont nettement plus courts (médiane 19 caractères vs
83 pour les autres) et sont typiquement des non-réponses de politesse (« Non »,
« Aucun », « pas d'idée », « déjà en place »). Lecture : le questionnaire
auto-administré récolte beaucoup de réponses ouvertes vides de contenu, que
l'entrevue téléphonique produit peu (l'intervieweur.e relance ou ne consigne
rien). **Attention à l'effet sur les comparaisons de modes** : à effectif brut
égal, le matériau téléphone est plus dense en contenu, donc comparer des
pourcentages calculés sur *toutes* les annotations désavantage mécaniquement
l'internet. Calculer les distributions de labels **hors « non classable »** pour
tout contraste internet/téléphone.

**Répartition des annotations par mode** : 1 253 internet (77,6 %) / 362
téléphone (22,4 %), globalement cohérent avec le poids du mode téléphone dans
l'échantillon (25/130 = 19 %). Points saillants :

- **q18_2, q18_4, q18_5 : 0 annotation téléphone** — attendu, ces 3 colonnes
  n'existent pas dans le fichier réponses téléphone (voir section "Particularités
  et anomalies"). Toute lecture comparative de q18 doit l'expliciter.
- **q10-Comment : 11 téléphone / 6 internet (64,7 % téléphone)**, et
  q12-Comment / q16-Comment à 50 % — surreprésentation nette du téléphone dans
  les champs "Autre". Cela **corrobore l'hypothèse d'artefact de codage** déjà
  formulée dans l'ETA (l'intervieweur.e classe les verbatims en "Autre" par
  défaut). Les annotations de ces champs sont donc le matériau tout indiqué pour
  trancher l'action en attente « examiner qualitativement les verbatims "Autre"
  du mode téléphone ».
- À l'inverse q11_1 (1 téléphone / 16), q17_1 (1/6), q2_2 (5/41) et q18_6 (1/30)
  reposent quasi exclusivement sur l'internet — éviter d'y présenter un contraste
  internet/téléphone, l'effectif téléphone ne le supporte pas.

## Document de vérification manuelle des annotations (2026-07-26)

Script : `scripts/organismes_verification_annotations.R`. Sorties dans
`rapports/verification_annotations/` :
- `verification_annotations_complet.pdf` — **187 pages**, les 29 questions avec
  table des matières ;
- `par_question/verification_<code>.pdf` — **29 PDF autonomes** (2 à 13 pages),
  pour confier une question à une personne sans lui transmettre tout le document.

Structure par question : libellé de la question → **question mère** quand la
question seule est incompréhensible → propriété annotée (la consigne donnée à
l'annotateur) → tableau récapitulatif des catégories (n, %, ventilation
internet/téléphone) → **intégralité des réponses regroupées par catégorie**,
chacune préfixée de `#respondent_id · mode`. Catégories triées par effectif
décroissant, « non classable » toujours en dernier.

**Choix retenus avec l'utilisateur** : regroupement par catégorie (et non par
répondant) pour permettre de repérer un intrus d'un coup d'œil ; pas d'espace de
vérification imprimé (document compact) ; les deux formats (complet + unitaire).

**Document entièrement en français (2026-07-26)** : `\usepackage[french]{babel}`
traduit les titres automatiques (« Table des matières » plutôt que
« Contents ») **et** active la césure française, ce qui compte sur 187 pages de
texte justifié. Métadonnées PDF forcées (`pdflang=fr-CA`, `pdftitle`,
`pdfcreator=Opubliq` — sinon hyperref écrit « LaTeX with hyperref »). Les
valeurs de `mode` étant des codes ASCII, `libelle_mode()` affiche
« téléphone » et non « telephone ». Vérifié : plus aucun marqueur anglais dans
le document complet ni dans les 29 PDF unitaires (les occurrences restantes —
*part, page, question, mode, internet* — sont des mots français ou du texte de
répondants).

**Libellés d'annotation corrigés dans les CSV sources (2026-07-26)** — script
`scripts/organismes_corriger_libelles.R`, idempotent :
- « Partenariats et outreach » → « **Partenariats et travail de proximité** »
  (q4, n=26) : anglicisme. Les verbatims de la catégorie portent sur les
  kiosques, tournées d'organismes et séances d'information dans le milieu.
- « Besoins matériels immediats » → « **immédiats** » (q1_1, n=5).
Après correction, `organismes_annotation_mode.R` a été relancé et revalide
1 615/1 615 verbatims — la réécriture des CSV n'altère rien d'autre.

**Points techniques :**
- Le LaTeX est **généré directement**, pas via R Markdown : les verbatims sont du
  texte libre et pandoc interpréterait les caractères markdown qu'ils
  contiennent. Tout passe par `escaper_latex()`. Compilation `xelatex` via
  `tinytex::latexmk` (⚠️ lui passer un chemin Windows `C:/...` — un chemin
  git-bash `/c/...` fait échouer la compilation sans produire de log).
- **Le chapeau de q18 n'existe pas dans `dictionnaire_variables.csv`** (seuls
  q18_1 à q18_6 y figurent) : il est extrait de l'élément html `q18_intro` du
  schéma SurveyJS `questionnaire_organismes.json`.
- Les colonnes `justification`, `gender`, `age`, `education`, `income`,
  `region`, `language`, `occupation` des exports d'annotation sont **vides à
  100 %** (0/1615) — écartées du document.
- Intégrité vérifiée après compilation : les 1 615 marqueurs `#id` sont présents
  et **les 1 469 verbatims de plus de 12 caractères sont retrouvés intégralement**
  dans le PDF complet comme dans les 29 PDF unitaires. ⚠️ Piège du contrôle :
  `pdf_text()` intercale l'**en-tête courant** dans le flux de texte extrait, ce
  qui coupe artificiellement tout verbatim à cheval sur deux pages (182 faux
  positifs au premier essai) ; il faut retirer les lignes d'en-tête page par page
  avant de recoller, et normaliser les ligatures `ﬀ`/`ﬁ`/`ﬂ`.

## Réconciliation des bounces — de 93 à 45 (2026-08-10)

Nicolas a fourni `sondage/listes_organismes/55_bounces_globaux.csv` en réponse à la
demande de liste nominative des échecs d'envoi. Ce fichier a déclenché un débat sur le
bon chiffre à retenir, documenté ici en entier pour ne pas le refaire.

### La chaîne de chiffres, et pourquoi elle bouge

1. **93** — le total d'échecs d'envoi rapporté au départ par Nicolas (oral/global,
   utilisé jusqu'ici comme `n_echecs_envoi` dans `comparaison_internet_telephone.Rmd`).
2. **55** — ce que Nicolas annonce comme le nombre d'adresses distinctes une fois les
   doublons de son suivi retirés (93 − 55 = 38 événements qu'il considère comme des
   répétitions de la même adresse, mécanisme non détaillé par lui — voir plus bas).
3. **54** — le compte réel du fichier reçu (`read_lines` : 54 lignes non vides, 54
   distinctes, aucun doublon interne). Écart de 1 avec le « 55 » annoncé, jamais
   réconcilié — négligeable, à noter si le chiffre ressort ailleurs.
4. **46** — sur ces 54, seules 46 adresses correspondent **exactement** à une adresse de
   nos 7 fichiers d'envoi (`sondage/listes_organismes/*.csv`, la population de 946).
   Les 8 autres ont été cherchées trois façons (email exact, domaine, nom d'organisme)
   dans ces 7 fichiers — aucune trace :
   - `comiteusagers.cuci.cemtl@ssss.gouv.qc.ca` (ressemble à l'adresse du **client**
     lui-même, pas un organisme invité) et `info@maisoncrossroads.org` : domaine
     totalement absent de nos 946, sous aucune forme.
   - `contact@actionr.org`, `coordinator@actionr.org`, `jumelage@actionr.org`,
     `michaud@actionr.org` : on a bien invité cet organisme (Action Réfugiés Montréal,
     `organismes_partie_3.csv`), mais à **`info@actionr.org`** — 4 adresses différentes
     de celle utilisée.
   - `media@pietons.quebec` : invité à `info@pietons.quebec` (`partie_6`) — différente.
   - `sousletoitdepal@projetpal.com` : invité à `cap@projetpal.com` (`partie_2`, Logi-P.A.L.) — différente.
5. **48** — chiffre retenu initialement (**choix conservateur de l'utilisateur,
   2026-08-10**) : 46 (correspondance exacte — dont `info@actionr.org`, l'adresse
   réellement invitée, qui bondit elle-même directement, en plus des 4 adresses
   redirigées ci-dessus) + **2 organismes de plus** (pas 3 : actionr.org était déjà dans
   les 46), pietons.quebec et projetpal.com, sur la base de l'explication de
   l'utilisateur : les envois se font depuis le logiciel Opubliq (fait par Hubert),
   uniquement à partir de nos listes, et les bounces atterrissent dans la boîte de
   Nicolas — donc une adresse différente qui bondit pour un organisme qu'on a réellement
   invité est vraisemblablement une redirection interne côté destinataire (`info@` qui
   redistribue vers d'autres boîtes), pas une adresse à laquelle on aurait envoyé
   directement. Pour `ssss.gouv.qc.ca` et `maisoncrossroads.org`, aucune redirection ne
   peut expliquer un bounce pour un domaine qu'on n'a **jamais** contacté — ces 2 restent
   exclus dans tous les cas.
6. **45 — chiffre final, corrigé par audit le 2026-08-10.** En croisant les 48 bounces
   retenus avec la liste des répondants, **3 adresses se sont révélées être à la fois un
   "bounce" ET une soumission complète au sondage** : `info@aqdr.org`,
   `info@stellapourlavie.ca`, `je.arsenault@axiaservices.com` (Axia Services — un des
   organismes physiquement locaux confirmés, voir plus bas). Contradiction logique
   directe : une adresse dont l'envoi a échoué ne peut pas avoir servi à répondre.
   Retirées automatiquement (par `setdiff` contre les courriels répondants dans les
   scripts, pas par une liste codée en dur) plutôt que par hypothèse sur leur origine —
   contrairement aux cas actionr.org/pietons.quebec/projetpal.com, ici aucune conjecture
   n'est nécessaire, la preuve (la réponse elle-même) est directement dans nos données.

**n_population_valide = 946 − 45 = 901** (remplace le 853 utilisé jusqu'ici, basé sur
946 − 93).

### Le principe retenu pour trancher — et sa limite assumée

Question soulevée par l'utilisateur : on a décidé de **ne pas dédoublonner** 2 organismes
ayant soumis 2 réponses chacun (130 répondants, pas 128 — voir section dédiée plus haut).
Par cohérence, ne devrait-on pas non plus dédoublonner les 4 adresses bounées
d'actionr.org ?

**Principe retenu : compter les actions indépendantes, pas leurs artefacts en aval.**
- Les 2×2 réponses = 4 **actes indépendants** de soumission (4 `response_id` distincts,
  des horodatages différents, des réponses substantiellement différentes) → 4 comptées.
- Les 4 bounces d'actionr.org = l'artefact probable d'**un seul envoi** (une seule
  adresse dans notre liste, un seul acte d'invitation de notre côté) qui se redistribue
  et échoue en aval → compté comme 1 organisme, pas 4.

**Limite assumée, non vérifiée :** ce raisonnement suppose que le mécanisme est bien une
redirection côté destinataire, pas des tentatives d'envoi répétées par le logiciel
Opubliq lui-même (auquel cas ce serait plus proche du cas des réponses, et il faudrait
compter chaque tentative séparément). Personne n'a confirmé le mécanisme technique exact
avec Nicolas ou Hubert — **45 reste un choix conservateur pour les 2 organismes
"redirection" qu'il inclut encore, pas un chiffre entièrement validé.**

### Reste à faire

- Ventilés par zone (fait, voir sections dédiées plus bas) — le dénominateur local (40)
  « sans retrait des bounces » est maintenant corrigé.
- Idéalement, faire confirmer par Nicolas le mécanisme des 8 adresses non appariées
  (redirection vs liste différente) plutôt que de trancher par hypothèse.

## `source_sheet` (catégorisation d'origine Hubert) souffre du même biais que `categorie_territoire` (2026-08-10)

Premier réflexe (erroné) : utiliser `source_sheet` (Local/Montréal/Grand Montréal/
Provincial, colonne des 7 fichiers d'envoi d'origine — voir section sur la granularité de
la typologie de départ) pour calculer un taux de réponse par zone, en pensant que
c'était une alternative fiable à `categorie_territoire` puisque assignée directement par
Hubert à la construction des listes plutôt que dérivée après coup par mots-clés.

**Résultat obtenu : 1 seul répondant classé "Local" sur 83 identifiés (taux 1,8 %,
`organismes_taux_reponse_zone_source_sheet.csv`).** Immédiatement suspect : on avait déjà
établi, en croisant l'adresse physique des répondants au bottin, qu'un nombre bien plus
grand a réellement ses locaux dans l'Est de Montréal (voir vérification ci-dessous). Un
seul classé "Local" par `source_sheet` contredit directement ce chiffre.

**Explication probable : `source_sheet` mesure vraisemblablement la même chose que
`categorie_territoire`** (le territoire auto-déclaré, pas l'adresse), pas une donnée
indépendante plus fiable. Les totaux des deux corroborent cette lecture — très proches
sans être identiques (Montréal 271 vs 272, Grand Montréal 284 vs 293, Provincial 333 vs
341) — cohérent avec deux dérivations différentes d'une même source de biais, pas deux
mesures indépendantes qui se recouperaient par coïncidence. **Pas confirmé avec Hubert**,
mais l'hypothèse la plus probable. **Conséquence : ne pas utiliser `source_sheet` pour un
taux de réponse "local" au sens physique** — utile seulement comme angle "desserte
déclarée à la Hubert", à comparer au taux par adresse, pas à le remplacer.

### Vérification manuelle des répondants physiquement locaux (2026-08-10)

Reprise de la classification `physiquement_local` (déjà construite pour les 946 invités,
`scripts/organismes_local_desserte_vs_adresse.R`) appliquée aux 83 répondants identifiés.
Avant vérification manuelle : 23 répondants physiquement locaux. Deux problèmes trouvés
et un troisième vérifié :

1. **Contamination Montréal-Nord, corrigée** : « Centre de rêves et espoirs » (12550
   boulevard Lacordaire, Montréal-Nord) avait été inclus par une version antérieure du
   script, avant la correction du 2026-08-10 qui exclut explicitement Montréal-Nord
   (mauvais CIUSSS). Disparaît une fois la version corrigée appliquée aux répondants.
2. **« Clinique juridique de Saint-Michel »** ajoutée par la règle de nom (org dont le
   nom référence directement le quartier), pas par la rue (adresse réelle : 3737
   boulevard Crémazie Est, dans l'arrondissement composé Villeray–Saint-Michel–
   Parc-Extension). Même règle que les 5 cas retenus côté population — jugée acceptable.
3. **Rosemont–La Petite-Patrie (10 des 23), vérifié par code postal** (pas de source de
   frontières officielle disponible, donc heuristique, pas une certitude) : 8/10 ont un
   code postal H1X/H1Y (Rosemont) — dont un directement sur le boulevard Rosemont
   (Action main-d'oeuvre) et un nommé « Oasis des enfants de Rosemont ». **2/10 ont un
   code postal H2S** (Centre d'orientation paralégale et sociale pour immigrants, 435
   rue Beaubien Est ; Regroupement des aidantes et aidants naturels de Montréal, 5800 rue
   Saint-Denis) — plus probablement La Petite-Patrie que Rosemont.
   **Décision de l'utilisateur (2026-08-10) : garder les 8 confirmés Rosemont pour
   l'instant**, traiter les 2 H2S comme non confirmés/à vérifier plus tard (pas encore
   tranché s'ils comptent ou non — voir résultats du taux ci-dessous, calculés avec les
   8 gardés).

**Chiffre retenu pour l'instant : 21 répondants physiquement locaux** (23 − 1 Montréal-Nord
+ 0 net sur Saint-Michel, la clinique remplaçant Montréal-Nord dans le compte − 2 H2S
non confirmés). La même correction Montréal-Nord/H2S/Saint-Michel a aussi été appliquée
au dénominateur (946 invités) dans le script final (voir résultats ci-dessous).

### Taux de réponse par adresse physique (2026-08-10)

Script : `scripts/organismes_taux_reponse_zone_adresse.R`, sortie dans
`organismes_taux_reponse_zone_adresse.csv`. Applique la classification
`physiquement_local` (avec les raffinements Saint-Michel/Montréal-Nord/Rosemont ci-dessus)
aux 946 invités (moins les 45 bounces retenus, voir audit ci-dessus) et aux 83 répondants
identifiés.

| | Population valide | Répondants | Taux |
|---|---|---|---|
| **Local (adresse physique)** | 146 | 21 | **14,4 %** |
| Reste | 755 | 62 | 8,2 % |
| **Total** | 901 | 83 | 9,2 % |

**Comparaison directe avec `source_sheet` (catégorisation d'origine Hubert)** :

| Méthode | Population valide | Répondants | Taux |
|---|---|---|---|
| `source_sheet` (Hubert, déclaratif) | 56 | 1 | 1,8 % |
| **Adresse physique (vérifiée)** | 146 | 21 | **14,4 %** |

**Renversement complet du narratif.** Avec `categorie_territoire` et `source_sheet` (tous
deux basés sur le territoire auto-déclaré), la conclusion était que les organismes locaux
répondaient beaucoup moins que les autres (1,8-2,5 %). Avec l'adresse physique — la
mesure vérifiée ligne par ligne, pas un proxy déclaratif — **les organismes locaux
répondent en fait MIEUX que le reste** (14,4 % vs 8,2 %, près du double). La lecture
"sous-taux de réponse local" présentée plus haut (section "Taux de réponse par zone
territoriale", "confirmée par trois méthodes indépendantes") est donc elle-même
invalidée : les trois méthodes utilisaient toutes, directement ou indirectement, un
territoire auto-déclaré plutôt que la localisation physique — pas trois preuves
indépendantes d'un même biais, comme déjà noté plus haut pour `categorie_territoire` seul.

### Validation croisée avec q0 (2026-08-10)

`q0` (« Est-ce que votre organisme dessert le territoire de l'Est de l'île de Montréal ? »
Oui/Non) est demandée directement dans le questionnaire — auto-déclaration de
l'organisme au moment de répondre, disponible pour les 130 répondants (y compris les 45
non identifiés, contrairement à `physiquement_local`).

- **Sur les 130 : 80,8 % répondent Oui** (105/130 ; 85,7 % en ligne, 60 % au téléphone).
- **Croisement avec `physiquement_local` (83 identifiés)** :

  | | q0 = Oui | q0 = Non |
  |---|---|---|
  | Physiquement local (n=21) | 20 (95 %) | 1 |
  | Pas physiquement local (n=62) | 50 (81 %) | 12 |

**Ça valide la classification par adresse** : 95 % des organismes physiquement locaux se
disent bien desservir le territoire, cohérent. **Mais ça confirme aussi que q0 est un
très mauvais filtre "local" à lui seul** : même chez les organismes PAS physiquement
locaux, 81 % répondent quand même Oui — la question posée est un seuil bas (dessert
l'Est, même en partie, même parmi d'autres territoires plus larges), pas un signal
d'ancrage local. Ne pas utiliser q0 seul comme proxy de "local".

## Audit général du taux de réponse (2026-08-10)

Passe d'audit demandée par l'utilisateur sur l'ensemble des calculs de taux de réponse
(volet organismes) après la séquence de corrections ci-dessus. Un bug réel trouvé et
corrigé partout, un bug cosmétique corrigé, deux scripts réconciliés, deux nuances
vérifiées et jugées sans impact.

### 🔴 Bug réel : 3 "bounces" avaient pourtant répondu (corrigé)

En croisant les 48 bounces retenus (section "Réconciliation des bounces") avec la liste
des répondants, **3 adresses étaient à la fois comptées comme bounce ET comme
répondant** : `info@aqdr.org`, `info@stellapourlavie.ca`,
`je.arsenault@axiaservices.com` (Axia Services — un des organismes physiquement locaux
confirmés). Contradiction logique directe : une adresse dont l'envoi a échoué ne peut pas
avoir servi à répondre (vérifié : les 3 ont soumis une réponse complète les 8, 14 et 28
mai 2026, par internet, avec nom d'organisme renseigné).

**Corrigé dans les 3 scripts concernés** (`comparaison_internet_telephone.Rmd`,
`organismes_taux_reponse_zone_source_sheet.R`, `organismes_taux_reponse_zone_adresse.R`)
par un retrait automatique (`setdiff` des bounces contre les courriels répondants), pas
une liste codée en dur — pour que ça reste correct si le fichier de bounces change.
**48 → 45 bounces retenus, `n_population_valide` = 946 − 45 = 901** (plutôt que 898).
Chiffres finaux mis à jour partout (voir sections "Réconciliation des bounces",
"`source_sheet`..." et "Taux de réponse par adresse physique" ci-dessus) : l'écart est
mineur (145→146 organismes locaux valides, 14,5 %→14,4 %), la correction ne change pas
la conclusion mais retire une incohérence logique qui aurait pu être relevée par le
client.

### 🟡 Bug cosmétique : commentaire périmé (corrigé)

Un commentaire dans `comparaison_internet_telephone.Rmd` référençait encore l'ancien
dénominateur « 946/853 » (avant la réconciliation des bounces du 2026-08-10) au lieu du
nouveau. Mis à jour à « 946/901 ».

### 🟡 Deux scripts de classification adresse divergents (réconciliés)

`organismes_local_desserte_vs_adresse.R` (premier script écrit) n'avait jamais reçu le
raffinement Rosemont/H2S trouvé après coup (voir section "Vérification manuelle des
répondants physiquement locaux") — seul `organismes_taux_reponse_zone_adresse.R` (écrit
après la découverte du problème) l'avait. Résultat avant correction :
`organismes_local_desserte_vs_adresse.csv` contenait un chiffre "physiquement local"
gonflé (188) par rapport au chiffre final correct (157 brut, avant retrait des bounces).
**Corrigé** : même logique Rosemont/H2S (extraction du code postal, exclusion H2S sauf
signal fort) ajoutée aux deux scripts. Les deux produisent maintenant le même chiffre :
**157 organismes physiquement locaux (brut, sur 946)**, 35 desservent l'Est selon le
texte `territoire`, seulement **7** sont les deux à la fois (était 9 avant la correction
Rosemont/H2S).

### 🟢 Vérifié, pas de problème

- Les 83 répondants identifiés sont tous bel et bien dans la population de 946 (aucune
  fuite entre les deux jeux de données).
- La construction des 946 (dédoublonnage de 970 lignes brutes par courriel) est saine :
  12 courriels partagés par des lignes à "nom différent", mais presque tous sont de
  simples variantes de formatage du même organisme (majuscules, ordre des mots, nom
  abrégé vs complet), pas de vraie fusion problématique.

### 🟡 Nuance mineure, non corrigée (impact négligeable)

`info@lescalier.ca` est partagé par « Les Distributions l'Escalier » et « Les
Habitations l'Escalier de Montréal » — probablement 2 programmes distincts d'un même
réseau (comme le cas « L'Anonyme » trouvé plus tôt dans le bottin), comptés comme 1 seul
organisme dans nos 946 à cause du courriel partagé. Effet négligeable sur le taux (au
plus 946 devient 947) — pas corrigé, jugé non prioritaire.

### Reste non résolu (pas trouvé par cet audit, déjà connu)

- Le mécanisme de redirection pour les 2 organismes restants dans les bounces
  (pietons.quebec, projetpal.com) n'est toujours pas confirmé avec Nicolas — voir section
  "Réconciliation des bounces", "Limite assumée, non vérifiée".
- `scripts/organismes_zone_locale.R` et `organismes_zone_territoire.R` (les tout premiers
  scripts, basés sur `categorie_territoire`/`04_bottin_secteurs.csv`, invalidés) restent
  dans le repo sans avertissement en en-tête — risque de confusion si quelqu'un les
  relance sans lire ce fichier.

## Prochaines étapes (mise à jour 2026-07-27)

- **Taux de réponse par zone** (voir section dédiée) : relancer le calcul une fois reçue
  la liste nominative des 93 échecs d'envoi (Nicolas) et le fichier de suivi des 25 appels
  téléphoniques (Hubert/Nicolas). Aucun script n'est encore versionné pour ce calcul —
  à écrire au moment de la relance.
- **Corriger le taux de réponse global dans `comparaison_internet_telephone.Rmd`** : le
  15,0 % (128/853) mélange trois canaux de recrutement au numérateur avec un dénominateur
  qui n'en couvre qu'un. Valeur cohérente : 9,7 % (83/853) pour l'invitation courriel,
  les deux autres canaux décrits séparément.

- Analyse qualitative du volet usagers (section D, entièrement ouverte, + commentaires
  libres des autres sections) une fois le découpage quantitatif/qualitatif fait (même
  logique que `organismes_eta.R`, pas encore répliquée pour usagers).
- Décider si le point de vigilance sur le sous-groupe `interviewer` nécessite un suivi
  auprès de l'équipe terrain avant la livraison finale du rapport.
- Exploiter la variable `mode` des annotations : comparer la distribution des
  `label` internet vs téléphone par question (en se limitant aux questions où
  l'effectif téléphone le permet), en commençant par les champs "Autre"
  (q10/q12/q16/q21/q23/q24-Comment) pour statuer sur l'hypothèse d'artefact de
  codage.
