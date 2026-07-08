# Nettoyage et fusion des réponses au questionnaire "organismes communautaires"
# (mode internet + mode téléphone) -> data/organismes/clean/organismes_combined.csv
#
# Décisions (voir PROJECT_MEMORY.md) :
#  - les deux modes sont fusionnés avec une colonne `mode`
#  - q0 n'est PAS filtré (les "Non" sont une question de recherche en soi)
#  - q16 est harmonisé en minuscules (casing incohérent entre modes)
#  - les doublons de soumission (même email) sont flagués, pas supprimés

library(readxl)
library(dplyr)
library(stringr)
library(readr)
library(jsonlite)
library(purrr)

# Ce script suppose que le répertoire de travail R est la racine du projet
# (le dossier contenant data/ et scripts/).

chemin_internet   <- "data/organismes/sondage_c4504161-d6d4-439d-8203-1e5aabf3b7ad_reponses.xlsx"
chemin_telephone  <- "data/organismes/sondage_1bf3ef5c-c052-4e13-be00-e2f6d6dd33d2_reponses.xlsx"
chemin_sortie_dir <- "data/organismes/clean"

dir.create(chemin_sortie_dir, showWarnings = FALSE, recursive = TRUE)

internet  <- read_excel(chemin_internet)  %>% mutate(mode = "internet")
telephone <- read_excel(chemin_telephone) %>% mutate(mode = "telephone")

# Fusion : dplyr::bind_rows aligne les colonnes communes et remplit de NA
# les colonnes absentes d'un des deux jeux (ex. q18_2/q18_4/q18_5 côté téléphone,
# Description/secteur_activite/... côté internet uniquement).
combine <- bind_rows(internet, telephone)

# Nettoyage générique du texte : on enlève les espaces en début/fin de toutes
# les colonnes de type caractère (fermées comme ouvertes).
combine <- combine %>%
  mutate(across(where(is.character), ~ na_if(str_trim(.x), "")))

# Les colonnes checkbox (choix multiples) sont exportées comme des chaînes au
# format JSON, ex. `["besoin_services", "les_deux"]` (et parfois une valeur nue
# non entourée de crochets, ex. `other`). On les convertit en une chaîne lisible
# "valeur1 | valeur2" pour faciliter la lecture/le tri dans Excel.
decoder_choix_multiples <- function(x, nettoyer_valeur = identity) {
  map_chr(x, function(cellule) {
    if (is.na(cellule)) return(NA_character_)
    valeurs <- tryCatch(fromJSON(cellule), error = function(e) cellule)
    str_c(nettoyer_valeur(valeurs), collapse = " | ")
  })
}

# q12 : le mode téléphone préfixe chaque choix ("a. Commissaire aux plaintes"),
# le mode internet non ("Commissaire aux plaintes") -> on retire le préfixe
# valeur par valeur, avant l'assemblage " | ".
retirer_prefixe_lettre <- function(valeurs) str_replace(valeurs, "^[a-d]\\.\\s*", "")

colonnes_checkbox <- c("q1", "q10", "q12", "q21", "q22", "q23", "q24")
colonnes_checkbox <- colonnes_checkbox[colonnes_checkbox %in% names(combine)]
for (col in colonnes_checkbox) {
  nettoyeur <- if (col == "q12") retirer_prefixe_lettre else identity
  combine[[col]] <- decoder_choix_multiples(combine[[col]], nettoyeur)
}

# Harmonisation du casing Oui/OUI, Non/NON, NSP incohérent entre modes
# (q16, q14_1, q15 : internet utilise "Oui"/"Non", téléphone "OUI"/"NON")
harmoniser_oui_non <- function(x) {
  case_when(
    is.na(x) ~ NA_character_,
    str_to_lower(x) == "oui" ~ "Oui",
    str_to_lower(x) == "non" ~ "Non",
    str_to_lower(x) == "nsp" ~ "NSP",
    str_to_lower(x) == "ne sais pas" ~ "Ne sais pas",
    TRUE ~ x
  )
}
combine <- combine %>%
  mutate(across(any_of(c("q16", "q14_1", "q15")), harmoniser_oui_non))

# Recodage numérique des variables fermées, demandé par le client (2026-07-07) :
#   Oui = 1, Non = 2
#   Échelles à 4 niveaux (satisfaction ou équivalent) : 1 = le plus négatif/faible,
#   4 = le plus positif/élevé
# "Ne sais pas" / "NSP" / "Autre" (valeurs hors Oui/Non) sont codées 9.
# Les questions à choix multiples (checkbox) ne sont PAS recodées ici : plusieurs
# réponses possibles par répondant, donc un code 1/2 unique ne s'applique pas.
recoder_binaire <- function(x) {
  case_when(
    is.na(x) ~ NA_integer_,
    str_to_lower(x) == "oui" ~ 1L,
    str_to_lower(x) == "non" ~ 2L,
    TRUE ~ NA_integer_
  )
}
recoder_oui_non_autre <- function(x) {
  case_when(
    is.na(x) ~ NA_integer_,
    str_to_lower(x) == "oui" ~ 1L,
    str_to_lower(x) == "non" ~ 2L,
    TRUE ~ 9L  # NSP / Ne sais pas / other
  )
}
recoder_echelle <- function(x, niveaux) {
  # niveaux : vecteur de 4 valeurs dans l'ordre 1 (négatif/faible) -> 4 (positif/élevé)
  match(x, niveaux) %>% as.integer()
}

combine <- combine %>%
  mutate(
    # q0 manquant côté téléphone (10 cas) : hypothèse de travail (2026-07-07,
    # voir PROJECT_MEMORY.md) que l'intervieweur.e ne posait/notait cette
    # question que lorsque la réponse était "Oui", donc un q0 manquant en
    # téléphone est traité comme "Non". Signalé au lecteur dans le rapport.
    q0    = ifelse(mode == "telephone" & is.na(recoder_binaire(q0)), 2L, recoder_binaire(q0)),
    q14   = recoder_binaire(q14),
    q15   = recoder_binaire(q15),
    q17   = recoder_binaire(q17),
    q14_1 = recoder_oui_non_autre(q14_1),
    q16   = recoder_oui_non_autre(q16),
    q3    = recoder_echelle(q3, c("Pas du tout de connaissance", "Peu de connaissance",
                                    "Assez grande connaissance", "Très grande connaissance")),
    q5    = recoder_echelle(q5, c("pas_du_tout", "peu_respectes", "assez_respectes", "tres_respectes")),
    q11   = recoder_echelle(q11, c("tres_difficile", "assez_difficile", "assez_facile", "tres_facile")),
    q2    = recoder_echelle(q2, c("jamais", "rarement", "souvent", "tres_souvent"))
  )

# Détection des doublons de soumission (même courriel, hors valeurs manquantes)
combine <- combine %>%
  mutate(doublon_email = !is.na(participant_email) &
           duplicated(participant_email) | (!is.na(participant_email) &
           duplicated(participant_email, fromLast = TRUE)))

# Réordonnancement : métadonnées, puis mode, puis les questions dans l'ordre q0->q25
ordre_questions <- c(
  "q0","q1","q1_1","q2","q2_1","q2_2","q3","q4","q5","q5_1","q5_2","q5_3",
  "q6","q7","q8","q9","q10","q10-Comment","q11","q11_1","q11_2","q12","q12-Comment",
  "q13","q14","q14_1","q15","q16","q16-Comment","q17","q17_1",
  "q18_1","q18_2","q18_3","q18_4","q18_5","q18_6","q19","q20",
  "q21","q21-Comment","q22","q23","q23-Comment","q24","q24-Comment","q25"
)
colonnes_meta <- c(
  "response_id","project_id","survey_id","mode","submitted_at",
  "participant_email","participant_name","doublon_email",
  "Description","secteur_activite","Telephone","Site_web","source_sheet","__token"
)
# certaines colonnes meta peuvent ne pas exister selon les jeux (ex. __token) -> on filtre
colonnes_meta      <- colonnes_meta[colonnes_meta %in% names(combine)]
ordre_questions    <- ordre_questions[ordre_questions %in% names(combine)]
autres_colonnes    <- setdiff(names(combine), c(colonnes_meta, ordre_questions))

combine <- combine %>% select(all_of(colonnes_meta), all_of(ordre_questions), all_of(autres_colonnes))

cat("Jeu combiné :", nrow(combine), "lignes,", ncol(combine), "colonnes\n")
cat("  - internet :", sum(combine$mode == "internet"), "\n")
cat("  - telephone:", sum(combine$mode == "telephone"), "\n")
cat("Doublons de soumission détectés (email) :", sum(combine$doublon_email), "lignes\n")
if (any(combine$doublon_email)) {
  print(combine %>% filter(doublon_email) %>% select(participant_email, submitted_at, mode))
}

write_excel_csv(combine, file.path(chemin_sortie_dir, "organismes_combined.csv"), na = "")

cat("\n-> Écrit:", file.path(chemin_sortie_dir, "organismes_combined.csv"), "\n")
