# ---------------------------------------------------------------------------
# Ajout de la variable `mode` (internet / telephone) aux fichiers d'annotation
# qualitative du volet organismes.
#
# Les exports de la plateforme d'annotation ne conservent que `respondent_id`,
# sans indiquer si la reponse provient du questionnaire en ligne ou d'une
# entrevue telephonique. Ce script rattache chaque annotation a sa ligne
# d'origine dans `organismes_qualitatif.csv` et y insere la colonne `mode`
# juste apres `respondent_id`.
#
# Cle de jointure : `respondent_id` est un index de ligne commencant a 0,
# donc ligne = respondent_id + 1 dans organismes_qualitatif.csv (n = 130,
# lignes 1-105 = internet, 106-130 = telephone). Cette hypothese est
# revalidee a chaque execution en comparant le verbatim annote (`text`) au
# texte de la colonne correspondante : le script s'arrete si un seul
# verbatim ne concorde pas.
#
# Le script est idempotent : les fichiers ayant deja une colonne `mode`
# (ex. q1_1, traite precedemment) sont revalides puis laisses tels quels.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

racine <- "C:/Users/alexa/Dropbox/Opubliq/contrat_medaillon_ciuss/sondage"
dossier_annot <- file.path(racine, "data/organismes/clean/annotation_quali")

# --- Source de verite : le jeu qualitatif nettoye ---------------------------
qualitatif <- read_csv(
  file.path(racine, "data/organismes/clean/organismes_qualitatif.csv"),
  col_types = cols(.default = col_character()),
  progress = FALSE
)

stopifnot(nrow(qualitatif) == 130, "mode" %in% names(qualitatif))

# Normalisation pour la comparaison des verbatims (espaces/casse seulement,
# le contenu lui-meme n'est jamais modifie).
normaliser <- function(x) gsub("[[:space:]]+", " ", trimws(tolower(x)))

# Ecrit un CSV en UTF-8 avec BOM, comme les exports de la plateforme.
ecrire_csv_bom <- function(d, chemin) {
  tmp <- tempfile(fileext = ".csv")
  write_csv(d, tmp, na = "")
  con <- file(tmp, "rb"); contenu <- readBin(con, "raw", file.size(tmp)); close(con)
  con <- file(chemin, "wb")
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), contenu), con)
  close(con)
  unlink(tmp)
}

# Ne cible que les exports de la plateforme d'annotation (pas les sorties
# generees par ce script lui-meme).
fichiers <- list.files(dossier_annot, pattern = "^opubliq-annotations-.*\\.csv$",
                       full.names = TRUE)
resume <- list()

for (f in fichiers) {
  annot <- read_csv(f, col_types = cols(.default = col_character()),
                    progress = FALSE)

  variable <- unique(annot$variable)
  stopifnot(length(variable) == 1)

  # La colonne peut porter un nom non syntaxique (ex. "q10-Comment").
  colonne <- if (variable %in% names(qualitatif)) variable else make.names(variable)
  if (!colonne %in% names(qualitatif)) {
    stop("Colonne introuvable dans organismes_qualitatif.csv : ", variable)
  }

  ligne <- as.integer(annot$respondent_id) + 1L
  if (any(is.na(ligne)) || any(ligne < 1L | ligne > nrow(qualitatif))) {
    stop("respondent_id hors bornes pour ", variable)
  }

  # Validation : le verbatim annote doit correspondre a la source.
  discordants <- which(normaliser(qualitatif[[colonne]][ligne]) !=
                         normaliser(annot$text))
  if (length(discordants) > 0) {
    stop(sprintf("%s : %d verbatim(s) ne concordent pas avec la source (lignes %s)",
                 variable, length(discordants),
                 paste(head(discordants, 5), collapse = ", ")))
  }

  mode_attendu <- qualitatif$mode[ligne]

  if ("mode" %in% names(annot)) {
    # Deja traite : on verifie seulement la coherence.
    if (!identical(annot$mode, mode_attendu)) {
      stop("La colonne `mode` existante est incoherente pour ", variable)
    }
    statut <- "deja fait"
  } else {
    annot <- annot %>%
      mutate(mode = mode_attendu, .after = respondent_id)
    ecrire_csv_bom(annot, f)
    statut <- "ajoute"
  }

  resume[[variable]] <- tibble(
    variable  = variable,
    n         = nrow(annot),
    internet  = sum(mode_attendu == "internet"),
    telephone = sum(mode_attendu == "telephone"),
    statut    = statut
  )
}

resume <- bind_rows(resume) %>% arrange(variable)
resume <- resume %>%
  mutate(pct_telephone = round(100 * telephone / n, 1))

print(as.data.frame(resume), row.names = FALSE)

cat("\nTotal annotations :", sum(resume$n),
    "| internet :", sum(resume$internet),
    "| telephone :", sum(resume$telephone), "\n")

chemin_resume <- file.path(racine, "data/organismes/clean",
                           "annotation_quali_resume_modes.csv")
write_csv(resume, chemin_resume)
cat("Resume ecrit dans", chemin_resume, "\n")
