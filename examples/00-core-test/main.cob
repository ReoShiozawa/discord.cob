       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-CORE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE "example-token" TO DC-BOT-TOKEN
           MOVE 129 TO DC-INTENTS

           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT

           IF DC-STATUS-CODE = 0
               DISPLAY "client initialized"
           ELSE
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
           END-IF
           STOP RUN.
       END PROGRAM EXAMPLE-CORE.
