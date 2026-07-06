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
       COPY "discord-voice.cpy".
       COPY "discord-music.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.
       01 WS-COMMAND PIC X(256).
       01 WS-EVENT-NAME PIC X(64) VALUE "READY".
       01 WS-HANDLER-NAME PIC X(64) VALUE "APP-ON-READY".
       01 WS-REPLACED-HANDLER PIC X(64) VALUE "APP-ON-READY-REPLACED".
       01 WS-STEP-COUNT PIC S9(9) COMP-5 VALUE 2.
       01 WS-WAIT-MS PIC 9(10) COMP-5 VALUE 0.
       01 WS-STOP-FILE PIC X(512)
           VALUE "/tmp/discord-cob-core-test.stop".
       01 WS-FILE-EXISTS-FLAG PIC 9 VALUE 0.
       01 WS-SHUTDOWN-GUILD-ID PIC X(32) VALUE "shutdown-guild".

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-REGISTER-DISPATCH
           PERFORM TEST-REPLACE-HANDLER
           PERFORM TEST-BOT-REGISTER-DEFAULTS
           PERFORM TEST-BOT-RUN
           PERFORM TEST-FILE-EXISTS
           PERFORM TEST-BOT-RUN-UNTIL-FILE
           PERFORM TEST-BOT-SHUTDOWN
           PERFORM FINISH-TEST.

       TEST-REGISTER-DISPATCH.
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

           IF DC-HANDLER-COUNT NOT = 1
               DISPLAY "core-test: handler count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-REPLACE-HANDLER.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-ON"
               USING DC-CLIENT
                     WS-EVENT-NAME
                     WS-HANDLER-NAME
                     DC-RESULT
           PERFORM CHECK-OK
           CALL "DC-ON"
               USING DC-CLIENT
                     WS-EVENT-NAME
                     WS-REPLACED-HANDLER
                     DC-RESULT
           PERFORM CHECK-OK

           IF DC-HANDLER-COUNT NOT = 1
               DISPLAY "core-test: replace handler count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-PROGRAM(1))
               NOT = "APP-ON-READY-REPLACED"
               DISPLAY "core-test: replace handler program mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE 0 TO DC-CLIENT-STATE
           INITIALIZE DC-EVENT
           MOVE "READY" TO DC-EVENT-NAME
           CALL "DC-DISPATCH"
               USING DC-CLIENT DC-EVENT DC-RESULT
           PERFORM CHECK-OK
           IF DC-CLIENT-STATE NOT = 7
               DISPLAY "core-test: replace dispatch state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BOT-REGISTER-DEFAULTS.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-BOT-REGISTER-DEFAULTS"
               USING DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK

           IF DC-HANDLER-COUNT NOT = 3
               DISPLAY "core-test: bootstrap handler count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(1))
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "core-test: bootstrap first event mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(2))
               NOT = "VOICE_SERVER_UPDATE"
               DISPLAY "core-test: bootstrap second event mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(3))
               NOT = "INTERACTION_CREATE"
               DISPLAY "core-test: bootstrap third event mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BOT-RUN.
           INITIALIZE DC-CONFIG
           MOVE 3 TO DC-MUSIC-IDLE-LEAVE-TICKS
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           IF DC-CLIENT-MUSIC-IDLE-LEAVE-TICKS NOT = 3
               DISPLAY "core-test: music idle leave ticks mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-BOT-RUN"
               USING DC-CLIENT
                     WS-STEP-COUNT
                     WS-WAIT-MS
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-FILE-EXISTS.
           MOVE "rm -f /tmp/discord-cob-core-test.stop" TO WS-COMMAND
           CALL "SYSTEM" USING WS-COMMAND END-CALL

           MOVE 9 TO WS-FILE-EXISTS-FLAG
           CALL "DC-FILE-EXISTS"
               USING WS-STOP-FILE
                     WS-FILE-EXISTS-FLAG
                     DC-RESULT
           PERFORM CHECK-OK
           IF WS-FILE-EXISTS-FLAG NOT = 0
               DISPLAY "core-test: stop file missing-state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE "touch /tmp/discord-cob-core-test.stop" TO WS-COMMAND
           CALL "SYSTEM" USING WS-COMMAND END-CALL

           MOVE 0 TO WS-FILE-EXISTS-FLAG
           CALL "DC-FILE-EXISTS"
               USING WS-STOP-FILE
                     WS-FILE-EXISTS-FLAG
                     DC-RESULT
           PERFORM CHECK-OK
           IF WS-FILE-EXISTS-FLAG NOT = 1
               DISPLAY "core-test: stop file present-state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BOT-RUN-UNTIL-FILE.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           MOVE "touch /tmp/discord-cob-core-test.stop" TO WS-COMMAND
           CALL "SYSTEM" USING WS-COMMAND END-CALL

           CALL "DC-BOT-RUN-UNTIL-FILE"
               USING DC-CLIENT
                     WS-STOP-FILE
                     WS-WAIT-MS
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE "rm -f /tmp/discord-cob-core-test.stop" TO WS-COMMAND
           CALL "SYSTEM" USING WS-COMMAND END-CALL.

       TEST-BOT-SHUTDOWN.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK

           MOVE 2 TO DC-CLIENT-STATE
           MOVE 1 TO DC-CLIENT-GW-WS-OPEN-FLAG
           MOVE 0 TO DC-CLIENT-GW-WS-LIVE-FLAG
           MOVE 42 TO DC-CLIENT-GW-WS-HANDLE

           INITIALIZE DC-VOICE-SESSION
           MOVE WS-SHUTDOWN-GUILD-ID TO DC-VS-GUILD-ID
           MOVE "chan-1" TO DC-VS-CHANNEL-ID
           MOVE "sess-1" TO DC-VS-SESSION-ID
           MOVE "voice-token" TO DC-VS-TOKEN
           MOVE "voice.example.test" TO DC-VS-ENDPOINT
           MOVE 1 TO DC-VS-WS-OPEN-FLAG
           MOVE 4 TO DC-VS-STATE
           CALL "DC-VOICE-SESSION-SAVE"
               USING WS-SHUTDOWN-GUILD-ID
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-MUSIC-QUEUE
           INITIALIZE DC-AUDIO-PLAYER
           INITIALIZE DC-MUSIC-TRACK
           INITIALIZE DC-RTP-STATE
           INITIALIZE DC-OPUS-HANDLE
           MOVE WS-SHUTDOWN-GUILD-ID TO DC-MQ-GUILD-ID
           CALL "DC-MUSIC-STATE-SAVE"
               USING WS-SHUTDOWN-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-BOT-SHUTDOWN"
               USING DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK

           IF DC-CLIENT-GW-WS-OPEN-FLAG NOT = 0
               DISPLAY "core-test: shutdown gateway open flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-STATE NOT = 3
               DISPLAY "core-test: shutdown client state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-VOICE-SESSION-LOAD"
               USING WS-SHUTDOWN-GUILD-ID
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               DISPLAY "core-test: shutdown voice session was not cleared"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-MUSIC-STATE-LOAD"
               USING WS-SHUTDOWN-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               DISPLAY "core-test: shutdown music state was not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

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

       IDENTIFICATION DIVISION.
       PROGRAM-ID. APP-ON-READY-REPLACED.
       *> JP: 再登録で前の handler が差し替わることを確認する補助 program です。
       *> EN: Helper program used to verify that re-registration replaces the previous handler.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
           MOVE 7 TO DC-CLIENT-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM APP-ON-READY-REPLACED.
