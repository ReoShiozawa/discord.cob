       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-PLAY.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       01 DC-MUSIC-VOICE-CHANNEL-ID-IN PIC X(32).
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-VOICE-CHANNEL-ID-IN
           DC-AUDIO-SOURCE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Voice playback is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-PLAY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-SKIP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music player is not connected." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STOP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Music player is not connected." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-STOP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-LIST.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-QUEUE
           DC-RESULT.
       MAIN.
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-LIST.
