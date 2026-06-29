       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-APPLY-STATE-UPDATE.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-PATH PIC X(128).
	       01 WS-TEXT PIC X(512).

       LINKAGE SECTION.
       01 DC-VOICE-JSON PIC X(8192).
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-JSON
           DC-VOICE-SESSION
           DC-RESULT.
	       MAIN.
	           MOVE "$.d.session_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH WS-TEXT DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-VS-SESSION-ID
               IF FUNCTION TRIM(DC-VS-TOKEN) NOT = SPACES
                  AND FUNCTION TRIM(DC-VS-ENDPOINT) NOT = SPACES
                   MOVE 1 TO DC-VS-IDENTIFY-NEEDED
                   MOVE 2 TO DC-VS-STATE
               ELSE
                   MOVE 1 TO DC-VS-STATE
               END-IF
           END-IF
           GOBACK.
       END PROGRAM DC-VOICE-APPLY-STATE-UPDATE.
