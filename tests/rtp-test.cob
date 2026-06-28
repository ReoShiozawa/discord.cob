       IDENTIFICATION DIVISION.
       PROGRAM-ID. RTP-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-RTP-STATE
           MOVE 1 TO DC-RTP-SEQUENCE
           MOVE 960 TO DC-RTP-TIMESTAMP
           MOVE 1234 TO DC-RTP-SSRC
           MOVE 960 TO DC-RTP-FRAME-SAMPLES

           CALL "DC-OPUS-BUILD-SILENCE"
               USING DC-OPUS-FRAME DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-RTP-BUILD-PACKET"
               USING DC-RTP-STATE
                     DC-OPUS-FRAME
                     DC-RTP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK

           IF DC-RTP-PACKET-LENGTH NOT = 15
               DISPLAY "rtp-test: packet length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-RTP-PACKET-DATA(1:1) NOT = X"80"
               DISPLAY "rtp-test: RTP version byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-RTP-PACKET-DATA(2:1) NOT = X"78"
               DISPLAY "rtp-test: RTP payload byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-RTP-ADVANCE" USING DC-RTP-STATE DC-RESULT
           PERFORM CHECK-OK
           IF DC-RTP-SEQUENCE NOT = 2
               DISPLAY "rtp-test: sequence did not advance"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-RTP-TIMESTAMP NOT = 1920
               DISPLAY "rtp-test: timestamp did not advance"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM FINISH-TEST.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "rtp-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "rtp-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "rtp-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM RTP-TEST.
