       IDENTIFICATION DIVISION.
       PROGRAM-ID. WEBSOCKET-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-LONG-PAYLOAD PIC X(130).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.
       01 WS-IDX PIC 9(4) COMP-5.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-ENCODE-DECODE
           PERFORM TEST-MASKED-DECODE
           PERFORM TEST-EXTENDED-LENGTH
           PERFORM FINISH-TEST.

       TEST-ENCODE-DECODE.
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 5 TO DC-WS-PAYLOAD-LENGTH
           MOVE "hello" TO DC-WS-PAYLOAD

           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-BUFFER-LENGTH NOT = 7
               DISPLAY "websocket-test: short frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-FIN-FLAG NOT = 1
               DISPLAY "websocket-test: fin flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-OPCODE NOT = 1
               DISPLAY "websocket-test: opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD(1:5) NOT = "hello"
               DISPLAY "websocket-test: payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-MASKED-DECODE.
           INITIALIZE DC-WS-BUFFER
           MOVE 11 TO DC-WS-BUFFER-LENGTH
           MOVE FUNCTION CHAR(130) TO DC-WS-BUFFER-DATA(1:1)
           MOVE FUNCTION CHAR(134) TO DC-WS-BUFFER-DATA(2:1)
           MOVE FUNCTION CHAR(56) TO DC-WS-BUFFER-DATA(3:1)
           MOVE FUNCTION CHAR(251) TO DC-WS-BUFFER-DATA(4:1)
           MOVE FUNCTION CHAR(34) TO DC-WS-BUFFER-DATA(5:1)
           MOVE FUNCTION CHAR(62) TO DC-WS-BUFFER-DATA(6:1)
           MOVE FUNCTION CHAR(128) TO DC-WS-BUFFER-DATA(7:1)
           MOVE FUNCTION CHAR(160) TO DC-WS-BUFFER-DATA(8:1)
           MOVE FUNCTION CHAR(78) TO DC-WS-BUFFER-DATA(9:1)
           MOVE FUNCTION CHAR(82) TO DC-WS-BUFFER-DATA(10:1)
           MOVE FUNCTION CHAR(89) TO DC-WS-BUFFER-DATA(11:1)

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-PAYLOAD(1:5) NOT = "Hello"
               DISPLAY "websocket-test: masked payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-EXTENDED-LENGTH.
           MOVE ALL "A" TO WS-LONG-PAYLOAD
           INITIALIZE DC-WS-FRAME
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 2 TO DC-WS-OPCODE
           MOVE 130 TO DC-WS-PAYLOAD-LENGTH
           MOVE WS-LONG-PAYLOAD TO DC-WS-PAYLOAD(1:130)

           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-BUFFER-LENGTH NOT = 134
               DISPLAY "websocket-test: extended frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER DC-WS-FRAME DC-RESULT
           PERFORM CHECK-OK
           IF DC-WS-OPCODE NOT = 2
               DISPLAY "websocket-test: extended opcode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-WS-PAYLOAD-LENGTH NOT = 130
               DISPLAY "websocket-test: extended payload length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 130
               IF DC-WS-PAYLOAD(WS-IDX:1) NOT = "A"
                   DISPLAY "websocket-test: extended payload data mismatch"
                   ADD 1 TO WS-FAILURES
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "websocket-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "websocket-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "websocket-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM WEBSOCKET-TEST.
