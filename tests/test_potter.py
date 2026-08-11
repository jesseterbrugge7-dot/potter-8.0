import base64
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

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

    def test_model_aliases_resolve_to_stable_ids(self) -> None:
        self.assertEqual(
            potter.resolve_model_definition("gpt-5.6").id,
            "openai-gpt-5.6",
        )
        self.assertEqual(
            potter.resolve_model_definition("gemini-3.1-pro-preview").id,
            "google-gemini-3.1-pro",
        )
        self.assertEqual(
            potter.resolve_model_definition("claude-code").id,
            "anthropic-claude-code",
        )

    def test_unknown_model_is_rejected(self) -> None:
        with self.assertRaisesRegex(ValueError, "Unknown model"):
            potter.resolve_model_definition("free-stolen-premium-model")

    def test_provider_key_requirement_is_clear(self) -> None:
        definition = potter.resolve_model_definition("openai-gpt-5.6")
        with mock.patch.dict(os.environ, {}, clear=True):
            with self.assertRaisesRegex(potter.ProviderError, "OPENAI_API_KEY"):
                potter._require_provider_key(definition)
            self.assertIsNone(
                potter._require_provider_key(
                    potter.resolve_model_definition("ollama-local-free")
                )
            )

    def test_compatible_payload_contains_selected_model_and_image(self) -> None:
        definition = potter.resolve_model_definition("moonshot-kimi-k3")
        image = potter.ImageInput(
            mime_type="image/jpeg",
            data=base64.b64encode(b"\xff\xd8\xffpotter").decode("ascii"),
        )
        payload = potter._openai_compatible_payload(
            definition,
            [{"role": "assistant", "content": "Earlier reply"}],
            "What is this?",
            [image],
        )
        self.assertEqual(payload["model"], "kimi-k3")
        self.assertEqual(payload["messages"][-1]["content"][1]["type"], "image_url")

    def test_conversation_store_keeps_provider_history_separate(self) -> None:
        path = self.root / "conversations.json"
        store = potter.ConversationStore(path)
        first = potter.model_session_key("ios-test", "anthropic-fable-5")
        second = potter.model_session_key("ios-test", "xai-grok-4.5")
        store.append_turn(first, "Hello", "Hi")
        self.assertEqual(len(potter.ConversationStore(path).get(first)), 2)
        self.assertEqual(potter.ConversationStore(path).get(second), [])


if __name__ == "__main__":
    unittest.main()
