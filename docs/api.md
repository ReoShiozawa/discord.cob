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

Raw HTTP response parsing is available even though socket transport is not.

```cobol
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

`Content-Length` and basic `Transfer-Encoding: chunked` bodies are supported.

## WebSocket

Transport is still pending, but frame encoding and decoding are available.

```cobol
CALL "DC-WS-ENCODE-FRAME"
    USING DC-WS-FRAME
          DC-WS-BUFFER
          DC-RESULT.

CALL "DC-WS-DECODE-FRAME"
    USING DC-WS-BUFFER
          DC-WS-FRAME
          DC-RESULT.
```

Current coverage:

- unmasked frames
- masked frame decoding
- payload lengths up to 65535 bytes

Not yet covered:

- 64-bit payload lengths
- handshake validation
- live socket transport

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
