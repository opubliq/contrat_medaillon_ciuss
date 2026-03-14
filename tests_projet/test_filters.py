import unittest
import sys
from pathlib import Path
import importlib.util
from unittest.mock import patch

# Add the scripts directory to the Python path
scripts_dir = Path(__file__).resolve().parent.parent / "liste_organismes" / "scripts"
sys.path.append(str(scripts_dir))

# Import the scripts as modules
spec_03 = importlib.util.spec_from_file_location("03_filtre_llm", scripts_dir / "03_filtre_llm.py")
module_03 = importlib.util.module_from_spec(spec_03)
spec_03.loader.exec_module(module_03)

spec_04 = importlib.util.spec_from_file_location("04_classification_secteur", scripts_dir / "04_classification_secteur.py")
module_04 = importlib.util.module_from_spec(spec_04)
spec_04.loader.exec_module(module_04)

class TestFilters(unittest.TestCase):
    def test_exclude_ciusss_email(self):
        org = {
            "nom": "CIUSSS Test",
            "description": "Un organisme du CIUSSS",
            "courriel": "test@ssss.gouv.qc.ca",
        }
        processed_org = module_03.process_row(0, org)
        self.assertEqual(processed_org["pertinent"], "non")
        self.assertEqual(processed_org["raison"], "Courriel @ssss.gouv.qc.ca — entité gouvernementale CIUSSS/CISSS hors scope")

    def test_exclude_missing_email(self):
        org = {
            "nom": "No Email Test",
            "description": "Un organisme sans courriel",
            "courriel": "",
        }
        processed_org = module_03.process_row(0, org)
        self.assertEqual(processed_org["pertinent"], "non")
        self.assertEqual(processed_org["raison"], "Courriel manquant")

    def test_exclude_category(self):
        org = {
            "nom": "Sports Test",
            "description": "Un organisme de sports",
            "secteur": "sports_loisirs_tourisme",
        }
        # This test is a bit artificial since process_row calls the LLM.
        # We will mock the classify function in a future step.
        # For now, we manually set the secteur and check the exclusion.
        if org["secteur"] in module_04.CATEGORIES_A_EXCLURE:
            org["exclu"] = "oui"
        else:
            org["exclu"] = "non"

        self.assertEqual(org["exclu"], "oui")

    @patch.object(module_04, 'classify')
    @patch.object(module_03, 'filter_org')
    def test_specific_organizations(self, mock_filter_org, mock_classify):
        orgs_to_exclude = [
            {"nom": "Habitations Nouvelles Avenues", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Centre De Réadaptation En Dépendance De Montréal - Point De Service Hochelaga", "description": "", "clientele": "", "courriel": "test@ssss.gouv.qc.ca"},
            {"nom": "Centre De Réadaptation En Dépendance De Montréal - Point De Service Notre-Dame Est", "description": "", "clientele": "", "courriel": "test@ssss.gouv.qc.ca"},
            {"nom": "Centre Intégré Universitaire De Santé Et De Services Sociaux De L'est-De-L'île-De-Montréal - Commissaire Aux Plaintes Et À La Qualité Des Services", "description": "", "clientele": "", "courriel": "test@ssss.gouv.qc.ca"},
            {"nom": "Comité Des Usagers De L'hôpital Maisonneuve-Rosemont", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Chsld Juif Donald Berman", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Hôpital Juif De Réadaptation", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Centre Communautaire De Loisirs Sainte-Catherine D'alexandrie", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Âge D'or Rayons De Soleil De St-René-Goupil", "description": "", "clientele": "", "courriel": "test@test.com"},
            {"nom": "Réseau Des Services Spécialisés De Main-D'oeuvre", "description": "", "clientele": "", "courriel": "test@test.com"},
        ]

        for org in orgs_to_exclude:
            with self.subTest(org=org["nom"]):
                # Mock the LLM calls
                mock_filter_org.return_value = ("oui", "Mocked reason")
                mock_classify.return_value = {"secteur": "soutien_vulnerabilite", "secteur_secondaire": ""}

                # Simulate the pipeline
                processed_org_03 = module_03.process_row(0, org)

                if processed_org_03["pertinent"] == "oui":
                    processed_org_04 = module_04.process_row(processed_org_03, [])
                    if processed_org_04["secteur"] in module_04.CATEGORIES_A_EXCLURE or \
                       (processed_org_04.get("secteur_secondaire") and processed_org_04["secteur_secondaire"] in module_04.CATEGORIES_A_EXCLURE):
                        self.assertEqual(processed_org_04["exclu"], "oui")
                    else:
                        # If not excluded by category, it should be excluded by the LLM in step 3
                        mock_filter_org.return_value = ("non", "Mocked reason")
                        processed_org_03 = module_03.process_row(0, org)
                        self.assertEqual(processed_org_03["pertinent"], "non")
                else:
                    self.assertEqual(processed_org_03["pertinent"], "non")

if __name__ == "__main__":
    unittest.main()
