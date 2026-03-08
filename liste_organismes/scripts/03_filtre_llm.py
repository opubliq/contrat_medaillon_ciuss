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

SYSTEM_PROMPT = """Tu es un assistant qui classifie des organismes pour un projet de consultation du CIUSSS de l'Est de l'Île-de-Montréal.

Le CIUSSS veut consulter les organismes communautaires qui SERVENT DIRECTEMENT ou DÉFENDENT ACTIVEMENT les droits des personnes en situation de vulnérabilité: personnes âgées, personnes en situation d'itinérance, personnes avec problèmes de santé mentale ou de dépendance, personnes victimes de violence ou de maltraitance, familles en difficulté, personnes à faible revenu, personnes immigrantes, jeunes à risque.

Tu dois classifier chaque organisme comme PERTINENT ou NON-PERTINENT.

PERTINENT — organismes qui SERVENT ou DÉFENDENT des personnes vulnérables:
- Organismes offrant des services directs aux personnes vulnérables (hébergement d'urgence, aide alimentaire, soutien psychosocial, accompagnement)
- Défense des droits de personnes vulnérables (locataires précaires, personnes itinérantes, aînés maltraités, victimes de violence, personnes en situation de pauvreté)
- Santé mentale communautaire, dépendances, réinsertion sociale
- Organismes pour aînés en perte d'autonomie ou isolés
- Organismes pour familles en difficulté, enfants à risque, jeunes en situation précaire
- Groupes d'alphabétisation et intégration sociale des immigrants vulnérables
- Centres de femmes ou organismes contre la violence conjugale et sexuelle
- Organismes pour personnes en situation d'itinérance ou à risque
- Justice et défense des droits de groupes marginalisés

NON-PERTINENT — exclure systématiquement:
- Services gouvernementaux ou paragovernementaux (CLSC, hôpitaux, CSSS, écoles publiques, bibliothèques municipales)
- Entreprises privées, cliniques privées, cabinets de professionnels
- Clubs sportifs récréatifs (hockey mineur, soccer, natation récréative, etc.)
- Organismes culturels, artistiques ou patrimoniaux sans mission sociale directe envers des personnes vulnérables (chorales, troupes de théâtre, sociétés d'histoire, etc.)
- Services purement récréatifs ou de loisirs (camps de jour ordinaires, piscines, arénas, centres de plein air)
- Associations à mission économique, commerciale ou d'affaires (chambres de commerce, associations de commerçants, clubs d'entrepreneurs)
- Associations professionnelles ou syndicales (sans mission directe envers des personnes vulnérables)
- Organismes religieux à mission exclusivement cultuelle (sans services sociaux aux personnes vulnérables)
- Lignes téléphoniques ou ressources générales (911, 811, 211, etc.)
- Organismes à portée exclusivement provinciale ou nationale sans ancrage local et sans services directs

RÈGLE CRITIQUE: Un organisme culturel, sportif, récréatif ou économique qui offre aussi des activités ouvertes à tous n'est PAS pertinent, même s'il accueille parfois des personnes vulnérables. L'organisme doit avoir pour mission PRINCIPALE de servir ou défendre des personnes en situation de vulnérabilité.

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


def is_429(e):
    return hasattr(e, "response") and e.response is not None and e.response.status_code == 429


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
    retries = []  # lignes avec erreur 429 à refaire à la fin
    pending_flush = []  # lignes pertinentes en attente d'écriture

    if args.sample == 0:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        csv_file = open(OUTPUT, "w", newline="", encoding="utf-8")
        writer = csv.DictWriter(csv_file, fieldnames=CHAMPS_OUT)
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
            row["pertinent"] = result["pertinent"]
            row["raison"] = result["raison"]
        except Exception as e:
            if is_429(e):
                print(f"  [429] {row['nom'][:50]} — sera retenté à la fin")
                row["pertinent"] = "429"
                row["raison"] = "429"
                retries.append(row)
            else:
                print(f"  Erreur pour [{row['nom'][:50]}]: {e}")
                row["pertinent"] = "ERREUR"
                row["raison"] = str(e)
        return row

    for i, row in enumerate(rows):
        row = process_row(i, row)
        results.append(row)
        tag = "OUI" if row["pertinent"] is True else "NON" if row["pertinent"] is False else f"[{row['pertinent']}]"
        if row["pertinent"] not in ("429",):
            print(f"  [{tag}] {row['nom'][:80]} — {row['raison'][:120]}")
            if row["pertinent"] is True and writer:
                pending_flush.append(row)

        if (i + 1) % 14 == 0:
            flush_pending()
            time.sleep(1)  # rate limit 15 req/min
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
                row["pertinent"] = result["pertinent"]
                row["raison"] = result["raison"]
            except Exception as e:
                print(f"  Erreur (retry) pour [{row['nom'][:50]}]: {e}")
                row["pertinent"] = "ERREUR"
                row["raison"] = str(e)
            tag = "OUI" if row["pertinent"] is True else "NON" if row["pertinent"] is False else "???"
            print(f"  [{tag}] {row['nom'][:80]} — {row['raison'][:120]}")
            if row["pertinent"] is True and writer:
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
        pertinents = sum(1 for r in results if r["pertinent"] is True)
        print(f"\nSample terminé: {pertinents}/{len(results)} pertinents")
        return

    total_p = sum(1 for r in results if r["pertinent"] is True)
    total_np = sum(1 for r in results if r["pertinent"] is False)
    total_err = sum(1 for r in results if r["pertinent"] == "ERREUR")
    total_429 = sum(1 for r in results if r["pertinent"] == "429")
    print(f"\nTerminé.")
    print(f"  {total_p} pertinents")
    print(f"  {total_np} non-pertinents")
    if total_err:
        print(f"  {total_err} erreurs")
    if total_429:
        print(f"  {total_429} non-résolus après retry (429)")
    print(f"  → {OUTPUT}")


if __name__ == "__main__":
    main()
