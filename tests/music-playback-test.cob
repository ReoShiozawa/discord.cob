       IDENTIFICATION DIVISION.
       PROGRAM-ID. MUSIC-PLAYBACK-TEST.
       *> JP: music playback tick と track 進行の挙動を検証するテストです。
       *> JP: 再生開始条件、EOF、state 更新の流れが崩れていないかを見ます。
       *> EN: Test that verifies music-playback ticks and track progression.
       *> EN: It checks start conditions, EOF handling, and state updates across playback.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-music.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-CHANNEL-ID PIC X(32) VALUE "chan-1".
       01 WS-SOURCE-PATH PIC X(512) VALUE "build/test/sample-opus.ogg".
       01 WS-VOICE-UDP-HOST PIC X(256) VALUE "127.0.0.1".
       01 WS-VOICE-DISCOVERED-IP PIC X(64) VALUE "198.51.100.10".
       01 WS-COMMAND PIC X(4096).
       01 WS-EXPECTED-PAYLOAD PIC X(3).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM WRITE-FIXTURE
           PERFORM INIT-CLIENT
           PERFORM TEST-PLAY-QUEUES-TRACK
           PERFORM TEST-PLAYBACK-TICKS
           PERFORM TEST-STOP-CLEARS-QUEUE
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

       TEST-PLAY-QUEUES-TRACK.
           CALL "DC-MUSIC-PLAY"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     WS-SOURCE-PATH
                     DC-RESULT
           PERFORM CHECK-OK

           IF DC-CLIENT-GW-COMMAND-QUEUED NOT = 1
               DISPLAY "music-playback-test: gateway queue flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-NAME)
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "music-playback-test: gateway action mismatch"
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
               DISPLAY "music-playback-test: queue size mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-MQ-SOURCE(1))
               NOT = "build/test/sample-opus.ogg"
               DISPLAY "music-playback-test: queued source mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD.

       TEST-PLAYBACK-TICKS.
           PERFORM PREPARE-VOICE-SESSION

           CALL "DC-MUSIC-VOICE-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "ABC" TO WS-EXPECTED-PAYLOAD
           PERFORM CHECK-LAST-UDP-PAYLOAD

           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "music-playback-test: queue not drained"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-MUSIC-VOICE-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "DEF" TO WS-EXPECTED-PAYLOAD
           PERFORM CHECK-LAST-UDP-PAYLOAD

           CALL "DC-MUSIC-VOICE-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-STOP-CLEARS-QUEUE.
           CALL "DC-MUSIC-PLAY"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     WS-SOURCE-PATH
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-MUSIC-STOP"
               USING DC-CLIENT
                     WS-GUILD-ID
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
               DISPLAY "music-playback-test: stop did not clear queue"
               ADD 1 TO WS-FAILURES
           END-IF.

       PREPARE-VOICE-SESSION.
           INITIALIZE DC-VOICE-SESSION
           CALL "DC-VOICE-SESSION-INIT"
               USING DC-VOICE-SESSION
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE 1 TO DC-VS-READY-FLAG
           MOVE 1 TO DC-VS-UDP-READY-FLAG
           MOVE 4242 TO DC-VS-SSRC
           MOVE WS-VOICE-UDP-HOST TO DC-VS-IP
           MOVE 5000 TO DC-VS-PORT
           MOVE WS-VOICE-DISCOVERED-IP TO DC-VS-DISCOVERED-IP
           MOVE 62000 TO DC-VS-DISCOVERED-PORT

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-SET-RESPONSE"
               USING WS-VOICE-UDP-HOST
                     DC-VS-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-UDP-SESSION
           MOVE WS-VOICE-UDP-HOST TO DC-UDP-REMOTE-HOST
           MOVE DC-VS-PORT TO DC-UDP-REMOTE-PORT
           MOVE WS-VOICE-DISCOVERED-IP TO DC-UDP-LOCAL-IP
           MOVE DC-VS-DISCOVERED-PORT TO DC-UDP-LOCAL-PORT
           CALL "DC-UDP-OPEN"
               USING DC-UDP-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-UDP-HANDLE TO DC-VS-UDP-HANDLE.

       CHECK-LAST-UDP-PAYLOAD.
           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-UDP-HOST
                     DC-VS-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-LENGTH NOT = 15
               DISPLAY "music-playback-test: udp packet length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UDP-PACKET-DATA(13:3) NOT = WS-EXPECTED-PAYLOAD
               DISPLAY "music-playback-test: udp payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "music-playback-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "music-playback-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "music-playback-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM MUSIC-PLAYBACK-TEST.
