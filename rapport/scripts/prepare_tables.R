#!/usr/bin/env Rscript
# prepare_tables.R
# Lit 04_bottin_secteurs.csv, génère :
#   - data/table_local.csv
#   - data/table_montreal.csv
#   - data/table_grand_montreal.csv
#   - data/graphique_territoire.png
#   - data/graphique_secteurs.png

library(tidyverse)
library(ggplot2)

# ── Config ────────────────────────────────────────────────────────────────────

CSV_SOURCE <- "liste_organismes/data/04_bottin_secteurs.csv"
OUT_DIR    <- "rapport/data"
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)

N_MONTREAL    <- 15
N_GRAND_MTL   <- 10
N_PROVINCIAL  <- 10

COULEURS <- c(
  "local"         = "#2C5F8A",
  "montreal"      = "#4A90C4",
  "grand_montreal"= "#7BB8DC",
  "provincial"    = "#B0D4EC"
)

LABELS_SECTEUR <- c(
  aide_alimentaire       = "Aide alimentaire",
  hebergement_logement   = "Hébergement / logement",
  sante_mentale          = "Santé mentale",
  dependances            = "Dépendances",
  defense_droits         = "Défense des droits",
  aines                  = "Aînés",
  jeunes_familles        = "Jeunes et familles",
  immigrants_integration = "Immigration / intégration",
  employabilite          = "Employabilité",
  itinerance             = "Itinérance",
  handicap_accessibilite = "Handicap / accessibilité",
  autre                  = "Autre"
)

LABELS_TERRITOIRE <- c(
  local          = "Local (territoire CIUSSS-Est)",
  montreal       = "Île de Montréal",
  grand_montreal = "Grand Montréal",
  provincial     = "Provincial"
)

# ── Lecture ───────────────────────────────────────────────────────────────────

df <- read_csv(CSV_SOURCE, show_col_types = FALSE) |>
  filter(pertinent == TRUE | pertinent == "True") |>
  mutate(
    secteur_label = LABELS_SECTEUR[secteur] |> coalesce(secteur),
    territoire_label = LABELS_TERRITOIRE[categorie_territoire] |>
      coalesce(categorie_territoire)
  )

message(glue::glue("Organismes chargés : {nrow(df)}"))
message(glue::glue("Par territoire :\n{capture.output(count(df, categorie_territoire)) |> paste(collapse='\n')}"))

# ── Colonnes pour les tables ───────────────────────────────────────────────────

cols_table <- c("nom", "secteur_label", "courriel", "telephone")

format_table <- function(data) {
  data |>
    select(all_of(cols_table)) |>
    rename(
      Organisme = nom,
      Secteur   = secteur_label,
      Courriel  = courriel,
      Téléphone = telephone
    ) |>
    mutate(
      Organisme = str_to_title(Organisme),
      Courriel  = replace_na(Courriel, "—"),
      Téléphone = replace_na(Téléphone, "—")
    )
}

# ── Tables par territoire ─────────────────────────────────────────────────────

# Local : tous
df |>
  filter(categorie_territoire == "local") |>
  arrange(secteur, nom) |>
  format_table() |>
  write_csv(file.path(OUT_DIR, "table_local.csv"))

# Montréal : échantillon aléatoire reproductible
set.seed(42)
df_mtl <- df |> filter(categorie_territoire == "montreal")
df_mtl |>
  slice_sample(n = min(N_MONTREAL, nrow(df_mtl))) |>
  arrange(secteur, nom) |>
  format_table() |>
  write_csv(file.path(OUT_DIR, "table_montreal.csv"))

# Grand Montréal : échantillon aléatoire reproductible
set.seed(42)
df_gm <- df |> filter(categorie_territoire == "grand_montreal")
df_gm |>
  slice_sample(n = min(N_GRAND_MTL, nrow(df_gm))) |>
  arrange(secteur, nom) |>
  format_table() |>
  write_csv(file.path(OUT_DIR, "table_grand_montreal.csv"))

# Provincial : échantillon aléatoire reproductible
set.seed(42)
df_prov <- df |> filter(categorie_territoire == "provincial")
df_prov |>
  slice_sample(n = min(N_PROVINCIAL, nrow(df_prov))) |>
  arrange(secteur, nom) |>
  format_table() |>
  write_csv(file.path(OUT_DIR, "table_provincial.csv"))

message("Tables CSV générées.")

# ── Graphique 1 : distribution par territoire ─────────────────────────────────

g1 <- df |>
  count(categorie_territoire, territoire_label) |>
  mutate(territoire_label = fct_reorder(territoire_label, n)) |>
  ggplot(aes(x = n, y = territoire_label, fill = categorie_territoire)) +
  geom_col(width = 0.6, show.legend = FALSE) +
  geom_text(aes(label = n), hjust = -0.3, size = 3.5) +
  scale_fill_manual(values = COULEURS) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Organismes retenus par portée territoriale",
    x = "Nombre d'organismes",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank()
  )

ggsave(file.path(OUT_DIR, "graphique_territoire.png"), g1,
       width = 7, height = 3.5, dpi = 150)

# ── Graphique 2 : distribution par secteur ────────────────────────────────────

g2 <- df |>
  count(secteur_label) |>
  mutate(secteur_label = fct_reorder(secteur_label, n)) |>
  ggplot(aes(x = n, y = secteur_label)) +
  geom_col(width = 0.65, fill = "#2C5F8A") +
  geom_text(aes(label = n), hjust = -0.3, size = 3.5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title = "Organismes retenus par secteur d'activité",
    x = "Nombre d'organismes",
    y = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", size = 13),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank()
  )

ggsave(file.path(OUT_DIR, "graphique_secteurs.png"), g2,
       width = 7, height = 5, dpi = 150)

message("Graphiques PNG générés.")
message("Prêt pour quarto render.")
