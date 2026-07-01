       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-JOIN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Interaction voice channel id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-JOIN"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-USER-VOICE-CHANNEL-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-JOIN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-LEAVE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-LEAVE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-LEAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-PLAY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-AUDIO-SOURCE PIC X(512).
       01 WS-FILE-OPTION PIC X(64) VALUE "file".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction voice channel id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-AUDIO-SOURCE
           CALL "DC-INTERACTION-GET-OPTION"
               USING DC-INTERACTION
                     WS-FILE-OPTION
                     WS-AUDIO-SOURCE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-PLAY"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-USER-VOICE-CHANNEL-ID
                     WS-AUDIO-SOURCE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-PLAY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-SKIP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-SKIP"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-STOP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-STOP"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-STOP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-QUEUE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-QUEUE.
