       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-JOIN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: join command は interaction 文脈の必須値を検証してから、
           *> JP: 実際の voice join を domain helper へ委譲する薄い adapter です。
           *> EN: The join command is a thin adapter: it validates the required
           *> EN: interaction context and then delegates the actual voice join.
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
           *> JP: leave も guild 文脈だけ確認し、disconnect 手順自体は voice 層に任せます。
           *> EN: Leave only checks guild context here; the disconnect procedure
           *> EN: itself belongs to the voice layer.
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
       01 WS-INDEX-OPTION PIC X(64) VALUE "index".
       01 WS-INDEX-TEXT PIC X(512).
       01 WS-INDEX-VALUE PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: play command は guild/channel の存在確認に加え、
           *> JP: slash option "file" を引いて domain API へ渡します。
           *> EN: The play command validates guild/channel presence, resolves the
           *> EN: slash option named "file", and passes it to the domain API.
           *>
           *> JP: ここでは path 正規化や audio 読み込みを行わず、command handler を
           *> JP: interaction glue として薄く保ちます。
           *> EN: It intentionally avoids path normalization or audio loading so
           *> EN: the command handler remains a thin interaction-glue layer.
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
           *> JP: skip は現在再生中トラックの進行を 1 つ進める command で、
           *> JP: queue 操作の本体は music state 側にあります。
           *> EN: Skip advances the current playback flow by one track; the actual
           *> EN: queue mutation lives in the music-state layer.
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
       PROGRAM-ID. DC-MUSIC-CMD-PAUSE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: pause は guild 文脈の確認だけを行い、状態遷移は domain に委譲します。
           *> EN: Pause validates guild context here and delegates the actual
           *> EN: state transition to the music-domain API.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-PAUSE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-PAUSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-RESUME.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: resume も guild 文脈の確認のみ行い、条件判定は domain 側に任せます。
           *> EN: Resume likewise only checks guild context here and leaves
           *> EN: resume eligibility to the domain layer.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-RESUME"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-RESUME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-STOP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: stop は queue/playback cleanup を domain 側に委譲し、
           *> JP: interaction handler 側では guild 文脈の確認だけに留めます。
           *> EN: Stop delegates queue/playback cleanup to the domain layer and
           *> EN: keeps the interaction-side work limited to guild validation.
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
           *> JP: queue command は表示文をここで作らず、まず queue snapshot を取得する役目です。
           *> EN: The queue command does not format a display message here; it is
           *> EN: responsible first for fetching a queue snapshot.
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

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-REMOVE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       01 WS-INDEX-OPTION PIC X(64) VALUE "index".
       01 WS-INDEX-TEXT PIC X(512).
       01 WS-INDEX-VALUE PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: remove は slash option "index" を数値として解釈し、pending queue から 1 件外します。
           *> EN: remove interprets the slash option "index" as a number and
           *> EN: removes one item from the pending queue.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-INDEX-TEXT
           CALL "DC-INTERACTION-GET-OPTION"
               USING DC-INTERACTION
                     WS-INDEX-OPTION
                     WS-INDEX-TEXT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-INDEX-TEXT))
               TO WS-INDEX-VALUE
           IF WS-INDEX-VALUE <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_QUEUE_INDEX" TO DC-ERROR-CODE
               MOVE "Interaction queue index must be a positive number."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-TRACK
           CALL "DC-MUSIC-REMOVE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-INDEX-VALUE
                     DC-MUSIC-TRACK
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-REMOVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-CLEARQUEUE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: clearqueue は guild 文脈を確認し、pending queue のみを空にします。
           *> EN: clearqueue validates guild context and clears only the pending queue.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-MUSIC-CLEARQUEUE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-CLEARQUEUE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CMD-NOWPLAYING.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
           *> JP: nowplaying は guild 文脈を検証し、再生状態の問い合わせ経路を通します。
           *> JP: user-facing な文面は interaction fallback reply 側で整形します。
           *> EN: nowplaying validates guild context and exercises the playback-state
           *> EN: query path, while user-facing wording is built in the interaction reply layer.
           IF FUNCTION TRIM(DC-GUILD-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Interaction guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-TRACK
           CALL "DC-MUSIC-NOWPLAYING"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-MUSIC-TRACK
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CMD-NOWPLAYING.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-CONTROLS-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-COMPONENTS-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-COMPONENTS-JSON DC-RESULT.
       MAIN.
      *> JP: nowplaying 用の最小コントロール列を 1 箇所で固定します。
      *> EN: Keep the default now-playing control row in one place.
           MOVE SPACES TO DC-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Skip",'
                   DELIMITED BY SIZE
               '"custom_id":"music:skip"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Pause",'
                   DELIMITED BY SIZE
               '"custom_id":"music:pause"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Resume",'
                   DELIMITED BY SIZE
               '"custom_id":"music:resume"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Queue",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO DC-COMPONENTS-JSON
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-CONTROLS-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QCTRLS-ON.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-COMPONENTS-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-COMPONENTS-JSON DC-RESULT.
       MAIN.
      *> JP: queue が空でないときの queue panel controls です。
      *> EN: Queue-panel controls used when at least one queued item exists.
           MOVE SPACES TO DC-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Remove First",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:rm1"},' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Clear",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:clear"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Now Playing",'
                   DELIMITED BY SIZE
               '"custom_id":"music:np:view"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Refresh",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO DC-COMPONENTS-JSON
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QCTRLS-ON.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QCTRLS-OFF.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-COMPONENTS-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-COMPONENTS-JSON DC-RESULT.
       MAIN.
      *> JP: queue が空でも panel から nowplaying / refresh へ戻れるようにします。
      *> EN: Even with an empty queue, keep navigation back to now-playing and refresh available.
           MOVE SPACES TO DC-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Remove First",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:rm1","disabled":true},'
                   DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Clear",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:clear","disabled":true},'
                   DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Now Playing",'
                   DELIMITED BY SIZE
               '"custom_id":"music:np:view"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Refresh",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO DC-COMPONENTS-JSON
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QCTRLS-OFF.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-NOWPLAYING-PANEL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-CONTROLS-JSON PIC X(4096).
       01 WS-TRACK-TEXT PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GUILD-ID-IN PIC X(32).
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-PANEL-COMPONENTS-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-GUILD-ID-IN
           DC-PANEL-TEXT
           DC-PANEL-COMPONENTS-JSON
           DC-RESULT.
       MAIN.
      *> JP: nowplaying 向けの表示文とボタン列を、音楽 state からまとめて導出します。
      *> EN: Derive the now-playing text and optional controls from the current music state.
           MOVE SPACES TO DC-PANEL-TEXT
           MOVE SPACES TO DC-PANEL-COMPONENTS-JSON
           IF FUNCTION TRIM(DC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-TRACK
           CALL "DC-MUSIC-NOWPLAYING"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     DC-MUSIC-TRACK
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-TRACK-STATUS = 1
               MOVE SPACES TO WS-PANEL-TEXT
               CALL "DC-NOWPLAYING-FORMAT"
                   USING DC-MUSIC-TRACK
                         WS-PANEL-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               MOVE SPACES TO WS-CONTROLS-JSON
               CALL "DC-MUSIC-CONTROLS-BUILD"
                   USING WS-CONTROLS-JSON
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               MOVE WS-PANEL-TEXT TO DC-PANEL-TEXT
               MOVE WS-CONTROLS-JSON TO DC-PANEL-COMPONENTS-JSON
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     DC-MUSIC-QUEUE
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
              AND DC-MQ-SIZE > 0
               INITIALIZE DC-MUSIC-TRACK
               MOVE DC-MQ-TRACK-ID(DC-MQ-HEAD) TO DC-TRACK-ID
               MOVE DC-MQ-TITLE(DC-MQ-HEAD) TO DC-TRACK-TITLE
               MOVE DC-MQ-SOURCE(DC-MQ-HEAD) TO DC-TRACK-SOURCE
               MOVE DC-MQ-REQUESTER-ID(DC-MQ-HEAD)
                   TO DC-TRACK-REQUESTER-ID
               MOVE DC-MQ-STATUS(DC-MQ-HEAD) TO DC-TRACK-STATUS

               MOVE SPACES TO WS-TRACK-TEXT
               CALL "DC-TRACK-FORMAT"
                   USING DC-MUSIC-TRACK
                         WS-TRACK-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF

               STRING
                   "Up next: " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-TRACK-TEXT) DELIMITED BY SIZE
                   INTO DC-PANEL-TEXT
               END-STRING
           ELSE
               MOVE "Nothing is playing right now."
                   TO DC-PANEL-TEXT
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-NOWPLAYING-PANEL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-PANEL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       01 WS-NOWPLAYING-TEXT PIC X(2000).
       01 WS-QUEUE-TEXT PIC X(2000).
       01 WS-CURRENT-TRACK.
          05 WS-TRACK-ID PIC X(64).
          05 WS-TRACK-TITLE PIC X(128).
          05 WS-TRACK-SOURCE PIC X(512).
          05 WS-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-TRACK-REQUESTER-ID PIC X(32).
          05 WS-TRACK-STATUS PIC 9.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GUILD-ID-IN PIC X(32).
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-PANEL-COMPONENTS-JSON PIC X(4096).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-GUILD-ID-IN
           DC-PANEL-TEXT
           DC-PANEL-COMPONENTS-JSON
           DC-RESULT.
       MAIN.
      *> JP: queue panel は current track と pending queue をまとめて見せる簡易 dashboard です。
      *> EN: The queue panel is a compact dashboard that combines the current track and pending queue.
           MOVE SPACES TO DC-PANEL-TEXT
           MOVE SPACES TO DC-PANEL-COMPONENTS-JSON
           IF FUNCTION TRIM(DC-GUILD-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Music guild id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     DC-MUSIC-QUEUE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               IF DC-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
                   GOBACK
               END-IF
               INITIALIZE DC-MUSIC-QUEUE
           END-IF

           INITIALIZE WS-CURRENT-TRACK
           CALL "DC-MUSIC-NOWPLAYING"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     WS-CURRENT-TRACK
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-QUEUE-TEXT
           CALL "DC-QUEUE-FORMAT"
               USING DC-MUSIC-QUEUE
                     WS-QUEUE-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-TRACK-STATUS = 1
               MOVE SPACES TO WS-NOWPLAYING-TEXT
               CALL "DC-NOWPLAYING-FORMAT"
                   USING WS-CURRENT-TRACK
                         WS-NOWPLAYING-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
               STRING
                   FUNCTION TRIM(WS-NOWPLAYING-TEXT) DELIMITED BY SIZE
                   " | " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-QUEUE-TEXT) DELIMITED BY SIZE
                   INTO DC-PANEL-TEXT
               END-STRING
           ELSE
               MOVE WS-QUEUE-TEXT TO DC-PANEL-TEXT
           END-IF

           IF DC-MQ-SIZE > 0
               CALL "DC-MUSIC-QCTRLS-ON"
                   USING DC-PANEL-COMPONENTS-JSON
                         DC-RESULT
           ELSE
               CALL "DC-MUSIC-QCTRLS-OFF"
                   USING DC-PANEL-COMPONENTS-JSON
                         DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-PANEL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-NP-REPLY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE PIC X(128) VALUE "Now Playing".
       01 WS-COLOR PIC 9(10) COMP-5 VALUE 5814783.
       LINKAGE SECTION.
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PANEL-TEXT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               CALL "DC-IA-BUILD-EMBED"
                   USING WS-TITLE
                         DC-PANEL-TEXT
                         WS-COLOR
                         DC-REPLY-PAYLOAD
                         DC-RESULT
           ELSE
               CALL "DC-IA-BUILD-ECOMP"
                   USING WS-TITLE
                         DC-PANEL-TEXT
                         WS-COLOR
                         DC-COMPONENTS-JSON
                         DC-REPLY-PAYLOAD
                         DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-NP-REPLY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-NP-UPDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE PIC X(128) VALUE "Now Playing".
       01 WS-COLOR PIC 9(10) COMP-5 VALUE 5814783.
       LINKAGE SECTION.
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PANEL-TEXT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-COMPONENTS-JSON) = SPACES
               CALL "DC-IA-BUILD-UEMB"
                   USING WS-TITLE
                         DC-PANEL-TEXT
                         WS-COLOR
                         DC-REPLY-PAYLOAD
                         DC-RESULT
           ELSE
               CALL "DC-IA-BUILD-UECMP"
                   USING WS-TITLE
                         DC-PANEL-TEXT
                         WS-COLOR
                         DC-COMPONENTS-JSON
                         DC-REPLY-PAYLOAD
                         DC-RESULT
           END-IF
           GOBACK.
       END PROGRAM DC-MUSIC-NP-UPDATE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-Q-REPLY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE PIC X(128) VALUE "Queue".
       01 WS-COLOR PIC 9(10) COMP-5 VALUE 3447003.
       LINKAGE SECTION.
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PANEL-TEXT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-IA-BUILD-ECOMP"
               USING WS-TITLE
                     DC-PANEL-TEXT
                     WS-COLOR
                     DC-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-Q-REPLY.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-Q-UPDATE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TITLE PIC X(128) VALUE "Queue".
       01 WS-COLOR PIC 9(10) COMP-5 VALUE 3447003.
       LINKAGE SECTION.
       01 DC-PANEL-TEXT PIC X(2000).
       01 DC-COMPONENTS-JSON PIC X(4096).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PANEL-TEXT
           DC-COMPONENTS-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-IA-BUILD-UECMP"
               USING WS-TITLE
                     DC-PANEL-TEXT
                     WS-COLOR
                     DC-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-Q-UPDATE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-NOWPLAYING.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: /nowplaying だけは text だけでなくボタン列も返す custom handler で上書きします。
      *> EN: Override /nowplaying with a custom handler that can attach controls.
           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-NOWPLAYING-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-NP-REPLY"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-NOWPLAYING.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-QUEUE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: /queue は panel reply へ差し替え、続きの queue 操作へそのまま接続します。
      *> EN: Override /queue with a panel reply that connects directly into follow-up queue actions.
           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-QUEUE-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-Q-REPLY"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-QUEUE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-SKIP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: ボタン操作でも slash command と同じ domain API を通し、最後に panel を再描画します。
      *> EN: Button interactions reuse the same music-domain APIs, then rebuild the panel.
           CALL "DC-MUSIC-SKIP"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-NOWPLAYING-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-NP-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-SKIP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-PAUSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-MUSIC-PAUSE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-NOWPLAYING-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-NP-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-PAUSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-RESUME.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-MUSIC-RESUME"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-NOWPLAYING-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-NP-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-RESUME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-QVIEW.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-QUEUE-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-Q-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-QVIEW.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-QRM1.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-music.cpy".
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
      *> JP: queue の先頭削除は position=1 の remove API に寄せ、panel を再描画します。
      *> EN: Removing the queue head delegates to the generic remove API with position 1.
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-MUSIC-QUEUE
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
              AND DC-MQ-SIZE > 0
               INITIALIZE DC-MUSIC-TRACK
               CALL "DC-MUSIC-REMOVE"
                   USING DC-CLIENT
                         DC-GUILD-ID
                         1
                         DC-MUSIC-TRACK
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-QUEUE-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-Q-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-QRM1.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-QCLR.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-MUSIC-CLEARQUEUE"
               USING DC-CLIENT
                     DC-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-QUEUE-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-Q-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-QCLR.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-IA-NPVIEW.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PANEL-TEXT PIC X(2000).
       01 WS-COMPONENTS-JSON PIC X(4096).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-PANEL-TEXT
           MOVE SPACES TO WS-COMPONENTS-JSON
           CALL "DC-MUSIC-NOWPLAYING-PANEL"
               USING DC-CLIENT
                     DC-GUILD-ID
                     WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-NP-UPDATE"
               USING WS-PANEL-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-IA-NPVIEW.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-INTERACTIONS-REGISTER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-QUEUE-COMMAND PIC X(128) VALUE "/queue".
       01 WS-QUEUE-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-QUEUE".
       01 WS-NOWPLAYING-COMMAND PIC X(128) VALUE "/nowplaying".
       01 WS-NOWPLAYING-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-NOWPLAYING".
       01 WS-SKIP-ID PIC X(128) VALUE "music:skip".
       01 WS-SKIP-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-SKIP".
       01 WS-PAUSE-ID PIC X(128) VALUE "music:pause".
       01 WS-PAUSE-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-PAUSE".
       01 WS-RESUME-ID PIC X(128) VALUE "music:resume".
       01 WS-RESUME-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-RESUME".
       01 WS-QVIEW-ID PIC X(128) VALUE "music:queue:view".
       01 WS-QVIEW-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-QVIEW".
       01 WS-QRM1-ID PIC X(128) VALUE "music:queue:rm1".
       01 WS-QRM1-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-QRM1".
       01 WS-QCLR-ID PIC X(128) VALUE "music:queue:clear".
       01 WS-QCLR-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-QCLR".
       01 WS-NPVIEW-ID PIC X(128) VALUE "music:np:view".
       01 WS-NPVIEW-PROGRAM PIC X(64) VALUE "DC-MUSIC-IA-NPVIEW".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
      *> JP: built-in slash command surfaceに、より扱いやすい custom interaction UX を重ねます。
      *> EN: Layer a richer custom interaction UX on top of the built-in music commands.
           CALL "DC-INTERACTION-ON-COMMAND"
               USING DC-CLIENT
                     WS-QUEUE-COMMAND
                     WS-QUEUE-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMMAND"
               USING DC-CLIENT
                     WS-NOWPLAYING-COMMAND
                     WS-NOWPLAYING-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-SKIP-ID
                     WS-SKIP-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-PAUSE-ID
                     WS-PAUSE-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-RESUME-ID
                     WS-RESUME-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-QVIEW-ID
                     WS-QVIEW-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-QRM1-ID
                     WS-QRM1-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-QCLR-ID
                     WS-QCLR-PROGRAM
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-NPVIEW-ID
                     WS-NPVIEW-PROGRAM
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-INTERACTIONS-REGISTER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-COMMANDS-SCHEMA.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-CMD-NAME PIC X(32).
       01 WS-CMD-DESC PIC X(100).
       01 WS-OPT-NAME PIC X(32).
       01 WS-OPT-TYPE PIC 9(4) COMP-5.
       01 WS-OPT-DESC PIC X(100).
       01 WS-OPT-REQUIRED PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-command-schema.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-COMMAND-SCHEMA DC-RESULT.
       MAIN.
           *> JP: 組み込み music command 群を構造化 schema として宣言します。
           *> JP: contributor が command surface 全体を見渡すときの正本であり、
           *> JP: 高水準 schema API (dc-command-schema.cob) の利用例でもあります。
           *> EN: Declare the built-in music command set as a structured schema.
           *> EN: This is the single place to inspect the whole command surface,
           *> EN: and it doubles as the reference usage of the high-level schema
           *> EN: API in dc-command-schema.cob.
           CALL "DC-COMMAND-SCHEMA-INIT"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           PERFORM DECLARE-JOIN
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-LEAVE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-PLAY
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-SKIP
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-PAUSE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-RESUME
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-STOP
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-QUEUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-REMOVE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-CLEARQUEUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM DECLARE-NOWPLAYING
           GOBACK.

       DECLARE-JOIN.
           MOVE "join" TO WS-CMD-NAME
           MOVE "Join your current voice channel" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-LEAVE.
           MOVE "leave" TO WS-CMD-NAME
           MOVE "Leave the current voice channel" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-PLAY.
           MOVE "play" TO WS-CMD-NAME
           MOVE "Queue a local Ogg Opus file for playback"
               TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "file" TO WS-OPT-NAME
           MOVE 3 TO WS-OPT-TYPE
           MOVE "Path to a local .ogg or .opus file" TO WS-OPT-DESC
           MOVE 1 TO WS-OPT-REQUIRED
           PERFORM DECLARE-OPTION.

       DECLARE-SKIP.
           MOVE "skip" TO WS-CMD-NAME
           MOVE "Skip the current track" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-PAUSE.
           MOVE "pause" TO WS-CMD-NAME
           MOVE "Pause the current track" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-RESUME.
           MOVE "resume" TO WS-CMD-NAME
           MOVE "Resume the paused track" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-STOP.
           MOVE "stop" TO WS-CMD-NAME
           MOVE "Stop playback" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-QUEUE.
           MOVE "queue" TO WS-CMD-NAME
           MOVE "Show queued tracks" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-REMOVE.
           MOVE "remove" TO WS-CMD-NAME
           MOVE "Remove a queued track by position" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "index" TO WS-OPT-NAME
           MOVE 4 TO WS-OPT-TYPE
           MOVE "1-based queue position" TO WS-OPT-DESC
           MOVE 1 TO WS-OPT-REQUIRED
           PERFORM DECLARE-OPTION.

       DECLARE-CLEARQUEUE.
           MOVE "clearqueue" TO WS-CMD-NAME
           MOVE "Clear all queued tracks" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-NOWPLAYING.
           MOVE "nowplaying" TO WS-CMD-NAME
           MOVE "Show the current track" TO WS-CMD-DESC
           PERFORM DECLARE-COMMAND.

       DECLARE-COMMAND.
           CALL "DC-COMMAND-SCHEMA-ADD"
               USING DC-COMMAND-SCHEMA
                     WS-CMD-NAME
                     WS-CMD-DESC
                     DC-RESULT.

       DECLARE-OPTION.
           CALL "DC-COMMAND-SCHEMA-ADD-OPTION"
               USING DC-COMMAND-SCHEMA
                     WS-OPT-NAME
                     WS-OPT-TYPE
                     WS-OPT-DESC
                     WS-OPT-REQUIRED
                     DC-RESULT.
       END PROGRAM DC-MUSIC-COMMANDS-SCHEMA.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-COMMANDS-BUILD-SET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-command-schema.cpy".

       LINKAGE SECTION.
       01 DC-MUSIC-COMMANDS-JSON PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-MUSIC-COMMANDS-JSON DC-RESULT.
       MAIN.
           *> JP: 一括 overwrite 用の完全な command set JSON を組み立てます。
           *> JP: JSON の手組みはやめ、schema 宣言と共通変換 helper を経由します。
           *> EN: This builds the full command-set JSON used for bulk overwrite.
           *> EN: Instead of hand-written JSON, it goes through the schema
           *> EN: declaration and the shared conversion helper.
           MOVE SPACES TO DC-MUSIC-COMMANDS-JSON

           CALL "DC-MUSIC-COMMANDS-SCHEMA"
               USING DC-COMMAND-SCHEMA
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-COMMAND-SCHEMA-TO-JSON"
               USING DC-COMMAND-SCHEMA
                     DC-MUSIC-COMMANDS-JSON
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-COMMANDS-BUILD-SET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-COMMANDS-REGISTER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMAND-JSON PIC X(8192).
       01 WS-HTTP-RESPONSE.
          05 WS-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 WS-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 WS-HTTP-RAW-HEADERS PIC X(4096).
          05 WS-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 WS-HTTP-RESPONSE-BODY PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-GUILD-ID-IN DC-RESULT.
       MAIN.
           *> JP: register 版は Discord へ 1 command ずつ POST します。
           *> JP: 途中失敗した command が分かりやすい反面、全体の同期は overwrite より弱いです。
           *> EN: The register variant POSTs commands one by one. That makes it
           *> EN: easier to pinpoint a failing command, though it is less atomic
           *> EN: than a full overwrite.
           PERFORM REGISTER-JOIN
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-LEAVE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-PLAY
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-SKIP
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-PAUSE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-RESUME
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-STOP
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-QUEUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-REMOVE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-CLEARQUEUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-NOWPLAYING
           GOBACK.

       REGISTER-JOIN.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"join","type":1,' DELIMITED BY SIZE
               '"description":"Join your current voice channel"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-LEAVE.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"leave","type":1,' DELIMITED BY SIZE
               '"description":"Leave the current voice channel"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-PLAY.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"play","type":1,' DELIMITED BY SIZE
               '"description":"Queue a local Ogg Opus file for playback",'
                   DELIMITED BY SIZE
               '"options":[{"name":"file","type":3,' DELIMITED BY SIZE
               '"description":"Path to a local .ogg or .opus file",'
                   DELIMITED BY SIZE
               '"required":true}]}' DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-SKIP.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"skip","type":1,' DELIMITED BY SIZE
               '"description":"Skip the current track"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-PAUSE.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"pause","type":1,' DELIMITED BY SIZE
               '"description":"Pause the current track"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-RESUME.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"resume","type":1,' DELIMITED BY SIZE
               '"description":"Resume the paused track"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-STOP.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"stop","type":1,' DELIMITED BY SIZE
               '"description":"Stop playback"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-QUEUE.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"queue","type":1,' DELIMITED BY SIZE
               '"description":"Show queued tracks"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-REMOVE.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"remove","type":1,' DELIMITED BY SIZE
               '"description":"Remove a queued track by position",'
                   DELIMITED BY SIZE
               '"options":[{"name":"index","type":4,' DELIMITED BY SIZE
               '"description":"1-based queue position",'
                   DELIMITED BY SIZE
               '"required":true}]}' DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-CLEARQUEUE.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"clearqueue","type":1,' DELIMITED BY SIZE
               '"description":"Clear all queued tracks"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-NOWPLAYING.
           MOVE SPACES TO WS-COMMAND-JSON
           STRING
               '{"name":"nowplaying","type":1,' DELIMITED BY SIZE
               '"description":"Show the current track"}'
                   DELIMITED BY SIZE
               INTO WS-COMMAND-JSON
           END-STRING
           PERFORM REGISTER-COMMAND.

       REGISTER-COMMAND.
           *> JP: 個々の JSON 断片はここで共通登録 helper に流します。
           *> EN: Each per-command JSON snippet funnels through the shared
           *> EN: registration helper here.
           INITIALIZE WS-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-REGISTER"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     WS-COMMAND-JSON
                     WS-HTTP-RESPONSE
                     DC-RESULT.
       END PROGRAM DC-MUSIC-COMMANDS-REGISTER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-COMMANDS-OVERWRITE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMMANDS-JSON PIC X(8192).
       01 WS-HTTP-RESPONSE.
          05 WS-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 WS-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 WS-HTTP-RAW-HEADERS PIC X(4096).
          05 WS-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 WS-HTTP-RESPONSE-BODY PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-GUILD-ID-IN DC-RESULT.
       MAIN.
           *> JP: overwrite 版は現在の command 集合を丸ごと置き換えます。
           *> JP: 開発中の「定義を完全同期したい」ケースではこちらが主経路です。
           *> EN: The overwrite variant replaces the current command set as a whole.
           *> EN: It is the main path when development wants a fully synchronized definition.
           MOVE SPACES TO WS-COMMANDS-JSON
           CALL "DC-MUSIC-COMMANDS-BUILD-SET"
               USING WS-COMMANDS-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE WS-HTTP-RESPONSE
           CALL "DC-SLASH-COMMAND-OVERWRITE"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     WS-COMMANDS-JSON
                     WS-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-COMMANDS-OVERWRITE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-BOT-BOOTSTRAP.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-GUILD-ID-IN DC-RESULT.
       MAIN.
      *> JP: music bot の既定 wiring と slash command 同期を 1 回で済ませる helper です。
      *> EN: One-shot helper that performs the default music-bot wiring and
      *> EN: slash-command synchronization together.
           CALL "DC-BOT-REGISTER-DEFAULTS"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-INTERACTIONS-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-MUSIC-COMMANDS-OVERWRITE"
               USING DC-CLIENT
                     DC-GUILD-ID-IN
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-BOT-BOOTSTRAP.
