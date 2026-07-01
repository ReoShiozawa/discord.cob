       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-ROUTE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           EVALUATE FUNCTION TRIM(DC-COMMAND-NAME)
               WHEN "/join"
                   CALL "DC-MUSIC-CMD-JOIN"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/leave"
                   CALL "DC-MUSIC-CMD-LEAVE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/play"
                   CALL "DC-MUSIC-CMD-PLAY"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/skip"
                   CALL "DC-MUSIC-CMD-SKIP"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/stop"
                   CALL "DC-MUSIC-CMD-STOP"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/queue"
                   CALL "DC-MUSIC-CMD-QUEUE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN OTHER
                   MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                   MOVE "DC_ERR_COMMAND_NOT_FOUND" TO DC-ERROR-CODE
                   MOVE "Slash command is not registered."
                       TO DC-ERROR-MESSAGE
           END-EVALUATE
           GOBACK.
       END PROGRAM DC-COMMAND-ROUTE.
