# Génère un fichier PNG individuel par question quantitative (fermée),
# pour les deux volets (organismes, usagers). Reprend les mêmes graphiques
# que rapports/distributions_organismes.Rmd et rapports/distributions_usagers.Rmd,
# mais :
#  - un PNG par question (au lieu d'être intégrés au rapport PDF)
#  - axe des pourcentages (visuellement horizontal) sans quadrillage ni graduations
#  - note "n = X répondants" propre, en légende du graphique (caption)
#
# Suppose que organismes_cleaning.R et usagers_cleaning.R ont déjà été exécutés.
# Ce script suppose que le répertoire de travail R est la racine du projet.

library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(ggplot2)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"

couleur <- "#4F6396"

theme_graphique_png <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.major.y = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.minor   = element_blank(),
      axis.text.x  = element_blank(),
      axis.ticks   = element_blank(),
      axis.text.y  = element_text(color = "#3d3d3b", size = 11),
      axis.title   = element_blank(),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      plot.title   = element_text(size = 12, face = "bold", color = "#1a1a1a",
                                   hjust = 0, margin = margin(b = 12)),
      plot.caption = element_text(size = 9, color = "#8a8a86", face = "italic",
                                   hjust = 0, margin = margin(t = 10)),
      plot.margin  = margin(14, 16, 10, 10)
    )
}

graphique_radiogroup <- function(combine, code, lab, titre) {
  d <- combine %>% filter(!is.na(.data[[code]])) %>% select(valeur = all_of(code))
  n_total <- nrow(d)
  d <- d %>%
    mutate(valeur = factor(as.character(valeur), levels = names(lab), labels = unname(lab))) %>%
    count(valeur, name = "n") %>%
    complete(valeur, fill = list(n = 0)) %>%
    mutate(pct = 100 * n / sum(n), valeur = factor(valeur, levels = unique(rev(unname(lab)))))

  ggplot(d, aes(x = valeur, y = pct)) +
    geom_col(fill = couleur, width = 0.55) +
    geom_text(aes(label = ifelse(pct == 0, "", paste0(round(pct), " %"))),
              hjust = -0.15, size = 3, color = "#0b0b0b") +
    coord_flip(clip = "off") +
    scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.18))) +
    labs(title = titre, caption = paste0("n = ", n_total, " répondants")) +
    theme_graphique_png()
}

majuscule_initiale <- function(x) paste0(toupper(str_sub(x, 1, 1)), str_sub(x, 2))

graphique_checkbox <- function(combine, code, titre) {
  d <- combine %>% filter(!is.na(.data[[code]])) %>% select(valeur = all_of(code))
  n_total <- nrow(d)
  choix_distincts <- d$valeur %>% str_split("\\s*\\|\\s*") %>% unlist() %>% unique() %>% sort()
  d2 <- map_dfr(choix_distincts, function(ch) {
    tibble(choix = ifelse(ch == "other", "Autre", majuscule_initiale(ch)),
           pct = 100 * sum(str_detect(d$valeur, fixed(ch))) / n_total)
  })
  ordre <- d2 %>% arrange(pct) %>% pull(choix)
  d2 <- d2 %>% mutate(choix = factor(choix, levels = ordre))

  ggplot(d2, aes(x = choix, y = pct)) +
    geom_col(fill = couleur, width = 0.6) +
    geom_text(aes(label = paste0(round(pct), " %")), hjust = -0.1, size = 2.8, color = "#0b0b0b") +
    coord_flip(clip = "off") +
    scale_y_continuous(limits = c(0, 100), expand = expansion(mult = c(0, 0.22))) +
    labs(title = titre, caption = paste0("n = ", n_total, " répondants")) +
    theme_graphique_png()
}

# Sauvegarde chaque question d'un volet en PNG individuel dans dossier_out.
exporter_graphiques <- function(combine, dico, ordre_questions, codes_radiogroup, legende, dossier_out) {
  dir.create(dossier_out, showWarnings = FALSE, recursive = TRUE)
  texte_question <- function(code) dico$texte_question[dico$code == code][1]

  for (code in ordre_questions) {
    titre <- paste0(toupper(code), " — ", texte_question(code))
    g <- if (code %in% codes_radiogroup) {
      graphique_radiogroup(combine, code, legende[[code]], titre)
    } else {
      graphique_checkbox(combine, code, titre)
    }
    fichier <- file.path(dossier_out, paste0(code, ".png"))
    ggsave(fichier, g, width = 6.5, height = 2.6, dpi = 200, bg = "white")
    cat("-> Écrit:", fichier, "\n")
  }
}

# --- Volet organismes --------------------------------------------------------

dossier_organismes <- file.path(data_dir, "organismes/clean")
combine_organismes <- read.csv(file.path(dossier_organismes, "organismes_combined.csv"),
                                fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
dico_organismes <- read.csv(file.path(dossier_organismes, "dictionnaire_variables.csv"),
                             fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)

legende_organismes <- list(
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

codes_radiogroup_organismes <- c("q0", "q2", "q3", "q5", "q11", "q14", "q14_1", "q15", "q16", "q17")
ordre_questions_organismes  <- c("q0", "q1", "q2", "q3", "q5", "q10", "q11", "q12",
                                  "q14", "q14_1", "q15", "q16", "q17", "q21", "q22", "q23", "q24")

exporter_graphiques(combine_organismes, dico_organismes, ordre_questions_organismes,
                     codes_radiogroup_organismes, legende_organismes,
                     file.path(dossier_organismes, "graphiques"))

# --- Volet usagers -------------------------------------------------------------

dossier_usagers <- file.path(data_dir, "usagers/clean")
combine_usagers <- read.csv(file.path(dossier_usagers, "usagers_combined.csv"),
                             fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, na.strings = c("NA", ""))
dico_usagers <- read.csv(file.path(dossier_usagers, "dictionnaire_variables.csv"),
                          fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE, na.strings = c("NA", ""))

legende_usagers <- list(
  q1  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q2  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q3  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q4  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q5  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q7  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q8  = c("1" = "Oui", "2" = "Non", "9" = "Ne sais pas"),
  q10 = c("1" = "34 ans et -", "2" = "35 à 44 ans", "3" = "45 et 64 ans", "4" = "65 ans et +"),
  q9  = c("est_montreal" = "Est de Montréal", "grande_region" = "Reste de Montréal et sa grande région",
          "ailleurs_ile" = "Reste de Montréal et sa grande région", "exterieur_grande_region" = "Extérieur de la grande région")
)

codes_radiogroup_usagers <- c("q1", "q2", "q3", "q4", "q5", "q7", "q8", "q9", "q10")
ordre_questions_usagers  <- c("q1", "q2", "q3", "q4", "q5", "q7", "q7_1", "q8", "q9", "q10")

exporter_graphiques(combine_usagers, dico_usagers, ordre_questions_usagers,
                     codes_radiogroup_usagers, legende_usagers,
                     file.path(dossier_usagers, "graphiques"))
