       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-GATEWAY-CONNECT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-VOICE-SESSION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-VS-ENDPOINT) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice endpoint is required before connecting Gateway."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-WS-OPEN-FLAG = 1
               CALL "DC-VOICE-DISCONNECT"
                   USING DC-VOICE-SESSION
                         WS-LOCAL-RESULT
           END-IF

           INITIALIZE DC-WS-REQUEST
           INITIALIZE DC-WS-SESSION

           CALL "DC-VOICE-BUILD-WS-REQUEST"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-WS-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE 1 TO DC-WS-REQUEST-LIVE-FLAG

           CALL "DC-WS-CONNECT"
               USING DC-WS-REQUEST
                     DC-WS-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-GATEWAY-SESSION-SAVE"
               USING DC-VOICE-SESSION
                     DC-WS-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE 2 TO DC-VS-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-GATEWAY-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-DISCONNECT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-VOICE-SESSION DC-RESULT.
       MAIN.
           IF DC-VS-WS-LIVE-FLAG = 1
              AND DC-VS-WS-HANDLE > 0
               CALL "DC-TLS-CLOSE"
                   USING DC-VS-WS-HANDLE
                         WS-LOCAL-RESULT
           END-IF
           MOVE SPACES TO DC-VS-GATEWAY-URL
           MOVE SPACES TO DC-VS-IP
           MOVE 0 TO DC-VS-PORT
           MOVE SPACES TO DC-VS-DISCOVERED-IP
           MOVE 0 TO DC-VS-DISCOVERED-PORT
           IF DC-VS-UDP-HANDLE > 0
               INITIALIZE DC-UDP-SESSION
               MOVE DC-VS-UDP-HANDLE TO DC-UDP-HANDLE
               CALL "DC-UDP-CLOSE"
                   USING DC-UDP-SESSION
                         WS-LOCAL-RESULT
           END-IF
           MOVE 0 TO DC-VS-UDP-HANDLE
           MOVE 0 TO DC-VS-SSRC
           MOVE 0 TO DC-VS-HEARTBEAT-INTERVAL
           MOVE 0 TO DC-VS-HEARTBEAT-NEXT-AT
           MOVE 0 TO DC-VS-HEARTBEAT-NONCE
           MOVE 0 TO DC-VS-MEDIA-NONCE
           MOVE 0 TO DC-VS-LAST-SEQ
           MOVE 0 TO DC-VS-IDENTIFY-NEEDED
           MOVE 0 TO DC-VS-RESUME-REQUESTED
           MOVE 0 TO DC-VS-HEARTBEAT-DUE
           MOVE 0 TO DC-VS-AWAITING-ACK
           MOVE SPACES TO DC-VS-SECRET-KEY
           MOVE 0 TO DC-VS-READY-FLAG
           MOVE 0 TO DC-VS-UDP-READY-FLAG
           MOVE SPACES TO DC-VS-ENCRYPTION-MODE
           MOVE 0 TO DC-VS-COMMAND-QUEUED
           MOVE SPACES TO DC-VS-COMMAND-NAME
           MOVE SPACES TO DC-VS-COMMAND-PAYLOAD
           MOVE 0 TO DC-VS-WS-HANDLE
           MOVE 0 TO DC-VS-WS-OPEN-FLAG
           MOVE 0 TO DC-VS-WS-LAST-OPCODE
           MOVE 0 TO DC-VS-WS-LOOPBACK-FLAG
           MOVE 0 TO DC-VS-WS-LIVE-FLAG
           MOVE SPACES TO DC-VS-WS-HOST
           MOVE SPACES TO DC-VS-WS-PATH
           MOVE SPACES TO DC-VS-WS-SEC-KEY
           MOVE 0 TO DC-VS-WS-PORT
           MOVE 0 TO DC-VS-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE SPACES TO DC-VS-WS-HANDSHAKE-REQUEST
           MOVE 0 TO DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE SPACES TO DC-VS-WS-HANDSHAKE-RESPONSE
           MOVE 0 TO DC-VS-WS-INBOUND-BUFFER-LENGTH
           MOVE SPACES TO DC-VS-WS-INBOUND-BUFFER
           MOVE 0 TO DC-VS-WS-OUTBOUND-BUFFER-LENGTH
           MOVE SPACES TO DC-VS-WS-OUTBOUND-BUFFER
           MOVE 0 TO DC-VS-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-DISCONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-GATEWAY-SESSION-LOAD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-WS-SESSION
           DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-SESSION
           MOVE DC-VS-WS-HANDLE TO DC-WS-HANDLE
           MOVE DC-VS-WS-OPEN-FLAG TO DC-WS-OPEN-FLAG
           MOVE DC-VS-WS-LAST-OPCODE TO DC-WS-LAST-OPCODE
           MOVE DC-VS-WS-LOOPBACK-FLAG TO DC-WS-LOOPBACK-FLAG
           MOVE DC-VS-WS-LIVE-FLAG TO DC-WS-SESSION-LIVE-FLAG
           MOVE DC-VS-WS-HOST TO DC-WS-SESSION-HOST
           MOVE DC-VS-WS-PATH TO DC-WS-SESSION-PATH
           MOVE DC-VS-WS-SEC-KEY TO DC-WS-SESSION-SEC-KEY
           MOVE DC-VS-WS-PORT TO DC-WS-SESSION-PORT
           MOVE DC-VS-WS-HANDSHAKE-REQUEST-LENGTH
               TO DC-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE DC-VS-WS-HANDSHAKE-REQUEST TO DC-WS-HANDSHAKE-REQUEST
           MOVE DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH
               TO DC-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE DC-VS-WS-HANDSHAKE-RESPONSE TO DC-WS-HANDSHAKE-RESPONSE
           MOVE DC-VS-WS-INBOUND-BUFFER-LENGTH
               TO DC-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-VS-WS-INBOUND-BUFFER TO DC-WS-INBOUND-BUFFER
           MOVE DC-VS-WS-OUTBOUND-BUFFER-LENGTH
               TO DC-WS-OUTBOUND-BUFFER-LENGTH
           MOVE DC-VS-WS-OUTBOUND-BUFFER TO DC-WS-OUTBOUND-BUFFER
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-GATEWAY-SESSION-LOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-GATEWAY-SESSION-SAVE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-WS-SESSION
           DC-RESULT.
       MAIN.
           MOVE DC-WS-HANDLE TO DC-VS-WS-HANDLE
           MOVE DC-WS-OPEN-FLAG TO DC-VS-WS-OPEN-FLAG
           MOVE DC-WS-LAST-OPCODE TO DC-VS-WS-LAST-OPCODE
           MOVE DC-WS-LOOPBACK-FLAG TO DC-VS-WS-LOOPBACK-FLAG
           MOVE DC-WS-SESSION-LIVE-FLAG TO DC-VS-WS-LIVE-FLAG
           MOVE DC-WS-SESSION-HOST TO DC-VS-WS-HOST
           MOVE DC-WS-SESSION-PATH TO DC-VS-WS-PATH
           MOVE DC-WS-SESSION-SEC-KEY TO DC-VS-WS-SEC-KEY
           MOVE DC-WS-SESSION-PORT TO DC-VS-WS-PORT
           MOVE DC-WS-HANDSHAKE-REQUEST-LENGTH
               TO DC-VS-WS-HANDSHAKE-REQUEST-LENGTH
           MOVE DC-WS-HANDSHAKE-REQUEST TO DC-VS-WS-HANDSHAKE-REQUEST
           MOVE DC-WS-HANDSHAKE-RESPONSE-LENGTH
               TO DC-VS-WS-HANDSHAKE-RESPONSE-LENGTH
           MOVE DC-WS-HANDSHAKE-RESPONSE TO DC-VS-WS-HANDSHAKE-RESPONSE
           MOVE DC-WS-INBOUND-BUFFER-LENGTH
               TO DC-VS-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-WS-INBOUND-BUFFER TO DC-VS-WS-INBOUND-BUFFER
           MOVE DC-WS-OUTBOUND-BUFFER-LENGTH
               TO DC-VS-WS-OUTBOUND-BUFFER-LENGTH
           MOVE DC-WS-OUTBOUND-BUFFER TO DC-VS-WS-OUTBOUND-BUFFER
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-GATEWAY-SESSION-SAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-BUILD-WS-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-URL PIC X(512).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-SESSION
           DC-WS-REQUEST
           DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-REQUEST
           IF FUNCTION TRIM(DC-VS-ENDPOINT) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice endpoint is required before building a WS request."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL "DC-URL-BUILD-WSS"
               USING DC-VS-ENDPOINT
                     DC-CLIENT-VOICE-GATEWAY-VERSION
                     WS-URL
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE WS-URL TO DC-VS-GATEWAY-URL
           CALL "DC-URL-SPLIT-WSS"
               USING WS-URL
                     DC-WS-HOST
                     DC-WS-PATH
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-VS-WS-SEC-KEY) NOT = SPACES
               MOVE DC-VS-WS-SEC-KEY TO DC-WS-SEC-KEY
           ELSE
               CALL "DC-WS-GENERATE-KEY"
                   USING DC-WS-SEC-KEY DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-VOICE-BUILD-WS-REQUEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-NEXT-PAYLOAD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VOICE-IDENTIFY.
          05 WS-VI-SERVER-ID PIC X(32).
          05 WS-VI-USER-ID PIC X(32).
          05 WS-VI-SESSION-ID PIC X(128).
          05 WS-VI-TOKEN PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       01 DC-VOICE-ACTION-OUT PIC X(32).
       01 DC-VOICE-PAYLOAD-OUT PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-SESSION
           DC-VOICE-ACTION-OUT
           DC-VOICE-PAYLOAD-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-VOICE-ACTION-OUT
           MOVE SPACES TO DC-VOICE-PAYLOAD-OUT

           IF DC-VS-RESUME-REQUESTED = 1
               CALL "DC-VOICE-RESUME-BUILD"
                   USING DC-VOICE-SESSION DC-VOICE-PAYLOAD-OUT DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "RESUME" TO DC-VOICE-ACTION-OUT
               MOVE 0 TO DC-VS-RESUME-REQUESTED
               GOBACK
           END-IF

           IF DC-VS-IDENTIFY-NEEDED = 1
               MOVE DC-VS-GUILD-ID TO WS-VI-SERVER-ID
               MOVE DC-CLIENT-USER-ID TO WS-VI-USER-ID
               MOVE DC-VS-SESSION-ID TO WS-VI-SESSION-ID
               MOVE DC-VS-TOKEN TO WS-VI-TOKEN
               CALL "DC-VOICE-IDENTIFY-BUILD"
                   USING WS-VOICE-IDENTIFY
                         DC-VOICE-PAYLOAD-OUT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "IDENTIFY" TO DC-VOICE-ACTION-OUT
               MOVE 0 TO DC-VS-IDENTIFY-NEEDED
               GOBACK
           END-IF

           IF DC-VS-HEARTBEAT-DUE = 1
               CALL "DC-VOICE-HEARTBEAT-BUILD"
                   USING DC-VS-HEARTBEAT-NONCE
                         DC-VOICE-PAYLOAD-OUT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "HEARTBEAT" TO DC-VOICE-ACTION-OUT
               ADD 1 TO DC-VS-HEARTBEAT-NONCE
               MOVE 0 TO DC-VS-HEARTBEAT-DUE
               MOVE 1 TO DC-VS-AWAITING-ACK
               GOBACK
           END-IF

           IF DC-VS-COMMAND-QUEUED = 1
               MOVE DC-VS-COMMAND-NAME TO DC-VOICE-ACTION-OUT
               MOVE DC-VS-COMMAND-PAYLOAD TO DC-VOICE-PAYLOAD-OUT
               MOVE 0 TO DC-VS-COMMAND-QUEUED
               MOVE SPACES TO DC-VS-COMMAND-NAME
               MOVE SPACES TO DC-VS-COMMAND-PAYLOAD
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-NEXT-PAYLOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-QUEUE-PAYLOAD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-ACTION-IN PIC X(32).
       01 DC-VOICE-PAYLOAD-IN PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-VOICE-ACTION-IN
           DC-VOICE-PAYLOAD-IN
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-VOICE-ACTION-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY_QUEUE" TO DC-ERROR-CODE
               MOVE "Voice Gateway action name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-VOICE-PAYLOAD-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY_QUEUE" TO DC-ERROR-CODE
               MOVE "Voice Gateway payload is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-COMMAND-QUEUED = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY_QUEUE_FULL" TO DC-ERROR-CODE
               MOVE "Voice Gateway outbound queue is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 1 TO DC-VS-COMMAND-QUEUED
           MOVE DC-VOICE-ACTION-IN TO DC-VS-COMMAND-NAME
           MOVE DC-VOICE-PAYLOAD-IN TO DC-VS-COMMAND-PAYLOAD
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-QUEUE-PAYLOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-IDENTIFY-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-IDENTIFY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-IDENTIFY
           DC-VOICE-IDENTIFY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-VOICE-IDENTIFY-PAYLOAD
           STRING
               "{"
               DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":0," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "server_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VI-SERVER-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "user_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VI-USER-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "session_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VI-SESSION-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "token" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VI-TOKEN) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "max_dave_protocol_version" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":0}}" DELIMITED BY SIZE
               INTO DC-VOICE-IDENTIFY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-IDENTIFY-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SELECT-PROTOCOL-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PORT-TEXT PIC Z(4)9.

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-SELECT-PROTOCOL-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-SELECT-PROTOCOL
           DC-VOICE-SELECT-PROTOCOL-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE DC-SP-PORT TO WS-PORT-TEXT
           MOVE SPACES TO DC-VOICE-SELECT-PROTOCOL-PAYLOAD
           STRING
               "{"
               DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":1," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "protocol" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-SP-PROTOCOL) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "address" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-SP-ADDRESS) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "port" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-PORT-TEXT) DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "mode" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-SP-MODE) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}}" DELIMITED BY SIZE
               INTO DC-VOICE-SELECT-PROTOCOL-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-SELECT-PROTOCOL-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-RESUME-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-RESUME-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-VOICE-RESUME-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-VOICE-RESUME-PAYLOAD
           STRING
               "{"
               DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":7," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "server_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VS-GUILD-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "session_id" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VS-SESSION-ID) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "token" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-VS-TOKEN) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-VOICE-RESUME-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-RESUME-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-HANDLE-PAYLOAD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).
       01 WS-OP PIC S9(18) COMP-5.
       01 WS-SEQ PIC S9(18) COMP-5.
       01 WS-NUMBER PIC S9(18) COMP-5.
       01 WS-JSON-VALUE-POS PIC 9(5) COMP-5.
       01 WS-KEY-BYTE-COUNT PIC 9(3) COMP-5.
       01 WS-KEY-BYTE-VALUE PIC S9(9) COMP-5.
       01 WS-KEY-NUMBER-LEN PIC 9(2) COMP-5.
       01 WS-KEY-NUMBER-TEXT PIC X(4).
       01 WS-CURSOR PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.
       01 WS-TEXT PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-JSON PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-VOICE-JSON
           DC-RESULT.
       MAIN.
           MOVE "$.op" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-VOICE-JSON WS-PATH WS-OP DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE "$.seq" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-VOICE-JSON WS-PATH WS-SEQ WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-SEQ TO DC-VS-LAST-SEQ
           END-IF

           EVALUATE WS-OP
               WHEN 8
                   MOVE "$.d.heartbeat_interval" TO WS-PATH
                   CALL "DC-JSON-GET-NUMBER"
                       USING DC-VOICE-JSON
                             WS-PATH
                             WS-NUMBER
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
                   MOVE WS-NUMBER TO DC-VS-HEARTBEAT-INTERVAL
                   IF DC-VS-RESUME-REQUESTED NOT = 1
                       MOVE 1 TO DC-VS-IDENTIFY-NEEDED
                   END-IF
               WHEN 2
                   MOVE 0 TO DC-VS-IDENTIFY-NEEDED
                   PERFORM APPLY-READY
               WHEN 4
                   PERFORM APPLY-SESSION-DESCRIPTION
               WHEN 6
                   MOVE 0 TO DC-VS-AWAITING-ACK
                   MOVE 0 TO DC-VS-HEARTBEAT-DUE
                WHEN 9
                    MOVE 1 TO DC-VS-READY-FLAG
                    MOVE 0 TO DC-VS-RESUME-REQUESTED
                    MOVE 0 TO DC-VS-IDENTIFY-NEEDED
                    MOVE 4 TO DC-VS-STATE
           END-EVALUATE

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       APPLY-READY.
           MOVE SPACES TO DC-VS-DISCOVERED-IP
           MOVE 0 TO DC-VS-DISCOVERED-PORT
           MOVE 0 TO DC-VS-UDP-HANDLE
           MOVE "$.d.ssrc" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-VOICE-JSON
                     WS-PATH
                     WS-NUMBER
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE WS-NUMBER TO DC-VS-SSRC

           MOVE "$.d.ip" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH WS-TEXT WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-VS-IP
           END-IF

           MOVE "$.d.port" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-VOICE-JSON
                     WS-PATH
                     WS-NUMBER
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-NUMBER TO DC-VS-PORT
           END-IF

           MOVE 1 TO DC-VS-UDP-READY-FLAG
           MOVE 3 TO DC-VS-STATE.

       APPLY-SESSION-DESCRIPTION.
           MOVE "$.d.mode" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH WS-TEXT WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-VS-ENCRYPTION-MODE
           END-IF
           MOVE SPACES TO DC-VS-SECRET-KEY
           PERFORM APPLY-SESSION-SECRET-KEY
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE 1 TO DC-VS-READY-FLAG
           MOVE 0 TO DC-VS-RESUME-REQUESTED
           MOVE 0 TO DC-VS-IDENTIFY-NEEDED
           MOVE 4 TO DC-VS-STATE.

       APPLY-SESSION-SECRET-KEY.
           MOVE "$.d.secret_key" TO WS-PATH
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-VOICE-JSON
                     WS-PATH
                     WS-JSON-VALUE-POS
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-NOT-FOUND
               GO TO APPLY-SESSION-SECRET-KEY-EXIT
           END-IF
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GO TO APPLY-SESSION-SECRET-KEY-EXIT
           END-IF

           IF DC-VOICE-JSON(WS-JSON-VALUE-POS:1) NOT = "["
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice secret_key must be a JSON array."
                   TO DC-ERROR-MESSAGE
               GO TO APPLY-SESSION-SECRET-KEY-EXIT
           END-IF

           MOVE 0 TO WS-KEY-BYTE-COUNT
           COMPUTE WS-CURSOR = WS-JSON-VALUE-POS + 1

           PERFORM UNTIL WS-CURSOR > 8192
               MOVE DC-VOICE-JSON(WS-CURSOR:1) TO WS-CHAR
               IF WS-CHAR = "]"
                   EXIT PERFORM
               END-IF

               IF WS-CHAR = SPACE OR WS-CHAR = ","
                  OR WS-CHAR = X"09" OR WS-CHAR = X"0A"
                  OR WS-CHAR = X"0D"
                   ADD 1 TO WS-CURSOR
               ELSE
                   MOVE SPACES TO WS-KEY-NUMBER-TEXT
                   MOVE 0 TO WS-KEY-NUMBER-LEN
                   PERFORM UNTIL WS-CURSOR > 8192
                       MOVE DC-VOICE-JSON(WS-CURSOR:1) TO WS-CHAR
                       IF WS-CHAR >= "0" AND WS-CHAR <= "9"
                           ADD 1 TO WS-KEY-NUMBER-LEN
                           IF WS-KEY-NUMBER-LEN <= 4
                               MOVE WS-CHAR
                                   TO WS-KEY-NUMBER-TEXT(
                                       WS-KEY-NUMBER-LEN:1)
                           END-IF
                           ADD 1 TO WS-CURSOR
                       ELSE
                           EXIT PERFORM
                       END-IF
                   END-PERFORM

                   IF WS-KEY-NUMBER-LEN = 0
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
                       MOVE "Voice secret_key contained an invalid byte."
                           TO DC-ERROR-MESSAGE
                       GO TO APPLY-SESSION-SECRET-KEY-EXIT
                   END-IF

                   COMPUTE WS-KEY-BYTE-VALUE =
                       FUNCTION NUMVAL(
                           WS-KEY-NUMBER-TEXT(1:WS-KEY-NUMBER-LEN))
                   IF WS-KEY-BYTE-VALUE < 0 OR WS-KEY-BYTE-VALUE > 255
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
                       MOVE "Voice secret_key byte was out of range."
                           TO DC-ERROR-MESSAGE
                       GO TO APPLY-SESSION-SECRET-KEY-EXIT
                   END-IF

                   ADD 1 TO WS-KEY-BYTE-COUNT
                   IF WS-KEY-BYTE-COUNT > 32
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
                       MOVE "Voice secret_key length was invalid."
                           TO DC-ERROR-MESSAGE
                       GO TO APPLY-SESSION-SECRET-KEY-EXIT
                   END-IF

                   MOVE FUNCTION CHAR(WS-KEY-BYTE-VALUE + 1)
                       TO DC-VS-SECRET-KEY(WS-KEY-BYTE-COUNT:1)
               END-IF
           END-PERFORM

           IF WS-CURSOR > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice secret_key array was not terminated."
                   TO DC-ERROR-MESSAGE
               GO TO APPLY-SESSION-SECRET-KEY-EXIT
           END-IF

           IF WS-KEY-BYTE-COUNT NOT = 32
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice secret_key length was invalid."
                   TO DC-ERROR-MESSAGE
           END-IF.

       APPLY-SESSION-SECRET-KEY-EXIT.
           EXIT.
       END PROGRAM DC-VOICE-HANDLE-PAYLOAD.
