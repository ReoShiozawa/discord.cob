       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-HEARTBEAT-BUILD.
       *> JP: Voice Gateway heartbeat payload を組み立てる helper です。
       *> JP: Voice 側の keepalive 契約を Gateway 本体とは分けて扱います。
       *> EN: Helper that builds Voice Gateway heartbeat payloads.
       *> EN: It keeps the Voice-side keepalive contract separate from the main Gateway one.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-NONCE-TEXT PIC Z(17)9.

       LINKAGE SECTION.
       01 DC-VOICE-HEARTBEAT-NONCE PIC 9(18) COMP-5.
       01 DC-VOICE-HEARTBEAT-PAYLOAD PIC X(256).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-HEARTBEAT-NONCE
           DC-VOICE-HEARTBEAT-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE DC-VOICE-HEARTBEAT-NONCE TO WS-NONCE-TEXT
           MOVE SPACES TO DC-VOICE-HEARTBEAT-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":3," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-NONCE-TEXT) DELIMITED BY SIZE
               "}" DELIMITED BY SIZE
               INTO DC-VOICE-HEARTBEAT-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-HEARTBEAT-BUILD.
