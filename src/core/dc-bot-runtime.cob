       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-REGISTER-DEFAULTS.
       *> JP: framework 既定の Gateway event handler 群をまとめて登録します。
       *> JP: voice / interaction の標準配線を bot 起動時に一度で済ませるための helper です。
       *> EN: Register the framework's default Gateway-event handlers together.
       *> EN: This helper wires the standard voice and interaction paths in one
       *> EN: call during bot startup.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           CALL "DC-VOICE-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-BOT-REGISTER-DEFAULTS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-TICK.
       *> JP: bot 全体の 1 tick を高水準でまとめます。
       *> JP: Gateway が開いていれば先にそれを進め、その後に保存済み voice session 群を順に進めます。
       *> EN: High-level single tick for the whole bot.
       *> EN: If the Gateway is open, advance it first, then advance all stored
       *> EN: voice sessions in sequence.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           IF DC-CLIENT-GW-WS-OPEN-FLAG = 1
               CALL "DC-EVENT-LOOP-TICK"
                   USING DC-CLIENT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-VOICE-EVENT-LOOP-TICK-ALL"
               USING DC-CLIENT
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-BOT-TICK.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-RUN-STEPS.
       *> JP: bot tick を決まった回数だけ進める小さな runtime helper です。
       *> JP: examples や最小デーモンで、複雑な自前 loop を書かずに動作確認できます。
       *> EN: Small runtime helper that advances the bot tick a fixed number of times.
       *> EN: It helps examples and minimal daemons run without hand-writing a
       *> EN: more elaborate loop.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(9) COMP-5.
       01 WS-LAST-IDX PIC 9(9) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-BOT-STEP-COUNT PIC 9(9) COMP-5.
       01 DC-BOT-WAIT-MS PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-BOT-STEP-COUNT
           DC-BOT-WAIT-MS
           DC-RESULT.
       MAIN.
           IF DC-BOT-STEP-COUNT <= 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           MOVE DC-BOT-STEP-COUNT TO WS-LAST-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > WS-LAST-IDX
               CALL "DC-BOT-TICK"
                   USING DC-CLIENT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF DC-BOT-WAIT-MS > 0
                  AND WS-IDX < WS-LAST-IDX
                   CALL "DC-AUDIO-CLOCK-WAIT"
                       USING DC-BOT-WAIT-MS
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-BOT-RUN-STEPS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-RUN.
       *> JP: step 数を 0 以下にすると停止されるまで bot loop を回し続けます。
       *> JP: examples では inspect 用の固定回数実行と、常駐寄りの run を同じ API で扱えます。
       *> EN: When the step count is zero or less, keep advancing the bot loop
       *> EN: until the process is stopped. Examples can use the same API for
       *> EN: both bounded inspection runs and daemon-like execution.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(9) COMP-5.
       01 WS-LAST-IDX PIC 9(9) COMP-5.
       01 WS-STOP-FLAG PIC 9 VALUE 0.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-BOT-STEP-COUNT PIC S9(9) COMP-5.
       01 DC-BOT-WAIT-MS PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-BOT-STEP-COUNT
           DC-BOT-WAIT-MS
           DC-RESULT.
       MAIN.
           IF DC-BOT-STEP-COUNT > 0
               MOVE DC-BOT-STEP-COUNT TO WS-LAST-IDX
               PERFORM VARYING WS-IDX FROM 1 BY 1
                   UNTIL WS-IDX > WS-LAST-IDX
                   PERFORM RUN-ONE-TICK
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
                   IF DC-BOT-WAIT-MS > 0
                      AND WS-IDX < WS-LAST-IDX
                       CALL "DC-AUDIO-CLOCK-WAIT"
                           USING DC-BOT-WAIT-MS
                                 DC-RESULT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                   END-IF
               END-PERFORM
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           MOVE 0 TO WS-STOP-FLAG
           PERFORM UNTIL WS-STOP-FLAG = 1
               PERFORM RUN-ONE-TICK
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF DC-BOT-WAIT-MS > 0
                   CALL "DC-AUDIO-CLOCK-WAIT"
                       USING DC-BOT-WAIT-MS
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM.

       RUN-ONE-TICK.
           CALL "DC-BOT-TICK"
               USING DC-CLIENT
                     DC-RESULT.
       END PROGRAM DC-BOT-RUN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-FILE-EXISTS.
       *> JP: 動的 path の存在確認だけを行う小さな helper です。
       *> EN: Small helper that checks only whether a dynamic path exists.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT OPTIONAL DC-CHECK-FILE
               ASSIGN TO DYNAMIC WS-CHECK-PATH
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS DC-CHECK-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD DC-CHECK-FILE.
       01 DC-CHECK-RECORD PIC X(1).

       WORKING-STORAGE SECTION.
       01 WS-CHECK-PATH PIC X(512).
       01 WS-CHECK-PATH-Z PIC X(513).
       01 WS-ACCESS-RC PIC S9(9) COMP-5.
       01 DC-CHECK-STATUS PIC XX.

       LINKAGE SECTION.
       01 DC-CHECK-PATH PIC X(512).
       01 DC-FILE-EXISTS-FLAG PIC 9.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CHECK-PATH
           DC-FILE-EXISTS-FLAG
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-FILE-EXISTS-FLAG
           IF FUNCTION TRIM(DC-CHECK-PATH) = SPACES
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF
           MOVE SPACES TO WS-CHECK-PATH
           MOVE FUNCTION TRIM(DC-CHECK-PATH) TO WS-CHECK-PATH
           MOVE LOW-VALUE TO WS-CHECK-PATH-Z
           STRING FUNCTION TRIM(WS-CHECK-PATH)
                  X"00"
               DELIMITED BY SIZE
               INTO WS-CHECK-PATH-Z
           END-STRING

           CALL STATIC "access"
               USING BY REFERENCE WS-CHECK-PATH-Z
                     BY VALUE 0
               RETURNING WS-ACCESS-RC
           END-CALL
           IF WS-ACCESS-RC = 0
               MOVE 1 TO DC-FILE-EXISTS-FLAG
           ELSE
               MOVE 0 TO DC-FILE-EXISTS-FLAG
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-FILE-EXISTS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-RUN-UNTIL-FILE.
       *> JP: 指定 stop file が現れるまで bot loop を進め続けます。
       *> EN: Keep advancing the bot loop until the given stop file appears.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STOP-FILE-EXISTS PIC 9 VALUE 0.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-BOT-STOP-FILE PIC X(512).
       01 DC-BOT-WAIT-MS PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-BOT-STOP-FILE
           DC-BOT-WAIT-MS
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-BOT-STOP-FILE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_FILE_ACCESS" TO DC-ERROR-CODE
               MOVE "Stop-file path is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-STOP-FILE-EXISTS
           PERFORM UNTIL WS-STOP-FILE-EXISTS = 1
               CALL "DC-FILE-EXISTS"
                   USING DC-BOT-STOP-FILE
                         WS-STOP-FILE-EXISTS
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF WS-STOP-FILE-EXISTS = 1
                   EXIT PERFORM
               END-IF

               CALL "DC-BOT-TICK"
                   USING DC-CLIENT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF

               IF DC-BOT-WAIT-MS > 0
                   CALL "DC-AUDIO-CLOCK-WAIT"
                       USING DC-BOT-WAIT-MS
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-BOT-RUN-UNTIL-FILE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-BOT-SHUTDOWN.
       *> JP: bot が保持している Gateway / Voice / Music runtime をまとめて閉じます。
       *> JP: 常駐 loop の終了後や example の明示的 teardown で使う高水準 helper です。
       *> EN: Tear down the Gateway, Voice, and Music runtimes held by the bot.
       *> EN: This high-level helper is intended for explicit teardown after
       *> EN: long-running loops or examples finish.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice-store.cpy".
       COPY "discord-voice.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-GUILD-ID PIC X(32).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-VOICE-MAX-SESSIONS
               IF DC-VR-ENTRY-IN-USE(WS-IDX) = 1
                  AND FUNCTION TRIM(DC-VR-ENTRY-GUILD-ID(WS-IDX))
                      NOT = SPACES
                   MOVE DC-VR-ENTRY-GUILD-ID(WS-IDX) TO WS-GUILD-ID
                   PERFORM SHUTDOWN-STORED-VOICE
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           IF DC-CLIENT-GW-WS-OPEN-FLAG = 1
              OR DC-CLIENT-STATE > 0
               CALL "DC-CLIENT-DISCONNECT"
                   USING DC-CLIENT
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       SHUTDOWN-STORED-VOICE.
           CALL "DC-MUSIC-RUNTIME-SHUTDOWN"
               USING WS-GUILD-ID
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           CALL "DC-VOICE-SESSION-LOAD"
               USING WS-GUILD-ID
                     DC-VOICE-SESSION
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               CALL "DC-VOICE-DISCONNECT"
                   USING DC-VOICE-SESSION
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   EXIT PARAGRAPH
               END-IF
           ELSE
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-NOT-FOUND
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   EXIT PARAGRAPH
               END-IF
           END-IF

           CALL "DC-VOICE-SESSION-CLEAR"
               USING WS-GUILD-ID
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT.
       END PROGRAM DC-BOT-SHUTDOWN.
