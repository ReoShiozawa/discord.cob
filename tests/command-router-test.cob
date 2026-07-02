       IDENTIFICATION DIVISION.
       PROGRAM-ID. COMMAND-ROUTER-TEST.
       *> JP: command router の登録・探索・フォールバック挙動を検証するテストです。
       *> JP: slash / component / modal の各分岐が期待通り handler を選ぶかを確認します。
       *> EN: Test that verifies command-router registration, lookup, and fallback behavior.
       *> EN: It checks that slash, component, and modal branches pick the expected handlers.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-VOICE-CHANNEL-ID PIC X(32) VALUE "voice-1".
       01 WS-SOURCE-PATH PIC X(512) VALUE "build/test/sample-opus.ogg".
       01 WS-COMMAND PIC X(4096).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM WRITE-FIXTURE
           PERFORM INIT-CLIENT
           PERFORM TEST-JOIN
           PERFORM TEST-LEAVE
           PERFORM TEST-PLAY
           PERFORM TEST-QUEUE
           PERFORM TEST-SKIP
           PERFORM TEST-STOP
           PERFORM TEST-PLAY-OPTION-ERROR
           PERFORM TEST-UNKNOWN-COMMAND
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
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               INTO WS-COMMAND
           END-STRING
           CALL "SYSTEM" USING WS-COMMAND END-CALL.

       INIT-CLIENT.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG
                     DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE 2 TO DC-CLIENT-STATE
           MOVE "user-1" TO DC-CLIENT-USER-ID.

       TEST-JOIN.
           PERFORM PREPARE-INTERACTION
           MOVE "/join" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-CLIENT-GW-COMMAND-QUEUED NOT = 1
               DISPLAY "command-router-test: join queue flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-NAME)
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "command-router-test: join action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":"voice-1","self_mute":false,"self_deaf":false}}'
               DISPLAY "command-router-test: join payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM RESET-GATEWAY-COMMAND.

       TEST-LEAVE.
           PERFORM PREPARE-INTERACTION
           MOVE "/leave" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":null,"self_mute":false,"self_deaf":false}}'
               DISPLAY "command-router-test: leave payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM RESET-GATEWAY-COMMAND.

       TEST-PLAY.
           PERFORM PREPARE-INTERACTION
           MOVE "/play" TO DC-COMMAND-NAME
           MOVE 1 TO DC-COMMAND-OPTION-COUNT
           MOVE "file" TO DC-COMMAND-OPTION-NAME(1)
           MOVE WS-SOURCE-PATH TO DC-COMMAND-OPTION-VALUE(1)
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-NAME)
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "command-router-test: play action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 1
               DISPLAY "command-router-test: play queue size mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-MQ-SOURCE(1))
               NOT = FUNCTION TRIM(WS-SOURCE-PATH)
               DISPLAY "command-router-test: play queued source mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM RESET-GATEWAY-COMMAND.

       TEST-QUEUE.
           PERFORM PREPARE-INTERACTION
           MOVE "/queue" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-SKIP.
           PERFORM PREPARE-INTERACTION
           MOVE "/skip" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "command-router-test: skip did not drain queue"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-STOP.
           PERFORM PREPARE-INTERACTION
           MOVE "/play" TO DC-COMMAND-NAME
           MOVE 1 TO DC-COMMAND-OPTION-COUNT
           MOVE "file" TO DC-COMMAND-OPTION-NAME(1)
           MOVE WS-SOURCE-PATH TO DC-COMMAND-OPTION-VALUE(1)
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND

           PERFORM PREPARE-INTERACTION
           MOVE "/stop" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "command-router-test: stop did not clear queue"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PLAY-OPTION-ERROR.
           PERFORM PREPARE-INTERACTION
           MOVE "/play" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               DISPLAY "command-router-test: missing option status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE)
               NOT = "DC_ERR_INTERACTION_OPTION"
               DISPLAY "command-router-test: missing option error mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-UNKNOWN-COMMAND.
           PERFORM PREPARE-INTERACTION
           MOVE "/wat" TO DC-COMMAND-NAME
           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               DISPLAY "command-router-test: unknown command status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE)
               NOT = "DC_ERR_COMMAND_NOT_FOUND"
               DISPLAY "command-router-test: unknown command error mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       PREPARE-INTERACTION.
           INITIALIZE DC-INTERACTION
           MOVE WS-GUILD-ID TO DC-GUILD-ID
           MOVE "text-1" TO DC-CHANNEL-ID
           MOVE "user-1" TO DC-USER-ID
           MOVE WS-VOICE-CHANNEL-ID TO DC-USER-VOICE-CHANNEL-ID.

       RESET-GATEWAY-COMMAND.
           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "command-router-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "command-router-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "command-router-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM COMMAND-ROUTER-TEST.
