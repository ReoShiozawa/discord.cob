       IDENTIFICATION DIVISION.
       PROGRAM-ID. MUSIC-QUEUE-TEST.
       *> JP: music queue の push/pop/順序保持を検証するテストです。
       *> JP: 固定長 queue としての基礎動作を contributor が安心して触れるようにします。
       *> EN: Test that verifies music-queue push/pop behavior and ordering.
       *> EN: It keeps the fixed-size queue fundamentals stable for contributors touching this area.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-SOURCE PIC X(512) VALUE "song.opus".
       01 WS-SOURCE-TWO PIC X(512) VALUE "song-2.opus".
       01 WS-SOURCE-THREE PIC X(512) VALUE "song-3.opus".
       01 WS-REMOVE-POSITION PIC 9(4) COMP-5 VALUE 2.
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

           PERFORM TEST-REMOVE-AT

           PERFORM FINISH-TEST.

       TEST-REMOVE-AT.
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

           CALL "DC-TRACK-FROM-SOURCE"
               USING WS-SOURCE-TWO DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK
           MOVE "track-2" TO DC-TRACK-ID
           CALL "DC-MUSIC-QUEUE-PUSH"
               USING DC-MUSIC-QUEUE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-TRACK-FROM-SOURCE"
               USING WS-SOURCE-THREE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK
           MOVE "track-3" TO DC-TRACK-ID
           CALL "DC-MUSIC-QUEUE-PUSH"
               USING DC-MUSIC-QUEUE DC-MUSIC-TRACK DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-MUSIC-TRACK
           CALL "DC-MUSIC-QUEUE-REMOVE-AT"
               USING DC-MUSIC-QUEUE
                     WS-REMOVE-POSITION
                     DC-MUSIC-TRACK
                     DC-RESULT
           PERFORM CHECK-OK

           IF FUNCTION TRIM(DC-TRACK-SOURCE) NOT = "song-2.opus"
               DISPLAY "music-queue-test: removed track source mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-MQ-SIZE NOT = 2
               DISPLAY "music-queue-test: queue size after remove mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-MQ-SOURCE(DC-MQ-HEAD)) NOT = "song.opus"
               DISPLAY "music-queue-test: first queue item after remove mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-MQ-SOURCE(DC-MQ-TAIL)) NOT = "song-3.opus"
               DISPLAY "music-queue-test: last queue item after remove mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

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
