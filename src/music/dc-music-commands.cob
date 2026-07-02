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
       PROGRAM-ID. DC-MUSIC-COMMANDS-BUILD-SET.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-MUSIC-COMMANDS-JSON PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-MUSIC-COMMANDS-JSON DC-RESULT.
       MAIN.
           *> JP: 一括 overwrite 用の完全な command set JSON を組み立てます。
           *> JP: contributor が command surface 全体を見渡すときの正本でもあります。
           *> EN: This builds the full command-set JSON used for bulk overwrite.
           *> EN: It also serves as the single place to inspect the whole command surface.
           MOVE SPACES TO DC-MUSIC-COMMANDS-JSON
           STRING
               "[" DELIMITED BY SIZE
               '{"name":"join","type":1,' DELIMITED BY SIZE
               '"description":"Join your current voice channel"},'
                   DELIMITED BY SIZE
               '{"name":"leave","type":1,' DELIMITED BY SIZE
               '"description":"Leave the current voice channel"},'
                   DELIMITED BY SIZE
               '{"name":"play","type":1,' DELIMITED BY SIZE
               '"description":"Queue a local Ogg Opus file for playback",'
                   DELIMITED BY SIZE
               '"options":[{"name":"file","type":3,' DELIMITED BY SIZE
               '"description":"Path to a local .ogg or .opus file",'
                   DELIMITED BY SIZE
               '"required":true}]},' DELIMITED BY SIZE
               '{"name":"skip","type":1,' DELIMITED BY SIZE
               '"description":"Skip the current track"},'
                   DELIMITED BY SIZE
               '{"name":"stop","type":1,' DELIMITED BY SIZE
               '"description":"Stop playback"},'
                   DELIMITED BY SIZE
               '{"name":"queue","type":1,' DELIMITED BY SIZE
               '"description":"Show queued tracks"}'
                   DELIMITED BY SIZE
               "]" DELIMITED BY SIZE
               INTO DC-MUSIC-COMMANDS-JSON
           END-STRING

           CALL "DC-RESULT-OK" USING DC-RESULT
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
           PERFORM REGISTER-STOP
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           PERFORM REGISTER-QUEUE
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
