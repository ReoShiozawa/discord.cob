       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-IDENTIFY-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-INTENTS-TEXT PIC Z(9)9.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-IDENTIFY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-IDENTIFY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE DC-CLIENT-INTENTS TO WS-INTENTS-TEXT
           MOVE SPACES TO DC-IDENTIFY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":2," DELIMITED BY SIZE
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
               "intents" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               FUNCTION TRIM(WS-INTENTS-TEXT) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-IDENTIFY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-IDENTIFY-BUILD.
