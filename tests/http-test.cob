       IDENTIFICATION DIVISION.
       PROGRAM-ID. HTTP-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-HEADER-VALUE PIC X(512).
       01 WS-BODY-START PIC 9(5) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-HOST PIC X(256) VALUE "discord.com".
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-BUILD-REQUEST
           PERFORM TEST-HEADER-LOOKUP
           PERFORM TEST-CONTENT-LENGTH
           PERFORM TEST-CHUNKED
           PERFORM TEST-HTTP-GET
           PERFORM TEST-HTTP-POST
           PERFORM FINISH-TEST.

       TEST-BUILD-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           MOVE "POST" TO DC-HTTP-METHOD
           MOVE "discord.com" TO DC-HTTP-HOST
           MOVE "/api/v10/test" TO DC-HTTP-PATH
           MOVE "Bot token" TO DC-HTTP-AUTHORIZATION
           MOVE "application/json" TO DC-HTTP-CONTENT-TYPE
           MOVE 11 TO DC-HTTP-BODY-LENGTH
           MOVE '{"ok":true}' TO DC-HTTP-BODY
           CALL "DC-HTTP-BUILD-REQUEST"
               USING DC-HTTP-REQUEST DC-HTTP-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:27)
               NOT = "POST /api/v10/test HTTP/1.1"
               DISPLAY "http-test: build request line mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION LENGTH(
               FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               NOT = DC-HTTP-BUFFER-LENGTH
               DISPLAY "http-test: build request length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-BUFFER-DATA
                     "Authorization"
                     WS-HEADER-VALUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-HEADER-VALUE) NOT = "Bot token"
               DISPLAY "http-test: authorization header mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-BUFFER-DATA
                     "Content-Type"
                     WS-HEADER-VALUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-HEADER-VALUE) NOT = "application/json"
               DISPLAY "http-test: build content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - DC-HTTP-BODY-LENGTH + 1
           IF DC-HTTP-BUFFER-DATA(WS-BODY-START:11) NOT = '{"ok":true}'
               DISPLAY "http-test: build request body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

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

       TEST-HTTP-GET.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE DC-HTTP-RESPONSE
           INITIALIZE DC-HTTP-BUFFER
           MOVE WS-HOST TO DC-HTTP-HOST
           MOVE "/api/v10/gateway/bot" TO DC-HTTP-PATH
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
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-HTTP-GET"
               USING DC-HTTP-REQUEST DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "http-test: get status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:11) NOT = '{"ok":true}'
               DISPLAY "http-test: get body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:24)
               NOT = "GET /api/v10/gateway/bot"
                DISPLAY "http-test: get request line mismatch"
                ADD 1 TO WS-FAILURES
            END-IF.

       TEST-HTTP-POST.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE DC-HTTP-RESPONSE
           INITIALIZE DC-HTTP-BUFFER
           MOVE WS-HOST TO DC-HTTP-HOST
           MOVE "/api/v10/messages" TO DC-HTTP-PATH
           MOVE "application/json" TO DC-HTTP-CONTENT-TYPE
           MOVE 11 TO DC-HTTP-BODY-LENGTH
           MOVE '{"ok":true}' TO DC-HTTP-BODY
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 204 No Content" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 0" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-HTTP-POST"
               USING DC-HTTP-REQUEST DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 204
               DISPLAY "http-test: post status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:22)
               NOT = "POST /api/v10/messages"
                DISPLAY "http-test: post request line mismatch"
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
