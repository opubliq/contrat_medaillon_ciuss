"""
03_filtre_llm.py

Filtre de pertinence LLM entre l'étape territoire (02) et la classification
secteur (04). Conserve uniquement les organismes qui servent des populations
vulnérables ou défendent leurs droits.

Input:  data/02_bottin_territoire.csv
Output: data/03_bottin_pertinent.csv  (toutes les colonnes de l'input + pertinent + raison)
"""

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
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "03_bottin_pertinent.csv"

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.0-flash"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

SYSTEM_PROMPT = """Tu es un assistant qui évalue la pertinence d'organismes communautaires pour un projet du CIUSSS de l'Est de Montréal.

EXCLUSIONS ABSOLUES — réponds toujours "non" si l'organisme est :
- Un établissement de santé ou d'hébergement institutionnel, qu'il soit public ou privé : CIUSSS, CISSS, hôpital, CHSLD, centre de réadaptation, résidence privée pour aînés (RPA), clinique, centre hospitalier.
- Un organisme gouvernemental ou para-public : commissaire aux plaintes, comité d'usagers d'un établissement public, agence gouvernementale.
Un organisme communautaire ACCOMPAGNE ou DÉFEND des personnes vulnérables — il n'est pas lui-même l'institution qui les héberge ou les traite. Si l'organisme EST l'institution (même si sa clientèle est vulnérable), c'est "non".

DISTINCTION CLÉ : SERVICES DIRECTS vs LOISIRS/SPORTS
La mission de l'organisme doit être centrée sur des services directs (ex: santé, services sociaux, accompagnement, défense de droits) aux populations vulnérables.
Réponds "non" si l'organisme est principalement un club de loisirs, une association sportive ou un organisme culturel, même si sa clientèle inclut des personnes aînées ou handicapées.
Exemples d'exclusion : centres de loisirs généraux, clubs sportifs, organismes culturels.

RÈGLE PRINCIPALE : réponds "oui" si et seulement si, après avoir vérifié les exclusions ci-dessus, le nom, la description OU la clientèle de l'organisme mentionne EXPLICITEMENT une population vulnérable ou une mission de défense de droits.

Populations vulnérables (suffisent à elles seules pour répondre "oui") :
- Aînés, personnes âgées
- Personnes en situation d'itinérance, sans-abri
- Femmes victimes de violence, violence conjugale
- Personnes avec dépendances (alcool, drogues)
- Personnes avec problèmes de santé mentale
- Familles en difficulté, familles à risque
- Immigrants, réfugiés, demandeurs d'asile
- Enfants ou jeunes à risque, décrocheurs
- Personnes handicapées (physique ou intellectuel)
- Personnes en situation de pauvreté, précarité

Défense de droits (suffisent à elles seules pour répondre "oui") :
- Droits des locataires
- Droits des usagers du système de santé
- Droits des femmes
- Droits des immigrants
- Accès à la justice pour personnes défavorisées

Si aucune population vulnérable ni mission de défense de droits n'est mentionnée explicitement → "non", peu importe si c'est possible en arrière-plan.

Réponds UNIQUEMENT en JSON valide, sans markdown :
{"pertinent": "oui" ou "non", "raison": "explication courte en 1-2 phrases"}"""


def filter_org(nom, description, clientele):
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
    # Normaliser la valeur pertinent
    pertinent = str(result.get("pertinent", "")).strip().lower()
    if pertinent not in ("oui", "non"):
        pertinent = "non"
    raison = str(result.get("raison", "")).strip()
    return pertinent, raison


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
    fieldnames_in = list(rows[0].keys()) if rows else []
    print(f"{len(rows)} organismes chargés depuis {INPUT.name}")

    rows = deduplicate(rows)
    print(f"{len(rows)} organismes après déduplication sur (nom, adresse)")

    if args.sample > 0:
        rows = random.sample(rows, min(args.sample, len(rows)))
        print(f"Mode sample: {len(rows)} organismes sélectionnés\n")

    champs_out = fieldnames_in + ["pertinent", "raison"]

    results = []
    retries = []
    pending_flush = []

    if args.sample == 0:
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        csv_file = open(OUTPUT, "w", newline="", encoding="utf-8")
        writer = csv.DictWriter(csv_file, fieldnames=champs_out, extrasaction="ignore")
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
    if not row.get("courriel", "").strip():
        row["pertinent"] = "non"
        row["raison"] = "Courriel manquant"
        return row
    if "@ssss.gouv.qc.ca" in row.get("courriel", "").strip().lower():
        row["pertinent"] = "non"
        row["raison"] = "Courriel @ssss.gouv.qc.ca — entité gouvernementale CIUSSS/CISSS hors scope"
        return row
    try:
        pertinent, raison = filter_org(row["nom"], row["description"], row.get("clientele", ""))
        row["pertinent"] = pertinent
        row["raison"] = raison
    except Exception as e:
        if is_429(e):
            print(f"  [429] {row['nom'][:50]} — sera retenté à la fin")
            row["pertinent"] = "429"
            row["raison"] = ""
            retries.append(row)
        else:
            print(f"  Erreur pour [{row['nom'][:50]}]: {e}")
            row["pertinent"] = "ERREUR"
            row["raison"] = str(e)
    return row

    for i, row in enumerate(rows):
        row = process_row(i, row)
        results.append(row)
        if row["pertinent"] not in ("429",):
            label = "OUI" if row["pertinent"] == "oui" else "NON"
            print(f"  [{label}] {row['nom'][:70]}")
            if writer:
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
                pertinent, raison = filter_org(row["nom"], row["description"], row.get("clientele", ""))
                row["pertinent"] = pertinent
                row["raison"] = raison
            except Exception as e:
                print(f"  Erreur (retry) pour [{row['nom'][:50]}]: {e}")
                row["pertinent"] = "ERREUR"
                row["raison"] = str(e)
            label = "OUI" if row["pertinent"] == "oui" else "NON"
            print(f"  [{label}] {row['nom'][:70]}")
            if writer:
                pending_flush.append(row)
            if (i + 1) % 14 == 0:
                flush_pending()
                time.sleep(1)
            elif len(pending_flush) >= 10:
                flush_pending()

        flush_pending()

    if csv_file:
        csv_file.close()

    total = len(results)
    total_oui = sum(1 for r in results if r["pertinent"] == "oui")
    total_non = sum(1 for r in results if r["pertinent"] == "non")
    total_err = sum(1 for r in results if r["pertinent"] == "ERREUR")
    total_429 = sum(1 for r in results if r["pertinent"] == "429")

    if args.sample > 0:
        print(f"\nSample terminé — {total} organismes évalués:")
        print(f"  oui    : {total_oui}")
        print(f"  non    : {total_non}")
        if total_err:
            print(f"  erreurs: {total_err}")
        return

    print(f"\nTerminé. {total} organismes évalués.")
    print(f"  pertinent (oui): {total_oui}")
    print(f"  exclus    (non): {total_non}")
    if total_err:
        print(f"  erreurs        : {total_err}")
    if total_429:
        print(f"  non-résolus 429: {total_429}")
    print(f"\n  → {OUTPUT}")


if __name__ == "__main__":
    main()
