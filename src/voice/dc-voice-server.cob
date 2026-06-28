       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-APPLY-SERVER-UPDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).

       LINKAGE SECTION.
       01 DC-VOICE-JSON PIC X(8192).
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-JSON
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
           MOVE "$.d.token" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH DC-VS-TOKEN DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE "$.d.endpoint" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH DC-VS-ENDPOINT DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-APPLY-SERVER-UPDATE.
