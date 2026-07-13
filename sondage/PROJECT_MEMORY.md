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

## Prochaines étapes (mise à jour 2026-07-12)

- Analyse qualitative du volet usagers (section D, entièrement ouverte, + commentaires
  libres des autres sections) une fois le découpage quantitatif/qualitatif fait (même
  logique que `organismes_eta.R`, pas encore répliquée pour usagers).
- Décider si le point de vigilance sur le sous-groupe `interviewer` nécessite un suivi
  auprès de l'équipe terrain avant la livraison finale du rapport.
