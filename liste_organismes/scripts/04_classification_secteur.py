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

INPUT = Path(__file__).resolve().parent.parent / "data" / "03_bottin_pertinent.csv"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "04_bottin_secteurs.csv"
CHAMPS_IN = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele", "categorie_territoire"]
CHAMPS_OUT = CHAMPS_IN + ["secteur", "secteur_secondaire"]

API_KEY = os.getenv("GEMINI_API_KEY")
MODEL = "gemini-2.0-flash"
API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL}:generateContent"

# Taxonomie officielle ISQ — Enquête québécoise auprès des organismes d'action communautaire (EQOAC) 2023
# Source : https://statistique.quebec.ca/fr/fichier/action-communautaire-2023.pdf — pages 79-82
# Table de référence complète : liste_organismes/ref/taxonomie_isq_eqoac_2023.csv
TAXONOMIE = [
    "arts_culture_medias",
    "bien_etre_alimentaire",
    "defense_droits",
    "developpement_communautaire",
    "developpement_enfants_familles",
    "education_formation",
    "emploi",
    "environnement",
    "logement",
    "sante",
    "soutien_vulnerabilite",
    "sports_loisirs_tourisme",
    "autres_missions_sociales",
]

SYSTEM_PROMPT = """Tu es un assistant qui classifie des organismes communautaires par domaine de mission sociale pour un projet du CIUSSS de l'Est de Montréal.

Utilise la classification officielle de l'ISQ (Enquête québécoise auprès des organismes d'action communautaire, EQOAC 2023).

Assigne UN domaine principal obligatoire et optionnellement un domaine secondaire (laisser vide si aucun ne s'applique clairement).

Domaines autorisés (code : libellé officiel — description et exemples) :

- arts_culture_medias : Arts, culture et médias — Favoriser l'accès et la participation à l'art, à la culture et aux médias d'information. Ex. : arts visuels, théâtre, musique, chant choral, cinéma, journal local, radio communautaire, médias en ligne.

- bien_etre_alimentaire : Bien-être alimentaire — Œuvrer au bien-être et à la sécurité alimentaire. Ex. : repas à domicile, cuisines collectives, banques alimentaires, popotes roulantes, épiceries solidaires.

- defense_droits : Défense des droits — Promouvoir et défendre les droits et les intérêts de la population ou de groupes particuliers ; éducation populaire autonome ; mobilisation sociale. Ex. : droits des locataires, femmes, LGBTQ+, prestataires, personnes judiciarisées, aide juridique.

- developpement_communautaire : Développement communautaire — Améliorer les conditions de vie ou la vitalité d'un quartier ou territoire ; favoriser le sentiment d'appartenance, la concertation, la lutte contre la pauvreté et l'exclusion sociale. Ex. : maisons de quartier, tables de concertation, inclusion sociale, développement local.

- developpement_enfants_familles : Développement des enfants et des familles — Favoriser le développement et l'épanouissement des enfants (0-18 ans), des jeunes et des familles ; compétences parentales ; périnatalité. Ex. : haltes-garderies communautaires, aide psychosociale, accompagnement à la naissance, allaitement, relevailles.

- education_formation : Éducation et formation — Éduquer, enseigner et former ; améliorer les compétences de base ; lutter contre le décrochage scolaire ; éducation populaire citoyenne. Ex. : alphabétisation, francisation, aide aux devoirs, formation professionnelle.

- emploi : Emploi — Favoriser l'insertion sociale et socioprofessionnelle des personnes éloignées du marché du travail. Ex. : préparation à l'emploi, aide à la recherche ou au maintien en emploi, habiletés sociales, personnes handicapées.

- environnement : Environnement — Préserver ou protéger l'environnement ; favoriser une société écoresponsable. Ex. : milieux naturels, récupération, recyclage, développement durable, transport collectif.

- logement : Logement — Favoriser l'accès à un logement ; offrir des services relatifs à l'habitation ; favoriser la cohésion dans les logements sociaux. Ex. : logement social et communautaire, accompagnement, référencement, gestion de conflits entre locataires.

- sante : Santé — Favoriser la santé physique ou mentale de la population ou de clientèles particulières ; soutien aux proches aidants ; soins et ressources en santé. Ex. : personnes aînées ou en perte d'autonomie, troubles mentaux, déficience intellectuelle, réadaptation, aide à domicile, répit aux proches aidants.

- soutien_vulnerabilite : Soutien aux personnes en situation de vulnérabilité — Favoriser les capacités d'agir des personnes vulnérables ; prévention et accompagnement. Ex. : isolement social, personnes en crise, victimes de violence conjugale ou sexuelle, itinérance, dépendances (alcool, drogues, jeu).

- sports_loisirs_tourisme : Sports, loisirs et tourisme — Favoriser l'accès aux sports, aux loisirs et au tourisme. Ex. : installations sportives, activités sportives ou culturelles amateurs, ateliers, camps de vacances.

- autres_missions_sociales : Autres missions sociales — Toute mission ne s'apparentant à aucun des 12 domaines ci-dessus. Inclut aussi : intégration des immigrants et réfugiés, coopération internationale, prévention de la criminalité, promotion du bénévolat.

Réponds UNIQUEMENT en JSON valide, sans markdown:
{"secteur": "code_du_domaine", "secteur_secondaire": "code_ou_vide"}"""


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
        result["secteur"] = "autres_missions_sociales"
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
            if writer and row["secteur"] not in ("ERREUR", "429"):
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
            if writer and row["secteur"] not in ("ERREUR", "429"):
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
