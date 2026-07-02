       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-APPLY-SERVER-UPDATE.

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
      *> JP: VOICE_SERVER_UPDATE からは token と endpoint を受け取ります。
      *> EN: VOICE_SERVER_UPDATE contributes the token and endpoint.
      *> JP: session_id が先に揃っていれば、この時点で Voice Gateway identify を要求できます。
      *> EN: If session_id is already present, this is enough to request Voice Gateway identify.
	           MOVE "$.d.token" TO WS-PATH
	           CALL "DC-JSON-GET-STRING"
	               USING DC-VOICE-JSON WS-PATH WS-TEXT DC-RESULT
	           IF DC-STATUS-CODE NOT = DC-STATUS-OK
	               GOBACK
	           END-IF
	           MOVE WS-TEXT TO DC-VS-TOKEN
           MOVE "$.d.endpoint" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-VOICE-JSON WS-PATH WS-TEXT DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-VS-ENDPOINT
               IF FUNCTION TRIM(DC-VS-SESSION-ID) NOT = SPACES
                   MOVE 1 TO DC-VS-IDENTIFY-NEEDED
                   MOVE 2 TO DC-VS-STATE
               END-IF
           END-IF
           GOBACK.
       END PROGRAM DC-VOICE-APPLY-SERVER-UPDATE.
