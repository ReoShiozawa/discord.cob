       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-GATEWAY-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-VOICE-SESSION DC-RESULT.
       MAIN.
           MOVE 2 TO DC-VS-STATE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
           MOVE "Voice Gateway WebSocket is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-GATEWAY-CONNECT.

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
               WHEN 2
                   PERFORM APPLY-READY
               WHEN 4
                   PERFORM APPLY-SESSION-DESCRIPTION
               WHEN 6
                   MOVE 1 TO DC-VS-UDP-READY-FLAG
               WHEN 9
                   MOVE 1 TO DC-VS-READY-FLAG
                   MOVE 4 TO DC-VS-STATE
           END-EVALUATE

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       APPLY-READY.
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
           MOVE 1 TO DC-VS-READY-FLAG
           MOVE 4 TO DC-VS-STATE.
       END PROGRAM DC-VOICE-HANDLE-PAYLOAD.
