       IDENTIFICATION DIVISION.
       PROGRAM-ID. CORE-TEST.
       *> JP: core 初期化と event dispatch の最小経路を検証するテストです。
       *> JP: 補助 handler program も含め、このファイルだけで基本 dispatch を閉じています。
       *> EN: Test that verifies the minimal core initialization and event-dispatch path.
       *> EN: Including the helper handler program, this file keeps the basic dispatch flow self-contained.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.
       01 WS-EVENT-NAME PIC X(64) VALUE "READY".
       01 WS-HANDLER-NAME PIC X(64) VALUE "APP-ON-READY".

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE "test-token" TO DC-BOT-TOKEN
           MOVE 129 TO DC-INTENTS

           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           IF FUNCTION TRIM(DC-CLIENT-TOKEN) NOT = "test-token"
               DISPLAY "core-test: token was not copied"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-ON"
               USING DC-CLIENT
                     WS-EVENT-NAME
                     WS-HANDLER-NAME
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-EVENT
           MOVE "READY" TO DC-EVENT-NAME
           CALL "DC-DISPATCH"
               USING DC-CLIENT DC-EVENT DC-RESULT
           PERFORM CHECK-OK

           PERFORM FINISH-TEST.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "core-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "core-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "core-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM CORE-TEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. APP-ON-READY.
       *> JP: core 初期化と event dispatch の最小経路を検証するテストです。
       *> JP: 補助 handler program も含め、このファイルだけで基本 dispatch を閉じています。
       *> EN: Test that verifies the minimal core initialization and event-dispatch path.
       *> EN: Including the helper handler program, this file keeps the basic dispatch flow self-contained.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM APP-ON-READY.
