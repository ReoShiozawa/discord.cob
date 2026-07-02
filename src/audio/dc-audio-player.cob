       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-PLAYER-INIT.
       *> JP: audio player の初期化と停止を担当する高水準 helper 群です。
       *> JP: playback state の入口と終了処理をそろえ、上位の music flow を単純にします。
       *> EN: High-level helpers for initializing and stopping the audio player.
       *> EN: They standardize playback start/stop boundaries so the higher-level music flow stays simple.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AUDIO-PLAYER DC-RESULT.
       MAIN.
           INITIALIZE DC-AUDIO-PLAYER
           MOVE 0 TO DC-PLAYER-STATE
           MOVE 100 TO DC-PLAYER-VOLUME
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-PLAYER-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-PLAYER-STOP.
       *> JP: audio player の初期化と停止を担当する高水準 helper 群です。
       *> JP: playback state の入口と終了処理をそろえ、上位の music flow を単純にします。
       *> EN: High-level helpers for initializing and stopping the audio player.
       *> EN: They standardize playback start/stop boundaries so the higher-level music flow stays simple.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AUDIO-PLAYER DC-RESULT.
       MAIN.
           MOVE 3 TO DC-PLAYER-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-PLAYER-STOP.
