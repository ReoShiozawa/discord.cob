# discord.cob

`discord.cob` is an experimental framework for building Discord bots in COBOL.
The long-term goal is ambitious on purpose: a Discord Voice and music bot stack implemented in COBOL, with the public API shaped more like a bot framework than a bag of protocol helpers.

The current repository is the early scaffold for that effort. Core state handling, JSON path extraction, HTTP response parsing, WebSocket frame codecs, RTP packet building, and queue primitives are already in place. Live Discord connectivity, TLS, voice transport, and encryption are still under active development.

## Goals

- Keep the human-authored implementation in COBOL
- Hide Discord protocol complexity behind simple callable APIs
- Grow incrementally from parser and codec layers toward a working Gateway bot
- Eventually support voice join, RTP, encrypted voice packets, and music playback

## Current Status

Implemented today:

- Core client initialization, result handling, logging, event registration, and dispatch
- JSON path extraction for Discord-style payloads
- HTTP response parsing, header lookup, and basic chunked transfer decoding
- WebSocket frame encode/decode, including masked decode and 16-bit extended lengths
- RTP header and packet building
- Opus silence frame generation
- Music queue primitives and track helpers

Not implemented yet:

- TCP/TLS transport
- WebSocket handshake transport
- Live Discord Gateway session handling
- UDP voice transport
- Voice encryption
- Ogg Opus parsing and full audio playback

## Repository Layout

```text
src/
  core/          client state, dispatcher, result helpers
  json/          JSON validation and path readers
  net/           HTTP and WebSocket codecs, future transport layers
  gateway/       Gateway payload builders and event mapping
  voice/         voice session state and future UDP/gateway logic
  rtp/           RTP header and packet builders
  crypto/        future voice encryption layer
  opus/          Opus helpers and future readers/encoders
  audio/         player-side abstractions
  music/         queue and command helpers
  copybooks/     shared COBOL data definitions

examples/        runnable phase-oriented examples
tests/           executable COBOL tests
docs/            API notes and roadmap
```

## Quick Start

### Requirements

- GnuCOBOL `cobc`

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

Current test suite:

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

## Configuration

Discord tokens should not be hard-coded. The project uses environment-driven configuration and includes:

- `.env.example`
- `.gitignore` coverage for `.env`

The intended bot entrypoint pattern is shown in [examples/02-gateway-ready/main.cob](examples/02-gateway-ready/main.cob).

## Documentation

- Design document: [discord_cob_design.md](discord_cob_design.md)
- API notes: [docs/api.md](docs/api.md)
- Roadmap: [docs/roadmap.md](docs/roadmap.md)

## Roadmap Snapshot

Near-term priorities:

1. WebSocket handshake helpers and `Sec-WebSocket-Accept` validation
2. Minimal Discord Gateway `HELLO` and `READY` handling
3. Slash command `/ping`
4. Voice join state machine
5. UDP discovery and encrypted voice packet groundwork

## Contributing

The project is still in an exploratory phase, but issues and discussions around protocol handling, COBOL portability, and Discord compatibility are welcome. Small, test-backed changes fit best with the current direction.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
