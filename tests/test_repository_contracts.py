import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryContractTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = json.loads((ROOT / "data/equipment/catalog.json").read_text())
        cls.schema = json.loads((ROOT / "data/schemas/equipment.schema.json").read_text())
        cls.project = (ROOT / "project.godot").read_text()

    def test_project_main_scene_exists(self):
        match = re.search(r'^run/main_scene="([^"]+)"', self.project, re.M)
        self.assertIsNotNone(match)
        scene = match.group(1).removeprefix("res://")
        self.assertTrue((ROOT / scene).is_file())

    def test_catalog_ids_are_unique_and_schema_versioned(self):
        equipment = self.catalog["equipment"]
        ids = [entry["id"] for entry in equipment]
        self.assertEqual(len(ids), len(set(ids)))
        self.assertGreater(self.catalog["catalog_version"], 0)
        self.assertEqual(self.schema["$schema"], "https://json-schema.org/draft/2020-12/schema")

    def test_every_placeholder_has_required_definition_fields(self):
        required = self.schema["required"]
        for entry in self.catalog["equipment"]:
            with self.subTest(equipment=entry.get("id")):
                for key in required:
                    self.assertIn(key, entry)
                self.assertRegex(entry["id"], r"^[a-z][a-z0-9_]*$")
                self.assertEqual(entry["definition_version"], 1)
                self.assertIsNone(entry["simulation_model"])
                self.assertEqual(entry["interfaces"], [])
                self.assertEqual(entry["ports"], [])
                self.assertTrue(entry["limitations"])
                self.assertIsNone(entry["manufacturer"])
                self.assertIsNone(entry["model"])

    def test_prototype_does_not_fabricate_spec_values_or_claim_source_inventory(self):
        self.assertIn("not present", self.catalog["source_note"].lower())
        self.assertEqual(len(self.catalog["equipment"]), 4)
        for entry in self.catalog["equipment"]:
            self.assertEqual(entry["specifications"], {})
            self.assertEqual(entry["electrical_ratings"], {})
            self.assertIsNone(entry["dimensions_m"])

    def test_no_curriculum_features_added(self):
        forbidden = ("curriculum", "student management", "lesson completion", "quiz", "course module")
        source_files = [ROOT / "README.md"] + list((ROOT / "scripts").rglob("*.gd"))
        for path in source_files:
            source = path.read_text().lower()
            for phrase in forbidden:
                self.assertNotIn(phrase, source, f"{phrase} found in {path}")

    def test_project_save_format_is_documented(self):
        docs = (ROOT / "docs/ARCHITECTURE.md").read_text()
        script = (ROOT / "scripts/core/workshop.gd").read_text()
        self.assertIn('"format": "virtual-equipment-project"', script)
        self.assertIn("schema_version", script)
        self.assertIn("schema_version: 1", docs)


if __name__ == "__main__":
    unittest.main()
