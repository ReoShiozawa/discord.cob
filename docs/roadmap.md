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
- Mock-backed and live HTTP GET/POST/PUT/PATCH/DELETE execution over TLS
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

Status: URL request prep, WS request prep, live Gateway connect/login, event-loop tick send/recv flow, heartbeat scheduling, payload builders, outbound queueing, next-payload planning, HELLO handling, READY application, and basic synthetic op events are implemented.

Next:

- broader dispatch coverage
- richer reconnect / disconnect lifecycle handling
- missed-heartbeat / stale-ack handling

## Phase 4: Interactions

Status: slash-command routing, HTTP registration/list/delete/overwrite helpers, interaction payload parsing, deferred/follow-up callback helpers, component/modal field extraction, custom interaction routing, richer response payload builders, and follow-up/original response edit/delete helpers are implemented.

Next:

- Higher-level slash command schema / synchronization ergonomics
- embed-focused and schema-safe response builders
- follow-up retrieval / wait-mode helpers and response lifecycle polish

## Phase 5+: Voice / RTP / Crypto / Opus / Music

Status:

- RTP packet builder implemented for unencrypted local tests
- Music queue implemented
- Initial Ogg Opus packet extraction and explicit reader close are implemented
- Queue-backed playback state and a voice-attached playback tick are implemented for raw/local tests
- Voice payload builders, join/leave gateway payload queueing, state/server updates, session description secret-key capture, and UDP discovery helpers are implemented
- Voice WebSocket request preparation, live Voice Gateway connect, outbound queueing, heartbeat scheduling, UDP discovery apply-to-select-protocol flow, and a minimal event-loop tick are implemented
- UDP voice transport has fixture-backed and OS-backed session flow, and encrypted RTP frame send is available for negotiated `aead_xchacha20_poly1305_rtpsize` sessions
- Slash-command routing now reaches `/join`, `/leave`, `/play`, `/skip`, `/stop`, and `/queue`

Next:

- encrypted end-to-end playback over negotiated voice sessions
