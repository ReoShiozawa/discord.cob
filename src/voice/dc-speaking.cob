       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-SPEAKING-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-SPEAKING-PAYLOAD-JSON PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-SPEAKING-PAYLOAD
           DC-SPEAKING-PAYLOAD-JSON
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-SPEAKING-PAYLOAD-JSON
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "op" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":5}" DELIMITED BY SIZE
               INTO DC-SPEAKING-PAYLOAD-JSON
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-SPEAKING-BUILD.
