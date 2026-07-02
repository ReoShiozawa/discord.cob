       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-SLASH-COMMAND.
       *> JP: slash command request builder の使い方を示す example です。
       *> JP: application id、guild id、JSON payload がどの request へ落ちるかを見られます。
       *> EN: Example that demonstrates how to use the slash-command request builder.
       *> EN: It shows how the application id, guild id, and JSON payload land in the resulting request.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "example-guild-id".
       01 WS-COMMAND-JSON PIC X(8192)
           VALUE '{"name":"join","type":1,"description":"Join your current voice channel"}'.

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
           STOP RUN.
       END PROGRAM EXAMPLE-SLASH-COMMAND.
