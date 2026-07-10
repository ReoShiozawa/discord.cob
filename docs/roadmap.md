# Roadmap

## Phase 0: Core

Status: implemented.

- Copybooks
- Result helpers
- Client init
- Event registration
- Dispatch

## Phase 1: JSON

Status: implemented for the fixed-buffer framework contract.

- Validating token scanner with kind, offset, length, and depth output
- JSON grammar validation
- Escaped string and Unicode/surrogate decoding
- Safe string writer escaping
- Array indexing and nested-array paths
- Depth-aware object lookup

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

- Buffered live streaming and frame accumulation
- Coalesced-frame preservation and fragmented-message reassembly
- Ping/pong handling and explicit normal-close lifecycle helper

## Phase 3: Gateway

Status: URL request prep, WS request prep, live Gateway connect/login, event-loop tick send/recv flow, heartbeat scheduling, payload builders, outbound queueing, next-payload planning, HELLO handling, READY application, reconnect support, stale-heartbeat handling, and basic synthetic op events are implemented.

- Gateway dispatch, reconnect, stale-heartbeat recovery, and explicit teardown
- Bounded, unbounded, and stop-file-driven bot runtime helpers
- Graceful WebSocket close during Gateway shutdown

## Phase 4: Interactions

Status: slash-command routing, HTTP registration/list/delete/overwrite helpers, interaction payload parsing, autocomplete/component/modal field extraction, focused-option lookup, custom interaction routing, richer response payload builders, deferred/follow-up/autocomplete callback helpers, and follow-up/original response edit/delete helpers are implemented.

- High-level slash command schema validation and synchronization
- Embed/component/update/modal/autocomplete response builders
- Follow-up and original-response get/wait/edit/delete lifecycle helpers

## Phase 5+: Voice / RTP / Crypto / Opus / Music

Status:

- RTP packet builder implemented for unencrypted local tests
- Music queue implemented
- Ogg Opus packet extraction and explicit reader close are implemented
- Queue-backed playback state and a voice-attached playback tick are implemented
- Voice payload builders, join/leave gateway payload queueing, state/server updates, session description secret-key capture, and UDP discovery helpers are implemented
- Voice WebSocket request preparation, live Voice Gateway connect, reconnect, outbound queueing, heartbeat scheduling, UDP discovery apply-to-select-protocol flow, and a minimal event-loop tick are implemented
- Guild-scoped stored voice sessions now bridge Gateway dispatch and repeated voice/music ticks
- Stored voice ticks can auto-connect pending voice sessions once endpoint data is available
- A high-level music-bot bootstrap plus bounded and long-running bot tick runners are implemented
- UDP voice transport has fixture-backed and OS-backed session flow, and encrypted RTP frame send is available for negotiated `aead_xchacha20_poly1305_rtpsize` sessions
- Slash-command routing now reaches `/join`, `/leave`, `/play`, `/skip`, `/pause`, `/resume`, `/stop`, `/queue`, `/remove`, `/clearqueue`, and `/nowplaying`
- `/nowplaying` can now return an inline control panel, and music component interactions can drive skip/pause/resume updates in place
- `/queue` can now return an inline queue panel, and music component interactions can remove the head item, clear the queue, refresh the view, or jump back to now-playing
- idle music runtimes can now auto-queue a voice leave after a configurable number of idle bot ticks

- Negotiated `aead_xchacha20_poly1305_rtpsize` playback from local Ogg Opus sources
- Voice/Gateway normal-close teardown and idle voice leave
- Runnable examples for Voice join, UDP discovery, encrypted RTP, Opus playback, and the music bot

## First design milestone

Status: complete.

The architecture in `discord_cob_design.md` now has a runnable path from client initialization through Gateway/Interaction/Voice negotiation to encrypted Opus UDP playback. Future work is compatibility hardening, portability, optional media transcoding, and DAVE support rather than a missing core layer.
