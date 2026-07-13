# Génère le dictionnaire des variables du questionnaire "usagers"
# -> data/usagers/clean/dictionnaire_variables.csv
# (construit à la main à partir de questionnaire_usagers.json / _papier.json,
# même logique que le codebook du volet organismes)

library(readr)
library(tibble)

data_dir <- "G:/My Drive/_SharedFolder_CUCI-Est-de-Montréal/data"
chemin_sortie_dir <- file.path(data_dir, "usagers/clean")
dir.create(chemin_sortie_dir, showWarnings = FALSE, recursive = TRUE)

dico <- tribble(
  ~code,            ~section, ~type,   ~sous_type,  ~texte_question,                                                                                                    ~codage,                              ~notes,
  "response_id",     "meta",  "meta",  "id",        "Identifiant de la réponse",                                                                                        "",                                   "",
  "project_id",      "meta",  "meta",  "id",        "Identifiant du projet de sondage",                                                                                 "",                                   "",
  "survey_id",       "meta",  "meta",  "id",        "Identifiant du sondage",                                                                                           "",                                   "",
  "mode",            "meta",  "meta",  "mode",      "Mode de collecte (en_ligne / en_personne)",                                                                        "",                                   "en_personne = interviewer sur place + papier",
  "sous_mode",       "meta",  "meta",  "mode",      "Sous-mode de collecte (repondant / interviewer / papier)",                                                          "",                                   "",
  "submitted_at",    "meta",  "meta",  "date",      "Date/heure de soumission",                                                                                         "",                                   "",
  "q1",  "A", "ferme",  "radiogroup", "Avez-vous déjà entendu parler de l'existence de Comités des usagers ou de résidents (CLSC, hôpitaux, CHSLD) de l'Est-de-l'Île-de-Montréal ?", "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q1_1", "A", "ouvert", "comment",    "1.1 Commentaires (si oui à q1)",                                                                                                  "",                                   "",
  "q2",  "A", "ferme",  "radiogroup", "Avez-vous déjà eu recours à un Comité des usagers de l'Est-de-l'Île-de-Montréal ?",                                               "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q2_1", "A", "ouvert", "comment",    "2.1 Si oui, comment avez-vous trouvé l'expérience ?",                                                                             "",                                   "",
  "q3",  "B", "ferme",  "radiogroup", "De façon générale, avez-vous l'impression que les droits reconnus par les lois sont connus dans la population ?",                 "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q3-Comment", "B", "ouvert", "comment", "Précision \"Autre\" pour q3",                                                                                                  "",                                   "papier seulement (hasOther absent du questionnaire en ligne)",
  "q3_1", "B", "ouvert", "comment",    "3.1 Suggestions pour améliorer la connaissance des droits des usagers",                                                            "",                                   "",
  "q4",  "C", "ferme",  "radiogroup", "De façon générale, avez-vous l'impression que les droits sont respectés dans le milieu de la santé et des services sociaux ?",    "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q4-Comment", "C", "ouvert", "comment", "Précision \"Autre\" pour q4",                                                                                                  "",                                   "papier seulement (hasOther absent du questionnaire en ligne)",
  "q4_1", "C", "ouvert", "comment",    "4.1 Droits qui semblent moins respectés que d'autres",                                                                            "",                                   "",
  "q4_2", "C", "ouvert", "comment",    "4.2 Commentaires sur le respect des droits en général",                                                                           "",                                   "",
  "q5",  "C", "ferme",  "radiogroup", "Avez-vous vécu récemment une situation problématique liée à l'encontre de vos droits (manque d'information, non-respect du consentement, manque de confidentialité, etc.) ?", "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q5_1", "C", "ouvert", "comment",    "5.1 Laquelle ? (si oui à q5)",                                                                                                     "",                                   "",
  "q6_1", "D", "ouvert", "comment",    "Suggestions : Renseigner les usagers sur leurs droits et obligations",                                                            "",                                   "",
  "q6_2", "D", "ouvert", "comment",    "Suggestions : Promouvoir l'amélioration de la qualité de leurs conditions de vie",                                               "",                                   "",
  "q6_3", "D", "ouvert", "comment",    "Suggestions : Participer à l'évaluation du degré de satisfaction envers les services de l'établissement",                        "",                                   "",
  "q6_4", "D", "ouvert", "comment",    "Suggestions : Défendre leurs droits et intérêts collectifs",                                                                      "",                                   "",
  "q6_5", "D", "ouvert", "comment",    "Suggestions : Défendre, sur demande, les droits et intérêts individuels auprès de toute autorité compétente",                    "",                                   "",
  "q6_6", "D", "ouvert", "comment",    "Suggestions : Accompagner et assister, sur demande, dans toute démarche y compris une plainte",                                  "",                                   "",
  "q7",  "E", "ferme",  "radiogroup", "Savez-vous où vous adresser afin d'exprimer une plainte ou une insatisfaction comme usager du réseau ?",                          "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q7_1", "E", "ferme",  "checkbox",   "7.1 Si oui, ce serait auprès de qui ?",                                                                                            "choix multiples, texte \"val1 | val2\"", "conditionnel à q7 = Oui",
  "q7_1-Comment", "E", "ouvert", "comment", "Précision \"Autre\" pour q7_1",                                                                                              "",                                   "",
  "q7_1_organisme", "E", "ouvert", "comment", "Lequel organisme communautaire ? (si q7_1 contient \"organisme\")",                                                        "",                                   "",
  "q7_2", "E", "ouvert", "comment",    "7.2 Commentaires additionnels",                                                                                                   "",                                   "",
  "q8",  "F", "ferme",  "radiogroup", "Fréquentez-vous un organisme communautaire dans un quartier de l'Est de l'Île de Montréal ?",                                     "1=Oui, 2=Non, 9=Ne sais pas", "",
  "q8_1", "F", "ouvert", "text",       "8.1 Si oui, lequel ?",                                                                                                             "",                                   "conditionnel à q8 = Oui",
  "q8_2", "F", "ouvert", "comment",    "8.2 Commentaires additionnels",                                                                                                   "",                                   "",
  "q9",  "F", "ferme",  "radiogroup", "À quel endroit habitez-vous ?",                                                                                                    "nominal, non recodé (est_montreal / grande_region / ailleurs_ile / exterieur_grande_region)", "",
  "q9_1", "F", "ferme",  "radiogroup", "9.1 Si dans l'est de Montréal, quel quartier ?",                                                                                   "nominal, non recodé",                "conditionnel à q9 = est_montreal",
  "q10", "F", "ferme",  "radiogroup", "Quel est votre groupe d'âge ?",                                                                                                     "1=34 ans et -, 2=35 à 44 ans, 3=45 et 64 ans, 4=65 ans et +", "",
  "q11", "F", "ouvert", "text",       "À quelle communauté culturelle appartenez-vous ?",                                                                                  "",                                   "absent du fichier papier (colonne jamais créée)",
  "q12", "F", "ouvert", "comment",    "En conclusion, autres commentaires aux Comités des usagers",                                                                       "",                                   ""
)

write_excel_csv(dico, file.path(chemin_sortie_dir, "dictionnaire_variables.csv"), na = "")
cat("-> Écrit:", file.path(chemin_sortie_dir, "dictionnaire_variables.csv"), "(", nrow(dico), "variables )\n")
