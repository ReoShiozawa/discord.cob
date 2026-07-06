       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STATE-LOAD.
       *> JP: guild ごとの music runtime を load/save する state helper です。
       *> JP: queue と player の断面を EXTERNAL ストアから出し入れします。
       *> EN: State helper that loads and saves guild-scoped music runtimes.
       *> EN: It moves queue and player snapshots in and out of the EXTERNAL store.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-music.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-QUEUE
           DC-AUDIO-PLAYER
           DC-MUSIC-TRACK
           DC-RTP-STATE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-QUEUE
           INITIALIZE DC-AUDIO-PLAYER
           INITIALIZE DC-MUSIC-TRACK
           INITIALIZE DC-RTP-STATE
           INITIALIZE DC-OPUS-HANDLE

           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-MUSIC-MAX-RUNTIMES
               IF DC-MR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-MR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN)
                   MOVE DC-MR-QUEUE(WS-IDX) TO DC-MUSIC-QUEUE
                   MOVE DC-MR-PLAYER(WS-IDX) TO DC-AUDIO-PLAYER
                   MOVE DC-MR-CURRENT-TRACK(WS-IDX) TO DC-MUSIC-TRACK
                   MOVE DC-MR-RTP-STATE(WS-IDX) TO DC-RTP-STATE
                   MOVE DC-MR-OPUS-HANDLE(WS-IDX) TO DC-OPUS-HANDLE
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM

           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_STATE_MISSING" TO DC-ERROR-CODE
           MOVE "Music runtime state was not found."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-STATE-LOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STATE-SAVE.
       *> JP: guild ごとの music runtime を load/save する state helper です。
       *> JP: queue と player の断面を EXTERNAL ストアから出し入れします。
       *> EN: State helper that loads and saves guild-scoped music runtimes.
       *> EN: It moves queue and player snapshots in and out of the EXTERNAL store.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FREE-IDX PIC 9(4) COMP-5 VALUE 0.

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-music.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-QUEUE
           DC-AUDIO-PLAYER
           DC-MUSIC-TRACK
           DC-RTP-STATE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           MOVE 0 TO WS-FREE-IDX
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-MUSIC-MAX-RUNTIMES
               IF DC-MR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-MR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN)
                   PERFORM SAVE-ENTRY
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
               IF WS-FREE-IDX = 0
                  AND DC-MR-ENTRY-IN-USE(WS-IDX) NOT = 1
                   MOVE WS-IDX TO WS-FREE-IDX
               END-IF
           END-PERFORM

           IF WS-FREE-IDX = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_POOL_FULL" TO DC-ERROR-CODE
               MOVE "Music runtime table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE WS-FREE-IDX TO WS-IDX
           MOVE 1 TO DC-MR-ENTRY-IN-USE(WS-IDX)
           MOVE DC-MUSIC-GUILD-ID-IN TO DC-MR-ENTRY-GUILD-ID(WS-IDX)
           PERFORM SAVE-ENTRY
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       SAVE-ENTRY.
           MOVE DC-MUSIC-QUEUE TO DC-MR-QUEUE(WS-IDX)
           MOVE DC-AUDIO-PLAYER TO DC-MR-PLAYER(WS-IDX)
           MOVE DC-MUSIC-TRACK TO DC-MR-CURRENT-TRACK(WS-IDX)
           MOVE DC-RTP-STATE TO DC-MR-RTP-STATE(WS-IDX)
           MOVE DC-OPUS-HANDLE TO DC-MR-OPUS-HANDLE(WS-IDX)
           MOVE DC-MUSIC-GUILD-ID-IN TO DC-MR-ENTRY-GUILD-ID(WS-IDX).
       END PROGRAM DC-MUSIC-STATE-SAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STATE-CLEAR.
       *> JP: 保存済みの music runtime を guild 単位で削除します。
       *> JP: stop や teardown 後に、空 snapshot を残さず state を消したい場面で使います。
       *> EN: Clear a stored music runtime by guild.
       *> EN: Use this after stop/teardown when you want to remove the runtime
       *> EN: entirely instead of keeping an empty snapshot around.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
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

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-MUSIC-MAX-RUNTIMES
               IF DC-MR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-MR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN)
                   MOVE 0 TO DC-MR-ENTRY-IN-USE(WS-IDX)
                   MOVE SPACES TO DC-MR-ENTRY-GUILD-ID(WS-IDX)
                   INITIALIZE DC-MR-QUEUE(WS-IDX)
                   INITIALIZE DC-MR-PLAYER(WS-IDX)
                   INITIALIZE DC-MR-CURRENT-TRACK(WS-IDX)
                   INITIALIZE DC-MR-RTP-STATE(WS-IDX)
                   INITIALIZE DC-MR-OPUS-HANDLE(WS-IDX)
                   MOVE 0 TO DC-MR-IDLE-TICK-COUNT(WS-IDX)
                   EXIT PERFORM
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-STATE-CLEAR.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-RUNTIME-SHUTDOWN.
       *> JP: 保存済み music runtime を停止側の観点で片付けます。
       *> JP: 開いている Opus reader を閉じてから guild の runtime state を消します。
       *> EN: Tear down a stored music runtime from a shutdown perspective.
       *> EN: It closes any open Opus reader first and then removes the guild runtime state.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
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
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
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

           IF DC-OPUS-HANDLE-ID > 0
               CALL "DC-OPUS-CLOSE"
                   USING DC-OPUS-HANDLE
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-MUSIC-STATE-CLEAR"
               USING DC-MUSIC-GUILD-ID-IN
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-RUNTIME-SHUTDOWN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IDLE-COUNT-LOAD.
       *> JP: 自動退出判定用の idle tick 数を guild ごとに読み出します。
       *> EN: Load the guild-scoped idle-tick count used by auto-leave logic.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       01 DC-MUSIC-IDLE-TICK-COUNT PIC 9(9) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-IDLE-TICK-COUNT
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-MUSIC-IDLE-TICK-COUNT
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-MUSIC-MAX-RUNTIMES
               IF DC-MR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-MR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN)
                   MOVE DC-MR-IDLE-TICK-COUNT(WS-IDX)
                       TO DC-MUSIC-IDLE-TICK-COUNT
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM

           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_STATE_MISSING" TO DC-ERROR-CODE
           MOVE "Music runtime state was not found."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-IDLE-COUNT-LOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IDLE-COUNT-SAVE.
       *> JP: 自動退出判定用の idle tick 数を guild ごとに保存します。
       *> EN: Save the guild-scoped idle-tick count used by auto-leave logic.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-MUSIC-GUILD-ID-IN PIC X(32).
       01 DC-MUSIC-IDLE-TICK-COUNT PIC 9(9) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-GUILD-ID-IN
           DC-MUSIC-IDLE-TICK-COUNT
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-MUSIC-MAX-RUNTIMES
               IF DC-MR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-MR-ENTRY-GUILD-ID(WS-IDX))
                      = FUNCTION TRIM(DC-MUSIC-GUILD-ID-IN)
                   MOVE DC-MUSIC-IDLE-TICK-COUNT
                       TO DC-MR-IDLE-TICK-COUNT(WS-IDX)
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM

           MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_STATE_MISSING" TO DC-ERROR-CODE
           MOVE "Music runtime state was not found."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-MUSIC-IDLE-COUNT-SAVE.
