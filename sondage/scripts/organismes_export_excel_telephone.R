# ---------------------------------------------------------------------------
# Export Excel des annotations qualitatives -- entrevues telephoniques
# uniquement (volet organismes communautaires), pour transmission a la
# cliente (Medaillon).
#
# Filtre les 29 fichiers d'annotation
# (data/organismes/clean/annotation_quali/opubliq-annotations-*.csv) sur
# mode == "telephone" et les regroupe dans un classeur Excel, une feuille par
# question.
#
# Structure de chaque feuille : respondent_id | verbatim | categorie (label),
# trie par categorie (effectif decroissant, "non classable" en dernier) puis
# respondent_id -- meme logique de regroupement que le document de
# verification (organismes_verification_annotations.R).
# Une feuille "Resume" liste les 29 questions (libelle, consigne d'annotation,
# nombre de reponses telephone, nombre de categories).
#
# Prerequis : organismes_annotation_mode.R doit avoir ete execute (colonne
# `mode` presente dans les fichiers d'annotation).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(openxlsx)
})

racine <- "C:/Users/alexa/Dropbox/Opubliq/contrat_medaillon_ciuss/sondage"
dossier_annot <- file.path(racine, "data/organismes/clean/annotation_quali")
dossier_sortie <- file.path(racine, "rapports/annotations_telephone")
dir.create(dossier_sortie, recursive = TRUE, showWarnings = FALSE)

# --- Donnees ----------------------------------------------------------------

fichiers <- list.files(dossier_annot, pattern = "^opubliq-annotations-.*\\.csv$",
                       full.names = TRUE)
annot <- bind_rows(lapply(fichiers, read_csv,
                          col_types = cols(.default = col_character()),
                          progress = FALSE))

stopifnot("mode" %in% names(annot), nrow(annot) > 0)

telephone <- annot %>% filter(mode == "telephone")
stopifnot(nrow(telephone) > 0)

cat("Annotations telephone :", nrow(telephone),
    "| repondants distincts :", n_distinct(telephone$respondent_id),
    "| questions :", n_distinct(telephone$variable), "\n\n")

# --- Ordre des questions (meme logique que organismes_verification_annotations.R) --

variables <- telephone %>%
  distinct(variable) %>%
  mutate(
    base = sub("-Comment$", "", variable),
    num_q = as.integer(sub("^q(\\d+).*$", "\\1", base)),
    sous  = ifelse(grepl("_", variable),
                   as.integer(sub("^q\\d+_(\\d+)$", "\\1", variable)), 0L),
    comment = as.integer(grepl("-Comment$", variable))
  ) %>%
  arrange(num_q, comment, sous) %>%
  pull(variable)

# --- Styles -------------------------------------------------------------

style_entete <- createStyle(textDecoration = "bold", fgFill = "#1F4E79",
                            fontColour = "white", wrapText = TRUE,
                            valign = "center", halign = "center")
style_corps <- createStyle(wrapText = TRUE, valign = "top")

# --- Classeur -----------------------------------------------------------

wb <- createWorkbook()

# Feuille resume
resume <- telephone %>%
  group_by(variable) %>%
  summarise(
    question_text = first(question_text),
    propriete_annotee = first(propriete_annotee),
    n_reponses = n(),
    n_categories = n_distinct(label),
    .groups = "drop"
  ) %>%
  arrange(match(variable, variables))

addWorksheet(wb, "Resume")
writeData(wb, "Resume", resume, headerStyle = style_entete)
addStyle(wb, "Resume", style_corps, rows = 2:(nrow(resume) + 1),
        cols = seq_len(ncol(resume)), gridExpand = TRUE)
setColWidths(wb, "Resume", cols = seq_len(ncol(resume)),
            widths = c(14, 60, 40, 12, 12))
freezePane(wb, "Resume", firstRow = TRUE)

# Une feuille par question, verbatims groupes par categorie
for (v in variables) {
  d <- telephone %>% filter(variable == v)

  effectifs <- d %>%
    count(label, name = "n_label") %>%
    mutate(fourre = grepl("non classable", label, ignore.case = TRUE)) %>%
    arrange(fourre, desc(n_label), label)

  d <- d %>%
    mutate(
      ordre_label = match(label, effectifs$label),
      id_num = as.integer(respondent_id)
    ) %>%
    arrange(ordre_label, id_num) %>%
    select(respondent_id, verbatim = text, categorie = label)

  nom_feuille <- substr(gsub("[^A-Za-z0-9_]", "_", v), 1, 31)
  addWorksheet(wb, nom_feuille)
  writeData(wb, nom_feuille, d, headerStyle = style_entete)
  addStyle(wb, nom_feuille, style_corps, rows = 2:(nrow(d) + 1),
          cols = seq_len(ncol(d)), gridExpand = TRUE)
  setColWidths(wb, nom_feuille, cols = seq_len(ncol(d)), widths = c(10, 90, 28))
  freezePane(wb, nom_feuille, firstRow = TRUE)
}

chemin_sortie <- file.path(dossier_sortie, "organismes_annotations_telephone.xlsx")
saveWorkbook(wb, chemin_sortie, overwrite = TRUE)

cat("Classeur ecrit :", chemin_sortie, "\n")
cat("Feuilles :", length(variables) + 1, "(Resume +", length(variables), "questions)\n")
