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

Status: parser/codec utilities implemented, transport still pending.

Implemented:

- HTTP response parser
- HTTP header lookup
- Basic chunked body decoding
- WebSocket frame encode/decode
- Masked frame decoding

Next:

- Sec-WebSocket-Accept verification
- HTTP request builder
- WebSocket handshake request/response helpers
- TLS research track

## Phase 3: Gateway

Status: payload builders and event mapping skeleton.

Next:

- Gateway URL request
- WebSocket HELLO handling
- Heartbeat loop
- Identify
- READY dispatch

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
- Voice, UDP, crypto, and Opus reader are API skeletons

Next:

- Voice state/server update handling
- UDP discovery packet parser
- ChaCha20-Poly1305
- Ogg Opus packet extraction
- `/play file:<path>`
