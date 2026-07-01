       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTERACTION-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-event.cpy".
       COPY "discord-music.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-RAW-PLAY-JSON PIC X(8192).
       01 WS-RAW-MISSING-OPTION-JSON PIC X(8192).
       01 WS-WRAPPED-STOP-JSON PIC X(8192).
       01 WS-REPLY-PAYLOAD PIC X(8192).
       01 WS-EXPECTED-PLAY-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Queued: build/test/sample-opus.ogg"}}'.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-DISCORD-HOST PIC X(256) VALUE "discord.com".
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-SOURCE-PATH PIC X(512) VALUE "build/test/sample-opus.ogg".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-COMMAND PIC X(4096).
       01 WS-BODY-START PIC 9(5) COMP-5.
       01 WS-PATH PIC X(128).
       01 WS-TEXT PIC X(512).
       01 WS-POS PIC 9(5) COMP-5.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM WRITE-FIXTURE
           PERFORM INIT-CLIENT
           PERFORM BUILD-JSON-FIXTURES
           PERFORM TEST-PARSE-RAW
           PERFORM TEST-PARSE-WRAPPED
           PERFORM TEST-HANDLE-PLAY
           PERFORM TEST-HANDLE-ERROR
           PERFORM TEST-HANDLE-EVENT
           PERFORM TEST-CALLBACK-REPLY
           PERFORM TEST-DISPATCH-HANDLER-REPLY
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

       BUILD-JSON-FIXTURES.
           MOVE SPACES TO WS-RAW-PLAY-JSON
           STRING
               '{"id":"int-1","token":"tok-1","guild_id":"guild-1",' 
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},' DELIMITED BY SIZE
               '"data":{"name":"/play","options":[{"name":"file","value":"'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '"}]}}' DELIMITED BY SIZE
               INTO WS-RAW-PLAY-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MISSING-OPTION-JSON
           STRING
               '{"id":"int-1","token":"tok-1","guild_id":"guild-1",' 
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},' DELIMITED BY SIZE
               '"data":{"name":"/play"}}' DELIMITED BY SIZE
               INTO WS-RAW-MISSING-OPTION-JSON
           END-STRING

           MOVE SPACES TO WS-WRAPPED-STOP-JSON
           STRING
               '{"op":0,"t":"INTERACTION_CREATE","s":77,"d":{' 
                   DELIMITED BY SIZE
               '"id":"int-2","token":"tok-2","guild_id":"guild-2",'
                   DELIMITED BY SIZE
               '"channel_id":"text-2","member":{"user":{"id":"user-2"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/stop"}}}' DELIMITED BY SIZE
               INTO WS-WRAPPED-STOP-JSON
           END-STRING.

       TEST-PARSE-RAW.
           MOVE "$.id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.token" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.data.name" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.member.voice.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.data.options" TO WS-PATH
           MOVE 0 TO WS-POS
           CALL "DC-JSON-LOCATE-PATH"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-POS
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-INTERACTION-ID) NOT = "int-1"
               DISPLAY "interaction-test: raw id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) NOT = "tok-1"
               DISPLAY "interaction-test: raw token mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-GUILD-ID) NOT = "guild-1"
               DISPLAY "interaction-test: raw guild mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) NOT = "voice-1"
               DISPLAY "interaction-test: raw voice channel mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-NAME) NOT = "/play"
               DISPLAY "interaction-test: raw command mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-COMMAND-OPTION-COUNT NOT = 1
               DISPLAY "interaction-test: raw option count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-OPTION-NAME(1)) NOT = "file"
               DISPLAY "interaction-test: raw option name mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-OPTION-VALUE(1))
               NOT = FUNCTION TRIM(WS-SOURCE-PATH)
               DISPLAY "interaction-test: raw option value mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PARSE-WRAPPED.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-WRAPPED-STOP-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-INTERACTION-ID) NOT = "int-2"
               DISPLAY "interaction-test: wrapped id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-NAME) NOT = "/stop"
               DISPLAY "interaction-test: wrapped command mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-GUILD-ID) NOT = "guild-2"
               DISPLAY "interaction-test: wrapped guild mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-PLAY.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-NAME)
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "interaction-test: handle play action mismatch"
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
               DISPLAY "interaction-test: handle play queue size mismatch "
                   DC-MQ-SIZE
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY)
               DISPLAY "interaction-test: handle play reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM RESET-GATEWAY-COMMAND.

       TEST-HANDLE-ERROR.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MISSING-OPTION-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Error: Interaction option was not found."}}'
               DISPLAY "interaction-test: handle error reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-EVENT.
           INITIALIZE DC-EVENT
           MOVE "INTERACTION_CREATE" TO DC-EVENT-NAME
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-WRAPPED-STOP-JSON TRAILING))
               TO DC-EVENT-PAYLOAD-LENGTH
           MOVE WS-WRAPPED-STOP-JSON TO DC-EVENT-PAYLOAD
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE-EVENT"
               USING DC-CLIENT
                     DC-EVENT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Stopped playback."}}'
               DISPLAY "interaction-test: handle event reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CALLBACK-REPLY.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-CALLBACK-BUILD"
               USING DC-INTERACTION
                     WS-REPLY-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "POST"
               DISPLAY "interaction-test: callback method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-HOST) NOT = "discord.com"
               DISPLAY "interaction-test: callback host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY "interaction-test: callback content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/interactions/int-1/tok-1/callback"
               DISPLAY "interaction-test: callback path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-REPLY-PAYLOAD TRAILING)))
               NOT = FUNCTION TRIM(WS-REPLY-PAYLOAD)
               DISPLAY "interaction-test: callback body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-DISPATCH-HANDLER-REPLY.
           CALL "DC-INTERACTION-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-CALLBACK-FIXTURE
           INITIALIZE DC-EVENT
           MOVE "INTERACTION_CREATE" TO DC-EVENT-NAME
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-PLAY-JSON TRAILING))
               TO DC-EVENT-PAYLOAD-LENGTH
           MOVE WS-RAW-PLAY-JSON TO DC-EVENT-PAYLOAD
           CALL "DC-DISPATCH"
               USING DC-CLIENT
                     DC-EVENT
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:56)
               NOT = "POST /api/v10/interactions/int-1/tok-1/callback HTTP/1.1"
               DISPLAY "interaction-test: dispatch callback request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "interaction-test: dispatch callback body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY TRAILING)))
                   NOT = FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY)
                   DISPLAY "interaction-test: dispatch callback body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       PREPARE-CALLBACK-FIXTURE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 204 No Content" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 0" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       RESET-GATEWAY-COMMAND.
           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "interaction-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "interaction-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "interaction-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM INTERACTION-TEST.
