import csv
import json
import re
from pathlib import Path

import requests
from bs4 import BeautifulSoup

BASE_URL = "https://carteshm.org/2025/"
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "carteshm"
CHAMPS = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele"]


def scrape():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    response = requests.get(BASE_URL)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, "html.parser")
    script_tags = soup.find_all("script")
    script_tag = None
    for tag in script_tags:
        if tag.string and "places =" in tag.string:
            script_tag = tag
            break
    
    if not script_tag:
        print("Could not find the script tag with places data.")
        return

    script_content = script_tag.string
    match = re.search(r"places = ({.*?});", script_content, re.DOTALL)
    if not match:
        print("Could not extract places JSON from script.")
        return

    places_json = match.group(1)
    places_data = json.loads(places_json)

    rows = []
    for place_id, place in places_data.items():
        adresse = f"{place.get('address', '')} {place.get('address_details', '')} {place.get('city', '')} {place.get('postalcode', '')}".strip()
        rows.append({
            "nom": place.get("title", ""),
            "adresse": adresse,
            "description": place.get("description", ""),
            "telephone": place.get("phone", ""),
            "courriel": place.get("email", ""),
            "site_web": place.get("website", ""),
            "territoire": "",
            "clientele": ""
        })

    output_path = OUTPUT_DIR / "organismes.csv"
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CHAMPS)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Scraping finished. {len(rows)} organizations saved to {output_path}")


if __name__ == "__main__":
    scrape()
