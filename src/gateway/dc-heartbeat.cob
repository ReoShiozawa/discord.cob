       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HEARTBEAT-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SEQUENCE-TEXT PIC Z(9)9.

       LINKAGE SECTION.
       01 DC-GW-SEQUENCE-IN PIC S9(10) COMP-5.
       01 DC-HEARTBEAT-PAYLOAD PIC X(256).
       COPY "discord-result.cpy".

	       PROCEDURE DIVISION USING
	           DC-GW-SEQUENCE-IN
	           DC-HEARTBEAT-PAYLOAD
	           DC-RESULT.
	       MAIN.
	           MOVE SPACES TO DC-HEARTBEAT-PAYLOAD
	           IF DC-GW-SEQUENCE-IN < 0
	               MOVE '{"op":1,"d":null}' TO DC-HEARTBEAT-PAYLOAD
	           ELSE
	               MOVE DC-GW-SEQUENCE-IN TO WS-SEQUENCE-TEXT
	               STRING
	                   "{" DELIMITED BY SIZE
	                   QUOTE DELIMITED BY SIZE
	                   "op" DELIMITED BY SIZE
	                   QUOTE DELIMITED BY SIZE
	                   ":1," DELIMITED BY SIZE
	                   QUOTE DELIMITED BY SIZE
	                   "d" DELIMITED BY SIZE
	                   QUOTE DELIMITED BY SIZE
	                   ":" DELIMITED BY SIZE
	                   FUNCTION TRIM(WS-SEQUENCE-TEXT) DELIMITED BY SIZE
	                   "}" DELIMITED BY SIZE
	                   INTO DC-HEARTBEAT-PAYLOAD
	               END-STRING
	           END-IF
	           CALL "DC-RESULT-OK" USING DC-RESULT
	           GOBACK.
       END PROGRAM DC-HEARTBEAT-BUILD.
