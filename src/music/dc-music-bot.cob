       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-PLAY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-MUSIC-QUEUE.
          05 WS-MQ-GUILD-ID PIC X(32).
          05 WS-MQ-SIZE PIC 9(4) COMP-5.
          05 WS-MQ-HEAD PIC 9(4) COMP-5.
          05 WS-MQ-TAIL PIC 9(4) COMP-5.
          05 WS-MQ-TRACK OCCURS 100 TIMES.
             10 WS-MQ-TRACK-ID PIC X(64).
             10 WS-MQ-TITLE PIC X(128).
             10 WS-MQ-SOURCE PIC X(512).
             10 WS-MQ-REQUESTER-ID PIC X(32).
             10 WS-MQ-STATUS PIC 9.
       01 WS-AUDIO-PLAYER.
          05 WS-PLAYER-STATE PIC 9.
          05 WS-PLAYER-GUILD-ID PIC X(32).
          05 WS-PLAYER-TRACK-ID PIC X(64).
          05 WS-PLAYER-FRAME-COUNT PIC 9(10) COMP-5.
          05 WS-PLAYER-VOLUME PIC 9(3).
          05 WS-PLAYER-EOF-FLAG PIC 9.
       01 WS-CURRENT-TRACK.
          05 WS-CURRENT-TRACK-ID PIC X(64).
          05 WS-CURRENT-TRACK-TITLE PIC X(128).
          05 WS-CURRENT-TRACK-SOURCE PIC X(512).
          05 WS-CURRENT-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-CURRENT-TRACK-REQUESTER-ID PIC X(32).
          05 WS-CURRENT-TRACK-STATUS PIC 9.
       01 WS-RTP-STATE.
          05 WS-RTP-SEQUENCE PIC 9(10) COMP-5.
          05 WS-RTP-TIMESTAMP PIC 9(10) COMP-5.
          05 WS-RTP-SSRC PIC 9(10) COMP-5.
          05 WS-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.
       01 WS-OPUS-HANDLE.
          05 WS-OPUS-HANDLE-ID PIC 9(10) COMP-5.
          05 WS-OPUS-SOURCE PIC X(512).
          05 WS-OPUS-EOF-FLAG PIC 9.
       01 WS-NEW-TRACK.
          05 WS-NEW-TRACK-ID PIC X(64).
          05 WS-NEW-TRACK-TITLE PIC X(128).
          05 WS-NEW-TRACK-SOURCE PIC X(512).
          05 WS-NEW-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-NEW-TRACK-REQUESTER-ID PIC X(32).
          05 WS-NEW-TRACK-STATUS PIC 9.

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
           IF DC-CLIENT-STATE NOT = 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_NOT_READY" TO DC-ERROR-CODE
               MOVE "Gateway client must be ready before music play."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-MUSIC-VOICE-CHANNEL-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music voice channel id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-AUDIO-SOURCE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_SOURCE" TO DC-ERROR-CODE
               MOVE "Audio source path is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-STATE-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-MUSIC-QUEUE-INIT"
                   USING WS-MUSIC-QUEUE
                         DC-MUSIC-GUILD-ID-IN
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               CALL "DC-AUDIO-PLAYER-INIT"
                   USING WS-AUDIO-PLAYER
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE DC-MUSIC-GUILD-ID-IN TO WS-PLAYER-GUILD-ID
               INITIALIZE WS-CURRENT-TRACK
               INITIALIZE WS-RTP-STATE
               INITIALIZE WS-OPUS-HANDLE
           ELSE
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-VOICE-JOIN"
               USING DC-CLIENT
                     DC-MUSIC-GUILD-ID-IN
                     DC-MUSIC-VOICE-CHANNEL-ID-IN
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE WS-NEW-TRACK
           CALL "DC-TRACK-FROM-SOURCE"
               USING DC-AUDIO-SOURCE
                     WS-NEW-TRACK
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE DC-AUDIO-SOURCE TO WS-NEW-TRACK-ID

           CALL "DC-MUSIC-QUEUE-PUSH"
               USING WS-MUSIC-QUEUE
                     WS-NEW-TRACK
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-PLAY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-SKIP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-MUSIC-QUEUE.
          05 WS-MQ-GUILD-ID PIC X(32).
          05 WS-MQ-SIZE PIC 9(4) COMP-5.
          05 WS-MQ-HEAD PIC 9(4) COMP-5.
          05 WS-MQ-TAIL PIC 9(4) COMP-5.
          05 WS-MQ-TRACK OCCURS 100 TIMES.
             10 WS-MQ-TRACK-ID PIC X(64).
             10 WS-MQ-TITLE PIC X(128).
             10 WS-MQ-SOURCE PIC X(512).
             10 WS-MQ-REQUESTER-ID PIC X(32).
             10 WS-MQ-STATUS PIC 9.
       01 WS-AUDIO-PLAYER.
          05 WS-PLAYER-STATE PIC 9.
          05 WS-PLAYER-GUILD-ID PIC X(32).
          05 WS-PLAYER-TRACK-ID PIC X(64).
          05 WS-PLAYER-FRAME-COUNT PIC 9(10) COMP-5.
          05 WS-PLAYER-VOLUME PIC 9(3).
          05 WS-PLAYER-EOF-FLAG PIC 9.
       01 WS-CURRENT-TRACK.
          05 WS-CURRENT-TRACK-ID PIC X(64).
          05 WS-CURRENT-TRACK-TITLE PIC X(128).
          05 WS-CURRENT-TRACK-SOURCE PIC X(512).
          05 WS-CURRENT-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-CURRENT-TRACK-REQUESTER-ID PIC X(32).
          05 WS-CURRENT-TRACK-STATUS PIC 9.
       01 WS-RTP-STATE.
          05 WS-RTP-SEQUENCE PIC 9(10) COMP-5.
          05 WS-RTP-TIMESTAMP PIC 9(10) COMP-5.
          05 WS-RTP-SSRC PIC 9(10) COMP-5.
          05 WS-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.
       01 WS-OPUS-HANDLE.
          05 WS-OPUS-HANDLE-ID PIC 9(10) COMP-5.
          05 WS-OPUS-SOURCE PIC X(512).
          05 WS-OPUS-EOF-FLAG PIC 9.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-STATE-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-NOT-FOUND
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music player is not connected."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF WS-PLAYER-STATE = 1
               IF WS-OPUS-HANDLE-ID > 0
                   CALL "DC-OPUS-CLOSE"
                       USING WS-OPUS-HANDLE
                             WS-LOCAL-RESULT
                   IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                       MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                       MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                       MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                       GOBACK
                   END-IF
               END-IF
               INITIALIZE WS-CURRENT-TRACK
               INITIALIZE WS-OPUS-HANDLE
               MOVE 0 TO WS-PLAYER-STATE
               MOVE 1 TO WS-PLAYER-EOF-FLAG
           ELSE
               IF WS-MQ-SIZE > 0
                   INITIALIZE WS-CURRENT-TRACK
                   CALL "DC-MUSIC-QUEUE-POP"
                       USING WS-MUSIC-QUEUE
                             WS-CURRENT-TRACK
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
                   INITIALIZE WS-CURRENT-TRACK
               ELSE
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
                   MOVE "Music player is not connected."
                       TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STOP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-MUSIC-QUEUE.
          05 WS-MQ-GUILD-ID PIC X(32).
          05 WS-MQ-SIZE PIC 9(4) COMP-5.
          05 WS-MQ-HEAD PIC 9(4) COMP-5.
          05 WS-MQ-TAIL PIC 9(4) COMP-5.
          05 WS-MQ-TRACK OCCURS 100 TIMES.
             10 WS-MQ-TRACK-ID PIC X(64).
             10 WS-MQ-TITLE PIC X(128).
             10 WS-MQ-SOURCE PIC X(512).
             10 WS-MQ-REQUESTER-ID PIC X(32).
             10 WS-MQ-STATUS PIC 9.
       01 WS-AUDIO-PLAYER.
          05 WS-PLAYER-STATE PIC 9.
          05 WS-PLAYER-GUILD-ID PIC X(32).
          05 WS-PLAYER-TRACK-ID PIC X(64).
          05 WS-PLAYER-FRAME-COUNT PIC 9(10) COMP-5.
          05 WS-PLAYER-VOLUME PIC 9(3).
          05 WS-PLAYER-EOF-FLAG PIC 9.
       01 WS-CURRENT-TRACK.
          05 WS-CURRENT-TRACK-ID PIC X(64).
          05 WS-CURRENT-TRACK-TITLE PIC X(128).
          05 WS-CURRENT-TRACK-SOURCE PIC X(512).
          05 WS-CURRENT-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-CURRENT-TRACK-REQUESTER-ID PIC X(32).
          05 WS-CURRENT-TRACK-STATUS PIC 9.
       01 WS-RTP-STATE.
          05 WS-RTP-SEQUENCE PIC 9(10) COMP-5.
          05 WS-RTP-TIMESTAMP PIC 9(10) COMP-5.
          05 WS-RTP-SSRC PIC 9(10) COMP-5.
          05 WS-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.
       01 WS-OPUS-HANDLE.
          05 WS-OPUS-HANDLE-ID PIC 9(10) COMP-5.
          05 WS-OPUS-SOURCE PIC X(512).
          05 WS-OPUS-EOF-FLAG PIC 9.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-STATE-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
              AND DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               GOBACK
           END-IF

           IF WS-OPUS-HANDLE-ID > 0
               CALL "DC-OPUS-CLOSE"
                   USING WS-OPUS-HANDLE
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-MUSIC-QUEUE-INIT"
               USING WS-MUSIC-QUEUE
                     DC-MUSIC-GUILD-ID-IN
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-AUDIO-PLAYER-INIT"
               USING WS-AUDIO-PLAYER
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE DC-MUSIC-GUILD-ID-IN TO WS-PLAYER-GUILD-ID
           INITIALIZE WS-CURRENT-TRACK
           INITIALIZE WS-RTP-STATE
           INITIALIZE WS-OPUS-HANDLE

           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-STOP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-LIST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-AUDIO-PLAYER.
          05 WS-PLAYER-STATE PIC 9.
          05 WS-PLAYER-GUILD-ID PIC X(32).
          05 WS-PLAYER-TRACK-ID PIC X(64).
          05 WS-PLAYER-FRAME-COUNT PIC 9(10) COMP-5.
          05 WS-PLAYER-VOLUME PIC 9(3).
          05 WS-PLAYER-EOF-FLAG PIC 9.
       01 WS-CURRENT-TRACK.
          05 WS-CURRENT-TRACK-ID PIC X(64).
          05 WS-CURRENT-TRACK-TITLE PIC X(128).
          05 WS-CURRENT-TRACK-SOURCE PIC X(512).
          05 WS-CURRENT-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-CURRENT-TRACK-REQUESTER-ID PIC X(32).
          05 WS-CURRENT-TRACK-STATUS PIC 9.
       01 WS-RTP-STATE.
          05 WS-RTP-SEQUENCE PIC 9(10) COMP-5.
          05 WS-RTP-TIMESTAMP PIC 9(10) COMP-5.
          05 WS-RTP-SSRC PIC 9(10) COMP-5.
          05 WS-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.
       01 WS-OPUS-HANDLE.
          05 WS-OPUS-HANDLE-ID PIC 9(10) COMP-5.
          05 WS-OPUS-SOURCE PIC X(512).
          05 WS-OPUS-EOF-FLAG PIC 9.

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
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-STATE-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-MUSIC-QUEUE-INIT"
                   USING DC-MUSIC-QUEUE
                         DC-MUSIC-GUILD-ID-IN
                         DC-RESULT
               GOBACK
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-LIST.
