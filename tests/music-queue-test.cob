       IDENTIFICATION DIVISION.
       PROGRAM-ID. MUSIC-QUEUE-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-SOURCE PIC X(512) VALUE "song.opus".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           CALL "DC-MUSIC-QUEUE-INIT"
               USING DC-MUSIC-QUEUE WS-GUILD-ID DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-TRACK-FROM-SOURCE"
               USING WS-SOURCE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK
           MOVE "track-1" TO DC-TRACK-ID

           CALL "DC-MUSIC-QUEUE-PUSH"
               USING DC-MUSIC-QUEUE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 1
               DISPLAY "music-queue-test: queue size was not 1"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-MUSIC-TRACK
           CALL "DC-MUSIC-QUEUE-POP"
               USING DC-MUSIC-QUEUE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-TRACK-SOURCE) NOT = "song.opus"
               DISPLAY "music-queue-test: popped track source mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "music-queue-test: queue size was not 0"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM FINISH-TEST.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "music-queue-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "music-queue-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "music-queue-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM MUSIC-QUEUE-TEST.
