       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-HEADER-VALUE PIC X(512).
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-HEADER-LOOKUP
           PERFORM TEST-CONTENT-LENGTH
           PERFORM TEST-CHUNKED
           PERFORM FINISH-TEST.

       TEST-HEADER-LOOKUP.
           MOVE SPACES TO DC-HTTP-RAW-HEADERS
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: application/json" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 11" DELIMITED BY SIZE
               INTO DC-HTTP-RAW-HEADERS
           END-STRING
           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Content-Type"
                     WS-HEADER-VALUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-HEADER-VALUE)
               NOT = "application/json"
               DISPLAY "http-test: direct header lookup mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CONTENT-LENGTH.
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 11" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: application/json" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               '{"ok":true}' DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING

           CALL "DC-HTTP-PARSE-RESPONSE"
               USING WS-RAW-RESPONSE DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "http-test: status code mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY-LENGTH NOT = 11
               DISPLAY "http-test: content-length body size mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:11) NOT = '{"ok":true}'
               DISPLAY "http-test: response body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Content-Type"
                     WS-HEADER-VALUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-HEADER-VALUE)
               NOT = "application/json"
               DISPLAY "http-test: content-type header mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CHUNKED.
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Transfer-Encoding: chunked" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               "4" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Wiki" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "5" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "pedia" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "0" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING

           CALL "DC-HTTP-PARSE-RESPONSE"
               USING WS-RAW-RESPONSE DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-RESPONSE-BODY-LENGTH NOT = 9
               DISPLAY "http-test: chunked body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:9) NOT = "Wikipedia"
               DISPLAY "http-test: chunked body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "http-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "http-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "http-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM HTTP-TEST.
