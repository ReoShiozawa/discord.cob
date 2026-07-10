# discord.cob

[日本語版 README](README.ja.md)

`discord.cob` is an experimental open source framework for building Discord bots in COBOL.
Its long-term target is deliberately ambitious: a Discord Gateway, Voice, and music bot stack implemented in COBOL, while presenting a simple callable API to bot authors.

The first design milestone is implemented end to end: live Gateway and Voice session orchestration, interactions, UDP discovery, negotiated voice encryption, Ogg Opus playback, and queue-backed music commands are connected behind callable COBOL APIs. The project remains experimental software, but it is no longer only a protocol scaffold.

## Project Vision

The design direction is guided by three ideas:

- Keep the human-authored implementation in COBOL
- Hide Discord protocol complexity behind a framework-style API
- Build upward in phases, from protocol primitives to a working Voice music bot

The full design draft lives in [discord_cob_design.md](discord_cob_design.md).

## Status

Implemented today:

- Core client state, result helpers, event registration, and dispatch
- Depth-aware JSON validation/tokenization, escaped-string decoding, array path lookup, and safe string writing
- In-memory TCP/TLS transport fixtures and handle management
- OS-backed TCP/TLS transport through spawned `nc` / `openssl s_client` processes
- HTTP response parsing, header lookup, basic chunked transfer decoding, and mock-backed high-level GET/POST/PUT/PATCH/DELETE requests
- WebSocket frame encode/decode, buffering across transport reads, continuation reassembly, control frames, graceful close, in-memory sessions, and live TLS-backed sessions
- Live Discord Gateway connect/login plus a minimal recv/apply/send event-loop tick with heartbeat scheduling
- Live Voice Gateway connect plus a minimal recv/apply/queue/send voice tick with heartbeat scheduling
- Voice UDP discovery parsing, automatic apply-to-select-protocol queueing, and session description secret-key capture
- Fixture-backed and OS-backed UDP transport through shared handle APIs
- RTP header and packet building
- `aead_xchacha20_poly1305_rtpsize` voice packet encryption
- Initial Ogg Opus packet extraction plus explicit reader handle close
- Opus silence frame generation
- Music queue primitives, track helpers, and negotiated encrypted playback of local Ogg Opus sources
- Slash-command routing for `/join`, `/leave`, `/play`, `/skip`, `/pause`, `/resume`, `/stop`, `/queue`, `/remove`, `/clearqueue`, and `/nowplaying`
- Custom music interaction panels for `/nowplaying` and `/queue`, including inline playback/queue controls
- Slash-command registration, listing, deletion, and bulk overwrite over HTTP, including music command bootstrap helpers
- Interaction JSON parsing for slash commands, autocomplete, components, and modal submits; focused-option lookup; custom command/component/modal routing plus command-backed autocomplete dispatch; immediate/update/modal/deferred/follow-up/autocomplete reply helpers; follow-up wait/get/edit/delete and original response get/edit/delete helpers; and registerable dispatcher-backed interaction handlers

Deliberate limitations:

- Live TCP/TLS uses `nc` and `openssl s_client`; voice AEAD uses `libsodium`. No C adapter source is maintained in this repository.
- The music source path accepts local Ogg Opus/Opus input. Downloading, transcoding, and arbitrary PCM encoding are outside the first milestone.
- Discord's optional DAVE/E2EE evolution is represented by state scaffolding but is not part of the supported `aead_xchacha20_poly1305_rtpsize` transport.
- The full fixture suite is automated. A real Discord smoke test still requires user-owned credentials and a test guild.

## What This Repository Is

`discord.cob` is best understood as:

- an experimental but runnable COBOL Discord framework
- a reference implementation for modern network and realtime protocols in GnuCOBOL
- a foundation for local-file Voice music bots and protocol research

It is not presented as a production-hardened replacement for mature Discord libraries.

## Repository Layout

```text
src/
  core/          client state, dispatcher, result helpers
  json/          JSON validation and path readers
  net/           HTTP, transport, and WebSocket layers
  gateway/       Gateway payload builders and event mapping
  voice/         Voice Gateway, session state, and UDP negotiation
  rtp/           RTP packet and sequence/timestamp builders
  crypto/        voice encryption layer
  opus/          Ogg Opus readers and packet helpers
  audio/         playback-side abstractions
  music/         queue and command helpers
  copybooks/     shared COBOL data definitions

examples/        phase-oriented example programs
tests/           executable COBOL tests
docs/            API notes and roadmap
```

## Current API Shape

The public direction is a callable COBOL API centered around client setup and event dispatch:

```cobol
CALL "DC-CLIENT-INIT"
    USING DC-CONFIG
          DC-CLIENT
          DC-RESULT.

CALL "DC-ON"
    USING DC-CLIENT
          "READY"
          "APP-ON-READY"
          DC-RESULT.

CALL "DC-LOGIN"
    USING DC-CLIENT
          DC-RESULT.
```

The same API is used by the runnable Gateway, interaction, Voice, and music examples. Registered handler programs are invoked as `CALL handler USING DC-CLIENT DC-EVENT DC-RESULT`.

## Quick Start

### Requirements

- GnuCOBOL with `cobc`
- `libsodium`
- OpenSSL and netcat for live process-backed transports

On macOS with Homebrew:

```sh
brew install gnucobol libsodium pkg-config openssl netcat
```

### Build

```sh
make build
```

### Test

```sh
make test
```

Build every phase example with:

```sh
make examples
```

Current test executables:

- `core-test`
- `json-test`
- `http-test`
- `url-test`
- `transport-test`
- `websocket-test`
- `ws-handshake-test`
- `gateway-test`
- `voice-test`
- `rtp-test`
- `crypto-test`
- `command-router-test`
- `interaction-test`
- `slash-command-test`
- `opus-test`
- `music-queue-test`
- `music-playback-test`

### Run an Example

After `make examples`, binaries are available under `build/examples/`. The complete music-bot entry point is:

```sh
DISCORD_TOKEN=... \
DISCORD_APPLICATION_ID=... \
DISCORD_GUILD_ID=... \
./build/examples/09-music-bot
```

See [examples/09-music-bot/README.md](examples/09-music-bot/README.md) for runtime and clean-shutdown settings.

## Configuration

Discord tokens should not be hard-coded.
The repository includes:

- `.env.example`
- `.gitignore` coverage for `.env`

Runtime examples read credentials from environment variables rather than embedding them in source files.

## Roadmap

Post-milestone priorities:

1. More live Discord compatibility testing across reconnect and rate-limit scenarios
2. Portability beyond the current macOS/GnuCOBOL-oriented process transports
3. Larger buffers or streaming stores for high-volume payloads
4. Optional PCM transcoding/encoding integrations
5. DAVE support as Discord's voice requirements evolve

The original target, a COBOL bot that can join Voice and send encrypted Opus audio, is represented by the `08-play-opus-file` and `09-music-bot` examples.

## Design Notes

The broader project is intentionally unusual. It is trying to answer questions like:

- How far can modern network protocol work be pushed in COBOL?
- What would a framework-style Discord library look like in a procedural COBOL environment?
- Can Voice, RTP, and encryption layers be made tractable without abandoning the language boundary?

That is why the repository includes parser and codec layers early, even before the Gateway and Voice runtimes are fully rounded out.

## Documentation

- Design draft: [discord_cob_design.md](discord_cob_design.md)
- API notes: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## Contributing

Contributions are welcome, especially around:

- COBOL portability and GnuCOBOL behavior
- parser and codec correctness
- Discord protocol compatibility
- test coverage for protocol edge cases
- documentation and examples

Small, test-backed pull requests are the easiest place to start.
See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and repository conventions.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
