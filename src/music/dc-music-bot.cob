       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-PLAY.
       *> JP: music 機能の高水準 API 群です。
       *> JP: command handler から呼ばれる play/skip/stop/queue 操作を domain 単位で束ねています。
       *> EN: High-level APIs for the music feature set.
       *> EN: They bundle play/skip/stop/queue operations as domain actions for command handlers.

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
       01 WS-SPEAKING-OFF PIC 9 VALUE 0.
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
       *> JP: music 機能の高水準 API 群です。
       *> JP: command handler から呼ばれる play/skip/stop/queue 操作を domain 単位で束ねています。
       *> EN: High-level APIs for the music feature set.
       *> EN: They bundle play/skip/stop/queue operations as domain actions for command handlers.

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
       01 WS-NOTIFY-SPEAKING-OFF PIC 9 VALUE 0.
       01 WS-SPEAKING-OFF PIC 9 VALUE 0.

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
               MOVE 1 TO WS-NOTIFY-SPEAKING-OFF
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
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF WS-NOTIFY-SPEAKING-OFF = 1
               CALL "DC-MUSIC-QUEUE-SPEAKING-STORED"
                   USING DC-MUSIC-GUILD-ID-IN
                         WS-SPEAKING-OFF
                         DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-PAUSE.
       *> JP: 現在再生中の guild runtime を paused へ遷移させる高水準 API です。
       *> JP: queue と current track は維持し、tick 側だけを静止させます。
       *> EN: High-level API that moves the current guild runtime into the
       *> EN: paused state while preserving the queue and current track.

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
       01 WS-SPEAKING-OFF PIC 9 VALUE 0.

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

           IF WS-PLAYER-STATE = 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_ALREADY_PAUSED" TO DC-ERROR-CODE
               MOVE "Music player is already paused."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-PLAYER-STATE NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_PLAYING" TO DC-ERROR-CODE
               MOVE "Music player is not currently playing."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 2 TO WS-PLAYER-STATE
           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-MUSIC-QUEUE-SPEAKING-STORED"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-SPEAKING-OFF
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-PAUSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-RESUME.
       *> JP: paused 状態の guild runtime を playing に戻す高水準 API です。
       *> EN: High-level API that returns a paused guild runtime to playing.

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
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_PAUSED" TO DC-ERROR-CODE
               MOVE "Music player is already playing."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-PLAYER-STATE NOT = 2
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_PAUSED" TO DC-ERROR-CODE
               MOVE "Music player is not paused."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 1 TO WS-PLAYER-STATE
           MOVE 0 TO WS-PLAYER-EOF-FLAG
           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-RESUME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-REMOVE.
       *> JP: queue 内の指定位置の pending track を 1 つ取り除く高水準 API です。
       *> EN: High-level API that removes one pending track from the queue by position.

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

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       01 DC-MUSIC-REMOVE-POSITION PIC 9(4) COMP-5.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-REMOVE-POSITION
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-TRACK
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
               MOVE "DC_ERR_MUSIC_QUEUE_EMPTY" TO DC-ERROR-CODE
               MOVE "Music queue is empty."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-QUEUE-REMOVE-AT"
               USING WS-MUSIC-QUEUE
                     DC-MUSIC-REMOVE-POSITION
                     DC-MUSIC-TRACK
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
       END PROGRAM DC-MUSIC-REMOVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CLEARQUEUE.
       *> JP: current track は維持したまま、pending queue だけを空にする高水準 API です。
       *> EN: High-level API that clears only the pending queue while leaving
       *> EN: the current track/player state intact.

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
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-QUEUE-INIT"
               USING WS-MUSIC-QUEUE
                     DC-MUSIC-GUILD-ID-IN
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
       END PROGRAM DC-MUSIC-CLEARQUEUE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STOP.
       *> JP: music 機能の高水準 API 群です。
       *> JP: command handler から呼ばれる play/skip/stop/queue 操作を domain 単位で束ねています。
       *> EN: High-level APIs for the music feature set.
       *> EN: They bundle play/skip/stop/queue operations as domain actions for command handlers.

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
       01 WS-NOTIFY-SPEAKING-OFF PIC 9 VALUE 0.
       01 WS-SPEAKING-OFF PIC 9 VALUE 0.

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
           IF WS-PLAYER-STATE = 1
              OR WS-PLAYER-STATE = 2
               MOVE 1 TO WS-NOTIFY-SPEAKING-OFF
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

      *> JP: stop 後に空 runtime を残さず、次回は play 側で必要な分だけ再作成します。
      *> EN: After stop we remove the runtime entirely and let the next play
      *> EN: call recreate only what it needs.
           CALL "DC-MUSIC-STATE-CLEAR"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF WS-NOTIFY-SPEAKING-OFF = 1
               CALL "DC-MUSIC-QUEUE-SPEAKING-STORED"
                   USING DC-MUSIC-GUILD-ID-IN
                         WS-SPEAKING-OFF
                         DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-STOP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-NOWPLAYING.
       *> JP: guild ごとの current track を問い合わせる高水準 API です。
       *> JP: state が無い、または player が idle の場合は空 track を返して成功扱いにします。
       *> EN: High-level API that queries the current track for a guild.
       *> EN: Missing state or an idle player returns an empty track as a successful result.

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
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-TRACK
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
                     DC-MUSIC-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-NOT-FOUND
               INITIALIZE DC-MUSIC-TRACK
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

      *> JP: idle / stopped は「再生中なし」ですが、paused は current track を残して見せます。
      *> EN: Idle/stopped mean "nothing playing", while paused still exposes
      *> EN: the current track to higher-level status UIs.
           IF WS-PLAYER-STATE = 0
              OR WS-PLAYER-STATE = 3
               INITIALIZE DC-MUSIC-TRACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-NOWPLAYING.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-LIST.
       *> JP: music 機能の高水準 API 群です。
       *> JP: command handler から呼ばれる play/skip/stop/queue 操作を domain 単位で束ねています。
       *> EN: High-level APIs for the music feature set.
       *> EN: They bundle play/skip/stop/queue operations as domain actions for command handlers.

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
