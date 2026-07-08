# Génère le PDF du rapport de comparaison internet/téléphone destiné au client.
# Suppose que scripts/organismes_cleaning.R, organismes_eta.R et
# organismes_comparaison_modes.R ont déjà été exécutés (le rapport lit leurs
# sorties dans data/organismes/clean/).
#
# Ce script suppose que le répertoire de travail R est la racine du projet.

# Pandoc n'est pas sur le PATH sur cette machine mais est fourni avec Quarto.
Sys.setenv(RSTUDIO_PANDOC = "C:/Users/alexa/AppData/Local/Programs/Quarto/bin/tools")

rmarkdown::render("rapports/comparaison_internet_telephone.Rmd")

cat("\n-> PDF généré : rapports/comparaison_internet_telephone.pdf\n")
