       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-STATE-LOAD.

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
