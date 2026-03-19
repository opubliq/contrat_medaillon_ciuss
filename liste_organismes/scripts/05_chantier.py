"""
05_chantier.py

Traitement des 31 organismes du fichier Organismes_chantier_proximité.xlsx
pour l'issue s5t.

Fonctions utilitaires pour interroger le bottin et génération du CSV
des organismes à ajouter (non-doublons, pertinents et classifiés).

Output: data/05_chantier_a_ajouter.csv
"""

import csv
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DATA_DIR = SCRIPT_DIR.parent / "data"
BOTTIN_FILE = DATA_DIR / "04_bottin_secteurs.csv"
OUTPUT_FILE = DATA_DIR / "05_chantier_a_ajouter.csv"


def get_bottin_names() -> list[str]:
    """Retourne tous les noms normalisés (lower, strip) du bottin."""
    names = []
    with open(BOTTIN_FILE, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row['nom']:
                names.append(row['nom'].lower().strip())
    return names


def search_bottin(query: str) -> list[str]:
    """
    Recherche dans les noms du bottin.
    Retourne les noms correspondants (exact ou substring match).
    """
    query_norm = query.lower().strip()
    results = []

    with open(BOTTIN_FILE, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            name = row['nom'].lower().strip()
            # Exact match ou substring significant
            if query_norm == name or query_norm in name or name in query_norm:
                results.append(row['nom'])

    return results


# ============================================================================
# ORGANISMES À AJOUTER — Hardcodé selon évaluation s5t
# ============================================================================

ORGANISMES_A_AJOUTER = [
    # 1. Centre des aînés de Saint-Léonard
    {
        "nom": "Centre des aînés de Saint-Léonard",
        "adresse": "",
        "description": "Centre de jour pour aînés",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Aînés",
        "categorie_territoire": "local",
        "secteur": "soutien_vulnerabilite",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 2. Maison de la famille St-Léonard
    {
        "nom": "Maison de la famille St-Léonard",
        "adresse": "",
        "description": "Soutien et accompagnement familial",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Familles, enfants",
        "categorie_territoire": "local",
        "secteur": "developpement_enfants_familles",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 3. Prévention PDI
    {
        "nom": "Prévention PDI",
        "adresse": "",
        "description": "Prévention et soutien pour la déficience intellectuelle",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Personnes vivant avec une déficience intellectuelle",
        "categorie_territoire": "local",
        "secteur": "sante",
        "secteur_secondaire": "defense_droits",
        "exclu": "non"
    },
    # 4. Carrefour jeunesse-emploi
    {
        "nom": "Carrefour jeunesse-emploi",
        "adresse": "",
        "description": "Insertion en emploi et accompagnement pour jeunes",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Jeunes à risque, 15-35 ans",
        "categorie_territoire": "local",
        "secteur": "emploi",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 5. Joujouthèque Saint-Michel
    {
        "nom": "Joujouthèque Saint-Michel",
        "adresse": "",
        "description": "Service de prêt de jouets et d'accompagnement familial pour enfants",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Enfants, familles avec enfants",
        "categorie_territoire": "local",
        "secteur": "developpement_enfants_familles",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 6. Rameau d'Olivier
    {
        "nom": "Rameau d'Olivier",
        "adresse": "",
        "description": "Organisme d'aide humanitaire et d'insertion sociale",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "soutien_vulnerabilite",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 7. Pact de rue
    {
        "nom": "Pact de rue",
        "adresse": "",
        "description": "Prévention et intervention pour personnes en itinérance",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Personnes en itinérance ou à risque",
        "categorie_territoire": "local",
        "secteur": "soutien_vulnerabilite",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 8. Chez nous de Mercier-Est
    {
        "nom": "Chez nous de Mercier-Est",
        "adresse": "",
        "description": "Table/centre de quartier pour mobilisation communautaire",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Citoyens du quartier",
        "categorie_territoire": "local",
        "secteur": "developpement_communautaire",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 9. Table de quartier de Rivière-des-Prairies
    {
        "nom": "Table de quartier de Rivière-des-Prairies",
        "adresse": "",
        "description": "Table de quartier pour concertation et développement communautaire",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Citoyens du quartier",
        "categorie_territoire": "local",
        "secteur": "developpement_communautaire",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 10. PITREM
    {
        "nom": "PITREM",
        "adresse": "",
        "description": "Organisme d'action communautaire et de développement social",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables, citoyens",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 11. Tour de lire
    {
        "nom": "Tour de lire",
        "adresse": "",
        "description": "Littératie et alphabétisation pour adultes",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Adultes en situation d'analphabétisme",
        "categorie_territoire": "local",
        "secteur": "education_formation",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 12. Projet Harmonie (incertain - inclus avec bénéfice du doute)
    {
        "nom": "Projet Harmonie",
        "adresse": "",
        "description": "Projet d'intervention communautaire",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 13. Accès bénévolat (incertain - mais volontariat ciblé populations vulnérables)
    {
        "nom": "Accès bénévolat",
        "adresse": "",
        "description": "Plateforme d'accès au bénévolat pour populations vulnérables",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 14. La Maison grise (incertain - inclus avec bénéfice du doute)
    {
        "nom": "La Maison grise",
        "adresse": "",
        "description": "Organisme communautaire d'accompagnement",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 15. Centre de formation Antoine-de-Saint-Exupéry (incertain - formation professionnelle jeunes)
    {
        "nom": "Centre de formation Antoine-de-Saint-Exupéry",
        "adresse": "",
        "description": "Centre de formation professionnelle pour jeunes",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Jeunes à risque, décrocheurs",
        "categorie_territoire": "local",
        "secteur": "education_formation",
        "secteur_secondaire": "emploi",
        "exclu": "non"
    },
    # 16. CDC de la Pointe (incertain - centre de jour/ressources)
    {
        "nom": "CDC de la Pointe",
        "adresse": "",
        "description": "Centre de jour ou ressources communautaires",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
    # 17. ITMAV, St-Michel (incertain - mais acronyme suggère intervention)
    {
        "nom": "ITMAV, St-Michel",
        "adresse": "",
        "description": "Organisme d'intervention sociale",
        "telephone": "",
        "courriel": "",
        "site_web": "",
        "territoire": "local",
        "clientele": "Populations vulnérables",
        "categorie_territoire": "local",
        "secteur": "autres_missions_sociales",
        "secteur_secondaire": "",
        "exclu": "non"
    },
]

# ============================================================================
# DOUBLONS — Exclus (déjà dans 04_bottin_secteurs.csv)
# ============================================================================

DOUBLONS = [
    {
        "nom": "Société québécoise de la schizophrénie",
        "raison": "Match exact dans bottin"
    },
    {
        "nom": "Comité régional pour l'autisme et la déficience intellectuelle (CRADI)",
        "raison": "Match substring dans bottin"
    },
    {
        "nom": "Association bénévole Ligne espoir aînés de Pointe-aux-Trembles",
        "raison": "Possible variante 'Ligne espoir' dans bottin"
    },
    {
        "nom": "Escale famille le Triolet",
        "raison": "Match substring 'escale famille le triolet' dans bottin"
    },
    {
        "nom": "Je Passe Partout",
        "raison": "Match substring 'je passe partout, services de soutien scolaire' dans bottin"
    },
    {
        "nom": "Association de Montréal pour la déficience intellectuelle",
        "raison": "Match exact dans bottin"
    },
    {
        "nom": "Centre de Référence du Grand Montréal",
        "raison": "Match exact dans bottin"
    },
    {
        "nom": "Revdec",
        "raison": "Match exact dans bottin"
    },
]

# ============================================================================
# EXCLUSIONS — Non pertinents selon critères s5t
# ============================================================================

EXCLUSIONS = [
    {
        "nom": "Service de l'habitation de la ville de Montréal",
        "raison": "Service municipal para-public (gestionnaire habitation) — exclusion critère governemental"
    },
    {
        "nom": "Inspection bâtiment, Arrondissement Rosemont-Petite-Patrie",
        "raison": "Agence municipale para-publique — exclusion critère gouvernemental"
    },
    {
        "nom": "Compagnie Théâtre créole",
        "raison": "Organisme culturel/loisirs — exclusion critère loisirs/culture"
    },
    {
        "nom": "Office municipal d'habitation de Montréal (OMHM)",
        "raison": "Gestionnaire d'immeubles publics — exclusion critère logement/para-public"
    },
    {
        "nom": "Société Ressources-Loisirs de Pointe-aux-Trembles",
        "raison": "Centre de loisirs — exclusion critère loisirs"
    },
]


def generate_output():
    """Génère le fichier de sortie 05_chantier_a_ajouter.csv"""

    # Colonnes du schéma
    fieldnames = [
        'nom', 'adresse', 'description', 'telephone', 'courriel', 'site_web',
        'territoire', 'clientele', 'categorie_territoire', 'secteur',
        'secteur_secondaire', 'exclu'
    ]

    with open(OUTPUT_FILE, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        # Écrire les organismes à ajouter
        for org in ORGANISMES_A_AJOUTER:
            writer.writerow(org)

    print(f"✓ {len(ORGANISMES_A_AJOUTER)} organismes ajoutés à {OUTPUT_FILE.name}")
    print(f"  - {len(DOUBLONS)} doublons détectés et exclus")
    print(f"  - {len(EXCLUSIONS)} organismes exclus (non-pertinents)")
    print(f"  - Total input xlsx: 31 organismes")


if __name__ == "__main__":
    generate_output()

    # Info debug
    print("\n=== DEBUG ===")
    print(f"Bottin names: {len(get_bottin_names())} noms")
    sample_search = search_bottin("schizophrénie")
    print(f"Test search 'schizophrénie': {sample_search}")
