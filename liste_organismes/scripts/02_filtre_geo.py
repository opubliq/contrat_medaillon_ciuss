import csv
import json
import os
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent.parent.parent / ".env")

INPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "bottin211"
OUTPUT = Path(__file__).resolve().parent.parent / "data" / "02_bottin_geo_filtre.csv"
GEOCODE_CACHE = Path(__file__).resolve().parent.parent / "data" / "geocode_cache.json"

CHAMPS = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele", "lat", "lng"]

# Bounding box du territoire CIUSS Est de Montréal
BBOX_WEST = -73.673904
BBOX_SOUTH = 45.532288
BBOX_EAST = -73.484390
BBOX_NORTH = 45.705614

API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")
GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"


def load_all_pages():
    rows = []
    for f in sorted(INPUT_DIR.glob("page_*.csv")):
        with open(f, encoding="utf-8") as fh:
            reader = csv.DictReader(fh)
            for row in reader:
                if row["nom"] and row["nom"] != "void":
                    rows.append(row)
    return rows


def load_cache():
    if GEOCODE_CACHE.exists():
        with open(GEOCODE_CACHE, encoding="utf-8") as f:
            return json.load(f)
    return {}


def save_cache(cache):
    with open(GEOCODE_CACHE, "w", encoding="utf-8") as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)


def geocode(adresse, cache):
    if adresse in cache:
        return cache[adresse]

    params = {"address": adresse, "key": API_KEY, "region": "ca"}
    try:
        resp = requests.get(GEOCODE_URL, params=params, timeout=10)
        resp.raise_for_status()
        data = resp.json()
        if data["status"] == "OK" and data["results"]:
            loc = data["results"][0]["geometry"]["location"]
            coords = (loc["lat"], loc["lng"])
            cache[adresse] = coords
            return coords
        else:
            cache[adresse] = None
            return None
    except Exception as e:
        print(f"    Erreur geocoding [{adresse[:60]}]: {e}")
        cache[adresse] = None
        return None


def in_bbox(lat, lng):
    return BBOX_SOUTH <= lat <= BBOX_NORTH and BBOX_WEST <= lng <= BBOX_EAST


def main():
    if not API_KEY:
        print("GOOGLE_MAPS_API_KEY manquante dans .env")
        return

    rows = load_all_pages()
    print(f"{len(rows)} organismes chargés")

    cache = load_cache()
    print(f"{len(cache)} adresses en cache")

    inside = []
    outside = 0
    no_geocode = 0

    for i, row in enumerate(rows):
        adresse = row["adresse"]
        if not adresse:
            no_geocode += 1
            continue

        coords = geocode(adresse, cache)

        if coords is None:
            no_geocode += 1
        elif in_bbox(coords[0], coords[1]):
            row["lat"] = coords[0]
            row["lng"] = coords[1]
            inside.append(row)
        else:
            outside += 1

        if (i + 1) % 100 == 0:
            print(f"  {i + 1}/{len(rows)} — {len(inside)} dans la zone, {outside} hors zone, {no_geocode} non géocodés")
            save_cache(cache)

    save_cache(cache)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CHAMPS)
        writer.writeheader()
        writer.writerows(inside)

    print(f"\nTerminé.")
    print(f"  {len(inside)} dans la zone")
    print(f"  {outside} hors zone")
    print(f"  {no_geocode} non géocodés")
    print(f"  → {OUTPUT}")


if __name__ == "__main__":
    main()
