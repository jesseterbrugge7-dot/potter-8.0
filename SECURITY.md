# Security policy

Potter keeps the OpenAI API key in the Python process. The SwiftUI client only
receives a separate local-server access token.

- Never commit `.env`, API keys, or access tokens.
- Do not expose Potter to a folder containing secrets; text read by a tool may
  be sent to the configured model provider as conversation context.
- Do not put an OpenAI API key in the iOS source or app settings.
- File writes and command execution are disabled by default.
- CLI write/command actions require both an enable flag and per-action approval.
- The HTTP/iOS mode cannot use Potter's write or command tools.
- Keep the local API on a trusted network. Use `127.0.0.1` unless an iPhone must
  connect, and stop the server when finished.
- Review tool calls and generated code before using them on important data.
- `POTTER_DATA_DIR` stores continuation identifiers, not the API key. Protect it
  like other application state.

Please report security issues privately to the repository maintainer rather
than opening a public exploit report.
