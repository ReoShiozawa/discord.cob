       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-GATEWAY-READY.
       *> JP: Gateway ready ハンドリングの最小セットを示す example です。
       *> JP: 接続後に READY event をどう受けるかの雰囲気をつかめます。
       *> EN: Example that shows a minimal Gateway-ready handling setup.
       *> EN: It gives a feel for how a READY event is received after connection.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE FUNCTION GET-ENVIRONMENT("DISCORD_TOKEN")
               TO DC-BOT-TOKEN
           MOVE 129 TO DC-INTENTS

           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           CALL "DC-LOGIN"
               USING DC-CLIENT DC-RESULT

           DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
           DISPLAY FUNCTION TRIM(DC-ERROR-MESSAGE)
           STOP RUN.
       END PROGRAM EXAMPLE-GATEWAY-READY.
