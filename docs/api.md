# API Notes

## Result

All public APIs return `DC-RESULT`.

```cobol
COPY "discord-result.cpy".
```

`DC-STATUS-CODE = 0` means success. Errors use `DC-ERROR-CODE` and `DC-ERROR-MESSAGE`.

## Core

```cobol
CALL "DC-CLIENT-INIT"
    USING DC-CONFIG
          DC-CLIENT
          DC-RESULT.

CALL "DC-ON"
    USING DC-CLIENT
          EVENT-NAME
          HANDLER-PROGRAM
          DC-RESULT.

CALL "DC-DISPATCH"
    USING DC-CLIENT
          DC-EVENT
          DC-RESULT.
```

Handlers are normal COBOL programs.

```cobol
PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
```

## JSON

The first implementation is a path reader, not a full DOM parser.

```cobol
CALL "DC-JSON-GET-STRING"
    USING JSON-BUFFER
          JSON-PATH
          OUT-VALUE
          DC-RESULT.

CALL "DC-JSON-GET-NUMBER"
    USING JSON-BUFFER
          JSON-PATH
          OUT-NUMBER
          DC-RESULT.
```

Supported examples:

- `$.op`
- `$.t`
- `$.s`
- `$.d.session_id`
- `$.d.heartbeat_interval`

## RTP

```cobol
CALL "DC-RTP-BUILD-PACKET"
    USING DC-RTP-STATE
          DC-OPUS-FRAME
          DC-RTP-PACKET
          DC-RESULT.

CALL "DC-RTP-ADVANCE"
    USING DC-RTP-STATE
          DC-RESULT.
```

The current packet builder is still the unencrypted core.
`DC-VOICE-SEND-FRAME` can send that raw RTP payload over UDP for local tests when no encryption mode has been negotiated yet.
Once Voice session description negotiates an encryption mode, send attempts currently fail fast until the AEAD layer is implemented.

## UDP

The UDP transport now mirrors the TCP/TLS split between fixtures and an opt-in OS-backed runtime path.

```cobol
CALL "DC-UDP-OPEN"
    USING DC-UDP-SESSION
          DC-RESULT.

CALL "DC-UDP-SEND"
    USING DC-UDP-SESSION
          DC-UDP-PACKET
          DC-RESULT.

CALL "DC-UDP-RECV"
    USING DC-UDP-SESSION
          DC-UDP-PACKET
          DC-RESULT.
```

Fixture-backed sessions are used in tests.
When no matching fixture exists, the current live path uses spawned `nc -u` processes behind the same handle API.

## HTTP

Raw HTTP response parsing and mock-backed HTTPS request execution are available. Live sockets are still pending.

```cobol
CALL "DC-HTTP-BUILD-REQUEST"
    USING DC-HTTP-REQUEST
          DC-HTTP-BUFFER
          DC-RESULT.

CALL "DC-HTTP-GET"
    USING DC-HTTP-REQUEST
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-HTTP-POST"
    USING DC-HTTP-REQUEST
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-HTTP-PARSE-RESPONSE"
    USING RAW-RESPONSE
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-HTTP-GET-HEADER"
    USING DC-HTTP-RAW-HEADERS
          "Content-Type"
          HEADER-VALUE
          DC-RESULT.
```

`Content-Length`, basic `Transfer-Encoding: chunked` bodies, raw request generation, fixture-driven TLS execution, and live TLS-backed request execution are supported.

## TCP / TLS

The transport layer provides both in-memory fixtures and OS-backed process transports. The live path currently uses spawned `nc` and `openssl s_client` processes behind the same handle API.

```cobol
CALL "DC-TCP-CONNECT"
    USING HOST
          PORT
          TCP-HANDLE
          DC-RESULT.

CALL "DC-TLS-CONNECT"
    USING HOST
          PORT
          TLS-HANDLE
          DC-RESULT.

CALL "DC-TLS-CLOSE"
    USING TLS-HANDLE
          DC-RESULT.

CALL "DC-TLS-MOCK-SET-RESPONSE"
    USING HOST
          PORT
          DC-HTTP-BUFFER
          DC-RESULT.
```

## URL

```cobol
CALL "DC-URL-BUILD-WSS"
    USING ENDPOINT
          VERSION
          URL-OUT
          DC-RESULT.

CALL "DC-URL-SPLIT-WSS"
    USING URL-IN
          HOST-OUT
          PATH-OUT
          DC-RESULT.
```

## WebSocket

The WebSocket layer supports protocol-level connect/send/recv in an in-memory session and an opt-in live TLS-backed session path.

```cobol
CALL "DC-WS-ENCODE-FRAME"
    USING DC-WS-FRAME
          DC-WS-BUFFER
          DC-RESULT.

CALL "DC-WS-DECODE-FRAME"
    USING DC-WS-BUFFER
          DC-WS-FRAME
          DC-RESULT.

CALL "DC-WS-BUILD-HANDSHAKE-REQUEST"
    USING DC-WS-REQUEST
          DC-WS-BUFFER
          DC-RESULT.

CALL "DC-WS-VALIDATE-HS-RESPONSE"
    USING DC-WS-REQUEST
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-WS-CONNECT"
    USING DC-WS-REQUEST
          DC-WS-SESSION
          DC-RESULT.

CALL "DC-WS-SEND-TEXT"
    USING DC-WS-SESSION
          TEXT-PAYLOAD
          DC-RESULT.

CALL "DC-WS-RECV"
    USING DC-WS-SESSION
          DC-WS-FRAME
          DC-RESULT.
```

Current coverage:

- unmasked frames
- masked client and server frame handling
- payload lengths up to 65535 bytes
- opening handshake request/response helpers
- protocol-level connect/send/recv with in-memory session buffers
- opt-in live TLS-backed connect/send/recv
- ping to pong auto-response
- close frame state handling

Not yet covered:

- 64-bit payload lengths
- buffered multi-read / multi-frame live streaming

## Gateway

Gateway now has a minimal runtime path on top of the live WebSocket layer.

```cobol
CALL "DC-GATEWAY-BUILD-URL-REQUEST"
    USING DC-CLIENT
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-GATEWAY-APPLY-URL-RESPONSE"
    USING DC-CLIENT
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-GATEWAY-BUILD-WS-REQUEST"
    USING DC-CLIENT
          DC-WS-REQUEST
          DC-RESULT.

CALL "DC-GATEWAY-CONNECT"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-LOGIN"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-EVENT-LOOP-TICK"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-HEARTBEAT-BUILD"
    USING DC-CLIENT-SEQUENCE
          HEARTBEAT-PAYLOAD
          DC-RESULT.

CALL "DC-IDENTIFY-BUILD"
    USING DC-CLIENT
          IDENTIFY-PAYLOAD
          DC-RESULT.

CALL "DC-RESUME-BUILD"
    USING DC-CLIENT
          RESUME-PAYLOAD
          DC-RESULT.

CALL "DC-GATEWAY-QUEUE-PAYLOAD"
    USING DC-CLIENT
          ACTION-NAME
          JSON-PAYLOAD
          DC-RESULT.

CALL "DC-GATEWAY-NEXT-PAYLOAD"
    USING DC-CLIENT
          ACTION-NAME
          JSON-PAYLOAD
          DC-RESULT.

CALL "DC-GATEWAY-HANDLE-PAYLOAD"
    USING DC-CLIENT
          GATEWAY-JSON
          DC-EVENT
          DC-RESULT.
```

Current coverage:

- `/api/vX/gateway/bot` request preparation
- gateway URL response application
- gateway WS request preparation
- live Gateway connect/login over the shared HTTP/TLS/WebSocket stack
- minimal event-loop tick that can recv, apply, and send Gateway payloads
- heartbeat scheduling on top of repeated tick calls
- outbound payload queueing
- next-payload planning for Identify, Resume, Heartbeat, and queued sends
- `HELLO` heartbeat interval extraction
- `READY` session and user application
- synthetic events for `HEARTBEAT_ACK`, `RECONNECT`, and `INVALID_SESSION`

## Voice

Voice now has a minimal runtime path on top of the shared WebSocket and TLS stack.

```cobol
CALL "DC-VOICE-SESSION-INIT"
    USING DC-VOICE-SESSION
          GUILD-ID
          CHANNEL-ID
          DC-RESULT.

CALL "DC-VOICE-STATE-UPDATE-BUILD"
    USING GUILD-ID
          CHANNEL-ID
          GATEWAY-PAYLOAD
          DC-RESULT.

CALL "DC-VOICE-JOIN"
    USING DC-CLIENT
          GUILD-ID
          CHANNEL-ID
          DC-RESULT.

CALL "DC-VOICE-LEAVE"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-VOICE-APPLY-STATE-UPDATE"
    USING VOICE-STATE-JSON
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-APPLY-SERVER-UPDATE"
    USING VOICE-SERVER-JSON
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-IDENTIFY-BUILD"
    USING DC-VOICE-IDENTIFY
          IDENTIFY-PAYLOAD
          DC-RESULT.

CALL "DC-VOICE-SELECT-PROTOCOL-BUILD"
    USING DC-SELECT-PROTOCOL
          SELECT-PROTOCOL-PAYLOAD
          DC-RESULT.

CALL "DC-VOICE-RESUME-BUILD"
    USING DC-VOICE-SESSION
          RESUME-PAYLOAD
          DC-RESULT.

CALL "DC-VOICE-BUILD-WS-REQUEST"
    USING DC-CLIENT
          DC-VOICE-SESSION
          DC-WS-REQUEST
          DC-RESULT.

CALL "DC-VOICE-GATEWAY-CONNECT"
    USING DC-CLIENT
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-QUEUE-PAYLOAD"
    USING DC-VOICE-SESSION
          ACTION-NAME
          JSON-PAYLOAD
          DC-RESULT.

CALL "DC-VOICE-EVENT-LOOP-TICK"
    USING DC-CLIENT
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-HANDLE-PAYLOAD"
    USING DC-VOICE-SESSION
          VOICE-GATEWAY-JSON
          DC-RESULT.

CALL "DC-VOICE-UDP-DISCOVERY-BUILD"
    USING DC-UDP-DISCOVERY
          DC-RESULT.

CALL "DC-VOICE-UDP-DISCOVERY-PARSE"
    USING DC-UDP-DISCOVERY
          DC-RESULT.

CALL "DC-VOICE-UDP-DISCOVERY-APPLY"
    USING DC-VOICE-SESSION
          DC-UDP-DISCOVERY
          DC-RESULT.
```

Current coverage:

- voice session state/server payload application
- main-gateway voice state update payload building
- queued voice join/leave requests through the gateway planner
- voice identify, select-protocol, resume, and speaking payload builders
- voice WS request preparation
- live Voice Gateway connect over the shared WebSocket/TLS stack
- minimal voice event-loop tick that can recv, apply, queue, and send voice payloads
- voice heartbeat scheduling on top of repeated tick calls
- voice `HELLO`, `READY`, and session-description field application
- applying parsed UDP discovery results into queued select-protocol payloads
- queued select-protocol and speaking payload send flow
- UDP discovery request build and response parse

## Opus

```cobol
CALL "DC-OPUS-OPEN"
    USING DC-AUDIO-SOURCE
          DC-OPUS-HANDLE
          DC-RESULT.

CALL "DC-OPUS-READ-FRAME"
    USING DC-OPUS-HANDLE
          DC-OPUS-FRAME
          DC-RESULT.

CALL "DC-OPUS-CLOSE"
    USING DC-OPUS-HANDLE
          DC-RESULT.
```

Current coverage:

- initial in-memory Ogg Opus page parsing
- `OpusHead` and `OpusTags` skip handling
- multi-packet page extraction into Opus frames
- explicit reader handle close and reuse

Current limitations:

- whole-file buffering with a fixed 262144-byte reader buffer
- frame duration currently assumed as 20ms
- end-to-end live playback still needs fuller voice-session orchestration

## Interactions

```cobol
CALL "DC-INTERACTION-FROM-JSON"
    USING INTERACTION-JSON
          DC-INTERACTION
          DC-RESULT.

CALL "DC-INTERACTION-HANDLE"
    USING DC-CLIENT
          INTERACTION-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-CALLBACK-BUILD"
    USING DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-REGISTER"
    USING DC-CLIENT
          DC-RESULT.
```

Current coverage:

- raw and wrapped `INTERACTION_CREATE` JSON parsing
- slash-command routing into `/join`, `/leave`, `/play`, `/skip`, `/stop`, and `/queue`
- immediate type-4 reply payload construction
- callback HTTP request building and POST execution
- dispatcher-friendly handler registration through `DC-INTERACTION-REGISTER`

## Music Queue

```cobol
CALL "DC-MUSIC-QUEUE-INIT"
    USING DC-MUSIC-QUEUE
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-QUEUE-PUSH"
    USING DC-MUSIC-QUEUE
          DC-MUSIC-TRACK
          DC-RESULT.

CALL "DC-MUSIC-QUEUE-POP"
    USING DC-MUSIC-QUEUE
          DC-MUSIC-TRACK
          DC-RESULT.
```

Additional playback-facing entry points:

```cobol
CALL "DC-MUSIC-PLAY"
    USING DC-CLIENT
          GUILD-ID
          CHANNEL-ID
          DC-AUDIO-SOURCE
          DC-RESULT.

CALL "DC-MUSIC-SKIP"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-STOP"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-QUEUE-LIST"
    USING DC-CLIENT
          GUILD-ID
          DC-MUSIC-QUEUE
          DC-RESULT.

CALL "DC-MUSIC-VOICE-TICK"
    USING DC-CLIENT
          DC-VOICE-SESSION
          DC-RESULT.
```

Current coverage:

- queue-backed `/play file:<path>` command routing
- per-guild music runtime state
- Voice tick integration that can open queued Ogg Opus sources and send raw or encrypted RTP frames in fixture/local tests
- queue inspection, skip, and stop primitives

Current limitations:

- live Discord playback still stops at negotiated voice encryption
- slash-command registration through HTTP is still partial
- deferred replies, followups, and component/modal interaction flows are not implemented yet
