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

CALL "DC-BOT-REGISTER-DEFAULTS"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-BOT-TICK"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-BOT-RUN-STEPS"
    USING DC-CLIENT
          STEP-COUNT
          WAIT-MS
          DC-RESULT.

CALL "DC-BOT-RUN"
    USING DC-CLIENT
          STEP-COUNT
          WAIT-MS
          DC-RESULT.

CALL "DC-BOT-RUN-UNTIL-FILE"
    USING DC-CLIENT
          STOP-FILE
          WAIT-MS
          DC-RESULT.

CALL "DC-BOT-SHUTDOWN"
    USING DC-CLIENT
          DC-RESULT.
```

Handlers are normal COBOL programs.

```cobol
PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
```

`DC-BOT-REGISTER-DEFAULTS` wires the framework-provided voice and interaction handlers.
`DC-BOT-TICK` advances Gateway and all stored voice sessions once.
`DC-BOT-RUN-STEPS` repeats that high-level tick a fixed number of times.
`DC-BOT-RUN` does the same, but `STEP-COUNT <= 0` keeps the process loop running until it is stopped externally.
`DC-BOT-RUN-UNTIL-FILE` keeps the same loop running until the given stop-file path appears on disk.
`DC-BOT-SHUTDOWN` explicitly tears down stored voice/music runtimes and disconnects the Gateway session.

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

The current packet builder is still the unencrypted RTP core.
`DC-VOICE-SEND-FRAME` can send that raw RTP payload before encryption is negotiated, and it can also encrypt voice payloads for the currently supported Discord mode `aead_xchacha20_poly1305_rtpsize`.

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

CALL "DC-HTTP-PUT"
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

`Content-Length`, basic `Transfer-Encoding: chunked` bodies, raw request generation, fixture-driven TLS execution, and live TLS-backed GET/POST/PUT/PATCH/DELETE execution are supported.

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

## Voice / Music Runtime

The voice and music layers now expose guild-scoped stored-session helpers in addition
to the lower-level live session APIs.

```cobol
CALL "DC-VOICE-REGISTER"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-VOICE-SESSION-LOAD"
    USING GUILD-ID
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-SESSION-SAVE"
    USING GUILD-ID
          DC-VOICE-SESSION
          DC-RESULT.

CALL "DC-VOICE-EVENT-LOOP-TICK-STORED"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-VOICE-EVENT-LOOP-TICK-ALL"
    USING DC-CLIENT
          DC-RESULT.

CALL "DC-MUSIC-VOICE-TICK-STORED"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-BOT-BOOTSTRAP"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.
```

Current behavior:

- Gateway voice events populate stored voice sessions by guild
- stored voice ticks can auto-connect a Voice Gateway session when `endpoint` is ready
- music playback can advance through the stored-session path without the caller
  manually keeping a live `DC-VOICE-SESSION`
- `DC-MUSIC-BOT-BOOTSTRAP` performs default handler registration and command overwrite
- guild-scoped music runtimes can auto-queue a voice leave after a configurable number of idle bot ticks

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

CALL "DC-INTERACTION-BUILD-DEFERRED"
    USING REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-BUILD-UPDATE"
    USING REPLY-CONTENT
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-IA-BUILD-EMBED"
    USING EMBED-TITLE
          EMBED-DESCRIPTION
          EMBED-COLOR
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-IA-BUILD-ECOMP"
    USING EMBED-TITLE
          EMBED-DESCRIPTION
          EMBED-COLOR
          COMPONENTS-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-IA-BUILD-UEMB"
    USING EMBED-TITLE
          EMBED-DESCRIPTION
          EMBED-COLOR
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-IA-BUILD-UECMP"
    USING EMBED-TITLE
          EMBED-DESCRIPTION
          EMBED-COLOR
          COMPONENTS-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-IA-BUILD-UPDATE-COMP"
    USING REPLY-CONTENT
          COMPONENTS-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-BUILD-COMPONENT"
    USING REPLY-CONTENT
          COMPONENTS-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-BUILD-MODAL"
    USING CUSTOM-ID
          TITLE
          COMPONENTS-JSON
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-DEFER"
    USING DC-INTERACTION
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-DEFER-EDIT"
    USING DC-CLIENT
          DC-INTERACTION
          EDIT-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-DEFER-DEL"
    USING DC-CLIENT
          DC-INTERACTION
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-BUILD-FOLLOWUP"
    USING REPLY-CONTENT
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-FOLLOWUP-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-FOLLOWUP"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-WAIT-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-FUP-WAIT"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-WAIT-ID"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          MESSAGE-ID
          DC-RESULT.

CALL "DC-INTERACTION-FUP-GET-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-FUP-GET"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-EDIT-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          REPLY-PAYLOAD
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-FUP-EDIT"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-EDIT-MSG"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-JSON
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-WAIT-EDIT"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          EDIT-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-DEL-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-FUP-DEL"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-ID
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-DEL-MSG"
    USING DC-CLIENT
          DC-INTERACTION
          MESSAGE-JSON
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-FUP-WAIT-DEL"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-EDIT-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-EDIT"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-GET-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-GET"
    USING DC-CLIENT
          DC-INTERACTION
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-GET-MESSAGE-ID"
    USING MESSAGE-JSON
          MESSAGE-ID
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-DEL-BUILD"
    USING DC-CLIENT
          DC-INTERACTION
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-INTERACTION-ORIG-DEL"
    USING DC-CLIENT
          DC-INTERACTION
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-INTERACTION-ON-COMMAND"
    USING DC-CLIENT
          COMMAND-NAME
          HANDLER-PROGRAM
          DC-RESULT.

CALL "DC-INTERACTION-ON-COMPONENT"
    USING DC-CLIENT
          CUSTOM-ID
          HANDLER-PROGRAM
          DC-RESULT.

CALL "DC-INTERACTION-ON-MODAL"
    USING DC-CLIENT
          CUSTOM-ID
          HANDLER-PROGRAM
          DC-RESULT.

CALL "DC-INTERACTION-DISPATCH"
    USING DC-CLIENT
          DC-INTERACTION
          REPLY-PAYLOAD
          DC-RESULT.

CALL "DC-INTERACTION-REGISTER"
    USING DC-CLIENT
          DC-RESULT.
```

Current coverage:

- raw and wrapped `INTERACTION_CREATE` JSON parsing
- application command, component, and modal-submit field extraction
- custom command, component, and modal handler registration plus dispatch
- slash-command routing into `/join`, `/leave`, `/play`, `/skip`, `/pause`, `/resume`, `/stop`, `/queue`, `/remove`, `/clearqueue`, and `/nowplaying`
- immediate, embed, update, modal, ephemeral, and deferred response payload construction
- JSON-safe escaping for reply, embed, update, and follow-up content payloads
- music-specific custom interaction handlers for `/nowplaying` and `/queue` with button rows and embed-based panel replies
- callback, follow-up create/wait/get/edit/delete, and original-response get/edit/delete HTTP helpers
- one-call defer-to-original-edit and defer-to-original-delete helpers
- one-call follow-up wait + message-id extraction helper
- message-id extraction from follow-up/original response JSON
- JSON-to-edit/delete follow-up lifecycle helpers
- one-call wait-to-edit and wait-to-delete follow-up lifecycle helpers
- component select and modal input value lookup helpers
- dispatcher-friendly handler registration through `DC-INTERACTION-REGISTER`

## Slash Command Schema

Higher-level command definition API. Commands are declared as structured
schema data (`discord-command-schema.cpy`) instead of hand-written JSON, then
converted into a stable payload or synchronized to Discord in one call. The
low-level registration helpers below remain available and unchanged.

```cobol
CALL "DC-COMMAND-SCHEMA-INIT"
    USING DC-COMMAND-SCHEMA
          DC-RESULT.

CALL "DC-COMMAND-SCHEMA-ADD"
    USING DC-COMMAND-SCHEMA
          COMMAND-NAME
          COMMAND-DESCRIPTION
          DC-RESULT.

CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
    USING DC-COMMAND-SCHEMA
          OPTION-NAME
          OPTION-TYPE
          OPTION-DESCRIPTION
          OPTION-REQUIRED
          DC-RESULT.

CALL "DC-COMMAND-SCHEMA-VALIDATE"
    USING DC-COMMAND-SCHEMA
          DC-RESULT.

CALL "DC-COMMAND-SCHEMA-TO-JSON"
    USING DC-COMMAND-SCHEMA
          COMMANDS-JSON
          DC-RESULT.

CALL "DC-COMMAND-SCHEMA-SYNC"
    USING DC-CLIENT
          GUILD-ID
          DC-COMMAND-SCHEMA
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-MUSIC-COMMANDS-SCHEMA"
    USING DC-COMMAND-SCHEMA
          DC-RESULT.
```

Behavior notes:

- `DC-COMMAND-SCHEMA-ADD` appends one chat-input command (type 1) with a name
  and description; options are attached to the most recently added command
  with `DC-COMMAND-SCHEMA-ADD-OPTION`
- `OPTION-TYPE` takes Discord option types directly (for example 3 = string,
  4 = integer) as `PIC 9(4) COMP-5`; `OPTION-REQUIRED` is `0` or `1`
- `DC-COMMAND-SCHEMA-VALIDATE` rejects empty schemas, blank names or
  descriptions, non-lowercase names, and out-of-range types with the
  `DC_ERR_COMMAND_SCHEMA` error code
- `DC-COMMAND-SCHEMA-TO-JSON` validates first, then produces a stable JSON
  array with fixed key order, so the same schema always yields the same
  payload; text fields are JSON-escaped and `"required"` is emitted only when
  true
- `DC-COMMAND-SCHEMA-SYNC` converts the schema and performs a bulk overwrite
  (`PUT`) through `DC-SLASH-COMMAND-OVERWRITE`; an empty guild id targets
  global commands
- `DC-MUSIC-COMMANDS-SCHEMA` declares the built-in music command set through
  this API, and `DC-MUSIC-COMMANDS-BUILD-SET` now derives its JSON from that
  schema, so the built-in registration path is the reference migration example

Complete example:

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-SCHEMA-SYNC.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       COPY "discord-command-schema.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "example-guild-id".
       01 WS-COMMAND-NAME PIC X(32).
       01 WS-COMMAND-DESC PIC X(100).
       01 WS-OPTION-NAME PIC X(32).
       01 WS-OPTION-TYPE PIC 9(4) COMP-5.
       01 WS-OPTION-DESC PIC X(100).
       01 WS-OPTION-REQUIRED PIC 9(4) COMP-5.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE "example-token" TO DC-BOT-TOKEN
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           MOVE "example-application-id" TO DC-CLIENT-ID

           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA DC-RESULT

           MOVE "echo" TO WS-COMMAND-NAME
           MOVE "Echo a message back" TO WS-COMMAND-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-COMMAND-NAME
                     WS-COMMAND-DESC
                     DC-RESULT

           MOVE "message" TO WS-OPTION-NAME
           MOVE 3 TO WS-OPTION-TYPE
           MOVE "Message to echo" TO WS-OPTION-DESC
           MOVE 1 TO WS-OPTION-REQUIRED
           CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
               USING DC-COMMAND-SCHEMA
                     WS-OPTION-NAME
                     WS-OPTION-TYPE
                     WS-OPTION-DESC
                     WS-OPTION-REQUIRED
                     DC-RESULT

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-COMMAND-SCHEMA-SYNC"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-COMMAND-SCHEMA
                     DC-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-MESSAGE)
           END-IF
           STOP RUN.
       END PROGRAM EXAMPLE-SCHEMA-SYNC.
```

Current coverage:

- structured command declaration with name/description/options metadata over
  fixed-width tables (`discord-command-schema.cpy`)
- schema validation with a dedicated `DC_ERR_COMMAND_SCHEMA` error code
- deterministic schema-to-JSON conversion reusable for register and overwrite
  payloads
- one-call synchronization through the existing bulk-overwrite REST path
- built-in music commands declared through the same schema API
- mock-backed schema conversion and sync tests in `tests/slash-command-test.cob`

## Slash Command Registration

```cobol
CALL "DC-SLASH-COMMAND-BUILD-REQUEST"
    USING DC-CLIENT
          GUILD-ID
          COMMAND-JSON
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-SLASH-COMMAND-REGISTER"
    USING DC-CLIENT
          GUILD-ID
          COMMAND-JSON
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-SLASH-COMMAND-BUILD-LIST"
    USING DC-CLIENT
          GUILD-ID
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-SLASH-COMMAND-LIST"
    USING DC-CLIENT
          GUILD-ID
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-SLASH-COMMAND-BUILD-DELETE"
    USING DC-CLIENT
          GUILD-ID
          COMMAND-ID
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-SLASH-COMMAND-DELETE"
    USING DC-CLIENT
          GUILD-ID
          COMMAND-ID
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-SLASH-COMMAND-BUILD-SET"
    USING DC-CLIENT
          GUILD-ID
          COMMANDS-JSON
          DC-HTTP-REQUEST
          DC-RESULT.

CALL "DC-SLASH-COMMAND-OVERWRITE"
    USING DC-CLIENT
          GUILD-ID
          COMMANDS-JSON
          DC-HTTP-RESPONSE
          DC-RESULT.

CALL "DC-MUSIC-COMMANDS-REGISTER"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-COMMANDS-OVERWRITE"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-INTERACTIONS-REGISTER"
    USING DC-CLIENT
          DC-RESULT.
```

Current coverage:

- global or guild-scoped command registration, listing, deletion, and bulk overwrite over REST
- request building with bot authorization and versioned Discord paths
- built-in bootstrap registration and bulk overwrite helpers for `/join`, `/leave`, `/play`, `/skip`, `/pause`, `/resume`, `/stop`, `/queue`, `/remove`, `/clearqueue`, and `/nowplaying`
- built-in registration of the richer `/nowplaying` custom handler plus `music:skip`, `music:pause`, and `music:resume` component handlers
- mock-backed slash-command REST tests through the shared TLS/HTTP transport

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

CALL "DC-MUSIC-PAUSE"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-RESUME"
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

CALL "DC-MUSIC-REMOVE"
    USING DC-CLIENT
          GUILD-ID
          POSITION
          DC-MUSIC-TRACK
          DC-RESULT.

CALL "DC-MUSIC-CLEARQUEUE"
    USING DC-CLIENT
          GUILD-ID
          DC-RESULT.

CALL "DC-MUSIC-NOWPLAYING"
    USING DC-CLIENT
          GUILD-ID
          DC-MUSIC-TRACK
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
- queue inspection, queue removal/clear, now-playing lookup, pause/resume, skip, and stop primitives
- a custom `/nowplaying` interaction panel with inline skip/pause/resume buttons
- a custom `/queue` interaction panel with remove-first, clear, refresh, and now-playing navigation buttons
- idle playback runtimes can now auto-leave voice after a configurable number of idle ticks

Current limitations:

- live Discord playback still depends on the current negotiated voice-session path
- higher-level embed-focused reply builders still need dedicated sugar

The new `examples/08-play-opus-file/main.cob` shows the current direct live-oriented path for:

- registering the default voice and interaction handlers
- logging in over the Gateway runtime
- queueing a local Opus/Ogg Opus source with `DC-MUSIC-PLAY`
- advancing the bot loop with `DC-BOT-RUN` or `DC-BOT-RUN-UNTIL-FILE`
