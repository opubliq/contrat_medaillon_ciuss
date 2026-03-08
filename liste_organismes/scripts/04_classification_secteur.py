import argparse
import csv
import json
import os
import random
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent.parent / ".env")

INPUT = Path(__file__).resolve().parent.parent / "data" / "02_bottin_territoire.csv"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "04_bottin_secteurs.csv"
CHAMPS_IN = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele", "categorie_territoire"]
CHAMPS_OUT = CHAMPS_IN + ["secteur", "secteur_secondaire"]

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.0-flash"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

TAXONOMIE = [
    "action_communautaire",
    "aines",
    "alimentation",
    "education_alphabetisation",
    "enfance_jeunesse_famille",
    "itinerance",
    "justice_defense_droits",
    "sante_mentale_dependances",
    "violence_maltraitance",
    "autre",
]

SYSTEM_PROMPT = f"""Tu es un assistant qui classifie des organismes communautaires par secteur d'activité pour un projet du CIUSSS de l'Est de Montréal.

Assigne UN secteur principal obligatoire et optionnellement un deuxième secteur secondaire (laisser vide si aucun ne s'applique clairement).

Taxonomie autorisée:
- action_communautaire — centres communautaires, maisons de quartier, regroupements, organismes à vocation générale
- aines — services spécifiques aux personnes âgées, maintien à domicile, socialisation des aînés
- alimentation — banques alimentaires, popotes roulantes, cuisines collectives, sécurité alimentaire
- education_alphabetisation — alphabétisation, francisation, formation de base, raccrochage scolaire
- enfance_jeunesse_famille — 0-18 ans, famille, enfance, périnatalité, parentalité
- itinerance — personnes sans domicile fixe, hébergement d'urgence, prévention de l'itinérance
- justice_defense_droits — défense des droits (locataires, aînés, femmes, usagers, immigrants), accès à la justice
- sante_mentale_dependances — soutien psychosocial, crise, rétablissement, alcool, drogues, jeu
- violence_maltraitance — violence conjugale, agressions sexuelles, maltraitance des aînés, protection
- autre — ne rentre dans aucune catégorie ci-dessus

Réponds UNIQUEMENT en JSON valide, sans markdown:
{{"secteur": "nom_du_secteur", "secteur_secondaire": "nom_ou_vide"}}"""


def classify(nom, description, clientele):
    prompt = f"Organisme: {nom}\nDescription: {description}\nClientèle: {clientele}"
    payload = {
        "system_instruction": {"parts": [{"text": SYSTEM_PROMPT}]},
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {"temperature": 0.0},
    }
    resp = requests.post(f"{API_URL}?key={API_KEY}", json=payload, timeout=15)
    resp.raise_for_status()
    text = resp.json()["candidates"][0]["content"]["parts"][0]["text"]
    text = text.strip().removeprefix("```json").removesuffix("```").strip()
    result = json.loads(text)
    # Valider que le secteur est dans la taxonomie
    if result.get("secteur") not in TAXONOMIE:
        result["secteur"] = "autre"
    if result.get("secteur_secondaire") and result["secteur_secondaire"] not in TAXONOMIE:
        result["secteur_secondaire"] = ""
    return result


def is_429(e):
    return hasattr(e, "response") and e.response is not None and e.response.status_code == 429


def load_input():
    with open(INPUT, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def deduplicate(rows):
    seen = set()
    deduped = []
    for row in rows:
        key = (row["nom"].strip().lower(), row["adresse"].strip().lower())
        if key not in seen:
            seen.add(key)
            deduped.append(row)
    return deduped


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample", type=int, default=0, help="Nombre d'orgs random à tester")
    args = parser.parse_args()

    if not API_KEY:
        print("GEMINI_API_KEY manquante dans .env")
        return

    rows = load_input()
    print(f"{len(rows)} organismes chargés depuis {INPUT.name}")

    rows = deduplicate(rows)
    print(f"{len(rows)} organismes après déduplication sur nom")

    if args.sample > 0:
        rows = random.sample(rows, min(args.sample, len(rows)))
        print(f"Mode sample: {len(rows)} organismes sélectionnés\n")

    results = []
    retries = []
    pending_flush = []  # lignes accumulées en attente d'écriture

    if args.sample == 0:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        csv_file = open(OUTPUT, "w", newline="", encoding="utf-8")
        writer = csv.DictWriter(csv_file, fieldnames=CHAMPS_OUT, extrasaction="ignore")
        writer.writeheader()
        csv_file.flush()
    else:
        csv_file = None
        writer = None

    def flush_pending():
        if writer and pending_flush:
            writer.writerows(pending_flush)
            csv_file.flush()
            pending_flush.clear()

    def process_row(i, row):
        try:
            result = classify(row["nom"], row["description"], row["clientele"])
            row["secteur"] = result["secteur"]
            row["secteur_secondaire"] = result.get("secteur_secondaire", "")
        except Exception as e:
            if is_429(e):
                print(f"  [429] {row['nom'][:50]} — sera retenté à la fin")
                row["secteur"] = "429"
                row["secteur_secondaire"] = ""
                retries.append(row)
            else:
                print(f"  Erreur pour [{row['nom'][:50]}]: {e}")
                row["secteur"] = "ERREUR"
                row["secteur_secondaire"] = ""
        return row

    for i, row in enumerate(rows):
        row = process_row(i, row)
        results.append(row)
        if row["secteur"] not in ("429",):
            sec = f" / {row['secteur_secondaire']}" if row.get("secteur_secondaire") else ""
            print(f"  [{row['secteur']}{sec}] {row['nom'][:80]}")
            if writer and row["secteur"] != "autre":
                pending_flush.append(row)

        if (i + 1) % 14 == 0:
            flush_pending()
            time.sleep(1)
        elif len(pending_flush) >= 10:
            flush_pending()

    flush_pending()

    # Retry des 429
    if retries:
        print(f"\n--- Retry de {len(retries)} organismes avec erreur 429 (attente 60s) ---")
        time.sleep(60)
        for i, row in enumerate(retries):
            try:
                result = classify(row["nom"], row["description"], row["clientele"])
                row["secteur"] = result["secteur"]
                row["secteur_secondaire"] = result.get("secteur_secondaire", "")
            except Exception as e:
                print(f"  Erreur (retry) pour [{row['nom'][:50]}]: {e}")
                row["secteur"] = "ERREUR"
                row["secteur_secondaire"] = ""
            sec = f" / {row['secteur_secondaire']}" if row.get("secteur_secondaire") else ""
            print(f"  [{row['secteur']}{sec}] {row['nom'][:80]}")
            if writer and row["secteur"] != "autre":
                pending_flush.append(row)
            if (i + 1) % 14 == 0:
                flush_pending()
                time.sleep(1)
            elif len(pending_flush) >= 10:
                flush_pending()

        flush_pending()

    if csv_file:
        csv_file.close()

    if args.sample > 0:
        from collections import Counter
        dist = Counter(r["secteur"] for r in results)
        print(f"\nSample terminé — distribution des secteurs:")
        for secteur, count in sorted(dist.items(), key=lambda x: -x[1]):
            print(f"  {secteur}: {count}")
        return

    # Distribution des secteurs
    from collections import Counter
    dist = Counter(r["secteur"] for r in results)
    total = len(results)
    total_err = sum(1 for r in results if r["secteur"] == "ERREUR")
    total_429 = sum(1 for r in results if r["secteur"] == "429")

    print(f"\nTerminé. {total} organismes classifiés.")
    print(f"\nDistribution des secteurs:")
    for secteur, count in sorted(dist.items(), key=lambda x: -x[1]):
        print(f"  {secteur}: {count}")
    if total_err:
        print(f"\n  {total_err} erreurs")
    if total_429:
        print(f"  {total_429} non-résolus après retry (429)")
    print(f"\n  → {OUTPUT}")


if __name__ == "__main__":
    main()
