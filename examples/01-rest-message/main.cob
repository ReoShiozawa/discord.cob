       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-HTTP-PARSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-CONTENT-TYPE PIC X(512).
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION.
       MAIN.
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 17" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: text/plain" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               "hello from parser" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING

           CALL "DC-HTTP-PARSE-RESPONSE"
               USING WS-RAW-RESPONSE DC-HTTP-RESPONSE DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Content-Type"
                     WS-CONTENT-TYPE
                     DC-RESULT

           DISPLAY "status: " DC-HTTP-STATUS-CODE
           DISPLAY "content-type: " FUNCTION TRIM(WS-CONTENT-TYPE)
           DISPLAY "body: "
               DC-HTTP-RESPONSE-BODY(1:DC-HTTP-RESPONSE-BODY-LENGTH)
           STOP RUN.
       END PROGRAM EXAMPLE-HTTP-PARSE.
