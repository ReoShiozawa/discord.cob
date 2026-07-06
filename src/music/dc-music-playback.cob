       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-VOICE-TICK.

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
       01 WS-AUDIO-SOURCE PIC X(512).
       01 WS-OPUS-FRAME.
          05 WS-OPUS-LENGTH PIC 9(5) COMP-5.
          05 WS-OPUS-DATA PIC X(4096).
          05 WS-OPUS-DURATION-MS PIC 9(3) COMP-5.
       01 WS-SPEAKING-ACTION PIC X(32) VALUE "SPEAKING".
       01 WS-SPEAKING-STATE PIC 9 VALUE 0.
       01 WS-SPEAKING-PAYLOAD.
          05 WS-SPEAKING-FLAG PIC 9.
          05 WS-SPEAKING-DELAY PIC 9(10) COMP-5.
          05 WS-SPEAKING-SSRC PIC 9(10) COMP-5.
       01 WS-SPEAKING-JSON PIC X(8192).
       01 WS-IDLE-TICK-COUNT PIC 9(9) COMP-5.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
      *> JP: Music tick は guild 単位の playback state を読み出し、
      *> JP: 必要なら次トラック開始、再生継続、EOF 後始末までを 1 回分だけ進めます。
      *> EN: The music tick loads guild-scoped playback state and advances at most one step:
      *> EN: start next track, continue playback, or clean up after EOF.
           IF FUNCTION TRIM(DC-VS-GUILD-ID) = SPACES
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

      *> JP: 再生状態は voice session ではなく別の music state に保存しています。
      *> EN: Playback state lives in separate music storage rather than in the voice session itself.
           CALL "DC-MUSIC-STATE-LOAD"
               USING DC-VS-GUILD-ID
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

           MOVE 0 TO WS-IDLE-TICK-COUNT
           CALL "DC-MUSIC-IDLE-COUNT-LOAD"
               USING DC-VS-GUILD-ID
                     WS-IDLE-TICK-COUNT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
              AND WS-LOCAL-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM HANDLE-IDLE-AUTO-LEAVE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-VS-GUILD-ID) = SPACES
               GOBACK
           END-IF

           IF (WS-PLAYER-STATE = 0
               OR WS-PLAYER-STATE = 3)
              AND WS-MQ-SIZE > 0
              AND DC-VS-READY-FLAG = 1
              AND DC-VS-UDP-HANDLE > 0
              AND DC-VS-UDP-READY-FLAG = 1
              AND (FUNCTION TRIM(DC-VS-ENCRYPTION-MODE) = SPACES
              OR FUNCTION TRIM(DC-VS-ENCRYPTION-MODE)
                 = "aead_xchacha20_poly1305_rtpsize")
      *> JP: 再生開始には queue 項目だけでなく、voice ready / UDP ready / 対応暗号モードが必要です。
      *> EN: Starting playback requires not only queued tracks, but also voice ready, UDP ready,
      *> EN: and a supported encryption mode.
               PERFORM START-NEXT-TRACK
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           IF WS-IDLE-TICK-COUNT NOT = 0
              AND (WS-MQ-SIZE > 0
              OR WS-PLAYER-STATE = 1
              OR WS-PLAYER-STATE = 2)
               MOVE 0 TO WS-IDLE-TICK-COUNT
               CALL "DC-MUSIC-IDLE-COUNT-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-IDLE-TICK-COUNT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

      *> JP: paused 中は reader/RTP の位置を動かさず、state だけ保存して戻します。
      *> EN: While paused, keep the reader/RTP position unchanged and only
      *> EN: persist the current snapshot.
           IF WS-PLAYER-STATE = 2
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         DC-RESULT
               GOBACK
           END-IF

           IF WS-PLAYER-STATE NOT = 1
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         DC-RESULT
               GOBACK
           END-IF

           IF DC-VS-READY-FLAG NOT = 1
              OR DC-VS-UDP-HANDLE <= 0
              OR DC-VS-UDP-READY-FLAG NOT = 1
              OR (FUNCTION TRIM(DC-VS-ENCRYPTION-MODE) NOT = SPACES
              AND FUNCTION TRIM(DC-VS-ENCRYPTION-MODE)
                  NOT = "aead_xchacha20_poly1305_rtpsize")
      *> JP: 再生途中でも transport 条件が崩れたら、その tick では frame を送らず state だけ保存します。
      *> EN: Even mid-playback, if transport prerequisites are missing we skip frame send for this tick
      *> EN: and only persist state.
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         DC-RESULT
               GOBACK
           END-IF

           PERFORM QUEUE-SPEAKING

      *> JP: Opus reader から 1 frame だけ読み、tick ごとに 1 frame だけ送る設計です。
      *> EN: We read at most one Opus frame and send at most one frame per tick.
           CALL "DC-OPUS-READ-FRAME"
               USING WS-OPUS-HANDLE
                     WS-OPUS-FRAME
                     DC-RESULT
           IF DC-STATUS-CODE = DC-STATUS-EOF
      *> JP: EOF なら player を止め、track 状態を完了にして handle を閉じます。
      *> EN: On EOF, stop the player, mark the track complete, and close the reader handle.
               MOVE 1 TO WS-PLAYER-EOF-FLAG
               MOVE 0 TO WS-PLAYER-STATE
               MOVE 2 TO WS-CURRENT-TRACK-STATUS
               CALL "DC-OPUS-CLOSE"
                   USING WS-OPUS-HANDLE
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
               INITIALIZE WS-OPUS-HANDLE
               MOVE 0 TO WS-SPEAKING-STATE
               PERFORM QUEUE-SPEAKING-STATE
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         DC-RESULT
               GOBACK
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
      *> JP: 読み取り失敗は track error として保存し、次 tick へ持ち越さないようにします。
      *> EN: Read failures are persisted as track errors so the tick does not keep retrying blindly.
               MOVE 3 TO WS-CURRENT-TRACK-STATUS
               MOVE 0 TO WS-PLAYER-STATE
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         WS-LOCAL-RESULT
               GOBACK
           END-IF

           CALL "DC-VOICE-SEND-FRAME"
               USING DC-VOICE-SESSION
                     WS-RTP-STATE
                     WS-OPUS-FRAME
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           ADD 1 TO WS-PLAYER-FRAME-COUNT
           MOVE 1 TO WS-CURRENT-TRACK-STATUS

           CALL "DC-MUSIC-STATE-SAVE"
               USING DC-VS-GUILD-ID
                     WS-MUSIC-QUEUE
                     WS-AUDIO-PLAYER
                     WS-CURRENT-TRACK
                     WS-RTP-STATE
                     WS-OPUS-HANDLE
                     DC-RESULT
           GOBACK.

       START-NEXT-TRACK.
      *> JP: 次トラック開始では queue pop -> player init -> opus open -> RTP seed の順に初期化します。
      *> EN: Starting the next track initializes in this order:
      *> EN: queue pop -> player init -> opus open -> RTP seed.
           INITIALIZE WS-CURRENT-TRACK
           CALL "DC-MUSIC-QUEUE-POP"
               USING WS-MUSIC-QUEUE
                     WS-CURRENT-TRACK
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

           MOVE 1 TO WS-PLAYER-STATE
           MOVE DC-VS-GUILD-ID TO WS-PLAYER-GUILD-ID
           MOVE WS-CURRENT-TRACK-ID TO WS-PLAYER-TRACK-ID
           MOVE 0 TO WS-PLAYER-FRAME-COUNT
           MOVE 0 TO WS-PLAYER-EOF-FLAG
           MOVE 1 TO WS-CURRENT-TRACK-STATUS

           MOVE WS-CURRENT-TRACK-SOURCE TO WS-AUDIO-SOURCE
           CALL "DC-OPUS-OPEN"
               USING WS-AUDIO-SOURCE
                     WS-OPUS-HANDLE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE 3 TO WS-CURRENT-TRACK-STATUS
               MOVE 0 TO WS-PLAYER-STATE
               GOBACK
           END-IF

           INITIALIZE WS-RTP-STATE
      *> JP: RTP timestamp の初期値は 1 frame 分先へ進めた値を置きます。
      *> EN: The initial RTP timestamp is seeded to one frame's worth of samples.
           MOVE 1 TO WS-RTP-SEQUENCE
           COMPUTE WS-RTP-FRAME-SAMPLES =
               (DC-CLIENT-AUDIO-SAMPLE-RATE / 1000)
               * DC-CLIENT-AUDIO-FRAME-MS
           IF WS-RTP-FRAME-SAMPLES <= 0
               MOVE 960 TO WS-RTP-FRAME-SAMPLES
           END-IF
           MOVE WS-RTP-FRAME-SAMPLES TO WS-RTP-TIMESTAMP
           MOVE DC-VS-SSRC TO WS-RTP-SSRC.

       QUEUE-SPEAKING.
      *> JP: speaking 通知は最初の audio frame の前に 1 回だけ queue します。
      *> EN: The speaking notification is queued once, just before the first audio frame.
           IF WS-PLAYER-FRAME-COUNT NOT = 0
               EXIT PARAGRAPH
           END-IF
           IF DC-VS-SSRC <= 0
               EXIT PARAGRAPH
           END-IF

           MOVE 1 TO WS-SPEAKING-STATE
           PERFORM QUEUE-SPEAKING-STATE.

       QUEUE-SPEAKING-STATE.
      *> JP: speaking=true/false の両方を同じ queue 規約で扱います。
      *> JP: queued speaking は新しい状態で上書きし、別種 control payload は邪魔しません。
      *> EN: Both speaking=true and speaking=false use the same queue policy.
      *> EN: Queued speaking payloads can be replaced by a newer speaking state,
      *> EN: while other control payloads are left untouched.
           IF DC-VS-SSRC <= 0
               EXIT PARAGRAPH
           END-IF
           IF DC-VS-COMMAND-QUEUED = 1
              AND FUNCTION TRIM(DC-VS-COMMAND-NAME) NOT = "SPEAKING"
               EXIT PARAGRAPH
           END-IF

           INITIALIZE WS-SPEAKING-PAYLOAD
           MOVE WS-SPEAKING-STATE TO WS-SPEAKING-FLAG
           MOVE 0 TO WS-SPEAKING-DELAY
           MOVE DC-VS-SSRC TO WS-SPEAKING-SSRC
           MOVE SPACES TO WS-SPEAKING-JSON

           CALL "DC-SPEAKING-BUILD"
               USING WS-SPEAKING-PAYLOAD
                     WS-SPEAKING-JSON
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF

           IF DC-VS-COMMAND-QUEUED = 1
              AND FUNCTION TRIM(DC-VS-COMMAND-NAME) = "SPEAKING"
               MOVE WS-SPEAKING-ACTION TO DC-VS-COMMAND-NAME
               MOVE WS-SPEAKING-JSON TO DC-VS-COMMAND-PAYLOAD
               EXIT PARAGRAPH
           END-IF

           CALL "DC-VOICE-QUEUE-PAYLOAD"
               USING DC-VOICE-SESSION
                     WS-SPEAKING-ACTION
                     WS-SPEAKING-JSON
                     WS-LOCAL-RESULT.

       HANDLE-IDLE-AUTO-LEAVE.
      *> JP: queue も current playback も空なら idle tick を数え、しきい値で自動退出します。
      *> EN: If both the queue and current playback are empty, count idle ticks
      *> EN: and auto-leave once the configured threshold is reached.
           IF WS-MQ-SIZE > 0
               EXIT PARAGRAPH
           END-IF
           IF WS-PLAYER-STATE = 1
              OR WS-PLAYER-STATE = 2
               EXIT PARAGRAPH
           END-IF
           IF FUNCTION TRIM(DC-VS-CHANNEL-ID) = SPACES
               EXIT PARAGRAPH
           END-IF
           IF DC-CLIENT-MUSIC-IDLE-LEAVE-TICKS <= 0
               EXIT PARAGRAPH
           END-IF

           ADD 1 TO WS-IDLE-TICK-COUNT
           CALL "DC-MUSIC-IDLE-COUNT-SAVE"
               USING DC-VS-GUILD-ID
                     WS-IDLE-TICK-COUNT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           IF WS-IDLE-TICK-COUNT < DC-CLIENT-MUSIC-IDLE-LEAVE-TICKS
               CALL "DC-MUSIC-STATE-SAVE"
                   USING DC-VS-GUILD-ID
                         WS-MUSIC-QUEUE
                         WS-AUDIO-PLAYER
                         WS-CURRENT-TRACK
                         WS-RTP-STATE
                         WS-OPUS-HANDLE
                         DC-RESULT
               EXIT PARAGRAPH
           END-IF

           MOVE 0 TO WS-SPEAKING-STATE
           PERFORM QUEUE-SPEAKING-STATE
           CALL "DC-VOICE-LEAVE"
               USING DC-CLIENT
                     DC-VS-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF

           CALL "DC-MUSIC-STATE-CLEAR"
               USING DC-VS-GUILD-ID
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO DC-VS-GUILD-ID
           CALL "DC-RESULT-OK" USING DC-RESULT.
       END PROGRAM DC-MUSIC-VOICE-TICK.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-VOICE-TICK-STORED.
       *> JP: 保存済み voice session を load して music tick を進め、更新後の session を戻します。
       *> JP: 呼び出し側が live な DC-VOICE-SESSION を握らなくても guild id だけで tick できます。
       *> EN: Load the stored voice session, run one music tick, then save the
       *> EN: updated session back.
       *> EN: This lets callers drive playback by guild id without holding a
       *> EN: live DC-VOICE-SESSION structure themselves.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MUSIC-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           CALL "DC-VOICE-SESSION-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-VOICE-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-SESSION-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-VOICE-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-VOICE-TICK-STORED.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-SPEAKING-STORED.
       *> JP: 保存済み voice session に speaking 状態通知を queue します。
       *> EN: Queue a speaking-state notification onto a stored voice session.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".
       01 WS-SPEAKING-ACTION PIC X(32) VALUE "SPEAKING".
       01 WS-SPEAKING-PAYLOAD.
          05 WS-SPEAKING-FLAG PIC 9.
          05 WS-SPEAKING-DELAY PIC 9(10) COMP-5.
          05 WS-SPEAKING-SSRC PIC 9(10) COMP-5.
       01 WS-SPEAKING-JSON PIC X(8192).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       01 DC-MUSIC-SPEAKING-FLAG PIC 9.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-SPEAKING-FLAG
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-VOICE-SESSION-LOAD"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-VOICE-SESSION
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-SSRC <= 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           IF DC-VS-COMMAND-QUEUED = 1
              AND FUNCTION TRIM(DC-VS-COMMAND-NAME) NOT = "SPEAKING"
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           INITIALIZE WS-SPEAKING-PAYLOAD
           MOVE DC-MUSIC-SPEAKING-FLAG TO WS-SPEAKING-FLAG
           MOVE 0 TO WS-SPEAKING-DELAY
           MOVE DC-VS-SSRC TO WS-SPEAKING-SSRC
           MOVE SPACES TO WS-SPEAKING-JSON
           CALL "DC-SPEAKING-BUILD"
               USING WS-SPEAKING-PAYLOAD
                     WS-SPEAKING-JSON
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-VS-COMMAND-QUEUED = 1
              AND FUNCTION TRIM(DC-VS-COMMAND-NAME) = "SPEAKING"
               MOVE WS-SPEAKING-ACTION TO DC-VS-COMMAND-NAME
               MOVE WS-SPEAKING-JSON TO DC-VS-COMMAND-PAYLOAD
           ELSE
               CALL "DC-VOICE-QUEUE-PAYLOAD"
                   USING DC-VOICE-SESSION
                         WS-SPEAKING-ACTION
                         WS-SPEAKING-JSON
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-VOICE-SESSION-SAVE"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-VOICE-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-SPEAKING-STORED.
