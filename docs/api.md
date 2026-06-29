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
PROCEDURE DIVISION USING DC-EVENT DC-RESULT.
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

The current packet builder is unencrypted and intended for internal testing.
Voice encryption will wrap this in a later phase.

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

Gateway payload helpers are available before the full Discord Gateway session loop lands.

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
- outbound payload queueing
- next-payload planning for Identify, Resume, Heartbeat, and queued sends
- `HELLO` heartbeat interval extraction
- `READY` session and user application
- synthetic events for `HEARTBEAT_ACK`, `RECONNECT`, and `INVALID_SESSION`

## Voice

Voice session helpers are available for the pre-transport parts of the flow.

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
```

Current coverage:

- voice session state/server payload application
- main-gateway voice state update payload building
- queued voice join/leave requests through the gateway planner
- voice identify, select-protocol, resume, and speaking payload builders
- voice WS request preparation
- voice `HELLO`, `READY`, and session-description field application
- UDP discovery request build and response parse

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
