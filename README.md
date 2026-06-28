# discord.cob

[日本語版 README](README.ja.md)

`discord.cob` is an experimental open source framework for building Discord bots in COBOL.
Its long-term target is deliberately ambitious: a Discord Gateway, Voice, and music bot stack implemented in COBOL, while presenting a simple callable API to bot authors.

This repository is currently in a pre-alpha stage. The parser, codec, queue, and packet-building layers are taking shape; live Discord connectivity and voice playback are still in progress.

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
- HTTP response parsing, header lookup, and basic chunked transfer decoding
- WebSocket frame encode/decode, including masked frame decoding
- RTP header and packet building
- Opus silence frame generation
- Music queue primitives and track helpers

In progress or not implemented yet:

- TCP socket transport
- TLS client transport
- WebSocket handshake transport
- Discord Gateway session handling
- UDP voice transport
- Voice encryption
- Ogg Opus parsing
- Full audio playback and music bot workflows

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
  net/           HTTP and WebSocket codecs, future transport layers
  gateway/       Gateway payload builders and event mapping
  voice/         voice session state and future UDP/gateway logic
  rtp/           RTP packet and sequence/timestamp builders
  crypto/        future voice encryption layer
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

That higher-level API exists today as a scaffold. Some lower layers are already functional, while network transport and Discord session flows are still being implemented.

## Quick Start

### Requirements

- GnuCOBOL with `cobc`

On macOS with Homebrew:

```sh
brew install gnucobol
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
- `websocket-test`
- `rtp-test`
- `music-queue-test`

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

1. WebSocket handshake helpers and `Sec-WebSocket-Accept` validation
2. Minimal Discord Gateway `HELLO` and `READY` handling
3. Slash command `/ping`
4. Voice join state handling
5. UDP discovery groundwork
6. Encrypted voice packet groundwork

Long-term target:

- a COBOL Discord Voice music bot that can join a voice channel and play audio

## Design Notes

The broader project is intentionally unusual. It is trying to answer questions like:

- How far can modern network protocol work be pushed in COBOL?
- What would a framework-style Discord library look like in a procedural COBOL environment?
- Can Voice, RTP, and encryption layers be made tractable without abandoning the language boundary?

That is why the repository includes parser and codec layers early, even before live Gateway support is complete.

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
