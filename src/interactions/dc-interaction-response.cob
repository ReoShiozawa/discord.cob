       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-BUILD-REPLY.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-REPLY-CONTENT PIC X(2000).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-REPLY-CONTENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-REPLY-PAYLOAD
           STRING
               "{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "type" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":4," DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "data" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":{" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "content" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               ":" DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-REPLY-CONTENT) DELIMITED BY SIZE
               QUOTE DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO DC-REPLY-PAYLOAD
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-BUILD-REPLY.
