# Jointure de la classification territoriale d'Hubert (pipeline liste_organismes)
# aux répondants du sondage organismes, pour remplacer le proxy simplifié
# (organismes_zone_locale.R, basé sur q22) par une vraie distinction
# local / grand Montréal / provincial.
#
# Source : liste_organismes/data/04_bottin_secteurs.csv (colonne
# `categorie_territoire` : local, hochelaga-maisonneuve, montreal,
# grand_montreal, provincial), ajoutée au repo par Hubert le 2026-07-23
# (commit 0d87d25). C'est la classification de la LISTE DE POPULATION
# (organismes invités), pas des répondants -> jointure par nom nécessaire.
#
# Jointure par nom d'organisme (participant_name, mode internet uniquement —
# le mode téléphone ne renseigne pas ce champ, voir avertissement plus bas) :
#   1. correspondance exacte (nom normalisé : minuscules, espaces compressés)
#   2. sinon correspondance par inclusion (substring), seulement si UNIQUE
#   3. sinon non apparié -> NA, à traiter manuellement si le volume le justifie
#
# -> data/organismes/clean/organismes_zone_territoire.csv
#    (response_id, participant_name, categorie_territoire, methode_appariement)
# -> data/organismes/clean/distribution_zone_territoire_organismes.png

library(dplyr)
library(stringr)
library(readr)
library(ggplot2)
library(forcats)
library(purrr)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE)
bottin  <- read_csv("liste_organismes/data/04_bottin_secteurs.csv", show_col_types = FALSE)

normaliser <- function(x) {
  x <- str_to_lower(str_trim(x))
  str_squish(x)
}

bottin <- bottin %>% mutate(nom_norm = normaliser(nom)) %>% filter(!is.na(nom_norm), nom_norm != "")
noms_bottin <- unique(bottin$nom_norm)

# Une ligne par nom de bottin (garde la 1re catégorie si un nom apparaît plus
# d'une fois dans le bottin — rare, cf. dédoublonnage du pipeline liste_organismes)
bottin_uniq <- bottin %>% distinct(nom_norm, .keep_all = TRUE)

apparier <- function(nom_repondant) {
  if (is.na(nom_repondant) || nom_repondant == "") {
    return(c(categorie = NA_character_, methode = "nom_manquant"))
  }
  n <- normaliser(nom_repondant)

  # 1. correspondance exacte
  if (n %in% bottin_uniq$nom_norm) {
    cat <- bottin_uniq$categorie_territoire[bottin_uniq$nom_norm == n][1]
    return(c(categorie = cat, methode = "exact"))
  }

  # 2. correspondance par inclusion, uniquement si un seul candidat
  candidats <- noms_bottin[str_detect(noms_bottin, fixed(n)) | str_detect(n, fixed(noms_bottin))]
  candidats <- unique(candidats)
  if (length(candidats) == 1) {
    cat <- bottin_uniq$categorie_territoire[bottin_uniq$nom_norm == candidats][1]
    return(c(categorie = cat, methode = "substring_unique"))
  }
  if (length(candidats) > 1) {
    return(c(categorie = NA_character_, methode = "substring_ambigu"))
  }

  c(categorie = NA_character_, methode = "non_trouve")
}

resultats <- combine %>%
  select(response_id, mode, participant_name) %>%
  rowwise() %>%
  mutate(res = list(apparier(participant_name))) %>%
  ungroup() %>%
  mutate(categorie_territoire = map_chr(res, "categorie"),
         methode_appariement  = map_chr(res, "methode")) %>%
  select(-res)

write_excel_csv(resultats, file.path(dossier_clean, "organismes_zone_territoire.csv"), na = "")

cat("=== Méthode d'appariement, par mode ===\n")
print(resultats %>% count(mode, methode_appariement) %>% arrange(mode, desc(n)))

cat("\n=== Répartition categorie_territoire (répondants appariés) ===\n")
print(resultats %>% filter(!is.na(categorie_territoire)) %>% count(categorie_territoire, sort = TRUE))

n_apparies <- sum(!is.na(resultats$categorie_territoire))
cat("\nApariés :", n_apparies, "/", nrow(resultats), "répondants\n")

# --- Graphique ---------------------------------------------------------

resume <- resultats %>%
  filter(!is.na(categorie_territoire)) %>%
  count(categorie_territoire, name = "n") %>%
  mutate(pct = 100 * n / sum(n),
         categorie_territoire = recode(categorie_territoire,
           "local" = "Local (quartier CIUSSS-Est, hors HM)",
           "hochelaga-maisonneuve" = "Local — Hochelaga-Maisonneuve",
           "montreal" = "Montréal (hors Est)",
           "grand_montreal" = "Grand Montréal (banlieues)",
           "provincial" = "Provincial / hors Grand Montréal"
         ))

ordre <- c("Local — Hochelaga-Maisonneuve", "Local (quartier CIUSSS-Est, hors HM)",
           "Montréal (hors Est)", "Grand Montréal (banlieues)", "Provincial / hors Grand Montréal")
resume <- resume %>% mutate(categorie_territoire = factor(categorie_territoire, levels = ordre))

g <- ggplot(resume, aes(x = fct_rev(categorie_territoire), y = pct)) +
  geom_col(fill = "#4F6396", width = 0.6) +
  geom_text(aes(label = paste0(round(pct), " % (n=", n, ")")), hjust = -0.1, size = 3.2) +
  coord_flip(clip = "off") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.25))) +
  labs(title = "Volet organismes communautaires — répartition par zone territoriale",
       subtitle = paste0("Classification liste_organismes (bottin d'Hubert), n=", n_apparies,
                          " répondants appariés sur ", nrow(resultats)),
       x = NULL, y = "% des répondants appariés") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = "#e1e0d9", linewidth = 0.3),
        plot.title = element_text(size = 12, face = "bold"),
        plot.subtitle = element_text(size = 9, color = "#52514e"))

ggsave(file.path(dossier_clean, "distribution_zone_territoire_organismes.png"),
       g, width = 9.5, height = 3.6, dpi = 150)

cat("\n-> Écrit:", file.path(dossier_clean, "organismes_zone_territoire.csv"), "\n")
cat("-> Écrit:", file.path(dossier_clean, "distribution_zone_territoire_organismes.png"), "\n")
