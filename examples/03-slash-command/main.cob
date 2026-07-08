       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-SLASH-COMMAND.
       *> JP: slash command request builder の使い方を示す example です。
       *> JP: application id、guild id、JSON payload がどの request へ落ちるかを見られます。
       *> JP: 併せて、高水準 command schema API で JSON を手組みせずに
       *> JP: 同じ payload を宣言的に作る流れも示します。
       *> EN: Example that demonstrates how to use the slash-command request builder.
       *> EN: It shows how the application id, guild id, and JSON payload land in the resulting request.
       *> EN: It also shows the high-level command schema API building the same
       *> EN: kind of payload declaratively, without hand-written JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       COPY "discord-command-schema.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "example-guild-id".
       01 WS-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"join","type":1,"description":"Join your current voice channel"}'.
       01 WS-SCHEMA-JSON PIC X(8192).
       01 WS-COMMAND-NAME PIC X(32).
       01 WS-COMMAND-DESC PIC X(100).
       01 WS-OPTION-NAME PIC X(32).
       01 WS-OPTION-TYPE PIC 9(4) COMP-5.
       01 WS-OPTION-DESC PIC X(100).
       01 WS-OPTION-REQUIRED PIC 9(4) COMP-5.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE "example-token" TO DC-BOT-TOKEN
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG
                     DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           MOVE "example-application-id" TO DC-CLIENT-ID
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-SLASH-COMMAND-BUILD-REQUEST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-COMMAND-JSON
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           DISPLAY "method: " FUNCTION TRIM(DC-HTTP-METHOD)
           DISPLAY "host:   " FUNCTION TRIM(DC-HTTP-HOST)
           DISPLAY "path:   " FUNCTION TRIM(DC-HTTP-PATH)
           DISPLAY "body:   "
               DC-HTTP-BODY(1:DC-HTTP-BODY-LENGTH)

           *> JP: ここからは高水準 schema API 版です。command と option を
           *> JP: 宣言し、overwrite にそのまま渡せる JSON を生成します。
           *> JP: 実際に同期する場合は DC-COMMAND-SCHEMA-SYNC を呼びます。
           *> EN: The rest uses the high-level schema API: declare commands and
           *> EN: options, then produce JSON ready for the overwrite helper.
           *> EN: Call DC-COMMAND-SCHEMA-SYNC to actually synchronize it.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT

           MOVE "join" TO WS-COMMAND-NAME
           MOVE "Join your current voice channel" TO WS-COMMAND-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-COMMAND-NAME
                     WS-COMMAND-DESC
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           MOVE "echo" TO WS-COMMAND-NAME
           MOVE "Echo a message back" TO WS-COMMAND-DESC
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-COMMAND-NAME
                     WS-COMMAND-DESC
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           MOVE "message" TO WS-OPTION-NAME
           MOVE 3 TO WS-OPTION-TYPE
           MOVE "Message to echo" TO WS-OPTION-DESC
           MOVE 1 TO WS-OPTION-REQUIRED
           CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
               USING DC-COMMAND-SCHEMA
                     WS-OPTION-NAME
                     WS-OPTION-TYPE
                     WS-OPTION-DESC
                     WS-OPTION-REQUIRED
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           MOVE SPACES TO WS-SCHEMA-JSON
           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     WS-SCHEMA-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               STOP RUN
           END-IF

           DISPLAY "schema: " FUNCTION TRIM(WS-SCHEMA-JSON)
           STOP RUN.
       END PROGRAM EXAMPLE-SLASH-COMMAND.
