       IDENTIFICATION DIVISION.
       PROGRAM-ID. JSON-TEST.
       *> JP: JSON validate/path/token/write helper の基本契約を検証するテストです。
       *> JP: 上位レイヤーが依存する「最小限読める/書ける」をここで固定します。
       *> EN: Test that verifies the basic contracts of JSON validate/path/token/write helpers.
       *> EN: It locks down the minimal read/write behavior that higher layers depend on.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-JSON PIC X(8192).
       01 WS-PATH PIC X(128).
       01 WS-STRING PIC X(512).
       01 WS-NUMBER PIC S9(18) COMP-5.
       01 WS-TOKEN-COUNT PIC 9(5) COMP-5.
       01 WS-KEY PIC X(128).
       01 WS-VALUE PIC X(512).
       01 WS-WRITTEN-JSON PIC X(8192).
       COPY "discord-json.cpy".
       COPY "discord-result.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           MOVE '{"op":10,"t":"READY","s":42,"d":{"session_id":"abc123","heartbeat_interval":45000}}'
               TO WS-JSON

           MOVE "$.op" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING WS-JSON WS-PATH WS-NUMBER DC-RESULT
           PERFORM CHECK-OK
           IF WS-NUMBER NOT = 10
               DISPLAY "json-test: $.op was not 10"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.d.session_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-STRING) NOT = "abc123"
               DISPLAY "json-test: session_id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.d.heartbeat_interval" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING WS-JSON WS-PATH WS-NUMBER DC-RESULT
           PERFORM CHECK-OK
           IF WS-NUMBER NOT = 45000
               DISPLAY "json-test: heartbeat interval mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM TEST-DEPTH-AND-ARRAYS
           PERFORM TEST-ESCAPES
           PERFORM TEST-TOKENS-AND-VALIDATION
           PERFORM TEST-WRITER-ESCAPES

           PERFORM FINISH-TEST.

       TEST-DEPTH-AND-ARRAYS.
           MOVE SPACES TO WS-JSON
           MOVE '{"id":"outer","nested":{"id":"inner"},"items":[{"name":"first"},{"name":"second"}],"matrix":[[1,2],[3,4]]}'
               TO WS-JSON

           MOVE "$.id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-STRING) NOT = "outer"
               DISPLAY "json-test: depth-aware root lookup mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.nested.id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-STRING) NOT = "inner"
               DISPLAY "json-test: nested lookup mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.items[1].name" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-STRING) NOT = "second"
               DISPLAY "json-test: object array lookup mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.matrix[1][0]" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING WS-JSON WS-PATH WS-NUMBER DC-RESULT
           PERFORM CHECK-OK
           IF WS-NUMBER NOT = 3
               DISPLAY "json-test: nested array lookup mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-ESCAPES.
           MOVE SPACES TO WS-JSON
           MOVE '{"message":"line\nquote:\" ok","unicode":"\u65e5\u672c","emoji":"\ud83d\ude00"}'
               TO WS-JSON
           MOVE "$.message" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF WS-STRING(5:1) NOT = X"0A"
              OR WS-STRING(12:1) NOT = QUOTE
               DISPLAY "json-test: basic string unescape mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.unicode" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF WS-STRING(1:6) NOT = X"E697A5E69CAC"
               DISPLAY "json-test: unicode escape mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "$.emoji" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-JSON WS-PATH WS-STRING DC-RESULT
           PERFORM CHECK-OK
           IF WS-STRING(1:4) NOT = X"F09F9880"
               DISPLAY "json-test: surrogate escape mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-TOKENS-AND-VALIDATION.
           MOVE SPACES TO WS-JSON
           MOVE '{"ok":true,"none":null,"values":[1,false]}' TO WS-JSON
           CALL "DC-JSON-TOKENIZE"
               USING WS-JSON WS-TOKEN-COUNT DC-RESULT
           PERFORM CHECK-OK
           IF WS-TOKEN-COUNT NOT = 17
               DISPLAY "json-test: token count mismatch " WS-TOKEN-COUNT
               ADD 1 TO WS-FAILURES
           END-IF
           CALL "DC-JSON-SCAN"
               USING WS-JSON DC-JSON-TOKENS DC-RESULT
           PERFORM CHECK-OK
           IF DC-JT-KIND(1) NOT = DC-JT-OBJECT-START
              OR DC-JT-KIND(DC-JT-COUNT) NOT = DC-JT-OBJECT-END
               DISPLAY "json-test: scanner token boundary mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-JSON
           MOVE '{"broken":[1,2}' TO WS-JSON
           CALL "DC-JSON-VALIDATE" USING WS-JSON DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               DISPLAY "json-test: malformed JSON was accepted"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-JSON
           MOVE '{"missing" "colon"}' TO WS-JSON
           CALL "DC-JSON-VALIDATE" USING WS-JSON DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               DISPLAY "json-test: missing colon was accepted"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-JSON
           MOVE '{"trailing":true,}' TO WS-JSON
           CALL "DC-JSON-VALIDATE" USING WS-JSON DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-OK
               DISPLAY "json-test: trailing comma was accepted"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-WRITER-ESCAPES.
           MOVE SPACES TO WS-KEY
           MOVE "quote" TO WS-KEY(1:5)
           MOVE QUOTE TO WS-KEY(6:1)
           MOVE "key" TO WS-KEY(7:3)
           MOVE SPACES TO WS-VALUE
           MOVE "line" TO WS-VALUE(1:4)
           MOVE X"0A" TO WS-VALUE(5:1)
           MOVE "slash" TO WS-VALUE(6:5)
           MOVE X"5C" TO WS-VALUE(11:1)
           MOVE QUOTE TO WS-VALUE(12:1)
           CALL "DC-JSON-WRITE-STRING"
               USING WS-KEY WS-VALUE WS-WRITTEN-JSON DC-RESULT
           PERFORM CHECK-OK
           IF WS-WRITTEN-JSON(1:32)
               NOT = X"7B2271756F74655C226B6579223A226C696E655C6E736C6173685C5C5C22227D"
               DISPLAY "json-test: writer escape mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "json-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "json-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "json-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM JSON-TEST.
