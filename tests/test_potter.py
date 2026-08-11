import tempfile
import unittest
from pathlib import Path

import potter


class PotterCoreTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        potter.configure_runtime_policy(
            self.root,
            interactive=False,
            allow_writes=False,
            allow_shell=False,
        )

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def test_calculator_accepts_math(self) -> None:
        self.assertEqual(potter.calculate("sqrt(81) + 3 * 4"), "21.0")

    def test_calculator_rejects_code(self) -> None:
        result = potter.calculate("__import__('os').getcwd()")
        self.assertTrue(result.startswith("Calculation error:"))

    def test_workspace_blocks_parent_traversal(self) -> None:
        with self.assertRaises(ValueError):
            potter.resolve_workspace_path("../outside.txt")

    def test_read_file_inside_workspace(self) -> None:
        target = self.root / "note.txt"
        target.write_text("hello", encoding="utf-8")
        self.assertEqual(potter.read_text_file("note.txt"), "hello")

    def test_write_and_shell_are_disabled(self) -> None:
        self.assertIn("disabled", potter.write_text_file("x.txt", "x").lower())
        self.assertIn("disabled", potter.run_command(["python3", "--version"]).lower())

    def test_session_store_round_trip(self) -> None:
        path = self.root / "sessions.json"
        store = potter.SessionStore(path)
        store.set("test-session", "resp_123")
        self.assertEqual(potter.SessionStore(path).get("test-session"), "resp_123")
        self.assertTrue(store.reset("test-session"))
        self.assertIsNone(store.get("test-session"))

    def test_session_id_validation(self) -> None:
        self.assertEqual(potter.normalize_session_id("ios-123"), "ios-123")
        with self.assertRaises(ValueError):
            potter.normalize_session_id("../../bad")


if __name__ == "__main__":
    unittest.main()
