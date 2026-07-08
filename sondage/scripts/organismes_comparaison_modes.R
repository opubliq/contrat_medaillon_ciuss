# Comparaison internet vs téléphone sur les variables fermées (quantitatives)
# Question : mêmes tendances entre modes, ou effet particulier du téléphone
# (ex. désirabilité sociale liée à la présence d'un.e intervieweur.e) ?
#
# Ce script suppose que le répertoire de travail R est la racine du projet
# et que scripts/organismes_cleaning.R a déjà été exécuté.

library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(purrr)

dossier_clean <- "data/organismes/clean"
combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE)

# --- Variables ordinales à 4 niveaux (recodées 1-4) : test de Wilcoxon -------

vars_ordinales <- c("q2", "q3", "q5", "q11")
resultats_ordinaux <- map_dfr(vars_ordinales, function(v) {
  d <- combine %>% filter(!is.na(.data[[v]])) %>% select(mode, valeur = all_of(v))
  resultat_test <- suppressWarnings(wilcox.test(valeur ~ mode, data = d))
  d %>% group_by(mode) %>%
    summarise(n = n(), moyenne = mean(valeur), mediane = median(valeur), .groups = "drop") %>%
    pivot_wider(names_from = mode, values_from = c(n, moyenne, mediane)) %>%
    mutate(variable = v, methode = "wilcoxon",
           statistique = resultat_test$statistic, p_valeur = resultat_test$p.value)
})

# --- Variables binaires / quasi-binaires (1/2, parfois 9) : test de Fisher --

vars_binaires <- c("q0", "q14", "q15", "q16", "q17", "q14_1")
resultats_binaires <- map_dfr(vars_binaires, function(v) {
  d <- combine %>% filter(!is.na(.data[[v]])) %>% select(mode, valeur = all_of(v))
  tbl <- table(d$mode, d$valeur)
  resultat_test <- tryCatch(fisher.test(tbl), error = function(e) fisher.test(tbl, simulate.p.value = TRUE, B = 10000))
  prop_oui <- d %>% group_by(mode) %>%
    summarise(n = n(), n_oui = sum(valeur == 1), pct_oui = round(100 * mean(valeur == 1), 1), .groups = "drop")
  tibble(variable = v, n_internet = prop_oui$n[prop_oui$mode == "internet"],
         pct_oui_internet = prop_oui$pct_oui[prop_oui$mode == "internet"],
         n_telephone = prop_oui$n[prop_oui$mode == "telephone"],
         pct_oui_telephone = prop_oui$pct_oui[prop_oui$mode == "telephone"],
         methode = "fisher", p_valeur = resultat_test$p.value)
})

# --- Variables à choix multiples (checkbox) : % d'endossement par choix -----
# On décompose chaque colonne "valeur1 | valeur2" en indicatrices 0/1 par choix,
# puis on compare le taux d'endossement par mode (fisher.test 2x2 par choix).

comparer_checkbox <- function(colonne) {
  d <- combine %>% filter(!is.na(.data[[colonne]])) %>% select(mode, valeur = all_of(colonne))
  choix_distincts <- d$valeur %>% str_split("\\s*\\|\\s*") %>% unlist() %>% unique() %>% sort()
  map_dfr(choix_distincts, function(choix) {
    d2 <- d %>% mutate(endosse = str_detect(valeur, fixed(choix)))
    tbl <- table(d2$mode, d2$endosse)
    test <- tryCatch(fisher.test(tbl), error = function(e) list(p.value = NA_real_))
    d2 %>% group_by(mode) %>% summarise(n = n(), n_oui = sum(endosse), .groups = "drop") %>%
      pivot_wider(names_from = mode, values_from = c(n, n_oui)) %>%
      mutate(variable = colonne, choix = choix,
             pct_internet = round(100 * n_oui_internet / n_internet, 1),
             pct_telephone = round(100 * n_oui_telephone / n_telephone, 1),
             p_valeur = test$p.value)
  })
}

vars_checkbox_attitude <- c("q1", "q10", "q12")
resultats_checkbox <- map_dfr(vars_checkbox_attitude, comparer_checkbox)

vars_checkbox_profil <- c("q21", "q22", "q23", "q24")
resultats_profil <- map_dfr(vars_checkbox_profil, comparer_checkbox)

# --- Nombre de choix cochés par répondant (checkbox) : effet "acquiescence" -
# Un mode qui ferait cocher systématiquement plus (ou moins) d'options, toutes
# variables confondues, indique un effet de collecte (ex. biais d'acquiescement
# à l'oral) plutôt qu'une vraie différence de contenu par item.

vars_checkbox_toutes <- c(vars_checkbox_attitude, vars_checkbox_profil)
resultats_nb_choix <- map_dfr(vars_checkbox_toutes, function(v) {
  d <- combine %>% filter(!is.na(.data[[v]])) %>%
    mutate(n_choix = str_count(.data[[v]], "\\|") + 1)
  resultat_test <- suppressWarnings(wilcox.test(n_choix ~ mode, data = d))
  d %>% group_by(mode) %>%
    summarise(n = n(), moyenne_n_choix = round(mean(n_choix), 2),
              mediane_n_choix = median(n_choix), .groups = "drop") %>%
    pivot_wider(names_from = mode, values_from = c(n, moyenne_n_choix, mediane_n_choix)) %>%
    mutate(variable = v, p_valeur = resultat_test$p.value)
})

# --- Sorties ------------------------------------------------------------

write_excel_csv(resultats_ordinaux, file.path(dossier_clean, "comparaison_modes_ordinales.csv"), na = "")
write_excel_csv(resultats_binaires, file.path(dossier_clean, "comparaison_modes_binaires.csv"), na = "")
write_excel_csv(resultats_checkbox, file.path(dossier_clean, "comparaison_modes_checkbox_attitude.csv"), na = "")
write_excel_csv(resultats_profil, file.path(dossier_clean, "comparaison_modes_checkbox_profil.csv"), na = "")
write_excel_csv(resultats_nb_choix, file.path(dossier_clean, "comparaison_modes_nb_choix.csv"), na = "")

cat("=== Variables ordinales (1-4), test de Wilcoxon ===\n")
print(resultats_ordinaux %>% select(variable, n_internet, moyenne_internet, mediane_internet,
                                     n_telephone, moyenne_telephone, mediane_telephone, p_valeur))

cat("\n=== Variables binaires/quasi-binaires (% Oui), test de Fisher ===\n")
print(resultats_binaires)

cat("\n=== Checkbox 'attitude' (q1, q10, q12), % d'endossement par choix ===\n")
print(resultats_checkbox %>% select(variable, choix, pct_internet, pct_telephone, p_valeur), n = Inf)

cat("\n=== Checkbox 'profil organisme' (q21-24), % d'endossement par choix ===\n")
print(resultats_profil %>% select(variable, choix, pct_internet, pct_telephone, p_valeur), n = Inf)

cat("\n=== Nombre moyen de choix cochés par répondant (checkbox), par mode ===\n")
print(resultats_nb_choix %>% select(variable, n_internet, moyenne_n_choix_internet, mediane_n_choix_internet,
                                     n_telephone, moyenne_n_choix_telephone, mediane_n_choix_telephone, p_valeur))

cat("\n--- Différences significatives (p < .05), toutes catégories confondues ---\n")
sign <- bind_rows(
  resultats_ordinaux %>% select(variable, p_valeur) %>% mutate(choix = NA_character_),
  resultats_binaires %>% select(variable, p_valeur) %>% mutate(choix = NA_character_),
  resultats_checkbox %>% select(variable, choix, p_valeur),
  resultats_profil %>% select(variable, choix, p_valeur)
) %>% filter(p_valeur < 0.05)
print(sign, n = Inf)

cat("\nFichiers écrits dans", dossier_clean, "\n")
