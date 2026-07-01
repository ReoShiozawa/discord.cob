       IDENTIFICATION DIVISION.
       PROGRAM-ID. OPUS-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-FIXTURE-PATH PIC X(512) VALUE "build/test/sample-opus.ogg".
       01 WS-COMMAND PIC X(4096).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM WRITE-FIXTURE
           PERFORM TEST-OPEN
           PERFORM TEST-READ-FRAMES
           PERFORM TEST-CLOSE-REOPEN
           PERFORM FINISH-TEST.

       WRITE-FIXTURE.
           MOVE SPACES TO WS-COMMAND
           STRING
               "mkdir -p build/test && printf '" DELIMITED BY SIZE
               "\117\147\147\123\000\002" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\001\023OpusHead\001\002\000\000\200\273\000\000\000"
                   DELIMITED BY SIZE
               "\000\000" DELIMITED BY SIZE
               "\117\147\147\123\000\000" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\001\020OpusTags\000\000\000\000\000\000\000\000"
                   DELIMITED BY SIZE
               "\117\147\147\123\000\004" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\002\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\002\003\003ABCDEF" DELIMITED BY SIZE
               "' > " DELIMITED BY SIZE
               FUNCTION TRIM(WS-FIXTURE-PATH) DELIMITED BY SIZE
               INTO WS-COMMAND
           END-STRING
           CALL "SYSTEM" USING WS-COMMAND END-CALL.

       TEST-OPEN.
           CALL "DC-AUDIO-SOURCE-FROM-FILE"
               USING WS-FIXTURE-PATH
                     DC-AUDIO-SOURCE
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-OPUS-OPEN"
               USING DC-AUDIO-SOURCE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-OPUS-HANDLE-ID = 0
               DISPLAY "opus-test: handle id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-OPUS-SOURCE)
               NOT = "build/test/sample-opus.ogg"
               DISPLAY "opus-test: source mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-READ-FRAMES.
           INITIALIZE DC-OPUS-FRAME
           CALL "DC-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE
                     DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-OPUS-LENGTH NOT = 3
               DISPLAY "opus-test: first frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-OPUS-DATA(1:3) NOT = "ABC"
               DISPLAY "opus-test: first frame payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-OPUS-DURATION-MS NOT = 20
               DISPLAY "opus-test: first frame duration mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-OPUS-FRAME
           CALL "DC-OPUS-PACKET-NEXT"
               USING DC-OPUS-HANDLE
                     DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-OPUS-LENGTH NOT = 3
               DISPLAY "opus-test: second frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-OPUS-DATA(1:3) NOT = "DEF"
               DISPLAY "opus-test: second frame payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-OPUS-DURATION-MS NOT = 20
               DISPLAY "opus-test: second frame duration mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-OPUS-FRAME
           CALL "DC-OPUS-READ-FRAME"
               USING DC-OPUS-HANDLE
                     DC-OPUS-FRAME
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-EOF
               DISPLAY "opus-test: EOF not reported"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-OPUS-EOF-FLAG NOT = 1
               DISPLAY "opus-test: EOF flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CLOSE-REOPEN.
           CALL "DC-OPUS-CLOSE"
               USING DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-OPUS-HANDLE-ID NOT = 0
               DISPLAY "opus-test: close did not clear handle"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-OPUS-OPEN"
               USING DC-AUDIO-SOURCE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-OPUS-HANDLE-ID = 0
               DISPLAY "opus-test: reopen handle id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "opus-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "opus-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "opus-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM OPUS-TEST.
