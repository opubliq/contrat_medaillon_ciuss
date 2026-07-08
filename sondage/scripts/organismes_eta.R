# Analyse exploratoire du questionnaire "organismes communautaires"
#  1. sépare organismes_combined.csv en un fichier quantitatif (variables fermées)
#     et un fichier qualitatif (variables ouvertes / texte libre)
#  2. produit des statistiques descriptives de base sur les variables fermées
#
# Ce script suppose que le répertoire de travail R est la racine du projet
# et que scripts/organismes_cleaning.R a déjà été exécuté.

library(dplyr)
library(readr)
library(tidyr)
library(stringr)

dossier_clean <- "data/organismes/clean"

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE)
dico    <- read_csv(file.path(dossier_clean, "dictionnaire_variables.csv"), show_col_types = FALSE)

# --- 1. Séparation quantitatif / qualitatif -----------------------------

colonnes_id <- c("response_id", "mode", "participant_email", "participant_name",
                  "submitted_at", "doublon_email")
colonnes_id <- colonnes_id[colonnes_id %in% names(combine)]

codes_fermes  <- dico %>% filter(type == "ferme")  %>% pull(code)
codes_ouverts <- dico %>% filter(type == "ouvert") %>% pull(code)

codes_fermes  <- codes_fermes[codes_fermes %in% names(combine)]
codes_ouverts <- codes_ouverts[codes_ouverts %in% names(combine)]

quantitatif <- combine %>% select(all_of(colonnes_id), all_of(codes_fermes))
qualitatif  <- combine %>% select(all_of(colonnes_id), all_of(codes_ouverts))

write_excel_csv(quantitatif, file.path(dossier_clean, "organismes_quantitatif.csv"), na = "")
write_excel_csv(qualitatif,  file.path(dossier_clean, "organismes_qualitatif.csv"),  na = "")

cat("Quantitatif :", nrow(quantitatif), "lignes,", ncol(quantitatif), "colonnes",
    "(", length(codes_fermes), "variables fermées )\n")
cat("Qualitatif  :", nrow(qualitatif), "lignes,", ncol(qualitatif), "colonnes",
    "(", length(codes_ouverts), "variables ouvertes )\n\n")

# --- 2. Statistiques descriptives des variables fermées -----------------

cat("=== Profil des répondants ===\n")
cat("q0 - Dessert le territoire de l'Est de Montréal :\n")
print(table(combine$mode, combine$q0, useNA = "ifany"))

cat("\n=== Fréquences par variable fermée (radiogroup), ensemble des modes ===\n")
vars_radio <- dico %>% filter(type == "ferme", sous_type == "radiogroup") %>% pull(code)
vars_radio <- vars_radio[vars_radio %in% names(combine)]
for (v in vars_radio) {
  cat("\n--", v, "--\n")
  print(combine %>% count(!!sym(v), sort = TRUE, name = "n") %>% rename(reponse = !!sym(v)))
}

cat("\n=== Fréquences par variable fermée (checkbox - plusieurs réponses possibles) ===\n")
vars_checkbox <- dico %>% filter(type == "ferme", sous_type == "checkbox") %>% pull(code)
vars_checkbox <- vars_checkbox[vars_checkbox %in% names(combine)]
for (v in vars_checkbox) {
  cat("\n--", v, "--\n")
  reponses <- combine %>%
    filter(!is.na(!!sym(v))) %>%
    separate_rows(!!sym(v), sep = "\\s*\\|\\s*") %>%
    count(!!sym(v), sort = TRUE, name = "n") %>%
    rename(choix = !!sym(v))
  print(reponses)
}

cat("\n=== Taux de réponse (non-manquant) des variables ouvertes ===\n")
taux_reponse <- qualitatif %>%
  select(all_of(codes_ouverts)) %>%
  summarise(across(everything(), ~ sum(!is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "code", values_to = "n_reponses") %>%
  arrange(desc(n_reponses))
print(taux_reponse, n = Inf)

cat("\nFichiers écrits dans", dossier_clean, ":\n")
cat(" - organismes_quantitatif.csv\n - organismes_qualitatif.csv\n")
