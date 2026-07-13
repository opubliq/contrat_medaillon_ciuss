# Nettoyage et fusion des réponses au questionnaire "usagers" (volet population)
# -> data/usagers/clean/usagers_combined.csv
#
# Décisions (2026-07-12, avec l'utilisateur) :
#  - Le fichier "en ligne" (sondage_bf820e5c...) contient une colonne `source` avec
#    deux sous-groupes : `repondant` (auto-administré, probablement QR) et
#    `interviewer` (saisi par un.e intervieweur.e sur place). Le fichier "papier"
#    (sondage_65050b17...) est une 3e source, sans colonne `source`.
#  - `interviewer` est traité comme la MÊME catégorie que `papier` ("en personne",
#    collecte assistée), par opposition à `repondant` ("en ligne", auto-administré).
#    -> mode = "en_ligne" (repondant seul) vs "en_personne" (interviewer + papier).
#    La distinction fine est conservée dans la colonne `sous_mode` (repondant /
#    interviewer / papier) pour ne pas perdre l'information.
#  - ⚠️ Signal de saisie suspect repéré sur le sous-groupe `interviewer` : 225
#    réponses concentrées en 5 sessions (17, 23, 24, 25, 30 juin), au rythme d'une
#    réponse toutes les 30-90 secondes (trop rapide pour de vraies entrevues), dont
#    une session le 23 juin de 22h01 à 23h56 (horaire incompatible avec des
#    entrevues en salle d'attente). Aucune adresse IP n'est disponible dans les
#    exports pour trancher définitivement. Décision de l'utilisateur : regrouper
#    quand même `interviewer` avec `papier` sous "en_personne" (voir PROJECT_MEMORY.md).
#  - q11 (communauté culturelle) est absent du fichier papier (colonne jamais créée,
#    comme q18_2/4/5 côté téléphone pour le volet organismes) -> NA côté papier.
#  - q3-Comment / q4-Comment (précision "Autre") n'existent que côté papier : le
#    questionnaire papier a `hasOther` activé sur q3/q4, pas le questionnaire en ligne.

library(readxl)
library(dplyr)
library(stringr)
library(readr)
library(jsonlite)
library(purrr)

# Les données vivent hors du repo, sur le drive partagé Google Opubliq
# (accès restreint, données de sondage sensibles).
data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"

chemin_papier     <- file.path(data_dir, "usagers/sondage_65050b17-1eae-4939-ad42-a4c719e8d4df_reponses.xlsx")
chemin_en_ligne   <- file.path(data_dir, "usagers/sondage_bf820e5c-76b0-496f-9a1e-0286fc301f76_reponses.xlsx")
chemin_sortie_dir <- file.path(data_dir, "usagers/clean")

dir.create(chemin_sortie_dir, showWarnings = FALSE, recursive = TRUE)

# guess_max = Inf : q9_1 (quartier) est vide pour la plupart des répondants
# (conditionnel à q9 = "est_montreal") -> readxl devine le type à partir des
# premières lignes et se trompe (logical) si l'échantillon par défaut (1000
# lignes) ne contient que des NA avant la première vraie valeur texte.
papier    <- read_excel(chemin_papier,   guess_max = Inf) %>% mutate(mode = "en_personne", sous_mode = "papier")
en_ligne  <- read_excel(chemin_en_ligne, guess_max = Inf) %>%
  mutate(
    sous_mode = source,
    mode = ifelse(source == "repondant", "en_ligne", "en_personne")
  ) %>%
  select(-source)

# Fusion : dplyr::bind_rows aligne les colonnes communes et remplit de NA les
# colonnes absentes d'un des deux jeux (ex. q11 côté papier, q3-Comment/q4-Comment
# côté en ligne).
combine <- bind_rows(papier, en_ligne)

# Nettoyage générique du texte : on enlève les espaces en début/fin de toutes
# les colonnes de type caractère (fermées comme ouvertes).
combine <- combine %>%
  mutate(across(where(is.character), ~ na_if(str_trim(.x), "")))

# q7_1 (checkbox) est exportée comme une chaîne JSON, ex. `["Commissaire aux
# plaintes", "other"]`. Décodée en chaîne lisible "valeur1 | valeur2".
decoder_choix_multiples <- function(x) {
  map_chr(x, function(cellule) {
    if (is.na(cellule)) return(NA_character_)
    valeurs <- tryCatch(fromJSON(cellule), error = function(e) cellule)
    str_c(valeurs, collapse = " | ")
  })
}
combine$q7_1 <- decoder_choix_multiples(combine$q7_1)

# Recodage numérique des variables fermées Oui/Non/Ne sais pas -> 1/2/9, pour
# rester cohérent avec la convention adoptée pour le volet organismes.
recoder_oui_non_autre <- function(x) {
  case_when(
    is.na(x) ~ NA_integer_,
    str_to_lower(x) == "oui" ~ 1L,
    str_to_lower(x) == "non" ~ 2L,
    TRUE ~ 9L  # "Ne sais pas"
  )
}
# q10 (groupe d'âge) : échelle ordinale à 4 niveaux, 1 = plus jeune -> 4 = plus âgé.
recoder_echelle <- function(x, niveaux) match(x, niveaux) %>% as.integer()

combine <- combine %>%
  mutate(
    q1  = recoder_oui_non_autre(q1),
    q2  = recoder_oui_non_autre(q2),
    q3  = recoder_oui_non_autre(q3),
    q4  = recoder_oui_non_autre(q4),
    q5  = recoder_oui_non_autre(q5),
    q7  = recoder_oui_non_autre(q7),
    q8  = recoder_oui_non_autre(q8),
    q10 = recoder_echelle(q10, c("34 ans et -", "35 à 44 ans", "45 et 64 ans", "65 ans et +"))
  )
# q9 (lieu de résidence) et q9_1 (quartier) sont nominales (pas d'ordre naturel)
# -> conservées en texte lisible, non recodées.

# Réordonnancement : métadonnées, puis mode/sous_mode, puis les questions dans
# l'ordre du questionnaire (q1 -> q12).
ordre_questions <- c(
  "q1","q1_1","q2","q2_1",
  "q3","q3-Comment","q3_1",
  "q4","q4-Comment","q4_1","q4_2","q5","q5_1",
  "q6_1","q6_2","q6_3","q6_4","q6_5","q6_6",
  "q7","q7_1","q7_1-Comment","q7_1_organisme","q7_2",
  "q8","q8_1","q8_2","q9","q9_1","q10","q11","q12"
)
colonnes_meta <- c(
  "response_id","project_id","survey_id","mode","sous_mode","submitted_at",
  "participant_email","participant_name"
)
colonnes_meta   <- colonnes_meta[colonnes_meta %in% names(combine)]
ordre_questions <- ordre_questions[ordre_questions %in% names(combine)]
autres_colonnes <- setdiff(names(combine), c(colonnes_meta, ordre_questions))

combine <- combine %>% select(all_of(colonnes_meta), all_of(ordre_questions), all_of(autres_colonnes))

cat("Jeu combiné :", nrow(combine), "lignes,", ncol(combine), "colonnes\n")
cat("  - en_ligne (repondant)      :", sum(combine$sous_mode == "repondant"), "\n")
cat("  - en_personne / interviewer :", sum(combine$sous_mode == "interviewer"), "\n")
cat("  - en_personne / papier      :", sum(combine$sous_mode == "papier"), "\n")
cat("  Total en_ligne   :", sum(combine$mode == "en_ligne"), "\n")
cat("  Total en_personne:", sum(combine$mode == "en_personne"), "\n")

write_excel_csv(combine, file.path(chemin_sortie_dir, "usagers_combined.csv"), na = "")

cat("\n-> Écrit:", file.path(chemin_sortie_dir, "usagers_combined.csv"), "\n")
