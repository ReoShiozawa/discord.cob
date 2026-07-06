# discord.cob

[日本語版 README](README.ja.md)

`discord.cob` is an experimental open source framework for building Discord bots in COBOL.
Its long-term target is deliberately ambitious: a Discord Gateway, Voice, and music bot stack implemented in COBOL, while presenting a simple callable API to bot authors.

This repository is currently in a pre-alpha stage. The parser, codec, queue, packet-building, and initial playback layers are already working; live Gateway and Voice session connectivity, negotiated voice encryption, interaction parsing/reply flow, and queue-backed command routing are in place, and the remaining work is now mostly around higher-level bot ergonomics, richer response builders, and deeper end-to-end playback.

## Project Vision

The design direction is guided by three ideas:

- Keep the human-authored implementation in COBOL
- Hide Discord protocol complexity behind a framework-style API
- Build upward in phases, from protocol primitives to a working Voice music bot

The full design draft lives in [discord_cob_design.md](discord_cob_design.md).

## Status

Implemented today:

- Core client state, result helpers, event registration, and dispatch
- JSON validation and JSON path extraction for Discord-style payloads
- In-memory TCP/TLS transport fixtures and handle management
- OS-backed TCP/TLS transport through spawned `nc` / `openssl s_client` processes
- HTTP response parsing, header lookup, basic chunked transfer decoding, and mock-backed high-level GET/POST/PUT/PATCH/DELETE requests
- WebSocket frame encode/decode, masked client/server frame handling, in-memory session flow, and opt-in live TLS-backed session flow
- Live Discord Gateway connect/login plus a minimal recv/apply/send event-loop tick with heartbeat scheduling
- Live Voice Gateway connect plus a minimal recv/apply/queue/send voice tick with heartbeat scheduling
- Voice UDP discovery parsing, automatic apply-to-select-protocol queueing, and session description secret-key capture
- Fixture-backed and OS-backed UDP transport through shared handle APIs
- RTP header and packet building
- `aead_xchacha20_poly1305_rtpsize` voice packet encryption
- Initial Ogg Opus packet extraction plus explicit reader handle close
- Opus silence frame generation
- Music queue primitives, track helpers, and a queue-backed playback tick for raw/local voice tests
- Slash-command routing for `/join`, `/leave`, `/play`, `/skip`, `/pause`, `/resume`, `/stop`, `/queue`, `/remove`, `/clearqueue`, and `/nowplaying`
- Custom music interaction panels for `/nowplaying` and `/queue`, including inline playback/queue controls
- Slash-command registration, listing, deletion, and bulk overwrite over HTTP, including music command bootstrap helpers
- Interaction JSON parsing for slash commands, components, and modal submits; custom command/component/modal routing; immediate/update/modal/deferred/follow-up reply helpers; follow-up wait/get/edit/delete and original response get/edit/delete helpers; and registerable dispatcher-backed interaction handlers

In progress or not implemented yet:

- Gateway reconnect lifecycle and stale-heartbeat handling
- Full encrypted voice playback and music bot workflows

## What This Repository Is

`discord.cob` is currently best understood as:

- a structured COBOL codebase for Discord protocol research
- a growing framework scaffold with stable-ish internal module boundaries
- a testbed for modern network and realtime protocol handling in COBOL

It is not yet a production-ready Discord bot library.

## Repository Layout

```text
src/
  core/          client state, dispatcher, result helpers
  json/          JSON validation and path readers
  net/           HTTP, transport, and WebSocket layers
  gateway/       Gateway payload builders and event mapping
  voice/         voice session state and future UDP/gateway logic
  rtp/           RTP packet and sequence/timestamp builders
  crypto/        voice encryption layer
  opus/          Opus helpers and future readers/encoders
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

That higher-level API exists today as a scaffold. Core transport and protocol primitives are already functional, while Discord session orchestration and voice flows are still being implemented. Registered handler programs are invoked as `CALL handler USING DC-CLIENT DC-EVENT DC-RESULT`.

## Quick Start

### Requirements

- GnuCOBOL with `cobc`
- `libsodium`

On macOS with Homebrew:

```sh
brew install gnucobol libsodium pkg-config
```

### Build

```sh
make build
```

### Test

```sh
make test
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

The HTTP parsing example can be built and run with:

```sh
mkdir -p build/examples
cobc -free -Wall -I src/copybooks -x \
  -o build/examples/example-http \
  examples/01-rest-message/main.cob \
  $(find src -name '*.cob' | sort)
./build/examples/example-http
```

The intended bot-entry pattern is also sketched in [examples/02-gateway-ready/main.cob](examples/02-gateway-ready/main.cob).

## Configuration

Discord tokens should not be hard-coded.
The repository includes:

- `.env.example`
- `.gitignore` coverage for `.env`

The long-term direction is environment-driven configuration rather than embedding credentials in source files.

## Roadmap

Near-term priorities:

1. Gateway reconnect and stale-heartbeat handling
2. Encrypted voice packet groundwork
3. Embed-safe interaction builders and richer command-sync ergonomics
4. End-to-end encrypted playback workflow
5. Higher-level bot examples around music playback

Long-term target:

- a COBOL Discord Voice music bot that can join a voice channel and play audio

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

The project is still exploratory, but contributions are welcome, especially around:

- COBOL portability and GnuCOBOL behavior
- parser and codec correctness
- Discord protocol compatibility
- test coverage for protocol edge cases
- documentation and examples

Small, test-backed pull requests are the easiest place to start.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
