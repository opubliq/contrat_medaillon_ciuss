import csv
import time
from pathlib import Path

from bs4 import BeautifulSoup
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait

BASE_URL = (
    "https://www.211qc.ca/recherche?"
    "place=Montr%C3%A9al-Est,%20QC,%20Canada"
    "&lat=45.6320003&lng=-73.5066981"
    "&sort=name"
    "&field11=Montr%C3%A9al&field12=Montr%C3%A9al"
    "&serve=1&field13=Montr%C3%A9al-Est"
)
OUTPUT_DIR = Path(__file__).resolve().parent.parent / "data" / "bottin211"
CHAMPS = ["nom", "adresse", "description", "telephone", "courriel", "site_web", "territoire", "clientele"]
PER_PAGE = 15


def parse_item(item):
    nom_el = item.find(class_="recherche-content-list-item-title")
    nom = nom_el.get_text(strip=True) if nom_el else ""

    addr_div = item.find(class_="organisme-address")
    if addr_div:
        spans = [s.get_text(strip=True) for s in addr_div.find_all("span", recursive=False)]
        adresse = " ".join(s for s in spans if s != ",")
    else:
        adresse = ""

    desc_el = item.find(class_="organization-item-text-description")
    description = desc_el.get_text(strip=True) if desc_el else ""

    link_list = item.find(class_="recherche-content-list-item-link-list")
    if link_list:
        telephone = link_list.get("data-phone", "")
        courriel = link_list.get("data-email", "")
        site_web = link_list.get("data-website-address", "")
        territoire = link_list.get("data-territory", "")
        clientele = link_list.get("data-clientele", "")
    else:
        telephone = courriel = site_web = territoire = clientele = ""

    return {
        "nom": nom, "adresse": adresse, "description": description,
        "telephone": telephone, "courriel": courriel, "site_web": site_web,
        "territoire": territoire, "clientele": clientele,
    }


def save_page(page_num, rows):
    path = OUTPUT_DIR / f"page_{page_num:03d}.csv"
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CHAMPS)
        writer.writeheader()
        writer.writerows(rows)


def scrape():
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    options = webdriver.ChromeOptions()
    options.add_argument("--headless")
    driver = webdriver.Chrome(options=options)

    total_orgs = 0
    page = 1

    try:
        while True:
            url = BASE_URL if page == 1 else f"{BASE_URL}&page={page}"
            driver.get(url)
            try:
                WebDriverWait(driver, 15).until(
                    EC.presence_of_element_located((By.CLASS_NAME, "recherche-content-list-item"))
                )
            except Exception:
                print(f"  Page {page} — aucun résultat, fin.")
                break

            soup = BeautifulSoup(driver.page_source, "html.parser")
            items = soup.find_all(class_="recherche-content-list-item")
            if not items:
                print(f"  Page {page} — 0 items, fin.")
                break

            rows = [parse_item(item) for item in items]
            save_page(page, rows)
            total_orgs += len(rows)
            print(f"  Page {page} — {len(rows)} items ({total_orgs} total)")

            if len(items) < PER_PAGE:
                break

            page += 1
            time.sleep(0.5)

    finally:
        driver.quit()

    print(f"\nTerminé. {total_orgs} organismes sur {page} pages → {OUTPUT_DIR}/")


if __name__ == "__main__":
    scrape()
