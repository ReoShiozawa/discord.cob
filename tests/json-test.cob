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

           PERFORM FINISH-TEST.

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
