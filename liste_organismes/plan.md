1. Scraper le 211qc.ca (source centrale, ~2461 organismes pour Montréal-Est)
   - Script Python (requests + BeautifulSoup), pagination 15 résultats/page
   - URL: https://www.211qc.ca/recherche?place=Montréal-Est,...&serve=1&field13=Montréal-Est
   - Output: CSV brut avec nom, adresse, téléphone, site web, courriel, description services, population cible

2. Filtrer avec LLM: garder tous les organismes à vocation sociétale/communautaire
   - Script Python qui call un LLM gratuit via API (Gemini Flash ou Groq)
   - Classifier pertinent/non-pertinent à partir du nom + description

3. Enrichir avec le bottin municipal (28 orgs)
   - Cross-référencer avec le scrape du bottin ville.montreal-est.qc.ca
   - Ajouter infos manquantes (responsable, etc.)
   - Identifier des orgs locaux absents du 211

4. Valider/mettre à jour les coordonnées (seulement les orgs filtrés)
   a. Organismes avec URL → scraper le site pour courriel/téléphone
   b. Organismes sans URL → recherche via Brave Search API pour trouver le site web
   c. Scraper les sites trouvés en 4b
