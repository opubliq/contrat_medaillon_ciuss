# Distribution de la longueur (en mots) des réponses aux questions ouvertes,
# question par question, pour les deux sondages (organismes et usagers).
# -> data/organismes/clean/distribution_longueur_organismes.png
# -> data/usagers/clean/distribution_longueur_usagers.png
#
# Objectif : évaluer visuellement le volume de matière disponible pour
# l'analyse qualitative (codage thématique) de chaque question ouverte.
#
# Suppose que organismes_cleaning.R + organismes_eta.R (volet organismes) et
# usagers_cleaning.R (volet usagers) ont déjà été exécutés.

library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(purrr)
library(ggplot2)
library(forcats)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"

couleur_organismes <- "#2a78d6"
couleur_usagers     <- "#1baf7a"

theme_distribution <- function() {
  theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(color = "#e1e0d9", linewidth = 0.3),
      strip.text = element_text(face = "bold", size = 8),
      axis.title = element_text(color = "#52514e", size = 8),
      axis.text  = element_text(color = "#52514e", size = 7),
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "#52514e")
    )
}

# Compte les mots d'une chaîne de caractères (NA / vide -> NA, pas 0).
compter_mots <- function(x) {
  x <- str_trim(x)
  n <- str_count(x, "\\S+")
  ifelse(is.na(x) | x == "", NA_integer_, n)
}

# construit un data frame long (code, n_mots) pour un ensemble de colonnes
# ouvertes, un data frame de réponses en entrée
longueurs_par_question <- function(df, codes_ouverts) {
  codes_ouverts <- codes_ouverts[codes_ouverts %in% names(df)]
  df %>%
    select(all_of(codes_ouverts)) %>%
    mutate(across(everything(), compter_mots)) %>%
    pivot_longer(everything(), names_to = "code", values_to = "n_mots") %>%
    filter(!is.na(n_mots))
}

# Facette les questions par ordre décroissant de volume (nombre de réponses),
# une distribution (histogramme) par question, échelles libres (les longueurs
# varient énormément d'une question à l'autre).
graphique_distributions <- function(long_df, couleur, titre, sous_titre) {
  ordre <- long_df %>% count(code, name = "n") %>% arrange(desc(n)) %>% pull(code)
  long_df <- long_df %>% mutate(code = fct_relevel(code, ordre))

  ggplot(long_df, aes(x = n_mots)) +
    geom_histogram(bins = 20, fill = couleur, color = NA) +
    facet_wrap(vars(code), scales = "free", ncol = 5) +
    labs(title = titre, subtitle = sous_titre, x = "Longueur de la réponse (mots)", y = "Nombre de réponses") +
    theme_distribution()
}

# --- Volet organismes -------------------------------------------------------

dossier_organismes <- file.path(data_dir, "organismes/clean")
qual_organismes  <- read_csv(file.path(dossier_organismes, "organismes_qualitatif.csv"), show_col_types = FALSE)
dico_organismes  <- read_csv(file.path(dossier_organismes, "dictionnaire_variables.csv"), show_col_types = FALSE)
codes_ouverts_organismes <- dico_organismes %>% filter(type == "ouvert") %>% pull(code)

long_organismes <- longueurs_par_question(qual_organismes, codes_ouverts_organismes)

g_organismes <- graphique_distributions(
  long_organismes, couleur_organismes,
  "Volet organismes communautaires — distribution des longueurs de réponse",
  paste0(nrow(long_organismes), " réponses non vides, ", n_distinct(long_organismes$code), " questions ouvertes")
)

ggsave(file.path(dossier_organismes, "distribution_longueur_organismes.png"),
       g_organismes, width = 14, height = 12, dpi = 150)

# --- Volet usagers -----------------------------------------------------------

dossier_usagers <- file.path(data_dir, "usagers/clean")
combine_usagers <- read_csv(file.path(dossier_usagers, "usagers_combined.csv"), show_col_types = FALSE)
dico_usagers    <- read_csv(file.path(dossier_usagers, "dictionnaire_variables.csv"), show_col_types = FALSE)
codes_ouverts_usagers <- dico_usagers %>% filter(type == "ouvert") %>% pull(code)

long_usagers <- longueurs_par_question(combine_usagers, codes_ouverts_usagers)

g_usagers <- graphique_distributions(
  long_usagers, couleur_usagers,
  "Volet usagers — distribution des longueurs de réponse",
  paste0(nrow(long_usagers), " réponses non vides, ", n_distinct(long_usagers$code), " questions ouvertes")
)

ggsave(file.path(dossier_usagers, "distribution_longueur_usagers.png"),
       g_usagers, width = 14, height = 10, dpi = 150)

cat("-> Écrit:", file.path(dossier_organismes, "distribution_longueur_organismes.png"), "\n")
cat("-> Écrit:", file.path(dossier_usagers, "distribution_longueur_usagers.png"), "\n")
