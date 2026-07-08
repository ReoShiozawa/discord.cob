       IDENTIFICATION DIVISION.
       PROGRAM-ID. SLASH-COMMAND-TEST.
       *> JP: slash command 用 HTTP builder 群の path/body 契約を検証するテストです。
       *> JP: register/list/delete/overwrite 系の request 形が崩れないことを見ます。
       *> JP: 併せて高水準 command schema API の JSON 変換・検証・同期も見ます。
       *> EN: Test that verifies the path/body contracts of the slash-command HTTP builders.
       *> EN: It ensures request shapes for register, list, delete, and overwrite stay stable.
       *> EN: It also covers the high-level command schema API: JSON conversion,
       *> EN: validation, and synchronization.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       COPY "discord-command-schema.cpy".
       01 WS-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"join","type":1,"description":"Join your current voice channel"}'.
       01 WS-QUEUE-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"queue","type":1,"description":"Show queued tracks"}'.
       01 WS-REMOVE-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"remove","type":1,"description":"Remove a queued track by position","options":[{"name":"index","type":4,"description":"1-based queue position","required":true}]}'.
       01 WS-CLEARQUEUE-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"clearqueue","type":1,"description":"Clear all queued tracks"}'.
       01 WS-PAUSE-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"pause","type":1,"description":"Pause the current track"}'.
       01 WS-RESUME-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"resume","type":1,"description":"Resume the paused track"}'.
       01 WS-NOWPLAYING-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"nowplaying","type":1,"description":"Show the current track"}'.
       01 WS-COMMANDS-JSON PIC X(8192).
       01 WS-SCHEMA-JSON PIC X(8192).
       01 WS-SCHEMA-EXPECTED-JSON PIC X(8192).
       01 WS-SCHEMA-CMD-NAME PIC X(32).
       01 WS-SCHEMA-CMD-DESC PIC X(100).
       01 WS-SCHEMA-OPT-NAME PIC X(32).
       01 WS-SCHEMA-OPT-TYPE PIC 9(4) COMP-5.
       01 WS-SCHEMA-OPT-DESC PIC X(100).
       01 WS-SCHEMA-OPT-REQUIRED PIC 9(4) COMP-5.
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
           PERFORM TEST-SCHEMA-TO-JSON
           PERFORM TEST-SCHEMA-EMPTY-ERROR
           PERFORM TEST-SCHEMA-NAME-CASE-ERROR
           PERFORM TEST-SCHEMA-ORPHAN-OPTION-ERROR
           PERFORM TEST-SCHEMA-SYNC
           PERFORM TEST-MUSIC-SCHEMA-JSON
           PERFORM TEST-MUSIC-COMMANDS-REGISTER
           PERFORM TEST-MUSIC-COMMANDS-OVERWRITE
           PERFORM TEST-MUSIC-BOT-BOOTSTRAP
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

       BUILD-SAMPLE-SCHEMA.
           *> JP: schema tests 共通の宣言。option 無しと option 付きを 1 件ずつ持ちます。
           *> EN: Shared declaration for the schema tests: one command without
           *> EN: options and one command with a required option.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "ping" TO WS-SCHEMA-CMD-NAME
           MOVE "Check that the bot responds" TO WS-SCHEMA-CMD-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-CMD-NAME
                     WS-SCHEMA-CMD-DESC
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "echo" TO WS-SCHEMA-CMD-NAME
           MOVE "Echo a message back" TO WS-SCHEMA-CMD-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-CMD-NAME
                     WS-SCHEMA-CMD-DESC
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "message" TO WS-SCHEMA-OPT-NAME
           MOVE 3 TO WS-SCHEMA-OPT-TYPE
           MOVE "Message to echo" TO WS-SCHEMA-OPT-DESC
           MOVE 1 TO WS-SCHEMA-OPT-REQUIRED
           CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-OPT-NAME
                     WS-SCHEMA-OPT-TYPE
                     WS-SCHEMA-OPT-DESC
                     WS-SCHEMA-OPT-REQUIRED
                     DC-RESULT
           PERFORM CHECK-OK.

       BUILD-SCHEMA-EXPECTED-JSON.
           MOVE SPACES TO WS-SCHEMA-EXPECTED-JSON
           STRING
               "[" DELIMITED BY SIZE
               '{"name":"ping","type":1,' DELIMITED BY SIZE
               '"description":"Check that the bot responds"},'
                   DELIMITED BY SIZE
               '{"name":"echo","type":1,' DELIMITED BY SIZE
               '"description":"Echo a message back",'
                   DELIMITED BY SIZE
               '"options":[{"name":"message","type":3,'
                   DELIMITED BY SIZE
               '"description":"Message to echo",' DELIMITED BY SIZE
               '"required":true}]}' DELIMITED BY SIZE
               "]" DELIMITED BY SIZE
               INTO WS-SCHEMA-EXPECTED-JSON
           END-STRING.

       TEST-SCHEMA-TO-JSON.
           PERFORM BUILD-SAMPLE-SCHEMA
           PERFORM BUILD-SCHEMA-EXPECTED-JSON
           MOVE SPACES TO WS-SCHEMA-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-JSON
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-SCHEMA-JSON)
               NOT = FUNCTION TRIM(WS-SCHEMA-EXPECTED-JSON)
               DISPLAY "slash-command-test: schema json mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           *> JP: 同じ schema から 2 回変換しても payload が安定していることを見ます。
           *> EN: Converting the same schema twice must yield the same payload.
           MOVE SPACES TO WS-SCHEMA-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-JSON
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-SCHEMA-JSON)
               NOT = FUNCTION TRIM(WS-SCHEMA-EXPECTED-JSON)
               DISPLAY "slash-command-test: schema json not stable"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SCHEMA-EMPTY-ERROR.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE SPACES TO WS-SCHEMA-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-ERROR
               DISPLAY "slash-command-test: schema empty status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE)
               NOT = "DC_ERR_COMMAND_SCHEMA"
               DISPLAY "slash-command-test: schema empty code mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SCHEMA-NAME-CASE-ERROR.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "Ping" TO WS-SCHEMA-CMD-NAME
           MOVE "Check that the bot responds" TO WS-SCHEMA-CMD-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-CMD-NAME
                     WS-SCHEMA-CMD-DESC
                     DC-RESULT
           PERFORM CHECK-OK
           CALL "DC-COMMAND-SCHEMA-VALIDATE"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-ERROR
               DISPLAY "slash-command-test: schema case status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE)
               NOT = "DC_ERR_COMMAND_SCHEMA"
               DISPLAY "slash-command-test: schema case code mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SCHEMA-ORPHAN-OPTION-ERROR.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "message" TO WS-SCHEMA-OPT-NAME
           MOVE 3 TO WS-SCHEMA-OPT-TYPE
           MOVE "Message to echo" TO WS-SCHEMA-OPT-DESC
           MOVE 1 TO WS-SCHEMA-OPT-REQUIRED
           CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-OPT-NAME
                     WS-SCHEMA-OPT-TYPE
                     WS-SCHEMA-OPT-DESC
                     WS-SCHEMA-OPT-REQUIRED
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-ERROR
               DISPLAY
                   "slash-command-test: schema orphan status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-ERROR-CODE)
               NOT = "DC_ERR_COMMAND_SCHEMA"
               DISPLAY "slash-command-test: schema orphan code mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SCHEMA-SYNC.
           PERFORM BUILD-SAMPLE-SCHEMA
           PERFORM BUILD-SCHEMA-EXPECTED-JSON
           PERFORM PREPARE-OVERWRITE-RESPONSE
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-COMMAND-SCHEMA-SYNC"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-COMMAND-SCHEMA
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "slash-command-test: schema sync status mismatch"
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
               DISPLAY "slash-command-test: schema sync path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-SCHEMA-EXPECTED-JSON TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY
                   "slash-command-test: schema sync body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-SCHEMA-EXPECTED-JSON TRAILING)))
                   NOT = FUNCTION TRIM(WS-SCHEMA-EXPECTED-JSON)
                   DISPLAY "slash-command-test: schema sync body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-MUSIC-SCHEMA-JSON.
           *> JP: 組み込み music command set が schema API 経由でも従来と
           *> JP: 同一の JSON になることを見ます。
           *> EN: The built-in music command set must produce the same JSON
           *> EN: through the schema API as before.
           CALL "DC-MUSIC-COMMANDS-SCHEMA"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE SPACES TO WS-SCHEMA-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-JSON
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-SCHEMA-JSON)
               NOT = FUNCTION TRIM(WS-COMMANDS-JSON)
               DISPLAY "slash-command-test: music schema json mismatch"
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
                   FUNCTION TRIM(WS-NOWPLAYING-COMMAND-JSON TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "slash-command-test: music register body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-NOWPLAYING-COMMAND-JSON TRAILING)))
                   NOT = FUNCTION TRIM(WS-NOWPLAYING-COMMAND-JSON)
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

       TEST-MUSIC-BOT-BOOTSTRAP.
           PERFORM PREPARE-OVERWRITE-RESPONSE
           CALL "DC-MUSIC-BOT-BOOTSTRAP"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HANDLER-COUNT NOT = 3
               DISPLAY "slash-command-test: bootstrap handler count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(1))
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "slash-command-test: bootstrap first event mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(3))
               NOT = "INTERACTION_CREATE"
               DISPLAY "slash-command-test: bootstrap interaction event mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-IA-COMMAND-COUNT NOT = 2
               DISPLAY "slash-command-test: bootstrap command ia count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-IA-COMMAND-NAME(1))
               NOT = "/queue"
               DISPLAY "slash-command-test: bootstrap queue ia mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-IA-COMMAND-NAME(2))
               NOT = "/nowplaying"
               DISPLAY "slash-command-test: bootstrap nowplaying ia mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-IA-COMPONENT-COUNT NOT = 7
               DISPLAY
                   "slash-command-test: bootstrap component ia count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-IA-COMPONENT-ID(1))
               NOT = "music:skip"
               DISPLAY "slash-command-test: bootstrap skip component mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-IA-COMPONENT-ID(7))
               NOT = "music:np:view"
               DISPLAY "slash-command-test: bootstrap npview component mismatch"
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
               DISPLAY "slash-command-test: bootstrap overwrite path mismatch"
               ADD 1 TO WS-FAILURES
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
               '{"name":"pause","type":1,' DELIMITED BY SIZE
               '"description":"Pause the current track"},'
                   DELIMITED BY SIZE
               '{"name":"resume","type":1,' DELIMITED BY SIZE
               '"description":"Resume the paused track"},'
                   DELIMITED BY SIZE
               '{"name":"stop","type":1,' DELIMITED BY SIZE
               '"description":"Stop playback"},'
                   DELIMITED BY SIZE
               '{"name":"queue","type":1,' DELIMITED BY SIZE
               '"description":"Show queued tracks"},'
                   DELIMITED BY SIZE
               '{"name":"remove","type":1,' DELIMITED BY SIZE
               '"description":"Remove a queued track by position",'
                   DELIMITED BY SIZE
               '"options":[{"name":"index","type":4,' DELIMITED BY SIZE
               '"description":"1-based queue position",'
                   DELIMITED BY SIZE
               '"required":true}]},' DELIMITED BY SIZE
               '{"name":"clearqueue","type":1,' DELIMITED BY SIZE
               '"description":"Clear all queued tracks"},'
                   DELIMITED BY SIZE
               '{"name":"nowplaying","type":1,' DELIMITED BY SIZE
               '"description":"Show the current track"}'
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
