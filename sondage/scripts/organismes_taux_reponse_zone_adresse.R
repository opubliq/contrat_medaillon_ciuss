# Taux de réponse "local" à partir de la classification par ADRESSE PHYSIQUE
# (pas `categorie_territoire` ni `source_sheet`, tous deux invalidés le
# 2026-08-10 -- voir PROJECT_MEMORY.md : ils mesurent le territoire
# auto-déclaré, pas la localisation physique, et sous-comptent massivement les
# répondants réellement locaux).
#
# Applique aux 946 invités ET aux répondants identifiés la même règle de
# classification par adresse (voir organismes_local_desserte_vs_adresse.R pour
# le détail des corrections Saint-Michel/Montréal-Nord), avec en plus le
# raffinement Rosemont/La Petite-Patrie vérifié manuellement le 2026-08-10
# (PROJECT_MEMORY.md) : sur adresse "rosemont", exclure les codes postaux H2S
# (plus probablement La Petite-Patrie) sauf signal fort contraire (rue
# "boulevard rosemont" ou nom d'organisme référençant Rosemont).
#
# Dénominateur : population invitée (946), moins les 45 bounces retenus (48
# avant de retirer 3 adresses "bounce" contradictoires, qui ont pourtant
# répondu -- voir audit 2026-08-10, PROJECT_MEMORY.md).
# Numérateur : répondants identifiés par courriel (83 courriels distincts).
#
# -> data/organismes/clean/organismes_taux_reponse_zone_adresse.csv

library(dplyr)
library(stringr)
library(stringi)
library(purrr)
library(readr)
library(tidyr)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

normaliser_email   <- function(x) str_to_lower(str_trim(x))
normaliser_nom     <- function(x) str_squish(str_to_lower(str_trim(x)))
normaliser_accents <- function(x) stri_trans_general(str_to_lower(x), "Latin-ASCII")

# --- Bottin (adresse + territoire), 2 460 organismes -------------------------

bottin <- read_csv("liste_organismes/data/02_bottin_territoire.csv", show_col_types = FALSE) %>%
  mutate(courriel_norm = normaliser_email(courriel), nom_norm = normaliser_nom(nom))

apparier_bottin <- function(email, nom) {
  candidats <- bottin %>% filter(courriel_norm == email)
  if (nrow(candidats) == 0) return(tibble(adresse = NA_character_, territoire = NA_character_, nom_bottin = NA_character_))
  if (nrow(candidats) == 1) return(candidats %>% transmute(adresse, territoire, nom_bottin = nom))
  exact <- candidats %>% filter(nom_norm == nom)
  if (nrow(exact) >= 1) return(exact[1, ] %>% transmute(adresse, territoire, nom_bottin = nom))
  candidats[1, ] %>% transmute(adresse, territoire, nom_bottin = nom)
}

# --- Les 10 quartiers CIUSSS-Est, avec raffinements Saint-Michel (2026-08-10)
# et Rosemont/La Petite-Patrie (2026-08-10) -----------------------------------

QUARTIERS_SANS_ROSEMONT_SAINT_MICHEL <- c(
  "rivi[eè]re-des-prairies", "anjou", "mercier-est", "mercier-ouest",
  "pointe-aux-trembles", "montr[eé]al-est", "saint-l[eé]onard", "hochelaga"
)
pattern_quartiers <- paste(QUARTIERS_SANS_ROSEMONT_SAINT_MICHEL, collapse = "|")

DESSERTE_LOCALE_TERMS <- c(
  "saint-michel", "saint-leonard", "saint-léonard", "pointe-aux-trembles",
  "mercier-est", "mercier-ouest", "hochelaga",
  "montreal-est", "montréal-est", "riviere-des-prairies", "rivière-des-prairies",
  "rosemont", "anjou", "est de montreal", "est de montréal", "est de l'ile",
  "est de l'île", "ciusss de l'est"
)
pattern_desserte <- paste(DESSERTE_LOCALE_TERMS, collapse = "|")

classer_local <- function(df) {
  df %>% mutate(
    adresse_norm    = normaliser_accents(coalesce(adresse, "")),
    territoire_norm = normaliser_accents(coalesce(territoire, "")),
    nom_bottin_norm = normaliser_accents(coalesce(nom_bottin, "")),
    code_postal     = str_extract(adresse, "H[0-9][A-Z]"),

    # Saint-Michel : seulement rue explicite ou nom d'organisme (pas le nom
    # d'arrondissement composé, qui couvre aussi Villeray/Parc-Extension) ;
    # exclusion explicite Montréal-Nord (le boulevard s'y prolonge).
    saint_michel =
      (str_detect(adresse_norm, "boulevard saint-michel") | str_detect(nom_bottin_norm, "saint-michel")) &
      !str_detect(adresse_norm, "montreal-nord"),

    # Rosemont : accepté par défaut (borough "Rosemont-La Petite-Patrie"), SAUF
    # code postal H2S (plus probablement La Petite-Patrie, vérifié
    # manuellement le 2026-08-10 sur les répondants) à moins d'un signal fort
    # contraire (rue "boulevard rosemont" ou nom d'organisme = Rosemont).
    rosemont_brut     = str_detect(adresse_norm, "rosemont"),
    rosemont_signal_fort = str_detect(adresse_norm, "boulevard rosemont") | str_detect(nom_bottin_norm, "rosemont"),
    rosemont = rosemont_brut & !(coalesce(code_postal == "H2S", FALSE) & !rosemont_signal_fort),

    physiquement_local = str_detect(adresse_norm, normaliser_accents(pattern_quartiers)) | saint_michel | rosemont,
    dessert_local       = str_detect(territoire_norm, normaliser_accents(pattern_desserte))
  )
}

# --- Population invitée (946), avec bounces (48) -----------------------------

fichiers_invites <- c(
  "sondage/listes_organismes/organismes_locaux.csv",
  paste0("sondage/listes_organismes/organismes_partie_", 1:6, ".csv")
)

invites <- map_dfr(fichiers_invites, ~ read_csv(.x, show_col_types = FALSE) %>%
                      mutate(across(everything(), as.character))) %>%
  mutate(email_norm = normaliser_email(email), nom_norm = normaliser_nom(nom)) %>%
  filter(!is.na(email_norm), email_norm != "") %>%
  distinct(email_norm, .keep_all = TRUE) %>%
  rowwise() %>%
  mutate(m = list(apparier_bottin(email_norm, nom_norm))) %>%
  ungroup() %>%
  unnest(m) %>%
  classer_local()

# --- Répondants identifiés (courriel), chargés en premier pour pouvoir
# écarter toute adresse "bounce" contradictoire (qui a pourtant répondu, voir
# audit 2026-08-10 : info@aqdr.org, info@stellapourlavie.ca,
# je.arsenault@axiaservices.com) ---------------------------------------------

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE) %>%
  mutate(email_norm = normaliser_email(participant_email), nom_norm = normaliser_nom(participant_name)) %>%
  filter(!is.na(email_norm), email_norm != "") %>%
  distinct(email_norm, .keep_all = TRUE) %>%
  rowwise() %>%
  mutate(m = list(apparier_bottin(email_norm, nom_norm))) %>%
  ungroup() %>%
  unnest(m) %>%
  classer_local()

cat("\nRépondants identifiés (courriels distincts) :", nrow(combine), "\n")
cat("Répondants physiquement locaux (devrait être 21) :", sum(combine$physiquement_local), "\n")

bounces_bruts <- read_lines("sondage/listes_organismes/55_bounces_globaux.csv") %>%
  normaliser_email() %>% discard(~ .x == "")
bounces_exacts <- bounces_bruts[bounces_bruts %in% invites$email_norm]
bounces_redirection <- normaliser_email(c("info@actionr.org", "info@pietons.quebec", "cap@projetpal.com"))
bounces_avant_contradiction <- union(bounces_exacts, bounces_redirection)
bounces_contradictoires <- intersect(bounces_avant_contradiction, unique(combine$email_norm))
bounces_45 <- setdiff(bounces_avant_contradiction, bounces_contradictoires)
stopifnot(length(bounces_45) == 45)

invites <- invites %>% mutate(bounce = email_norm %in% bounces_45)

cat("\n=== Population invitée (946), physiquement_local, avant/après retrait bounces ===\n")
cat("Physiquement local, brut               :", sum(invites$physiquement_local), "\n")
cat("Physiquement local, net des bounces     :", sum(invites$physiquement_local & !invites$bounce), "\n")

# --- Taux de réponse, PHYSIQUEMENT_LOCAL vs Reste ---------------------------

denom <- invites %>% filter(!bounce) %>%
  group_by(local = physiquement_local) %>% summarise(invites_valide = n(), .groups = "drop")
num <- combine %>% group_by(local = physiquement_local) %>% summarise(repondants = n(), .groups = "drop")

taux_adresse <- denom %>% left_join(num, by = "local") %>%
  mutate(repondants = coalesce(repondants, 0L),
         taux = round(100 * repondants / invites_valide, 1),
         local = ifelse(local, "Local (adresse physique)", "Reste")) %>%
  arrange(desc(local))

taux_adresse_total <- taux_adresse %>% summarise(
  local = "TOTAL", invites_valide = sum(invites_valide), repondants = sum(repondants),
  taux = round(100 * sum(repondants) / sum(invites_valide), 1))

cat("\n=== Taux de réponse -- classification par ADRESSE PHYSIQUE ===\n")
print(bind_rows(taux_adresse, taux_adresse_total))

# --- Comparaison avec la classification de Hubert (source_sheet) -----------
# Recharge le résumé déjà produit par organismes_taux_reponse_zone_source_sheet.R

chemin_hubert <- file.path(dossier_clean, "organismes_taux_reponse_zone_source_sheet.csv")
if (file.exists(chemin_hubert)) {
  hubert <- read_csv(chemin_hubert, show_col_types = FALSE)
  hubert_local <- hubert %>% filter(source_sheet == "Local")
  cat("\n=== Comparaison : Local selon Hubert (source_sheet) vs Local par adresse ===\n")
  comparaison <- tibble(
    methode = c("source_sheet (Hubert, déclaratif)", "Adresse physique (vérifiée)"),
    invites_valide = c(hubert_local$invites_valide, taux_adresse$invites_valide[taux_adresse$local == "Local (adresse physique)"]),
    repondants     = c(hubert_local$repondants, taux_adresse$repondants[taux_adresse$local == "Local (adresse physique)"]),
    taux           = c(hubert_local$taux, taux_adresse$taux[taux_adresse$local == "Local (adresse physique)"])
  )
  print(comparaison)
} else {
  cat("\n(Pas de fichier source_sheet trouvé pour comparaison :", chemin_hubert, ")\n")
}

write_excel_csv(bind_rows(taux_adresse, taux_adresse_total),
                file.path(dossier_clean, "organismes_taux_reponse_zone_adresse.csv"), na = "")
cat("\n-> Écrit:", file.path(dossier_clean, "organismes_taux_reponse_zone_adresse.csv"), "\n")
