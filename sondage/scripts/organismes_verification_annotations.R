# ---------------------------------------------------------------------------
# Document de verification manuelle des annotations qualitatives
# (volet organismes communautaires).
#
# Produit, pour chaque question ouverte annotee :
#   1. le libelle de la question, et celui de la question "mere" quand la
#      question seule est incomprehensible (ex. "q10-Comment" = le champ
#      "Autre, precisez" de q10 ; "q18_3" = une des 6 fonctions listees
#      sous le chapeau q18) ;
#   2. la propriete annotee (la consigne donnee a l'annotateur) ;
#   3. un resume des categories : nom, effectif, part, ventilation par mode ;
#   4. l'integralite des reponses, regroupees par categorie, chacune avec
#      son numero de repondant et son mode de collecte.
#
# Sorties (dans rapports/verification_annotations/) :
#   - verification_annotations_complet.pdf   (les 29 questions, avec table
#                                             des matieres)
#   - par_question/verification_<code>.pdf   (29 fichiers autonomes, pour
#                                             distribuer une question a une
#                                             personne sans lui envoyer tout)
#
# Le LaTeX est genere directement (plutot que via R Markdown) parce que les
# verbatims sont du texte libre : passer par pandoc lui ferait interpreter
# les caracteres markdown qu'ils contiennent. Ici, tout est echappe
# explicitement par `escaper_latex()`.
#
# Prerequis : organismes_annotation_mode.R doit avoir ete execute (colonne
# `mode` presente dans les fichiers d'annotation).
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(jsonlite)
})

racine <- "C:/Users/alexa/Dropbox/Opubliq/contrat_medaillon_ciuss/sondage"
dossier_annot <- file.path(racine, "data/organismes/clean/annotation_quali")
dossier_sortie <- file.path(racine, "rapports/verification_annotations")
dossier_unitaire <- file.path(dossier_sortie, "par_question")

dir.create(dossier_unitaire, recursive = TRUE, showWarnings = FALSE)

# --- Donnees ----------------------------------------------------------------

fichiers <- list.files(dossier_annot, pattern = "^opubliq-annotations-.*\\.csv$",
                       full.names = TRUE)
annot <- bind_rows(lapply(fichiers, read_csv,
                          col_types = cols(.default = col_character()),
                          progress = FALSE))

stopifnot("mode" %in% names(annot), nrow(annot) > 0)

dico <- read_csv(file.path(racine, "data/organismes/clean/dictionnaire_variables.csv"),
                 col_types = cols(.default = col_character()), progress = FALSE)

# --- Questions meres --------------------------------------------------------
# Trois cas de figure :
#   - "q10-Comment" -> q10 : champ "Autre, precisez" d'une question fermee ;
#   - "q2_1"        -> q2  : sous-question d'une question fermee ;
#   - "q18_3"       -> q18 : sous-item d'une batterie, dont le chapeau n'existe
#                            pas dans le dictionnaire et vient du JSON.
code_mere <- function(v) {
  if (grepl("-Comment$", v)) return(sub("-Comment$", "", v))
  if (grepl("_", v)) return(sub("_.*$", "", v))
  NA_character_
}

# Chapeau de la batterie q18, absent du dictionnaire : recupere dans le
# schema SurveyJS (element html `q18_intro`).
chapeau_q18 <- local({
  j <- fromJSON(file.path(racine, "data/organismes/questionnaire_organismes.json"),
                simplifyVector = FALSE)
  trouve <- NULL
  parcourir <- function(x) {
    if (is.list(x)) {
      if (!is.null(x$name) && identical(x$name, "q18_intro") && !is.null(x$html)) {
        trouve <<- x$html
      }
      for (e in x) parcourir(e)
    }
  }
  parcourir(j)
  if (is.null(trouve)) NA_character_
  else trimws(gsub("[[:space:]]+", " ", gsub("<[^>]*>", " ", trouve)))
})

texte_mere <- function(v) {
  m <- code_mere(v)
  if (is.na(m)) return(NULL)
  if (m == "q18") {
    if (is.na(chapeau_q18)) return(NULL)
    return(list(code = "q18", texte = chapeau_q18))
  }
  i <- match(m, dico$code)
  if (is.na(i)) return(NULL)
  list(code = m, texte = dico$texte_question[i])
}

# --- Echappement LaTeX ------------------------------------------------------

# Les valeurs de `mode` sont des codes ASCII ("telephone") : on les affiche
# avec leur orthographe francaise dans le document.
libelle_mode <- function(x) {
  ifelse(x == "telephone", "téléphone", ifelse(x == "internet", "internet", x))
}

escaper_latex <- function(x) {
  x[is.na(x)] <- ""
  x <- gsub("\u00a0", " ", x)          # espace insecable -> espace normale
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  x <- gsub("([&%$#_{}])", "\\\\\\1", x)
  x <- gsub("~", "\\\\textasciitilde{}", x)
  x <- gsub("\\^", "\\\\textasciicircum{}", x)
  x
}

# Convertit un verbatim en LaTeX : echappement + sauts de ligne transformes en
# paragraphes, pour preserver la mise en forme d'origine des reponses longues.
verbatim_latex <- function(x) {
  x <- escaper_latex(x)
  paragraphes <- unlist(strsplit(x, "\r?\n"))
  paragraphes <- trimws(paragraphes)
  paragraphes <- paragraphes[nzchar(paragraphes)]
  if (length(paragraphes) == 0) paragraphes <- "\\textit{(réponse vide)}"
  paste(paragraphes, collapse = "\n\n")
}

# --- Preambule --------------------------------------------------------------

preambule <- function(titre, sous_titre, avec_toc) {
  c(
    "\\documentclass[11pt,a4paper]{article}",
    "\\usepackage{fontspec}",
    # babel french : traduit les titres automatiques (« Table des matieres »
    # au lieu de « Contents ») ET active la cesure francaise, indispensable
    # sur 187 pages de texte justifie.
    "\\usepackage[french]{babel}",
    "\\usepackage[margin=2.2cm,top=2.4cm,bottom=2.4cm]{geometry}",
    "\\usepackage{xcolor}",
    "\\usepackage{booktabs}",
    "\\usepackage{fancyhdr}",
    "\\usepackage[hidelinks]{hyperref}",
    "\\setmainfont{Latin Modern Roman}",
    paste0("\\hypersetup{pdflang={fr-CA},pdftitle={", escaper_latex(titre),
           "},pdfsubject={", escaper_latex(sous_titre),
           "},pdfcreator={Opubliq},pdfproducer={Opubliq}}"),
    "\\definecolor{gris}{gray}{0.42}",
    "\\definecolor{grisclair}{gray}{0.88}",
    "\\definecolor{bleu}{RGB}{31,78,121}",
    "\\setlength{\\parindent}{0pt}",
    "\\setlength{\\parskip}{0.45em}",
    "\\pagestyle{fancy}",
    "\\fancyhf{}",
    paste0("\\fancyhead[L]{\\small\\color{gris}", escaper_latex(sous_titre), "}"),
    "\\fancyhead[R]{\\small\\color{gris}\\thepage}",
    "\\renewcommand{\\headrulewidth}{0.4pt}",
    "\\usepackage{titlesec}",
    "\\titleformat{\\section}{\\Large\\bfseries\\color{bleu}}{}{0pt}{}",
    "\\titleformat{\\subsection}{\\large\\bfseries}{}{0pt}{}",
    "\\titlespacing*{\\subsection}{0pt}{1.4em}{0.5em}",
    "\\begin{document}",
    "\\begin{center}",
    paste0("{\\LARGE\\bfseries\\color{bleu} ", escaper_latex(titre), "}\\\\[0.6em]"),
    paste0("{\\large ", escaper_latex(sous_titre), "}\\\\[0.4em]"),
    paste0("{\\color{gris}\\small Généré le ", format(Sys.Date(), "%d %B %Y"), "}"),
    "\\end{center}",
    "\\vspace{1em}",
    if (avec_toc) c("\\tableofcontents", "\\newpage") else NULL
  )
}

# --- Rendu d'une question ---------------------------------------------------

bloc_question <- function(v, d) {
  d <- d %>% filter(variable == v)
  q_texte <- unique(d$question_text)[1]
  propriete <- unique(d$propriete_annotee)[1]
  mere <- texte_mere(v)

  out <- character()
  out <- c(out, "", paste0("\\section{", escaper_latex(v), " \\textmd{\\normalsize --- ",
                           escaper_latex(q_texte), "}}"))

  # Encadre de contexte : question mere + consigne d'annotation
  contexte <- character()
  if (!is.null(mere)) {
    contexte <- c(contexte,
      paste0("\\textbf{Question mère (", escaper_latex(mere$code), ")} : ",
             escaper_latex(mere$texte), "\\par"))
  }
  contexte <- c(contexte,
    paste0("\\textbf{Propriété annotée} : \\textit{", escaper_latex(propriete), "}\\par"))

  out <- c(out,
    "\\vspace{0.2em}",
    "{\\color{grisclair}\\hrule}",
    "\\vspace{0.6em}",
    contexte,
    "\\vspace{0.2em}",
    "{\\color{grisclair}\\hrule}",
    "\\vspace{0.9em}")

  # Resume des categories : "non classable" toujours en dernier
  resume <- d %>%
    count(label, name = "n") %>%
    mutate(fourre = grepl("non classable", label, ignore.case = TRUE)) %>%
    arrange(fourre, desc(n), label)
  ventil <- d %>% count(label, mode, name = "n_mode")
  resume <- resume %>%
    mutate(
      internet  = sapply(label, function(l)
        sum(ventil$n_mode[ventil$label == l & ventil$mode == "internet"])),
      telephone = sapply(label, function(l)
        sum(ventil$n_mode[ventil$label == l & ventil$mode == "telephone"])),
      pct = sprintf("%.1f\\%%", 100 * n / nrow(d))
    )

  out <- c(out,
    paste0("\\textbf{Résumé des catégories} \\hfill {\\color{gris}\\small ",
           nrow(resume), " catégories \\textbullet{} ", nrow(d), " réponses (",
           sum(d$mode == "internet"), " internet, ",
           sum(d$mode == "telephone"), " téléphone)}"),
    "\\vspace{0.4em}",
    "",
    "\\begin{tabular}{p{0.52\\textwidth}rrrr}",
    "\\toprule",
    "\\textbf{Catégorie} & \\textbf{n} & \\textbf{\\%} & \\textbf{Int.} & \\textbf{Tél.} \\\\",
    "\\midrule")
  for (i in seq_len(nrow(resume))) {
    out <- c(out, paste0(
      escaper_latex(resume$label[i]), " & ", resume$n[i], " & ", resume$pct[i],
      " & ", resume$internet[i], " & ", resume$telephone[i], " \\\\"))
  }
  out <- c(out, "\\midrule",
    paste0("\\textbf{Total} & \\textbf{", nrow(d), "} & & \\textbf{",
           sum(d$mode == "internet"), "} & \\textbf{",
           sum(d$mode == "telephone"), "} \\\\"),
    "\\bottomrule", "\\end{tabular}", "", "\\vspace{1.2em}")

  # Reponses, regroupees par categorie (ordre du tableau de resume)
  for (lab in resume$label) {
    sous <- d %>%
      filter(label == lab) %>%
      mutate(id_num = as.integer(respondent_id)) %>%
      arrange(id_num)

    out <- c(out, paste0("\\subsection*{", escaper_latex(lab),
                         " \\textmd{\\normalsize(n=", nrow(sous), ")}}"),
             paste0("\\addcontentsline{toc}{subsection}{\\quad ",
                    escaper_latex(lab), " (n=", nrow(sous), ")}"))

    for (i in seq_len(nrow(sous))) {
      out <- c(out,
        paste0("{\\small\\color{gris}\\textbf{\\#", escaper_latex(sous$respondent_id[i]),
               "} \\textbullet{} ", escaper_latex(libelle_mode(sous$mode[i])), "}\\par"),
        "\\vspace{-0.15em}",
        verbatim_latex(sous$text[i]),
        "\\vspace{0.35em}",
        "{\\color{grisclair}\\hrule}",
        "\\vspace{0.55em}")
    }
  }
  out
}

# --- Compilation ------------------------------------------------------------

compiler <- function(lignes, chemin_tex) {
  writeLines(c(lignes, "\\end{document}"), chemin_tex, useBytes = TRUE)
  tinytex::latexmk(chemin_tex, engine = "xelatex")
}

variables <- annot %>%
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

cat("Questions a traiter :", length(variables), "\n\n")

# 1. Document complet
cat("--- Document complet ---\n")
lignes <- preambule(
  "Vérification des annotations qualitatives",
  "Consultation sur les droits des usagers — volet organismes communautaires",
  avec_toc = TRUE)
for (v in variables) {
  cat("  ", v, "\n")
  lignes <- c(lignes, bloc_question(v, annot), "\\clearpage")
}
tex_complet <- file.path(dossier_sortie, "verification_annotations_complet.tex")
compiler(lignes, tex_complet)

# 2. Un document par question
cat("\n--- Documents par question ---\n")
for (v in variables) {
  cat("  ", v, "\n")
  l <- preambule(
    paste0("Vérification des annotations — ", v),
    "Consultation sur les droits des usagers — volet organismes communautaires",
    avec_toc = FALSE)
  l <- c(l, bloc_question(v, annot))
  nom <- paste0("verification_", gsub("-", "_", v), ".tex")
  compiler(l, file.path(dossier_unitaire, nom))
}

# Menage des fichiers auxiliaires LaTeX
aux <- list.files(c(dossier_sortie, dossier_unitaire),
                  pattern = "\\.(aux|log|out|toc|fls|fdb_latexmk|xdv)$",
                  full.names = TRUE)
unlink(aux)

cat("\nPDF complet    :", sub("\\.tex$", ".pdf", tex_complet), "\n")
cat("PDF par question:", dossier_unitaire, "\n")
