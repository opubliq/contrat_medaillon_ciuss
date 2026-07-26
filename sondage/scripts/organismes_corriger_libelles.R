# ---------------------------------------------------------------------------
# Correction de libelles d'annotation fautifs dans les exports de la
# plateforme (data/organismes/clean/annotation_quali/).
#
# Corrections appliquees (decidees avec l'utilisateur, 2026-07-26) :
#   - "Partenariats et outreach"    -> "Partenariats et travail de proximite"
#     (q4, n=26) : anglicisme. Les verbatims de cette categorie portent sur
#     les kiosques, tournees d'organismes et seances d'information dans le
#     milieu, d'ou "travail de proximite".
#   - "Besoins materiels immediats" -> accent manquant sur "immediats"
#     (q1_1, n=5).
#
# Idempotent : relancer ne fait rien si les libelles sont deja corriges.
# Preserve le BOM UTF-8 et la structure des fichiers (voir
# organismes_annotation_mode.R pour la meme mecanique d'ecriture).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

racine <- "C:/Users/alexa/Dropbox/Opubliq/contrat_medaillon_ciuss/sondage"
dossier_annot <- file.path(racine, "data/organismes/clean/annotation_quali")

corrections <- c(
  "Partenariats et outreach"    = "Partenariats et travail de proximité",
  "Besoins matériels immediats" = "Besoins matériels immédiats"
)

ecrire_csv_bom <- function(d, chemin) {
  tmp <- tempfile(fileext = ".csv")
  write_csv(d, tmp, na = "")
  con <- file(tmp, "rb"); contenu <- readBin(con, "raw", file.size(tmp)); close(con)
  con <- file(chemin, "wb")
  writeBin(c(as.raw(c(0xEF, 0xBB, 0xBF)), contenu), con)
  close(con)
  unlink(tmp)
}

fichiers <- list.files(dossier_annot, pattern = "^opubliq-annotations-.*\\.csv$",
                       full.names = TRUE)
total <- 0

for (f in fichiers) {
  a <- read_csv(f, col_types = cols(.default = col_character()), progress = FALSE)
  avant <- a$label
  for (i in seq_along(corrections)) {
    a$label[a$label == names(corrections)[i]] <- corrections[[i]]
  }
  n <- sum(avant != a$label)
  if (n > 0) {
    ecrire_csv_bom(a, f)
    cat(sprintf("  %-14s %d libelle(s) corrige(s)\n", unique(a$variable), n))
    total <- total + n
  }
}

cat("\nTotal :", total, "libelle(s) corrige(s)\n")

# Verification : plus aucune occurrence des libelles fautifs
restant <- sum(sapply(fichiers, function(f) {
  a <- read_csv(f, col_types = cols(.default = col_character()), progress = FALSE)
  sum(a$label %in% names(corrections))
}))
cat("Occurrences fautives restantes :", restant, "\n")
stopifnot(restant == 0)
