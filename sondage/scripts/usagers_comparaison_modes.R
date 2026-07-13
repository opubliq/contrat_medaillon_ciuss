# Comparaison en ligne (repondant) vs en personne (interviewer + papier) sur les
# variables fermées (quantitatives) du volet usagers.
# Question : mêmes tendances entre modes, ou effet particulier de la présence
# d'un tiers (intervieweur / saisie papier) ?
#
# Suppose que scripts/usagers_cleaning.R a déjà été exécuté.
# Les données vivent hors du repo, sur le drive partagé Google Opubliq.

library(dplyr)
library(readr)
library(tidyr)
library(stringr)
library(purrr)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "usagers/clean")
combine <- read_csv(file.path(dossier_clean, "usagers_combined.csv"), show_col_types = FALSE)

# --- Variable ordinale (q10, groupe d'âge, 4 niveaux) : test de Wilcoxon -----

vars_ordinales <- c("q10")
resultats_ordinaux <- map_dfr(vars_ordinales, function(v) {
  d <- combine %>% filter(!is.na(.data[[v]])) %>% select(mode, valeur = all_of(v))
  resultat_test <- suppressWarnings(wilcox.test(valeur ~ mode, data = d))
  d %>% group_by(mode) %>%
    summarise(n = n(), moyenne = mean(valeur), mediane = median(valeur), .groups = "drop") %>%
    pivot_wider(names_from = mode, values_from = c(n, moyenne, mediane)) %>%
    mutate(variable = v, methode = "wilcoxon",
           statistique = resultat_test$statistic, p_valeur = resultat_test$p.value)
})

# --- Variables Oui/Non/Ne sais pas (1/2/9) : test de Fisher ------------------
# (on compare la proportion de "Oui" par mode, comme pour les variables
# binaires du volet organismes)

vars_binaires <- c("q1", "q2", "q3", "q4", "q5", "q7", "q8")
resultats_binaires <- map_dfr(vars_binaires, function(v) {
  d <- combine %>% filter(!is.na(.data[[v]])) %>% select(mode, valeur = all_of(v))
  tbl <- table(d$mode, d$valeur)
  resultat_test <- tryCatch(fisher.test(tbl), error = function(e) fisher.test(tbl, simulate.p.value = TRUE, B = 10000))
  prop_oui <- d %>% group_by(mode) %>%
    summarise(n = n(), n_oui = sum(valeur == 1), pct_oui = round(100 * mean(valeur == 1), 1), .groups = "drop")
  tibble(variable = v,
         n_en_ligne = prop_oui$n[prop_oui$mode == "en_ligne"],
         pct_oui_en_ligne = prop_oui$pct_oui[prop_oui$mode == "en_ligne"],
         n_en_personne = prop_oui$n[prop_oui$mode == "en_personne"],
         pct_oui_en_personne = prop_oui$pct_oui[prop_oui$mode == "en_personne"],
         methode = "fisher", p_valeur = resultat_test$p.value)
})

# --- q9 (lieu de résidence, nominal à 4 catégories) : test du Chi-carré ------

resultat_q9 <- {
  d <- combine %>% filter(!is.na(q9)) %>% select(mode, valeur = q9)
  tbl <- table(d$mode, d$valeur)
  test <- tryCatch(chisq.test(tbl), error = function(e) chisq.test(tbl, simulate.p.value = TRUE, B = 10000))
  tibble(variable = "q9", methode = "chi2", statistique = unname(test$statistic), p_valeur = test$p.value)
}

# --- q7_1 (checkbox, à qui s'adresser pour une plainte) : % d'endossement ---
# par choix, test de Fisher par choix (même logique que pour le volet organismes)

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
             pct_en_ligne = round(100 * n_oui_en_ligne / n_en_ligne, 1),
             pct_en_personne = round(100 * n_oui_en_personne / n_en_personne, 1),
             p_valeur = test$p.value)
  })
}
resultats_checkbox <- comparer_checkbox("q7_1")

# --- Sorties ------------------------------------------------------------

write_excel_csv(resultats_ordinaux, file.path(dossier_clean, "comparaison_modes_ordinales.csv"), na = "")
write_excel_csv(resultats_binaires, file.path(dossier_clean, "comparaison_modes_binaires.csv"), na = "")
write_excel_csv(resultat_q9,        file.path(dossier_clean, "comparaison_modes_q9.csv"), na = "")
write_excel_csv(resultats_checkbox, file.path(dossier_clean, "comparaison_modes_checkbox.csv"), na = "")

cat("=== q10 (groupe d'âge), test de Wilcoxon ===\n")
print(resultats_ordinaux %>% select(variable, n_en_ligne, moyenne_en_ligne, mediane_en_ligne,
                                     n_en_personne, moyenne_en_personne, mediane_en_personne, p_valeur))

cat("\n=== Variables Oui/Non/Ne sais pas (% Oui), test de Fisher ===\n")
print(resultats_binaires)

cat("\n=== q9 (lieu de résidence), test du Chi-carré ===\n")
print(resultat_q9)

cat("\n=== q7_1 (à qui s'adresser), % d'endossement par choix ===\n")
print(resultats_checkbox %>% select(variable, choix, pct_en_ligne, pct_en_personne, p_valeur), n = Inf)

cat("\n--- Différences significatives (p < .05), toutes catégories confondues ---\n")
sign <- bind_rows(
  resultats_ordinaux %>% select(variable, p_valeur) %>% mutate(choix = NA_character_),
  resultats_binaires %>% select(variable, p_valeur) %>% mutate(choix = NA_character_),
  resultat_q9 %>% select(variable, p_valeur) %>% mutate(choix = NA_character_),
  resultats_checkbox %>% select(variable, choix, p_valeur)
) %>% filter(p_valeur < 0.05)
print(sign, n = Inf)

cat("\nFichiers écrits dans", dossier_clean, "\n")
