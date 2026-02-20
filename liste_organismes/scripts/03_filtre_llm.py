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
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "03_bottin_llm_filtre.csv"
CHAMPS_IN = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele", "categorie_territoire"]
CHAMPS_OUT = CHAMPS_IN + ["pertinent", "raison"]

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.0-flash"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

SYSTEM_PROMPT = """Tu es un assistant qui classifie des organismes pour un projet de consultation du CIUSS de l'Est de Montréal.

Le CIUSS veut consulter les organismes COMMUNAUTAIRES et SOCIÉTAUX de son territoire pour comprendre comment mieux accompagner la population dans la défense des droits et l'accès aux services de santé.

Tu dois classifier chaque organisme comme PERTINENT ou NON-PERTINENT.

PERTINENT — organismes à vocation communautaire ou sociétale:
- Aide alimentaire, hébergement, soutien aux personnes vulnérables
- Défense des droits (locataires, aînés, immigrants, femmes, etc.)
- Intégration des immigrants, alphabétisation
- Santé mentale, dépendances, soutien psychosocial
- Organismes pour aînés, jeunes, familles
- Centres communautaires, maisons de quartier
- Organismes d'employabilité, insertion sociale
- Regroupements d'organismes communautaires

NON-PERTINENT — exclure:
- Services gouvernementaux ou paragovernementaux (CLSC, hôpitaux, écoles publiques)
- Entreprises privées, cliniques privées
- Clubs sportifs récréatifs (hockey mineur, soccer, etc.)
- Organismes culturels/artistiques sans mission sociale
- Services purement récréatifs (camps de jour, piscines, arénas)
- Lignes téléphoniques générales (911, 811, 211, etc.)
- Organismes à portée provinciale/nationale sans ancrage local
- Associations à mission économique ou d'affaires (ex: Association des gens d'affaires — mission économique, pas communautaire/sociale)

Réponds UNIQUEMENT en JSON valide, sans markdown:
{"pertinent": true/false, "raison": "explication courte"}"""


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
    return json.loads(text)


def load_input():
    with open(INPUT, encoding="utf-8") as f:
        return list(csv.DictReader(f))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--sample", type=int, default=0, help="Nombre d'orgs random à tester")
    args = parser.parse_args()

    if not API_KEY:
        print("GEMINI_API_KEY manquante dans .env")
        return

    rows = load_input()
    print(f"{len(rows)} organismes chargés depuis {INPUT.name}")

    if args.sample > 0:
        rows = random.sample(rows, min(args.sample, len(rows)))
        print(f"Mode sample: {len(rows)} organismes sélectionnés\n")

    results = []
    for i, row in enumerate(rows):
        try:
            result = classify(row["nom"], row["description"], row["clientele"])
            row["pertinent"] = result["pertinent"]
            row["raison"] = result["raison"]
        except Exception as e:
            print(f"  Erreur pour [{row['nom'][:50]}]: {e}")
            row["pertinent"] = "ERREUR"
            row["raison"] = str(e)

        results.append(row)
        tag = "OUI" if row["pertinent"] is True else "NON" if row["pertinent"] is False else "???"
        print(f"  [{tag}] {row['nom'][:80]} — {row['raison'][:120]}")

        if (i + 1) % 14 == 0:
            time.sleep(1)  # rate limit 15 req/min

    if args.sample > 0:
        pertinents = sum(1 for r in results if r["pertinent"] is True)
        print(f"\nSample terminé: {pertinents}/{len(results)} pertinents")
        return

    # Full run: save
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pertinents = [r for r in results if r["pertinent"] is True]
    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CHAMPS_OUT)
        writer.writeheader()
        writer.writerows(pertinents)

    total_p = len(pertinents)
    total_np = sum(1 for r in results if r["pertinent"] is False)
    total_err = sum(1 for r in results if r["pertinent"] == "ERREUR")
    print(f"\nTerminé.")
    print(f"  {total_p} pertinents")
    print(f"  {total_np} non-pertinents")
    if total_err:
        print(f"  {total_err} erreurs")
    print(f"  → {OUTPUT}")


if __name__ == "__main__":
    main()
