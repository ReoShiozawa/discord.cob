       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-PLAY-OPUS-FILE.
       *> JP: local Ogg Opus ファイルを voice channel へ流す最短経路の example です。
       *> JP: 既定 handler 登録 -> login -> music play -> bot loop をそのまま並べます。
       *> EN: Example that takes the shortest current path for streaming a
       *> EN: local Ogg Opus file into a voice channel.
       *> EN: It wires default handlers, logs in, queues one track, and then
       *> EN: keeps the bot loop advancing.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32).
       01 WS-VOICE-CHANNEL-ID PIC X(32).
       01 WS-AUDIO-SOURCE PIC X(512).
       01 WS-STEP-COUNT PIC S9(9) COMP-5 VALUE 0.
       01 WS-STEP-COUNT-TEXT PIC X(32).
       01 WS-STOP-FILE PIC X(512).
       01 WS-WAIT-MS PIC 9(10) COMP-5 VALUE 20.
       01 WS-IDLE-LEAVE-TICKS PIC 9(9) COMP-5 VALUE 1200.
       01 WS-IDLE-LEAVE-TEXT PIC X(32).

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           ACCEPT DC-BOT-TOKEN FROM ENVIRONMENT "DISCORD_TOKEN"
           ACCEPT WS-GUILD-ID FROM ENVIRONMENT "DISCORD_GUILD_ID"
           ACCEPT WS-VOICE-CHANNEL-ID
               FROM ENVIRONMENT "DISCORD_VOICE_CHANNEL_ID"
           ACCEPT WS-AUDIO-SOURCE
               FROM ENVIRONMENT "DISCORD_AUDIO_SOURCE"
           ACCEPT WS-STEP-COUNT-TEXT
               FROM ENVIRONMENT "DISCORD_STEP_COUNT"
           ACCEPT WS-STOP-FILE
               FROM ENVIRONMENT "DISCORD_STOP_FILE"
           ACCEPT WS-IDLE-LEAVE-TEXT
               FROM ENVIRONMENT "DISCORD_IDLE_LEAVE_TICKS"
           MOVE 129 TO DC-INTENTS

           IF FUNCTION TRIM(WS-STEP-COUNT-TEXT) NOT = SPACES
               MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-STEP-COUNT-TEXT))
                   TO WS-STEP-COUNT
           END-IF
           IF FUNCTION TRIM(WS-IDLE-LEAVE-TEXT) NOT = SPACES
               MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-IDLE-LEAVE-TEXT))
                   TO WS-IDLE-LEAVE-TICKS
           END-IF
           MOVE WS-IDLE-LEAVE-TICKS TO DC-MUSIC-IDLE-LEAVE-TICKS
           IF FUNCTION TRIM(DC-BOT-TOKEN) = SPACES
              OR FUNCTION TRIM(WS-GUILD-ID) = SPACES
              OR FUNCTION TRIM(WS-VOICE-CHANNEL-ID) = SPACES
              OR FUNCTION TRIM(WS-AUDIO-SOURCE) = SPACES
               DISPLAY "token, guild, voice channel, and audio source are required"
               STOP RUN RETURNING 2
           END-IF
           IF WS-STEP-COUNT <= 0
              AND FUNCTION TRIM(WS-STOP-FILE) = SPACES
               MOVE ".discord-cob.stop" TO WS-STOP-FILE
           END-IF

           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG
                     DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           CALL "DC-BOT-REGISTER-DEFAULTS"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           CALL "DC-LOGIN"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           CALL "DC-MUSIC-PLAY"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-VOICE-CHANNEL-ID
                     WS-AUDIO-SOURCE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           DISPLAY "queued local opus source"
           DISPLAY FUNCTION TRIM(WS-AUDIO-SOURCE)
           IF WS-STEP-COUNT <= 0
               DISPLAY "running ticks: until stop file appears"
               DISPLAY FUNCTION TRIM(WS-STOP-FILE)
           ELSE
               DISPLAY "running ticks: " WS-STEP-COUNT
           END-IF

           IF WS-STEP-COUNT <= 0
               CALL "DC-BOT-RUN-UNTIL-FILE"
                   USING DC-CLIENT
                         WS-STOP-FILE
                         WS-WAIT-MS
                         DC-RESULT
           ELSE
               CALL "DC-BOT-RUN"
                   USING DC-CLIENT
                         WS-STEP-COUNT
                         WS-WAIT-MS
                         DC-RESULT
           END-IF
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           CALL "DC-BOT-SHUTDOWN"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = 0
               PERFORM DISPLAY-ERROR
               STOP RUN
           END-IF

           DISPLAY "done"
           STOP RUN.

       DISPLAY-ERROR.
           DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
           DISPLAY FUNCTION TRIM(DC-ERROR-MESSAGE).
       END PROGRAM EXAMPLE-PLAY-OPUS-FILE.
