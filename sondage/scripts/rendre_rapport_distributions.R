# Génère le PDF du rapport minimaliste de distributions (volet organismes,
# variables fermées, internet + téléphone fusionnés, sans texte narratif).
# Suppose que organismes_cleaning.R a déjà été exécuté.
#
# Ce script suppose que le répertoire de travail R est la racine du projet.

Sys.setenv(RSTUDIO_PANDOC = "C:/Users/alexa/AppData/Local/Programs/Quarto/bin/tools")

rmarkdown::render("rapports/distributions_organismes.Rmd")

cat("\n-> PDF généré : rapports/distributions_organismes.pdf\n")
