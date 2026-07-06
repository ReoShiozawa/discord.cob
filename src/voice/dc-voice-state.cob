       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-APPLY-STATE-UPDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).
       01 WS-TEXT PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-VOICE-JSON PIC X(8192).
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-JSON
           DC-VOICE-SESSION
           DC-RESULT.
	       MAIN.
      *> JP: VOICE_STATE_UPDATE からは主に session_id を受け取ります。
      *> EN: VOICE_STATE_UPDATE primarily contributes the session_id.
      *> JP: token/endpoint が先に来ていれば identify 可能になるので、ここで state を進めます。
      *> EN: If token/endpoint have already arrived, this makes identify possible and advances state.
	           MOVE SPACES TO WS-TEXT
	           MOVE "$.d.channel_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH WS-TEXT WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-VS-CHANNEL-ID
           ELSE
               MOVE SPACES TO DC-VS-CHANNEL-ID
           END-IF

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
