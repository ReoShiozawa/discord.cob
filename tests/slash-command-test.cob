       IDENTIFICATION DIVISION.
       PROGRAM-ID. SLASH-COMMAND-TEST.
       *> JP: slash command 用 HTTP builder 群の path/body 契約を検証するテストです。
       *> JP: register/list/delete/overwrite 系の request 形が崩れないことを見ます。
       *> EN: Test that verifies the path/body contracts of the slash-command HTTP builders.
       *> EN: It ensures request shapes for register, list, delete, and overwrite stay stable.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"join","type":1,"description":"Join your current voice channel"}'.
       01 WS-QUEUE-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"queue","type":1,"description":"Show queued tracks"}'.
       01 WS-COMMANDS-JSON PIC X(8192).
       01 WS-LIST-BODY PIC X(8192).
       01 WS-OVERWRITE-BODY PIC X(8192).
       01 WS-COMMAND-ID PIC X(32) VALUE "cmd-1".
       01 WS-EMPTY-GUILD-ID PIC X(32).
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-HOST PIC X(256) VALUE "discord.com".
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-BODY-START PIC 9(5) COMP-5.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM INIT-CLIENT
           PERFORM TEST-BUILD-GLOBAL-REQUEST
           PERFORM TEST-BUILD-GUILD-REQUEST
           PERFORM TEST-BUILD-LIST-REQUEST
           PERFORM TEST-BUILD-DELETE-REQUEST
           PERFORM TEST-BUILD-OVERWRITE-REQUEST
           PERFORM TEST-REGISTER
           PERFORM TEST-LIST
           PERFORM TEST-DELETE
           PERFORM TEST-OVERWRITE
           PERFORM TEST-REGISTER-ERROR
           PERFORM TEST-MUSIC-COMMANDS-REGISTER
           PERFORM TEST-MUSIC-COMMANDS-OVERWRITE
           PERFORM FINISH-TEST.

       INIT-CLIENT.
           INITIALIZE DC-CONFIG
           MOVE "token" TO DC-BOT-TOKEN
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG
                     DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "app-1" TO DC-CLIENT-ID
           PERFORM BUILD-EXPECTED-COMMANDS-JSON
           PERFORM BUILD-LIST-BODY
           PERFORM BUILD-OVERWRITE-BODY.

       TEST-BUILD-GLOBAL-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-REQUEST"
               USING DC-CLIENT
                     WS-EMPTY-GUILD-ID
                     WS-COMMAND-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "POST"
               DISPLAY "slash-command-test: global method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-HOST) NOT = "discord.com"
               DISPLAY "slash-command-test: global host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/applications/app-1/commands"
               DISPLAY "slash-command-test: global path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-AUTHORIZATION) NOT = "Bot token"
               DISPLAY "slash-command-test: global auth mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY "slash-command-test: global content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-COMMAND-JSON TRAILING)))
               NOT = FUNCTION TRIM(WS-COMMAND-JSON)
               DISPLAY "slash-command-test: global body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-GUILD-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-REQUEST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMAND-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/applications/app-1/guilds/guild-1/commands"
               DISPLAY "slash-command-test: guild path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-LIST-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-LIST"
               USING DC-CLIENT
                     WS-EMPTY-GUILD-ID
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "GET"
               DISPLAY "slash-command-test: list method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/applications/app-1/commands"
               DISPLAY "slash-command-test: list path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE) NOT = SPACES
               DISPLAY "slash-command-test: list content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY-LENGTH NOT = 0
               DISPLAY "slash-command-test: list body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-DELETE-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-DELETE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMAND-ID
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "DELETE"
               DISPLAY "slash-command-test: delete method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/applications/app-1/guilds/guild-1/commands/cmd-1"
               DISPLAY "slash-command-test: delete path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-OVERWRITE-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-SET"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMANDS-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "PUT"
               DISPLAY "slash-command-test: overwrite method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/applications/app-1/guilds/guild-1/commands"
               DISPLAY "slash-command-test: overwrite path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY "slash-command-test: overwrite content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-COMMANDS-JSON TRAILING)))
               NOT = FUNCTION TRIM(WS-COMMANDS-JSON)
               DISPLAY "slash-command-test: overwrite body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-REGISTER.
           PERFORM PREPARE-SUCCESS-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-REGISTER"
               USING DC-CLIENT
                     WS-EMPTY-GUILD-ID
                     WS-COMMAND-JSON
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 201
               DISPLAY "slash-command-test: register status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:41)
               NOT = "POST /api/v10/applications/app-1/commands"
               DISPLAY "slash-command-test: register request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-LIST.
           PERFORM PREPARE-LIST-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-LIST"
               USING DC-CLIENT
                     WS-EMPTY-GUILD-ID
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "slash-command-test: list status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(
               1:FUNCTION LENGTH(FUNCTION TRIM(WS-LIST-BODY TRAILING)))
               NOT = FUNCTION TRIM(WS-LIST-BODY)
               DISPLAY "slash-command-test: list body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:40)
               NOT = "GET /api/v10/applications/app-1/commands"
               DISPLAY "slash-command-test: list request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-DELETE.
           PERFORM PREPARE-NO-CONTENT-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-DELETE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMAND-ID
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 204
               DISPLAY "slash-command-test: delete status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:64)
               NOT = "DELETE /api/v10/applications/app-1/guilds/guild-1/commands/cmd-1"
               DISPLAY "slash-command-test: delete request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-OVERWRITE.
           PERFORM PREPARE-OVERWRITE-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-OVERWRITE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMANDS-JSON
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "slash-command-test: overwrite status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(
               1:FUNCTION LENGTH(FUNCTION TRIM(WS-OVERWRITE-BODY TRAILING)))
               NOT = FUNCTION TRIM(WS-OVERWRITE-BODY)
               DISPLAY "slash-command-test: overwrite body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:55)
               NOT = "PUT /api/v10/applications/app-1/guilds/guild-1/commands"
               DISPLAY "slash-command-test: overwrite request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-COMMANDS-JSON TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "slash-command-test: overwrite body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-COMMANDS-JSON TRAILING)))
                   NOT = FUNCTION TRIM(WS-COMMANDS-JSON)
                   DISPLAY "slash-command-test: overwrite request body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-REGISTER-ERROR.
           PERFORM PREPARE-ERROR-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-REGISTER"
               USING DC-CLIENT
                     WS-EMPTY-GUILD-ID
                     WS-COMMAND-JSON
                     DC-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-ERROR
               DISPLAY "slash-command-test: error status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE) NOT = "DC_ERR_HTTP"
               DISPLAY "slash-command-test: error code mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-MUSIC-COMMANDS-REGISTER.
           PERFORM PREPARE-SUCCESS-RESPONSE
           CALL "DC-MUSIC-COMMANDS-REGISTER"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:56)
               NOT = "POST /api/v10/applications/app-1/guilds/guild-1/commands"
               DISPLAY "slash-command-test: music register path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-QUEUE-COMMAND-JSON TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "slash-command-test: music register body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-QUEUE-COMMAND-JSON TRAILING)))
                   NOT = FUNCTION TRIM(WS-QUEUE-COMMAND-JSON)
                   DISPLAY "slash-command-test: music register body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-MUSIC-COMMANDS-OVERWRITE.
           PERFORM PREPARE-OVERWRITE-RESPONSE
           CALL "DC-MUSIC-COMMANDS-OVERWRITE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:55)
               NOT = "PUT /api/v10/applications/app-1/guilds/guild-1/commands"
               DISPLAY "slash-command-test: music overwrite path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-COMMANDS-JSON TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "slash-command-test: music overwrite body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-COMMANDS-JSON TRAILING)))
                   NOT = FUNCTION TRIM(WS-COMMANDS-JSON)
                   DISPLAY "slash-command-test: music overwrite body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       BUILD-EXPECTED-COMMANDS-JSON.
           MOVE SPACES TO WS-COMMANDS-JSON
           STRING
               "[" DELIMITED BY SIZE
               '{"name":"join","type":1,' DELIMITED BY SIZE
               '"description":"Join your current voice channel"},'
                   DELIMITED BY SIZE
               '{"name":"leave","type":1,' DELIMITED BY SIZE
               '"description":"Leave the current voice channel"},'
                   DELIMITED BY SIZE
               '{"name":"play","type":1,' DELIMITED BY SIZE
               '"description":"Queue a local Ogg Opus file for playback",'
                   DELIMITED BY SIZE
               '"options":[{"name":"file","type":3,' DELIMITED BY SIZE
               '"description":"Path to a local .ogg or .opus file",'
                   DELIMITED BY SIZE
               '"required":true}]},' DELIMITED BY SIZE
               '{"name":"skip","type":1,' DELIMITED BY SIZE
               '"description":"Skip the current track"},'
                   DELIMITED BY SIZE
               '{"name":"stop","type":1,' DELIMITED BY SIZE
               '"description":"Stop playback"},'
                   DELIMITED BY SIZE
               '{"name":"queue","type":1,' DELIMITED BY SIZE
               '"description":"Show queued tracks"}'
                   DELIMITED BY SIZE
               "]" DELIMITED BY SIZE
               INTO WS-COMMANDS-JSON
           END-STRING.

       BUILD-LIST-BODY.
           MOVE SPACES TO WS-LIST-BODY
           STRING
               '[{"id":"cmd-1"}]' DELIMITED BY SIZE
               INTO WS-LIST-BODY
           END-STRING.

       BUILD-OVERWRITE-BODY.
           MOVE SPACES TO WS-OVERWRITE-BODY
           STRING
               '[{"id":"cmd-1","name":"join"}]' DELIMITED BY SIZE
               INTO WS-OVERWRITE-BODY
           END-STRING.

       PREPARE-SUCCESS-RESPONSE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 201 Created" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 14" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: application/json" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               '{"id":"cmd-1"}' DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-LIST-RESPONSE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 16" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: application/json" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               '[{"id":"cmd-1"}]' DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-NO-CONTENT-RESPONSE.
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
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-OVERWRITE-RESPONSE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 30" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Type: application/json" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               '[{"id":"cmd-1","name":"join"}]' DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-ERROR-RESPONSE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 400 Bad Request" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 2" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               "{}" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "slash-command-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "slash-command-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "slash-command-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM SLASH-COMMAND-TEST.
