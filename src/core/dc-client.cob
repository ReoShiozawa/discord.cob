       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CLIENT-INIT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CONFIG DC-CLIENT DC-RESULT.
       MAIN.
           *> JP: 初期化では user 設定を runtime client へ写し込みつつ、
           *> JP: 未指定値には framework の既定値を与えます。
           *> EN: Initialization copies user config into the runtime client and
           *> EN: fills in framework defaults for omitted values.
           *>
           *> JP: ここでは identity / audio / protocol version の固定設定だけを残し、
           *> JP: heartbeat や outbound queue のような実行時 state は必ず空に戻します。
           *> EN: This keeps static identity/audio/protocol settings while
           *> EN: always resetting runtime-only state such as heartbeats and queues.
           INITIALIZE DC-CLIENT
           MOVE DC-BOT-TOKEN TO DC-CLIENT-TOKEN
           MOVE DC-INTENTS TO DC-CLIENT-INTENTS
           MOVE DC-LOG-LEVEL TO DC-CLIENT-LOG-LEVEL
           IF DC-GATEWAY-VERSION = ZERO
               MOVE 10 TO DC-CLIENT-GATEWAY-VERSION
           ELSE
               MOVE DC-GATEWAY-VERSION TO DC-CLIENT-GATEWAY-VERSION
           END-IF
           IF DC-VOICE-GATEWAY-VERSION = ZERO
               MOVE 8 TO DC-CLIENT-VOICE-GATEWAY-VERSION
           ELSE
               MOVE DC-VOICE-GATEWAY-VERSION
                   TO DC-CLIENT-VOICE-GATEWAY-VERSION
           END-IF
           IF DC-AUDIO-FRAME-MS = ZERO
               MOVE 20 TO DC-CLIENT-AUDIO-FRAME-MS
           ELSE
               MOVE DC-AUDIO-FRAME-MS TO DC-CLIENT-AUDIO-FRAME-MS
           END-IF
           IF DC-AUDIO-SAMPLE-RATE = ZERO
               MOVE 48000 TO DC-CLIENT-AUDIO-SAMPLE-RATE
           ELSE
               MOVE DC-AUDIO-SAMPLE-RATE
                   TO DC-CLIENT-AUDIO-SAMPLE-RATE
           END-IF
           IF DC-AUDIO-CHANNELS = ZERO
               MOVE 2 TO DC-CLIENT-AUDIO-CHANNELS
           ELSE
               MOVE DC-AUDIO-CHANNELS TO DC-CLIENT-AUDIO-CHANNELS
           END-IF
           MOVE 0 TO DC-CLIENT-STATE
           MOVE 0 TO DC-CLIENT-SEQUENCE
           MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-NEXT-AT
           MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
           MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
           MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-DUE
           MOVE 0 TO DC-CLIENT-GW-AWAITING-ACK
           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD
           MOVE 0 TO DC-HANDLER-COUNT
           MOVE 0 TO DC-IA-COMMAND-COUNT
           MOVE 0 TO DC-IA-COMPONENT-COUNT
           MOVE 0 TO DC-IA-MODAL-COUNT
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-CLIENT-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-LOGIN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           *> JP: login は高水準の薄い入口で、実際の接続確立は Gateway 側へ委譲します。
           *> EN: Login is a thin high-level entry point; the actual connection
           *> EN: handshake is delegated to the Gateway layer.
           CALL "DC-GATEWAY-CONNECT"
               USING DC-CLIENT
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-LOGIN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CLIENT-SET-READY.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           *> JP: READY は Gateway hello/identify 完了後に event loop から立てられる、
           *> JP: 「通常運転に入った」ことを示す高水準 state です。
           *> EN: READY is the high-level state set by the event loop after
           *> EN: Gateway hello/identify completes and normal operation begins.
           MOVE 2 TO DC-CLIENT-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-CLIENT-SET-READY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CLIENT-DISCONNECT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           *> JP: 切断では socket を閉じるだけでなく、resume/heartbeat/queued command など
           *> JP: 接続にぶら下がる一時 state をまとめて破棄します。
           *> EN: Disconnect tears down not only the socket but also all
           *> EN: connection-scoped transient state such as resume, heartbeat,
           *> EN: and queued commands.
           *>
           *> JP: token や handler 登録のような client 全体の設定は保持するので、
           *> JP: 再接続時は再初期化なしで gateway を開き直せます。
           *> EN: Client-wide settings like the token and handler registry stay
           *> EN: intact so a reconnect can reopen the gateway without full reinit.
           IF DC-CLIENT-GW-WS-LIVE-FLAG = 1
              AND DC-CLIENT-GW-WS-HANDLE > 0
               CALL "DC-TLS-CLOSE"
                   USING DC-CLIENT-GW-WS-HANDLE
                         WS-LOCAL-RESULT
           END-IF
           MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-INTERVAL
           MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-NEXT-AT
           MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
           MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
           MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-DUE
           MOVE 0 TO DC-CLIENT-GW-AWAITING-ACK
           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD
           MOVE 0 TO DC-CLIENT-GW-WS-HANDLE
           MOVE 0 TO DC-CLIENT-GW-WS-OPEN-FLAG
           MOVE 0 TO DC-CLIENT-GW-WS-LAST-OPCODE
           MOVE 0 TO DC-CLIENT-GW-WS-LOOPBACK-FLAG
           MOVE 0 TO DC-CLIENT-GW-WS-LIVE-FLAG
           MOVE SPACES TO DC-CLIENT-GW-WS-HOST
           MOVE SPACES TO DC-CLIENT-GW-WS-PATH
           MOVE SPACES TO DC-CLIENT-GW-WS-SEC-KEY
           MOVE 0 TO DC-CLIENT-GW-WS-PORT
           MOVE 0 TO DC-CLIENT-GW-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE SPACES TO DC-CLIENT-GW-WS-HANDSHAKE-REQUEST
           MOVE 0 TO DC-CLIENT-GW-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE SPACES TO DC-CLIENT-GW-WS-HANDSHAKE-RESPONSE
           MOVE 0 TO DC-CLIENT-GW-WS-INBOUND-BUFFER-LENGTH
           MOVE SPACES TO DC-CLIENT-GW-WS-INBOUND-BUFFER
           MOVE 0 TO DC-CLIENT-GW-WS-OUTBOUND-BUFFER-LENGTH
           MOVE SPACES TO DC-CLIENT-GW-WS-OUTBOUND-BUFFER
           MOVE 3 TO DC-CLIENT-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-CLIENT-DISCONNECT.
