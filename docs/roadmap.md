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

Status: parser/codec utilities, handshake helpers, raw request builders, in-memory and OS-backed TCP/TLS transports, mock-backed and live HTTP execution, and in-memory plus opt-in live WebSocket session flow are implemented.

Implemented:

- HTTP response parser
- HTTP header lookup
- HTTP request builder
- Mock-backed and live HTTP GET/POST/PATCH/DELETE execution over TLS
- Basic chunked body decoding
- In-memory TCP/TLS connection handles and fixtures
- OS-backed TCP/TLS transport processes
- WebSocket frame encode/decode
- Masked client/server frame handling
- WebSocket handshake request builder
- `Sec-WebSocket-Accept` validation
- WebSocket connect/send/recv over in-memory session buffers
- Opt-in live WebSocket connect/send/recv over TLS

Next:

- Buffered live streaming and frame accumulation
- Explicit higher-level WebSocket close / lifecycle helpers

## Phase 3: Gateway

Status: URL request prep, WS request prep, payload builders, outbound queueing, next-payload planning, HELLO handling, READY application, and basic synthetic op events are implemented.

Next:

- Heartbeat loop
- live transport for Identify/Resume/custom sends
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
- Voice payload builders, join/leave gateway payload queueing, state/server updates, and UDP discovery helpers are implemented
- Voice WebSocket request preparation is implemented
- Crypto transport and Opus reader remain skeletons

Next:

- Voice Gateway WebSocket transport
- Voice select-protocol/send flow
- ChaCha20-Poly1305
- Ogg Opus packet extraction
- `/play file:<path>`
