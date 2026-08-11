# Potter 8.0

Potter 8.0 is an open-source AI agent that runs in a Python terminal and can
also power a native SwiftUI iPhone/iPad chat app. It uses the OpenAI Agents SDK,
defaults to `gpt-5.6`, keeps multi-turn conversation state, searches the web,
calculates, reads workspace files, and routes research, analysis, and coding
work to focused specialists.

The default reasoning effort is `high` for quality-first work. This increases
latency and API usage compared with `medium` or `low`.

It is an agent framework, not a claim of human intelligence or guaranteed
accuracy. Important output and actions should still be reviewed.

## What is included

- Interactive terminal chat and one-shot `ask` mode.
- Research, analysis, and builder specialists.
- OpenAI web search plus safe math, time, file-list, and file-read tools.
- Optional file writes and subprocesses in CLI mode only.
- Per-action approval for every write or command.
- Local authenticated HTTP bridge for the included SwiftUI app.
- Local conversation continuation, iOS chat history, tests, and MIT license.

## Fastest terminal setup

Requirements: Python 3.11+ and an OpenAI Platform API key.

```bash
cd potter-8.0
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -e .
export OPENAI_API_KEY="paste_your_key_here"
potter chat
```

The official setup uses the `OPENAI_API_KEY` environment variable; do not paste
the key into `potter.py` or commit it. OpenAI API usage is billed through the
Platform account and is separate from a ChatGPT subscription. See the official
[SDK setup](https://developers.openai.com/api/docs/libraries) and
[production security guidance](https://developers.openai.com/api/docs/guides/production-best-practices).

You can also run the single Python file directly:

```bash
python -m pip install openai-agents
export OPENAI_API_KEY="paste_your_key_here"
python potter.py
```

On Windows PowerShell:

```powershell
py -m venv .venv
.venv\Scripts\Activate.ps1
py -m pip install -e .
$env:OPENAI_API_KEY="paste_your_key_here"
potter chat
```

## Terminal commands

```bash
# Interactive chat
potter chat

# One question, then exit
potter ask "Research the newest battery technology and cite sources"

# Maximum reasoning for a particularly hard task (slower and more expensive)
potter --reasoning max ask "Audit this migration plan for hidden failure modes"

# Give Potter access to a particular project
potter --workspace /absolute/path/to/project chat

# Enable write requests; Potter still asks before every write
potter --workspace /absolute/path/to/project chat --allow-writes

# Enable argument-list commands; Potter still asks before every command
potter --workspace /absolute/path/to/project chat --allow-shell

# Forget a saved continuation
potter reset --session cli
```

Inside interactive chat, use `/new`, `/reset`, `/help`, or `/exit`.

The OpenAI Agents SDK runs the repeated tool loop and continuation flow. Potter
uses the documented `previous_response_id` strategy rather than replaying and
duplicating local history. See the official
[Agents SDK overview](https://developers.openai.com/api/docs/guides/agents) and
[running-agents guide](https://developers.openai.com/api/docs/guides/agents/running-agents).

## Run the iOS backend

The iOS app never contains the OpenAI API key. Start Potter on the Mac or other
computer that owns the key:

```bash
source .venv/bin/activate
export OPENAI_API_KEY="paste_your_key_here"
potter serve --host 0.0.0.0
```

The server prints two values needed by the app:

- A URL such as `http://Your-Mac.local:8787`.
- A random local access token.

The access token protects the local bridge; it is not an OpenAI API key. The
server disables shell and file-write tools in iOS/HTTP mode. Use this only on a
trusted local network and stop it with Ctrl-C when finished.

For a stable token across restarts:

```bash
export POTTER_SERVER_TOKEN="choose-a-long-random-token"
potter serve --host 0.0.0.0
```

## Build the SwiftUI app

Requirements: macOS, Xcode, and XcodeGen. The app targets iOS 17+.

```bash
cd ios/Potter8
xcodegen generate
open Potter8.xcodeproj
```

In Xcode:

1. Select the `Potter8` target and choose your Apple development team.
2. Change the bundle identifier if `com.potter8.app` is unavailable.
3. Run on an iPhone or Simulator.
4. Open Settings in the app and enter the server URL and printed access token.
5. Tap **Test connection**.

For Simulator use `http://127.0.0.1:8787`. For a physical iPhone, use the
printed `.local` address and allow Local Network access. The app enables only
local-network HTTP while leaving App Transport Security enabled elsewhere, in
line with Apple's
[NSAllowsLocalNetworking documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/nsapptransportsecurity/nsallowslocalnetworking).

### Private IPA without owning a Mac

The repository includes a manual GitHub Actions workflow that compiles an
unsigned IPA on a hosted macOS runner. You can then sign and install it locally
with your own Apple Account. Follow [PRIVATE_IPA.md](PRIVATE_IPA.md). Free Apple
signing expires after seven days, so this route requires a weekly refresh.

## Local API

Health check:

```bash
curl http://127.0.0.1:8787/health
```

Chat request:

```bash
curl http://127.0.0.1:8787/v1/chat \
  -H "Authorization: Bearer $POTTER_SERVER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"session_id":"demo","message":"What can you do?"}'
```

Endpoints:

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/health` | Server, version, and model status |
| `POST` | `/v1/chat` | Send one message in a named session |
| `POST` | `/v1/reset` | Forget one named session |

## Safety model

- All file paths are resolved inside `POTTER_WORKSPACE`; traversal and symlink
  escapes are blocked.
- Text reads are size-limited.
- Calculation uses a restricted syntax tree, never Python `eval`.
- Writes and commands are disabled by default.
- CLI writes/commands require an enable flag and a fresh terminal confirmation.
- Commands use an argument list with `shell=False` and receive an environment
  stripped of variables with key/token/secret/password-like names.
- HTTP/iOS mode cannot execute commands or write files.
- The iOS app stores the local bridge token in Keychain.

Read [SECURITY.md](SECURITY.md) before extending Potter with consequential tools.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `OPENAI_API_KEY` | required | OpenAI Platform API key for Python only |
| `POTTER_MODEL` | `gpt-5.6` | Model used by Potter and specialists |
| `POTTER_REASONING` | `high` | Reasoning effort: `none` through `max` |
| `POTTER_WORKSPACE` | current directory | Root available to file tools |
| `POTTER_DATA_DIR` | `~/.potter8` | Local continuation-ID storage |
| `POTTER_SERVER_TOKEN` | random per run | Local HTTP bearer token |

Use a lower-cost model by setting `POTTER_MODEL` before launch, provided that
model supports the tools you enable.

## Tests

The core safety and persistence tests do not need an API key:

```bash
python3 -m unittest discover -s tests -v
```

An actual model response is not run automatically because it would require
your API key and incur API usage.

## Open source

Potter 8.0 is released under the [MIT License](LICENSE). Contributions are
welcome; see [CONTRIBUTING.md](CONTRIBUTING.md). The Potter source is open
source; the hosted OpenAI models/API are external services and are not included
under Potter's MIT license.
