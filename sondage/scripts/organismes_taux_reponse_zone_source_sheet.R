# Taux de réponse par zone, volet organismes, à partir de la catégorisation
# D'ORIGINE de Hubert (colonne `source_sheet` des 7 fichiers de listes d'envoi :
# Local / Montréal / Grand Montréal / Provincial) -- PAS `categorie_territoire`
# du bottin (invalidée le 2026-08-10, voir PROJECT_MEMORY.md : mesure le
# territoire auto-déclaré, pas la localisation physique, biaisée dans les deux
# sens).
#
# Dénominateur : population invitée (946), moins les 45 bounces retenus
# (voir PROJECT_MEMORY.md, section "Réconciliation des bounces", 2026-08-10 :
# 46 correspondance exacte (dont info@actionr.org, qui bondit elle-même en plus
# de 4 adresses redirigées) + 2 organismes de plus via redirection plausible --
# choix conservateur, mécanisme non confirmé avec Nicolas -- moins 3 retirés le
# 2026-08-10 (audit) : ces 3 adresses "bounce" ont pourtant soumis une réponse
# complète au sondage (info@aqdr.org, info@stellapourlavie.ca,
# je.arsenault@axiaservices.com) -- contradiction logique, un vrai bounce ne
# peut pas avoir servi à répondre. Retirées automatiquement ci-dessous par
# `setdiff` contre les courriels répondants, pas par une liste codée en dur.
# Numérateur : répondants identifiés par courriel (85), appariés à la même
# population par courriel exact.
#
# -> data/organismes/clean/organismes_taux_reponse_zone_source_sheet.csv

library(dplyr)
library(stringr)
library(purrr)
library(readr)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

normaliser_email <- function(x) str_to_lower(str_trim(x))

# --- Population invitée, avec source_sheet (Local prioritaire pour les 17
# emails communs à organismes_locaux.csv et aux parties 1-6 -- c'est le fichier
# que Hubert a construit spécifiquement pour désigner ces organismes comme
# locaux, plus délibéré que la catégorie générique du scraping 211) ---------

fichiers_invites <- c(
  "sondage/listes_organismes/organismes_locaux.csv",
  paste0("sondage/listes_organismes/organismes_partie_", 1:6, ".csv")
)

invites <- map_dfr(fichiers_invites, ~ read_csv(.x, show_col_types = FALSE) %>%
                      mutate(across(everything(), as.character))) %>%
  mutate(email_norm = normaliser_email(email)) %>%
  filter(!is.na(email_norm), email_norm != "") %>%
  distinct(email_norm, .keep_all = TRUE)

cat("Population invitée :", nrow(invites), "\n")
cat("\n=== Répartition source_sheet (population totale, 946) ===\n")
print(table(invites$source_sheet, useNA = "ifany"))

# --- Répondants identifiés (courriel), chargés en premier pour pouvoir
# écarter toute adresse "bounce" contradictoire (qui a pourtant répondu) ----

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE) %>%
  mutate(email_norm = normaliser_email(participant_email)) %>%
  filter(!is.na(email_norm), email_norm != "")

cat("\nRépondants avec courriel non vide :", nrow(combine), "(courriels distincts :", n_distinct(combine$email_norm), ")\n")

# --- Bounces retenus (45) : 46 correspondance exacte au fichier de Nicolas +
# 2 organismes via redirection plausible (adresse réellement invitée), moins
# les adresses ayant pourtant répondu (contradiction, voir audit 2026-08-10) -

bounces_bruts <- read_lines("sondage/listes_organismes/55_bounces_globaux.csv") %>%
  normaliser_email() %>%
  discard(~ .x == "")

bounces_exacts <- bounces_bruts[bounces_bruts %in% invites$email_norm]
cat("\nBounces en correspondance exacte :", length(bounces_exacts), "\n")

# Les 3 organismes retenus par redirection plausible, identifiés par
# l'adresse qu'ON A RÉELLEMENT INVITÉE (pas l'adresse bounée) :
bounces_redirection <- normaliser_email(c(
  "info@actionr.org", "info@pietons.quebec", "cap@projetpal.com"
))
stopifnot(all(bounces_redirection %in% invites$email_norm))

bounces_avant_contradiction <- union(bounces_exacts, bounces_redirection)
bounces_contradictoires <- intersect(bounces_avant_contradiction, unique(combine$email_norm))
if (length(bounces_contradictoires) > 0) {
  cat("\n⚠️ Bounces contradictoires retirés (ont pourtant répondu) :", length(bounces_contradictoires), "\n")
  print(bounces_contradictoires)
}
bounces_45 <- setdiff(bounces_avant_contradiction, bounces_contradictoires)
cat("Total bounces retenus (devrait être 45) :", length(bounces_45), "\n")

invites <- invites %>% mutate(bounce = email_norm %in% bounces_45)

cat("\n=== Bounces par zone (source_sheet) ===\n")
print(invites %>% filter(bounce) %>% count(source_sheet, sort = TRUE))

repondants_par_zone <- combine %>%
  distinct(email_norm) %>%
  inner_join(invites %>% select(email_norm, source_sheet), by = "email_norm")

cat("Répondants appariés à la population invitée :", nrow(repondants_par_zone), "/", n_distinct(combine$email_norm), "\n")

# --- Taux de réponse par zone -----------------------------------------------

resume <- invites %>%
  group_by(source_sheet) %>%
  summarise(invites_brut = n(), bounces = sum(bounce), .groups = "drop") %>%
  mutate(invites_valide = invites_brut - bounces) %>%
  left_join(repondants_par_zone %>% count(source_sheet, name = "repondants"), by = "source_sheet") %>%
  mutate(repondants = coalesce(repondants, 0L),
         taux = round(100 * repondants / invites_valide, 1)) %>%
  arrange(desc(invites_brut))

total <- resume %>% summarise(
  source_sheet = "TOTAL",
  invites_brut = sum(invites_brut), bounces = sum(bounces),
  invites_valide = sum(invites_valide), repondants = sum(repondants),
  taux = round(100 * sum(repondants) / sum(invites_valide), 1)
)

resume_complet <- bind_rows(resume, total)

cat("\n=== Taux de réponse par zone (catégorisation d'origine Hubert, source_sheet) ===\n")
print(resume_complet)

write_excel_csv(resume_complet, file.path(dossier_clean, "organismes_taux_reponse_zone_source_sheet.csv"), na = "")
cat("\n-> Écrit:", file.path(dossier_clean, "organismes_taux_reponse_zone_source_sheet.csv"), "\n")
