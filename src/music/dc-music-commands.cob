       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-JOIN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
           MOVE "Voice join is not implemented yet." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-JOIN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-LEAVE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
           MOVE "Voice leave is not implemented yet." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-LEAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-PLAY.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music playback is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-PLAY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-SKIP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music player is not connected." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-STOP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music player is not connected." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-STOP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-QUEUE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-INTERACTION DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music queue is not connected to a player."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-QUEUE.
