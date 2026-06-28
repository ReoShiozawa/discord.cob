       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-LOCATE-PATH.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-JSON-LEN PIC 9(5) COMP-5.
       01 WS-PATH-LEN PIC 9(4) COMP-5.
       01 WS-PATH-POS PIC 9(4) COMP-5.
       01 WS-KEY PIC X(128).
       01 WS-KEY-LEN PIC 9(4) COMP-5.
       01 WS-SEARCH-POS PIC 9(5) COMP-5.
       01 WS-IDX PIC 9(5) COMP-5.
       01 WS-KEY-START PIC 9(5) COMP-5.
       01 WS-AFTER-QUOTE PIC 9(5) COMP-5.
       01 WS-CURSOR PIC 9(5) COMP-5.
       01 WS-FOUND-FLAG PIC 9.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-VALUE-POS PIC 9(5) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-PATH-IN
           DC-JSON-VALUE-POS
           DC-RESULT.
       MAIN.
           MOVE 8192 TO WS-JSON-LEN
           PERFORM UNTIL WS-JSON-LEN = 0
               OR DC-JSON-BUFFER-IN(WS-JSON-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-JSON-LEN
           END-PERFORM

           MOVE 128 TO WS-PATH-LEN
           PERFORM UNTIL WS-PATH-LEN = 0
               OR DC-JSON-PATH-IN(WS-PATH-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-PATH-LEN
           END-PERFORM

           IF WS-PATH-LEN < 3
              OR DC-JSON-PATH-IN(1:2) NOT = "$."
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_PATH" TO DC-ERROR-CODE
               MOVE "JSON path must start with $." TO DC-ERROR-MESSAGE
               MOVE 0 TO DC-JSON-VALUE-POS
               GOBACK
           END-IF

           MOVE 3 TO WS-PATH-POS
           MOVE 1 TO WS-SEARCH-POS

           PERFORM UNTIL WS-PATH-POS > WS-PATH-LEN
               MOVE SPACES TO WS-KEY
               MOVE 0 TO WS-KEY-LEN
               PERFORM UNTIL WS-PATH-POS > WS-PATH-LEN
                   OR DC-JSON-PATH-IN(WS-PATH-POS:1) = "."
                   ADD 1 TO WS-KEY-LEN
                   MOVE DC-JSON-PATH-IN(WS-PATH-POS:1)
                       TO WS-KEY(WS-KEY-LEN:1)
                   ADD 1 TO WS-PATH-POS
               END-PERFORM
               IF WS-PATH-POS <= WS-PATH-LEN
                  AND DC-JSON-PATH-IN(WS-PATH-POS:1) = "."
                   ADD 1 TO WS-PATH-POS
               END-IF

               IF WS-KEY-LEN = 0
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_JSON_PATH" TO DC-ERROR-CODE
                   MOVE "JSON path contains an empty segment."
                       TO DC-ERROR-MESSAGE
                   MOVE 0 TO DC-JSON-VALUE-POS
                   GOBACK
               END-IF

               PERFORM FIND-KEY
               IF WS-FOUND-FLAG = 0
                   MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                   MOVE "DC_ERR_JSON_NOT_FOUND" TO DC-ERROR-CODE
                   MOVE "JSON path was not found." TO DC-ERROR-MESSAGE
                   MOVE 0 TO DC-JSON-VALUE-POS
                   GOBACK
               END-IF
           END-PERFORM

           MOVE WS-SEARCH-POS TO DC-JSON-VALUE-POS
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       FIND-KEY.
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM WS-SEARCH-POS BY 1
               UNTIL WS-IDX > WS-JSON-LEN
                  OR WS-FOUND-FLAG = 1
               COMPUTE WS-KEY-START = WS-IDX + 1
               COMPUTE WS-AFTER-QUOTE = WS-IDX + WS-KEY-LEN + 1
               IF WS-AFTER-QUOTE <= WS-JSON-LEN
                  AND DC-JSON-BUFFER-IN(WS-IDX:1) = QUOTE
                  AND DC-JSON-BUFFER-IN(WS-KEY-START:WS-KEY-LEN)
                      = WS-KEY(1:WS-KEY-LEN)
                  AND DC-JSON-BUFFER-IN(WS-AFTER-QUOTE:1) = QUOTE
                   COMPUTE WS-CURSOR = WS-AFTER-QUOTE + 1
                   PERFORM SKIP-WHITESPACE
                   IF WS-CURSOR <= WS-JSON-LEN
                      AND DC-JSON-BUFFER-IN(WS-CURSOR:1) = ":"
                       ADD 1 TO WS-CURSOR
                       PERFORM SKIP-WHITESPACE
                       MOVE WS-CURSOR TO WS-SEARCH-POS
                       MOVE 1 TO WS-FOUND-FLAG
                   END-IF
               END-IF
           END-PERFORM.

       SKIP-WHITESPACE.
           PERFORM UNTIL WS-CURSOR > WS-JSON-LEN
               OR (DC-JSON-BUFFER-IN(WS-CURSOR:1) NOT = SPACE
               AND DC-JSON-BUFFER-IN(WS-CURSOR:1) NOT = X"09"
               AND DC-JSON-BUFFER-IN(WS-CURSOR:1) NOT = X"0A"
               AND DC-JSON-BUFFER-IN(WS-CURSOR:1) NOT = X"0D")
               ADD 1 TO WS-CURSOR
           END-PERFORM.
       END PROGRAM DC-JSON-LOCATE-PATH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-GET-STRING.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VALUE-POS PIC 9(5) COMP-5.
       01 WS-VALUE-START PIC 9(5) COMP-5.
       01 WS-END-POS PIC 9(5) COMP-5.
       01 WS-COPY-LEN PIC 9(5) COMP-5.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-OUT-VALUE PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-PATH-IN
           DC-JSON-OUT-VALUE
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-JSON-OUT-VALUE
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-JSON-BUFFER-IN
                     DC-JSON-PATH-IN
                     WS-VALUE-POS
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF WS-VALUE-POS = 0
              OR DC-JSON-BUFFER-IN(WS-VALUE-POS:1) NOT = QUOTE
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_TYPE" TO DC-ERROR-CODE
               MOVE "JSON value is not a string." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           COMPUTE WS-VALUE-START = WS-VALUE-POS + 1
           MOVE WS-VALUE-START TO WS-END-POS
           PERFORM UNTIL WS-END-POS > 8192
               OR DC-JSON-BUFFER-IN(WS-END-POS:1) = QUOTE
               ADD 1 TO WS-END-POS
           END-PERFORM

           IF WS-END-POS > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_PARSE" TO DC-ERROR-CODE
               MOVE "Unterminated JSON string." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           COMPUTE WS-COPY-LEN = WS-END-POS - WS-VALUE-START
           IF WS-COPY-LEN > 512
               MOVE 512 TO WS-COPY-LEN
           END-IF
           IF WS-COPY-LEN > 0
               MOVE DC-JSON-BUFFER-IN(WS-VALUE-START:WS-COPY-LEN)
                   TO DC-JSON-OUT-VALUE(1:WS-COPY-LEN)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-GET-STRING.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-JSON-GET-NUMBER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VALUE-POS PIC 9(5) COMP-5.
       01 WS-END-POS PIC 9(5) COMP-5.
       01 WS-NUMBER-LEN PIC 9(5) COMP-5.
       01 WS-NUMBER-TEXT PIC X(64).
       01 WS-CHAR PIC X.

       LINKAGE SECTION.
       01 DC-JSON-BUFFER-IN PIC X(8192).
       01 DC-JSON-PATH-IN PIC X(128).
       01 DC-JSON-OUT-NUMBER PIC S9(18) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-JSON-BUFFER-IN
           DC-JSON-PATH-IN
           DC-JSON-OUT-NUMBER
           DC-RESULT.
       MAIN.
           MOVE ZERO TO DC-JSON-OUT-NUMBER
           MOVE SPACES TO WS-NUMBER-TEXT
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-JSON-BUFFER-IN
                     DC-JSON-PATH-IN
                     WS-VALUE-POS
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE WS-VALUE-POS TO WS-END-POS
           PERFORM UNTIL WS-END-POS > 8192
               MOVE DC-JSON-BUFFER-IN(WS-END-POS:1) TO WS-CHAR
               IF (WS-CHAR >= "0" AND WS-CHAR <= "9")
                  OR WS-CHAR = "-"
                  OR WS-CHAR = "+"
                  OR WS-CHAR = "."
                   ADD 1 TO WS-END-POS
               ELSE
                   EXIT PERFORM
               END-IF
           END-PERFORM

           COMPUTE WS-NUMBER-LEN = WS-END-POS - WS-VALUE-POS
           IF WS-NUMBER-LEN = 0 OR WS-NUMBER-LEN > 64
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_JSON_TYPE" TO DC-ERROR-CODE
               MOVE "JSON value is not a number." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-JSON-BUFFER-IN(WS-VALUE-POS:WS-NUMBER-LEN)
               TO WS-NUMBER-TEXT(1:WS-NUMBER-LEN)
           COMPUTE DC-JSON-OUT-NUMBER =
               FUNCTION NUMVAL(WS-NUMBER-TEXT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-JSON-GET-NUMBER.
