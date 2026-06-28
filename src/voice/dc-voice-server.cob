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
	           END-IF
	           GOBACK.
       END PROGRAM DC-VOICE-APPLY-SERVER-UPDATE.
