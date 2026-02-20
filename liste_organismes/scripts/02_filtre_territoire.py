"""
02_filtre_territoire.py

Lit tous les bottin211/page_*.csv, assigne une colonne `categorie_territoire`
à chaque organisme selon la logique ci-dessous, et produit
data/02_bottin_territoire.csv (sans colonnes lat/lng).

Catégories (par ordre de priorité) :
  local          — quartiers CIUSSS-Est spécifiques
  montreal       — île de Montréal sans banlieues
  grand_montreal — Grand Montréal / Montréal + banlieues
  provincial     — trop large (Québec, Canada…) ou sans mention de Montréal
  void           — champ territoire vide
"""

import csv
import re
import unicodedata
from pathlib import Path

INPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "bottin211"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "02_bottin_territoire.csv"

CHAMPS = [
    "nom", "adresse", "description", "telephone",
    "courriel", "site_web", "territoire", "clientele",
    "categorie_territoire",
]

# ---------------------------------------------------------------------------
# Termes de la liste blanche LOCAL (quartiers CIUSSS-Est)
# ---------------------------------------------------------------------------
LOCAL_TERMS = [
    "saint-michel",
    "saint-leonard",
    "saint-léonard",
    "pointe-aux-trembles",
    "mercier-est",
    "mercier-ouest",
    "mercier-hochelaga-maisonneuve",
    "montreal-est",
    "montréal-est",
    "montreal-nord",
    "montréal-nord",
    "riviere-des-prairies",
    "rivière-des-prairies",
    "rosemont",
    "est de montreal",
    "est de montréal",
    "est de l'ile",
    "est de l'île",
    "ciusss de l'est",
]

# Termes banlieues (si présents → grand_montreal plutôt que montreal)
SUBURB_TERMS = [
    "laval",
    "longueuil",
    "rive-sud",
    "rive sud",
    "rive-nord",
    "rive nord",
    "repentigny",
    "brossard",
    "terrebonne",
    "blainville",
    "saint-jerome",
    "saint-jérôme",
    "mirabel",
    "vaudreuil",
    "saint-hyacinthe",
]

# Termes provincial / Canada
PROVINCIAL_TERMS = [
    "québec",
    "quebec",
    "province du québec",
    "province of quebec",
    "province du quebec",
    "canada",
    "ontario",
]


def normalize(text: str) -> str:
    """Minuscules + suppression des accents pour comparaisons tolérantes."""
    nfkd = unicodedata.normalize("NFKD", text.lower())
    return "".join(c for c in nfkd if not unicodedata.combining(c))


def contains_any(text_norm: str, terms: list[str]) -> bool:
    return any(normalize(t) in text_norm for t in terms)


def categorize(territoire: str) -> str:
    if not territoire or not territoire.strip():
        return "void"

    t_norm = normalize(territoire)

    # 1. LOCAL — priorité absolue
    if contains_any(t_norm, LOCAL_TERMS):
        return "local"

    # 2. Grand Montréal explicite
    if "grand montreal" in t_norm or "grand montréal" in normalize(territoire):
        return "grand_montreal"

    # Présence de "montreal" / "île de montreal" dans le champ
    has_montreal = bool(re.search(r"\bmontr[eé]al\b", t_norm))
    has_ile = "ile de montreal" in t_norm or "île de montréal" in normalize(territoire)

    # 3. Montréal + banlieue → grand_montreal
    if (has_montreal or has_ile) and contains_any(t_norm, SUBURB_TERMS):
        return "grand_montreal"

    # 4. Montréal seul → montreal
    if has_montreal or has_ile:
        return "montreal"

    # 5. Provincial / trop large
    if contains_any(t_norm, PROVINCIAL_TERMS):
        return "provincial"

    # 6. Aucune mention de Montréal → provincial (trop large ou hors zone)
    return "provincial"


def load_all_pages() -> list[dict]:
    rows = []
    for f in sorted(INPUT_DIR.glob("page_*.csv")):
        with open(f, encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            for row in reader:
                if row.get("nom") and row["nom"] != "void":
                    rows.append(row)
    return rows


def main():
    rows = load_all_pages()
    print(f"{len(rows)} organismes chargés")

    counts: dict[str, int] = {}
    output_rows = []

    for row in rows:
        cat = categorize(row.get("territoire", ""))
        row["categorie_territoire"] = cat
        counts[cat] = counts.get(cat, 0) + 1
        # Construire la ligne de sortie (sans lat/lng)
        output_rows.append({k: row.get(k, "") for k in CHAMPS})

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CHAMPS)
        writer.writeheader()
        writer.writerows(output_rows)

    print(f"\nDécompte par catégorie_territoire :")
    for cat in ("local", "montreal", "grand_montreal", "provincial", "void"):
        n = counts.get(cat, 0)
        print(f"  {cat:<20} {n:>5}")
    print(f"  {'TOTAL':<20} {sum(counts.values()):>5}")
    print(f"\n→ {OUTPUT}")


if __name__ == "__main__":
    main()
