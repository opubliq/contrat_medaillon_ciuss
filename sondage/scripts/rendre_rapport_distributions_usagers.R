# Génère le PDF du rapport minimaliste de distributions (volet usagers,
# variables fermées, tous modes de collecte fusionnés, sans texte narratif).
# Suppose que usagers_cleaning.R et longueur_reponses_ouvertes.R ont déjà été exécutés.
#
# Ce script suppose que le répertoire de travail R est la racine du projet.

Sys.setenv(RSTUDIO_PANDOC = "C:/Users/alexa/AppData/Local/Programs/Quarto/bin/tools")

rmarkdown::render("rapports/distributions_usagers.Rmd")

cat("\n-> PDF généré : rapports/distributions_usagers.pdf\n")
