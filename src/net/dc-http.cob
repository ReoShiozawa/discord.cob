       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-PARSE-STATUS.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-HTTP-RAW-RESPONSE PIC X(8192).
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-RAW-RESPONSE
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           CALL "DC-HTTP-PARSE-RESPONSE"
               USING DC-HTTP-RAW-RESPONSE
                     DC-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-HTTP-PARSE-STATUS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-PARSE-RESPONSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-LEN PIC 9(5) COMP-5.
       01 WS-SEP-POS PIC 9(5) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-HEADER-COPY-LEN PIC 9(5) COMP-5.
       01 WS-BODY-START PIC 9(5) COMP-5.
       01 WS-BODY-LEN PIC 9(9) COMP-5.
       01 WS-CONTENT-LENGTH-TEXT PIC X(512).
       01 WS-TRANSFER-ENCODING PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-HTTP-RAW-RESPONSE PIC X(8192).
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-RAW-RESPONSE
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           INITIALIZE DC-HTTP-RESPONSE
           MOVE SPACES TO WS-CONTENT-LENGTH-TEXT
           MOVE SPACES TO WS-TRANSFER-ENCODING

           PERFORM FIND-RAW-LENGTH
           IF WS-RAW-LEN < 12
              OR DC-HTTP-RAW-RESPONSE(1:5) NOT = "HTTP/"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "HTTP response does not start with HTTP/."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM FIND-HEADER-SEPARATOR
           IF WS-SEP-POS = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "HTTP response header terminator was not found."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           COMPUTE DC-HTTP-STATUS-CODE =
               FUNCTION NUMVAL(DC-HTTP-RAW-RESPONSE(10:3))

           COMPUTE DC-HTTP-HEADER-LENGTH = WS-SEP-POS - 1
           MOVE DC-HTTP-HEADER-LENGTH TO WS-HEADER-COPY-LEN
           IF WS-HEADER-COPY-LEN > 4096
               MOVE 4096 TO WS-HEADER-COPY-LEN
           END-IF
           IF WS-HEADER-COPY-LEN > 0
               MOVE DC-HTTP-RAW-RESPONSE(1:WS-HEADER-COPY-LEN)
                   TO DC-HTTP-RAW-HEADERS(1:WS-HEADER-COPY-LEN)
           END-IF

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Content-Length"
                     WS-CONTENT-LENGTH-TEXT
                     WS-LOCAL-RESULT

           CALL "DC-HTTP-GET-HEADER"
               USING DC-HTTP-RAW-HEADERS
                     "Transfer-Encoding"
                     WS-TRANSFER-ENCODING
                     WS-LOCAL-RESULT

           COMPUTE WS-BODY-START = WS-SEP-POS + 4
           IF WS-BODY-START > WS-RAW-LEN
               MOVE 0 TO DC-HTTP-RESPONSE-BODY-LENGTH
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           IF FUNCTION UPPER-CASE(FUNCTION TRIM(WS-TRANSFER-ENCODING))
               = "CHUNKED"
               CALL "DC-HTTP-DECODE-CHUNKED"
                   USING DC-HTTP-RAW-RESPONSE(WS-BODY-START:)
                         DC-HTTP-RESPONSE-BODY
                         DC-HTTP-RESPONSE-BODY-LENGTH
                         DC-RESULT
               GOBACK
           END-IF

           IF FUNCTION TRIM(WS-CONTENT-LENGTH-TEXT) NOT = SPACES
               COMPUTE WS-BODY-LEN =
                   FUNCTION NUMVAL(WS-CONTENT-LENGTH-TEXT)
           ELSE
               COMPUTE WS-BODY-LEN = WS-RAW-LEN - WS-BODY-START + 1
           END-IF

           IF WS-BODY-LEN < 0
               MOVE 0 TO WS-BODY-LEN
           END-IF
           IF WS-BODY-LEN > 8192
               MOVE 8192 TO WS-BODY-LEN
           END-IF
           MOVE WS-BODY-LEN TO DC-HTTP-RESPONSE-BODY-LENGTH
           IF WS-BODY-LEN > 0
               MOVE DC-HTTP-RAW-RESPONSE(WS-BODY-START:WS-BODY-LEN)
                   TO DC-HTTP-RESPONSE-BODY(1:WS-BODY-LEN)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       FIND-RAW-LENGTH.
           MOVE 8192 TO WS-RAW-LEN
           PERFORM UNTIL WS-RAW-LEN = 0
               OR DC-HTTP-RAW-RESPONSE(WS-RAW-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-RAW-LEN
           END-PERFORM.

       FIND-HEADER-SEPARATOR.
           MOVE 0 TO WS-SEP-POS
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-RAW-LEN - 3
                  OR WS-SEP-POS NOT = 0
               IF DC-HTTP-RAW-RESPONSE(WS-IDX:4) = X"0D0A0D0A"
                   MOVE WS-IDX TO WS-SEP-POS
               END-IF
           END-PERFORM.
       END PROGRAM DC-HTTP-PARSE-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-GET-HEADER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-HEADER-LEN PIC 9(5) COMP-5.
       01 WS-LINE-START PIC 9(5) COMP-5.
       01 WS-LINE-END PIC 9(5) COMP-5.
       01 WS-COLON-POS PIC 9(5) COMP-5.
       01 WS-VALUE-START PIC 9(5) COMP-5.
       01 WS-VALUE-END PIC 9(5) COMP-5.
       01 WS-COPY-LEN PIC 9(5) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-NAME-LEN PIC 9(4) COMP-5.
       01 WS-LINE-NAME-LEN PIC 9(4) COMP-5.
       01 WS-TARGET-NAME PIC X(128).

       LINKAGE SECTION.
       01 DC-HTTP-RAW-HEADERS-IN PIC X(4096).
       01 DC-HTTP-HEADER-NAME-IN PIC X(128).
       01 DC-HTTP-HEADER-VALUE-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-RAW-HEADERS-IN
           DC-HTTP-HEADER-NAME-IN
           DC-HTTP-HEADER-VALUE-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-HTTP-HEADER-VALUE-OUT
           MOVE SPACES TO WS-TARGET-NAME
           MOVE LENGTH OF DC-HTTP-RAW-HEADERS-IN TO WS-HEADER-LEN
           PERFORM UNTIL WS-HEADER-LEN = 0
               OR DC-HTTP-RAW-HEADERS-IN(WS-HEADER-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-HEADER-LEN
           END-PERFORM
           MOVE 0 TO WS-NAME-LEN
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 128
               IF DC-HTTP-HEADER-NAME-IN(WS-IDX:1) = SPACE
                  OR DC-HTTP-HEADER-NAME-IN(WS-IDX:1) = LOW-VALUE
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-NAME-LEN
               MOVE FUNCTION UPPER-CASE(DC-HTTP-HEADER-NAME-IN(WS-IDX:1))
                   TO WS-TARGET-NAME(WS-IDX:1)
           END-PERFORM
           MOVE 1 TO WS-LINE-START
           PERFORM UNTIL WS-LINE-START > WS-HEADER-LEN
               MOVE WS-LINE-START TO WS-LINE-END
               PERFORM UNTIL WS-LINE-END > WS-HEADER-LEN - 1
                   OR DC-HTTP-RAW-HEADERS-IN(WS-LINE-END:2) = X"0D0A"
                   ADD 1 TO WS-LINE-END
               END-PERFORM
               IF WS-LINE-END <= WS-HEADER-LEN - 1
                  AND DC-HTTP-RAW-HEADERS-IN(WS-LINE-END:2) = X"0D0A"
                   SUBTRACT 1 FROM WS-LINE-END
               ELSE
                   MOVE WS-HEADER-LEN TO WS-LINE-END
               END-IF

               MOVE 0 TO WS-COLON-POS
               PERFORM VARYING WS-IDX FROM WS-LINE-START BY 1
                   UNTIL WS-IDX > WS-LINE-END
                      OR WS-COLON-POS NOT = 0
                   IF DC-HTTP-RAW-HEADERS-IN(WS-IDX:1) = ":"
                       MOVE WS-IDX TO WS-COLON-POS
                   END-IF
               END-PERFORM

               IF WS-COLON-POS NOT = 0
                   COMPUTE WS-LINE-NAME-LEN =
                       WS-COLON-POS - WS-LINE-START
                   IF WS-LINE-NAME-LEN = WS-NAME-LEN
                      AND FUNCTION UPPER-CASE(
                          DC-HTTP-RAW-HEADERS-IN(
                              WS-LINE-START:WS-NAME-LEN))
                          = WS-TARGET-NAME(1:WS-NAME-LEN)
                       COMPUTE WS-VALUE-START = WS-COLON-POS + 1
                       PERFORM UNTIL WS-VALUE-START > WS-LINE-END
                           OR DC-HTTP-RAW-HEADERS-IN(WS-VALUE-START:1)
                               NOT = SPACE
                           ADD 1 TO WS-VALUE-START
                       END-PERFORM
                       COMPUTE WS-VALUE-END = WS-LINE-END + 1
                       COMPUTE WS-COPY-LEN = WS-VALUE-END - WS-VALUE-START
                       IF WS-COPY-LEN > 512
                           MOVE 512 TO WS-COPY-LEN
                       END-IF
                       IF WS-COPY-LEN > 0
                           MOVE DC-HTTP-RAW-HEADERS-IN(
                               WS-VALUE-START:WS-COPY-LEN)
                               TO DC-HTTP-HEADER-VALUE-OUT(1:WS-COPY-LEN)
                       END-IF
                       CALL "DC-RESULT-OK" USING DC-RESULT
                       GOBACK
                   END-IF
               END-IF

               IF WS-LINE-END + 3 > WS-HEADER-LEN
                   EXIT PERFORM
               END-IF
               COMPUTE WS-LINE-START = WS-LINE-END + 3
           END-PERFORM

           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_HEADER_NOT_FOUND" TO DC-ERROR-CODE
           MOVE "HTTP header was not found." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-GET-HEADER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-DECODE-CHUNKED.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-RAW-LEN PIC 9(5) COMP-5.
       01 WS-CURSOR PIC 9(5) COMP-5.
       01 WS-LINE-END PIC 9(5) COMP-5.
       01 WS-SIZE-TEXT PIC X(32).
       01 WS-SIZE-TEXT-LEN PIC 9(4) COMP-5.
       01 WS-CHUNK-SIZE PIC 9(9) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-DIGIT PIC X.
       01 WS-DIGIT-VALUE PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-HTTP-CHUNKED-BODY-IN PIC X(8192).
       01 DC-HTTP-DECODED-BODY-OUT PIC X(8192).
       01 DC-HTTP-DECODED-BODY-LENGTH PIC 9(9) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-CHUNKED-BODY-IN
           DC-HTTP-DECODED-BODY-OUT
           DC-HTTP-DECODED-BODY-LENGTH
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-HTTP-DECODED-BODY-OUT
           MOVE 0 TO DC-HTTP-DECODED-BODY-LENGTH

           MOVE 8192 TO WS-RAW-LEN
           PERFORM UNTIL WS-RAW-LEN = 0
               OR DC-HTTP-CHUNKED-BODY-IN(WS-RAW-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-RAW-LEN
           END-PERFORM

           MOVE 1 TO WS-CURSOR
           PERFORM UNTIL WS-CURSOR > WS-RAW-LEN
               MOVE WS-CURSOR TO WS-LINE-END
               PERFORM UNTIL WS-LINE-END > WS-RAW-LEN - 1
                   OR DC-HTTP-CHUNKED-BODY-IN(WS-LINE-END:2) = X"0D0A"
                   ADD 1 TO WS-LINE-END
               END-PERFORM

               IF WS-LINE-END > WS-RAW-LEN - 1
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
                   MOVE "Chunked body size line was not terminated."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               MOVE SPACES TO WS-SIZE-TEXT
               COMPUTE WS-SIZE-TEXT-LEN = WS-LINE-END - WS-CURSOR
               IF WS-SIZE-TEXT-LEN > 32
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
                   MOVE "Chunked size line is too long."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               IF WS-SIZE-TEXT-LEN > 0
                   MOVE DC-HTTP-CHUNKED-BODY-IN(
                       WS-CURSOR:WS-SIZE-TEXT-LEN)
                       TO WS-SIZE-TEXT(1:WS-SIZE-TEXT-LEN)
               END-IF
               PERFORM PARSE-HEX-SIZE

               IF WS-CHUNK-SIZE = 0
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF

               COMPUTE WS-CURSOR = WS-LINE-END + 2
               IF WS-CURSOR + WS-CHUNK-SIZE - 1 > WS-RAW-LEN
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
                   MOVE "Chunked body ended before the full chunk arrived."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               IF DC-HTTP-DECODED-BODY-LENGTH + WS-CHUNK-SIZE > 8192
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
                   MOVE "Decoded chunked body is too large."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               MOVE DC-HTTP-CHUNKED-BODY-IN(WS-CURSOR:WS-CHUNK-SIZE)
                   TO DC-HTTP-DECODED-BODY-OUT(
                       DC-HTTP-DECODED-BODY-LENGTH + 1:WS-CHUNK-SIZE)
               ADD WS-CHUNK-SIZE TO DC-HTTP-DECODED-BODY-LENGTH
               COMPUTE WS-CURSOR = WS-CURSOR + WS-CHUNK-SIZE + 2
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       PARSE-HEX-SIZE.
           MOVE 0 TO WS-CHUNK-SIZE
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-SIZE-TEXT-LEN
               MOVE WS-SIZE-TEXT(WS-IDX:1) TO WS-DIGIT
               EVALUATE TRUE
                   WHEN WS-DIGIT >= "0" AND WS-DIGIT <= "9"
                       COMPUTE WS-DIGIT-VALUE =
                           FUNCTION NUMVAL(WS-DIGIT)
                   WHEN FUNCTION UPPER-CASE(WS-DIGIT) >= "A"
                    AND FUNCTION UPPER-CASE(WS-DIGIT) <= "F"
                       EVALUATE FUNCTION UPPER-CASE(WS-DIGIT)
                           WHEN "A"
                               MOVE 10 TO WS-DIGIT-VALUE
                           WHEN "B"
                               MOVE 11 TO WS-DIGIT-VALUE
                           WHEN "C"
                               MOVE 12 TO WS-DIGIT-VALUE
                           WHEN "D"
                               MOVE 13 TO WS-DIGIT-VALUE
                           WHEN "E"
                               MOVE 14 TO WS-DIGIT-VALUE
                           WHEN "F"
                               MOVE 15 TO WS-DIGIT-VALUE
                       END-EVALUATE
                   WHEN OTHER
                       MOVE 0 TO WS-DIGIT-VALUE
               END-EVALUATE
               COMPUTE WS-CHUNK-SIZE =
                   (WS-CHUNK-SIZE * 16) + WS-DIGIT-VALUE
           END-PERFORM.
       END PROGRAM DC-HTTP-DECODE-CHUNKED.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-GET.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-GET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-POST.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-POST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-PATCH.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-PATCH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-DELETE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-DELETE.
