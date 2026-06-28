# Roadmap

## Phase 0: Core

Status: implemented enough for tests.

- Copybooks
- Result helpers
- Client init
- Event registration
- Dispatch

## Phase 1: JSON

Status: initial path reader implemented.

Next:

- Proper tokenizer output
- Escape handling
- Array indexing
- Depth-aware lookup

## Phase 2: HTTP / TLS / WebSocket

Status: parser/codec utilities and handshake helpers are implemented, transport still pending.

Implemented:

- HTTP response parser
- HTTP header lookup
- Basic chunked body decoding
- WebSocket frame encode/decode
- Masked frame decoding
- WebSocket handshake request builder
- `Sec-WebSocket-Accept` validation

Next:

- HTTP request builder
- TLS research track

## Phase 3: Gateway

Status: payload builders, HELLO handling, READY application, and basic synthetic op events are implemented.

Next:

- Gateway URL request
- Heartbeat loop
- live Identify/Resume send flow
- broader dispatch coverage

## Phase 4: Interactions

Status: command router skeleton.

Next:

- Slash command registration through HTTP
- Interaction payload parser
- Interaction callback HTTP response

## Phase 5+: Voice / RTP / Crypto / Opus / Music

Status:

- RTP packet builder implemented for unencrypted local tests
- Music queue implemented
- Voice payload builders, state/server updates, and UDP discovery helpers are implemented
- Crypto transport and Opus reader remain skeletons

Next:

- Voice Gateway WebSocket transport
- Voice select-protocol/send flow
- ChaCha20-Poly1305
- Ogg Opus packet extraction
- `/play file:<path>`
