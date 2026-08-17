# Décompose la population invitée (946 organismes) selon deux variables
# indépendantes, plutôt qu'une seule catégorie "local" ambiguë :
#   - dessert_local   : le texte `territoire` (auto-déclaré) mentionne un des
#                       10 quartiers CIUSSS-Est (même logique que
#                       liste_organismes/scripts/02_filtre_territoire.py,
#                       corrigée : ajout d'Anjou, retrait de Montréal-Nord —
#                       voir PROJECT_MEMORY.md, section du 2026-08-10)
#   - physiquement_local : l'adresse (`adresse`) est dans un des 10 quartiers
#
# Contexte : `categorie_territoire` (utilisé jusqu'ici pour le taux de réponse
# par zone) ne regarde QUE le texte `territoire`, jamais l'adresse -> proxy
# invalidé pour mesurer la localisation physique (voir PROJECT_MEMORY.md).
#
# -> data/organismes/clean/organismes_local_desserte_vs_adresse.csv

library(dplyr)
library(stringr)
library(stringi)
library(purrr)
library(readr)
library(tidyr)

# Suppose que le répertoire de travail R est la racine du projet.
data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

normaliser_email <- function(x) str_to_lower(str_trim(x))
normaliser_nom    <- function(x) str_squish(str_to_lower(str_trim(x)))

# --- Population invitée (946 courriels uniques) -----------------------------

fichiers_invites <- c(
  "sondage/listes_organismes/organismes_locaux.csv",
  paste0("sondage/listes_organismes/organismes_partie_", 1:6, ".csv")
)

invites <- map_dfr(fichiers_invites, ~ read_csv(.x, show_col_types = FALSE) %>%
                      mutate(across(everything(), as.character))) %>%
  mutate(email_norm = normaliser_email(email), nom_norm = normaliser_nom(nom)) %>%
  filter(!is.na(email_norm), email_norm != "") %>%
  distinct(email_norm, .keep_all = TRUE)

cat("Population invitée (courriels uniques) :", nrow(invites), "\n")

# --- Bottin (adresse + territoire), 2 460 organismes -------------------------

bottin <- read_csv("liste_organismes/data/02_bottin_territoire.csv", show_col_types = FALSE) %>%
  mutate(courriel_norm = normaliser_email(courriel), nom_norm = normaliser_nom(nom))

# Désambiguïsation des courriels partagés par plusieurs organismes du bottin :
# priorité à la correspondance exacte de nom, sinon 1re ligne rencontrée.
apparier_bottin <- function(email, nom) {
  candidats <- bottin %>% filter(courriel_norm == email)
  if (nrow(candidats) == 0) return(tibble(adresse = NA_character_, territoire = NA_character_, nom_bottin = NA_character_))
  if (nrow(candidats) == 1) return(candidats %>% transmute(adresse, territoire, nom_bottin = nom))
  exact <- candidats %>% filter(nom_norm == nom)
  if (nrow(exact) >= 1) return(exact[1, ] %>% transmute(adresse, territoire, nom_bottin = nom))
  candidats[1, ] %>% transmute(adresse, territoire, nom_bottin = nom)
}

invites <- invites %>%
  rowwise() %>%
  mutate(m = list(apparier_bottin(email_norm, nom_norm))) %>%
  ungroup() %>%
  tidyr::unnest(m)

cat("Appariés au bottin (adresse/territoire connus) :", sum(!is.na(invites$adresse) | !is.na(invites$territoire)), "/", nrow(invites), "\n")

# --- Les 10 quartiers CIUSSS-Est, confirmés avec l'utilisateur 2026-08-10 ---
# ⚠️ "saint-michel" est traité à part (voir plus bas) : le nom complet de
# l'arrondissement "Villeray-Saint-Michel-Parc-Extension" couvre AUSSI Villeray
# et Parc-Extension (hors Est-de-Montréal), et une adresse affiche presque
# toujours le nom d'arrondissement complet plutôt que le quartier précis.
# Vérifié manuellement le 2026-08-10 sur les 85 adresses candidates : ~80 sont
# en fait à Parc-Extension/Villeray (avenue du Parc, rue Jean-Talon Ouest,
# rue Villeray...), 2 sont des faux positifs sans rapport (rue Saint-Michel à
# Kanesatake/Laurentides ; boulevard Saint-Michel à Montréal-Nord, mauvais
# CIUSSS), et seules 5 sont vraiment dans le quartier Saint-Michel : soit
# l'adresse est explicitement SUR le boulevard Saint-Michel, soit le nom de
# l'organisme référence directement "Saint-Michel".
# ⚠️ "rosemont" a le même risque (arrondissement composé "Rosemont-La
# Petite-Patrie") : vérifié manuellement le 2026-08-10 sur les 23 répondants
# candidats (avant le retrait des bounces contradictoires), 8/10 des adresses
# "rosemont" ont un code postal H1X/H1Y (Rosemont), 2/10 un code postal H2S
# (plus probablement La Petite-Patrie) -- exclues sauf adresse explicitement
# sur "boulevard Rosemont" ou nom d'organisme référençant Rosemont. Voir
# PROJECT_MEMORY.md pour le détail (organismes concernés, incertitude assumée
# faute de source de frontières officielle).
QUARTIERS_SANS_ROSEMONT_SAINT_MICHEL <- c(
  "rivi[eè]re-des-prairies", "anjou", "mercier-est", "mercier-ouest",
  "pointe-aux-trembles", "montr[eé]al-est", "saint-l[eé]onard", "hochelaga"
)
pattern_quartiers <- paste(QUARTIERS_SANS_ROSEMONT_SAINT_MICHEL, collapse = "|")
pattern_saint_michel_rue <- "boulevard saint-michel"

# Mots-clés desserte déclarée : LOCAL_TERMS de 02_filtre_territoire.py,
# corrigé (+ anjou, + hochelaga seul [bug: absent de LOCAL_TERMS d'origine,
# uniquement "mercier-hochelaga-maisonneuve"], - montreal-nord/montréal-nord).
DESSERTE_LOCALE_TERMS <- c(
  "saint-michel", "saint-leonard", "saint-léonard", "pointe-aux-trembles",
  "mercier-est", "mercier-ouest", "hochelaga",
  "montreal-est", "montréal-est", "riviere-des-prairies", "rivière-des-prairies",
  "rosemont", "anjou", "est de montreal", "est de montréal", "est de l'ile",
  "est de l'île", "ciusss de l'est"
)
pattern_desserte <- paste(DESSERTE_LOCALE_TERMS, collapse = "|")

normaliser_accents <- function(x) {
  x <- str_to_lower(x)
  stringi::stri_trans_general(x, "Latin-ASCII")
}

invites <- invites %>%
  mutate(
    adresse_norm    = normaliser_accents(coalesce(adresse, "")),
    territoire_norm = normaliser_accents(coalesce(territoire, "")),
    nom_bottin_norm = normaliser_accents(coalesce(nom_bottin, "")),
    code_postal     = str_extract(adresse, "H[0-9][A-Z]"),
    # "boulevard saint-michel" se prolonge dans Montréal-Nord (mauvais CIUSSS,
    # exclu explicitement) -> ex. Maisons de l'Ancre, 10031 boul. Saint-Michel,
    # Montréal-Nord, repéré en vérification manuelle le 2026-08-10.
    saint_michel =
      (str_detect(adresse_norm, pattern_saint_michel_rue) | str_detect(nom_bottin_norm, "saint-michel")) &
      !str_detect(adresse_norm, "montreal-nord"),
    # Rosemont accepté par défaut, sauf code postal H2S (La Petite-Patrie)
    # sans signal fort contraire -- voir note plus haut.
    rosemont_brut         = str_detect(adresse_norm, "rosemont"),
    rosemont_signal_fort  = str_detect(adresse_norm, "boulevard rosemont") | str_detect(nom_bottin_norm, "rosemont"),
    rosemont = rosemont_brut & !(coalesce(code_postal == "H2S", FALSE) & !rosemont_signal_fort),
    physiquement_local = str_detect(adresse_norm, normaliser_accents(pattern_quartiers)) | saint_michel | rosemont,
    dessert_local      = str_detect(territoire_norm, normaliser_accents(pattern_desserte))
  )

# --- Résultat -----------------------------------------------------------------

n_dessert       <- sum(invites$dessert_local)
n_physique      <- sum(invites$physiquement_local)
n_les_deux      <- sum(invites$dessert_local & invites$physiquement_local)
n_dessert_seul  <- sum(invites$dessert_local & !invites$physiquement_local)
n_physique_seul <- sum(invites$physiquement_local & !invites$dessert_local)
n_ni_un_ni_autre<- sum(!invites$dessert_local & !invites$physiquement_local)
n_union         <- sum(invites$dessert_local | invites$physiquement_local)

cat("\n=== Population invitée, n =", nrow(invites), "===\n")
cat("Dessert le local (texte territoire)         :", n_dessert, "\n")
cat("Se trouve dans le local (adresse)            :", n_physique, "\n")
cat("Les deux à la fois                           :", n_les_deux, "\n")
cat("Dessert seulement (pas dans le local)        :", n_dessert_seul, "\n")
cat("Dans le local seulement (ne dessert pas)     :", n_physique_seul, "\n")
cat("Ni l'un ni l'autre                            :", n_ni_un_ni_autre, "\n")
cat("Union (dessert OU dans le local)             :", n_union, "\n")

write_excel_csv(
  invites %>% select(nom, email = email_norm, nom_bottin, adresse, territoire,
                      physiquement_local, dessert_local),
  file.path(dossier_clean, "organismes_local_desserte_vs_adresse.csv"),
  na = ""
)
cat("\n-> Écrit:", file.path(dossier_clean, "organismes_local_desserte_vs_adresse.csv"), "\n")
