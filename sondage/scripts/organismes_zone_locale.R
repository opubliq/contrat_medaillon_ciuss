# Variable de zone simplifiée, dérivée de q22 (quartiers desservis).
#
# Contexte (voir notes_rencontre_13juillet.md) : le client souhaite une
# distribution par zone (provincial / grand Montréal / local=Hochelaga). Cette
# classification existe dans le pipeline liste_organismes (categorie_territoire,
# scripts/02_filtre_territoire.R + 04_classification_secteur.py) mais son
# fichier de sortie (liste_organismes/data/04_bottin_secteurs.csv) est
# gitignored et n'est pas disponible dans cet environnement -> à demander à
# Hubert puis joindre par nom d'organisme pour une version plus fine.
#
# En attendant, proxy simplifié à partir de q22 (décision utilisateur,
# 2026-07-23) :
#   - q22 n'offre QUE les 10 quartiers du CIUSSS-Est comme choix (pas d'option
#     grand Montréal / provincial, pas de champ "Autre") -> impossible de
#     distinguer grand_montreal vs provincial avec cette seule question.
#   - "local"           = au moins un quartier CIUSSS-Est coché en q22
#   - "hors zone locale" = q22 vide (aucun quartier coché) -- proxy pour
#     "dessert probablement ailleurs qu'en Est de Montréal", PAS une certitude
#     (peut aussi refléter une non-réponse à cette question précise).
#
# -> data/organismes/clean/organismes_zone_locale.csv
#    (response_id, n_quartiers_locaux, zone_locale) pour croisements ultérieurs
# -> data/organismes/clean/distribution_zone_locale_organismes.png

library(dplyr)
library(stringr)
library(readr)
library(ggplot2)
library(forcats)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE)

couleur_globale <- "#2a78d6"

zone_locale <- combine %>%
  transmute(
    response_id,
    n_quartiers_locaux = ifelse(is.na(q22), 0L, str_count(q22, "\\|") + 1L),
    zone_locale = case_when(
      n_quartiers_locaux == 0L ~ "Hors zone locale (q22 vide)",
      n_quartiers_locaux == 1L ~ "Local — 1 quartier",
      TRUE                     ~ "Local — 2+ quartiers"
    )
  )

write_excel_csv(zone_locale, file.path(dossier_clean, "organismes_zone_locale.csv"), na = "")

resume <- zone_locale %>%
  count(zone_locale, name = "n") %>%
  mutate(pct = 100 * n / sum(n),
         zone_locale = factor(zone_locale, levels = c(
           "Hors zone locale (q22 vide)", "Local — 1 quartier", "Local — 2+ quartiers"
         )))

g <- ggplot(resume, aes(x = fct_rev(zone_locale), y = pct)) +
  geom_col(fill = couleur_globale, width = 0.6) +
  geom_text(aes(label = paste0(round(pct), " % (n=", n, ")")), hjust = -0.1, size = 3.2) +
  coord_flip(clip = "off") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.25))) +
  labs(title = "Volet organismes communautaires — répartition par zone (proxy dérivé de q22)",
       subtitle = paste0("Internet + téléphone fusionnés (n=", nrow(combine), " répondants)"),
       x = NULL, y = "% des répondants") +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank(), panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = "#e1e0d9", linewidth = 0.3),
        plot.title = element_text(size = 12, face = "bold"),
        plot.subtitle = element_text(size = 9, color = "#52514e"))

ggsave(file.path(dossier_clean, "distribution_zone_locale_organismes.png"),
       g, width = 9, height = 3.2, dpi = 150)

cat("Répartition par zone (proxy q22) :\n")
print(resume %>% select(zone_locale, n, pct))

cat("\n-> Écrit:", file.path(dossier_clean, "organismes_zone_locale.csv"), "\n")
cat("-> Écrit:", file.path(dossier_clean, "distribution_zone_locale_organismes.png"), "\n")
