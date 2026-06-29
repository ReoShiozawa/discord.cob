       IDENTIFICATION DIVISION.
       PROGRAM-ID. URL-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-result.cpy".
       01 WS-URL PIC X(512).
       01 WS-URL-IN PIC X(512).
       01 WS-HOST PIC X(256).
       01 WS-PATH PIC X(512).
       01 WS-VERSION PIC 9(2) COMP-5 VALUE 10.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-BUILD-WSS
           PERFORM TEST-SPLIT-WSS
           PERFORM FINISH-TEST.

       TEST-BUILD-WSS.
           MOVE SPACES TO WS-URL
           MOVE "gateway.discord.gg" TO WS-URL-IN
           CALL "DC-URL-BUILD-WSS"
               USING WS-URL-IN
                     WS-VERSION
                     WS-URL
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-URL) NOT = "wss://gateway.discord.gg/?v=10"
               DISPLAY "url-test: build wss mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SPLIT-WSS.
           MOVE SPACES TO WS-HOST
           MOVE SPACES TO WS-PATH
           MOVE "wss://gateway.discord.gg/?v=10&encoding=json" TO WS-URL-IN
           CALL "DC-URL-SPLIT-WSS"
               USING WS-URL-IN
                     WS-HOST
                     WS-PATH
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-HOST) NOT = "gateway.discord.gg"
               DISPLAY "url-test: split host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-PATH) NOT = "/?v=10&encoding=json"
               DISPLAY "url-test: split path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "url-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "url-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "url-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM URL-TEST.
