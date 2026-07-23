# Distributions globales (internet + téléphone fusionnés) des variables
# fermées (quantitatives) du volet organismes, question par question.
# -> data/organismes/clean/distribution_globale_radiogroup_organismes.png
# -> data/organismes/clean/distribution_globale_checkbox_organismes.png
#
# Même logique visuelle que rapports/comparaison_internet_telephone.Rmd
# (graphique_radiogroup / graphique_checkbox), mais SANS distinction de mode :
# les deux modes sont regroupés pour donner la distribution globale par
# question, en vue d'explorer ensuite des croisements entre questions.
#
# Suppose que organismes_cleaning.R a déjà été exécuté.

library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(readr)
library(ggplot2)
library(forcats)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
dossier_clean <- file.path(data_dir, "organismes/clean")

combine <- read_csv(file.path(dossier_clean, "organismes_combined.csv"), show_col_types = FALSE)
dico    <- read_csv(file.path(dossier_clean, "dictionnaire_variables.csv"), show_col_types = FALSE)

couleur_globale <- "#2a78d6"

theme_distribution <- function() {
  theme_minimal(base_size = 10) +
    theme(
      panel.grid.minor   = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_line(color = "#e1e0d9", linewidth = 0.3),
      strip.text = element_text(face = "bold", size = 8),
      axis.title = element_text(color = "#52514e", size = 8),
      axis.text  = element_text(color = "#52514e", size = 7),
      plot.title = element_text(size = 12, face = "bold"),
      plot.subtitle = element_text(size = 9, color = "#52514e")
    )
}

texte_question <- function(code) dico$texte_question[dico$code == code][1]
etiquette_facette <- function(code) str_trunc(paste0(code, " — ", texte_question(code)), 45)

# --- Variables radiogroup (choix unique) ------------------------------------
# Légende de recodage numérique -> texte lisible (voir dictionnaire_variables.csv,
# colonne `codage`), même mapping que rapports/comparaison_internet_telephone.Rmd.

legende <- list(
  q0    = c("1" = "Oui", "2" = "Non"),
  q14   = c("1" = "Oui", "2" = "Non"),
  q15   = c("1" = "Oui", "2" = "Non"),
  q17   = c("1" = "Oui", "2" = "Non"),
  q14_1 = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q16   = c("1" = "Oui", "2" = "Non", "9" = "NSP / Autre"),
  q2    = c("1" = "Jamais", "2" = "Rarement", "3" = "Souvent", "4" = "Très souvent"),
  q3    = c("4" = "Très grande connaissance", "3" = "Assez grande connaissance",
            "2" = "Peu de connaissance", "1" = "Pas du tout de connaissance"),
  q5    = c("4" = "Très respectés", "3" = "Assez respectés",
            "2" = "Peu respectés", "1" = "Pas du tout respectés"),
  q11   = c("4" = "Très facile", "3" = "Assez facile",
            "2" = "Assez difficile", "1" = "Très difficile")
)

pct_global_radiogroup <- function(code) {
  lab <- legende[[code]]
  d <- combine %>% filter(!is.na(.data[[code]])) %>% select(valeur = all_of(code))
  d %>%
    mutate(valeur = factor(as.character(valeur), levels = names(lab), labels = unname(lab))) %>%
    count(valeur, name = "n") %>%
    complete(valeur, fill = list(n = 0)) %>%
    mutate(pct = 100 * n / sum(n), code = etiquette_facette(code), n_total = sum(n))
}

codes_radiogroup <- dico %>% filter(type == "ferme", sous_type == "radiogroup") %>% pull(code)
codes_radiogroup <- codes_radiogroup[codes_radiogroup %in% names(combine) & codes_radiogroup %in% names(legende)]

long_radiogroup <- map_dfr(codes_radiogroup, pct_global_radiogroup)

g_radiogroup <- ggplot(long_radiogroup, aes(x = fct_rev(valeur), y = pct)) +
  geom_col(fill = couleur_globale, width = 0.65) +
  geom_text(aes(label = ifelse(pct == 0, "", paste0(round(pct), " %"))),
            hjust = -0.15, size = 2.6, color = "#0b0b0b") +
  coord_flip(clip = "off") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.22))) +
  facet_wrap(vars(code), scales = "free_y", ncol = 2) +
  labs(title = "Volet organismes communautaires — distributions globales (variables fermées, choix unique)",
       subtitle = paste0("Internet + téléphone fusionnés (n=", nrow(combine), " répondants)"),
       x = NULL, y = "% des répondants") +
  theme_distribution()

ggsave(file.path(dossier_clean, "distribution_globale_radiogroup_organismes.png"),
       g_radiogroup, width = 11, height = 12, dpi = 150)

# --- Variables checkbox (choix multiples) -----------------------------------
# % d'endossement de chaque choix, sur l'ensemble des répondants ayant répondu
# à la question (plusieurs choix possibles par répondant, donc le total peut
# dépasser 100 %).

pct_global_checkbox <- function(code) {
  d <- combine %>% filter(!is.na(.data[[code]])) %>% select(valeur = all_of(code))
  choix_distincts <- d$valeur %>% str_split("\\s*\\|\\s*") %>% unlist() %>% unique() %>% sort()
  n_total <- nrow(d)
  map_dfr(choix_distincts, function(ch) {
    n_oui <- sum(str_detect(d$valeur, fixed(ch)))
    tibble(choix = ifelse(ch == "other", "Autre", ch), n = n_oui, pct = 100 * n_oui / n_total)
  }) %>% mutate(code = etiquette_facette(code), n_total = n_total)
}

codes_checkbox <- dico %>% filter(type == "ferme", sous_type == "checkbox") %>% pull(code)
codes_checkbox <- codes_checkbox[codes_checkbox %in% names(combine)]

long_checkbox <- map_dfr(codes_checkbox, pct_global_checkbox)

g_checkbox <- ggplot(long_checkbox, aes(x = reorder(choix, pct), y = pct)) +
  geom_col(fill = couleur_globale, width = 0.65) +
  geom_text(aes(label = paste0(round(pct), " %")), hjust = -0.15, size = 2.4, color = "#0b0b0b") +
  coord_flip(clip = "off") +
  scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.22))) +
  facet_wrap(vars(code), scales = "free_y", ncol = 2) +
  labs(title = "Volet organismes communautaires — distributions globales (variables fermées, choix multiples)",
       subtitle = "Internet + téléphone fusionnés — % d'endossement par choix (peut dépasser 100 % par question)",
       x = NULL, y = "% des répondants") +
  theme_distribution()

ggsave(file.path(dossier_clean, "distribution_globale_checkbox_organismes.png"),
       g_checkbox, width = 11, height = 14, dpi = 150)

cat("-> Écrit:", file.path(dossier_clean, "distribution_globale_radiogroup_organismes.png"), "\n")
cat("-> Écrit:", file.path(dossier_clean, "distribution_globale_checkbox_organismes.png"), "\n")
