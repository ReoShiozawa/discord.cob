	       IDENTIFICATION DIVISION.
	       PROGRAM-ID. DC-RESUME-BUILD.
       *> JP: Gateway resume payload を組み立てる helper です。
       *> JP: session id と last sequence を切断復帰用 JSON に詰め直します。
       *> EN: Helper that builds Gateway resume payloads.
       *> EN: It repacks the session id and last sequence into the reconnect JSON shape.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-SEQUENCE-TEXT PIC Z(9)9.

	       LINKAGE SECTION.
	       COPY "discord-client.cpy".
	       01 DC-RESUME-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
	           DC-CLIENT
	           DC-RESUME-PAYLOAD
	           DC-RESULT.
	       MAIN.
	           MOVE DC-CLIENT-SEQUENCE TO WS-SEQUENCE-TEXT
	           MOVE SPACES TO DC-RESUME-PAYLOAD
	           STRING
	               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":6," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "d" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               "token" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               ":" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               FUNCTION TRIM(DC-CLIENT-TOKEN) DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               "," DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               "session_id" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               ":" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               FUNCTION TRIM(DC-CLIENT-SESSION-ID) DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               "," DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               "seq" DELIMITED BY SIZE
	               QUOTE DELIMITED BY SIZE
	               ":" DELIMITED BY SIZE
	               FUNCTION TRIM(WS-SEQUENCE-TEXT) DELIMITED BY SIZE
	               "}}" DELIMITED BY SIZE
	               INTO DC-RESUME-PAYLOAD
	           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-RESUME-BUILD.
