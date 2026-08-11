import base64
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

    def test_image_input_builds_multimodal_turn(self) -> None:
        jpeg = b"\xff\xd8\xff\xe0potter-test"
        images = potter.parse_image_inputs(
            [
                {
                    "mime_type": "image/jpeg",
                    "data": base64.b64encode(jpeg).decode("ascii"),
                }
            ]
        )
        turn = potter.build_agent_input("Describe this", images)
        self.assertEqual(turn[0]["role"], "user")
        self.assertEqual(turn[0]["content"][0]["type"], "input_text")
        self.assertEqual(turn[0]["content"][1]["type"], "input_image")
        self.assertTrue(turn[0]["content"][1]["image_url"].startswith("data:image/jpeg;base64,"))

    def test_image_input_rejects_invalid_base64(self) -> None:
        with self.assertRaisesRegex(ValueError, "valid Base64"):
            potter.parse_image_inputs(
                [{"mime_type": "image/jpeg", "data": "not-base64"}]
            )

    def test_image_input_rejects_mime_mismatch(self) -> None:
        encoded = base64.b64encode(b"not-a-png").decode("ascii")
        with self.assertRaisesRegex(ValueError, "does not match"):
            potter.parse_image_inputs(
                [{"mime_type": "image/png", "data": encoded}]
            )


if __name__ == "__main__":
    unittest.main()
