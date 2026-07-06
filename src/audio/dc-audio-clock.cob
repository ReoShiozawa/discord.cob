       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-CLOCK-WAIT.
       *> JP: audio frame の pacing に使う待機 helper をまとめたファイルです。
       *> JP: 送信 tick が音声フレーム長から大きくずれないよう時間差を吸収します。
       *> EN: Collects wait helpers used for audio-frame pacing.
       *> EN: These helpers absorb timing drift so send ticks stay close to the intended frame duration.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-SLEEP-US PIC 9(18) COMP-5.
       01 WS-SLEEP-STATUS PIC S9(9) COMP-5.
       LINKAGE SECTION.
       01 DC-AUDIO-WAIT-MS PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AUDIO-WAIT-MS DC-RESULT.
       MAIN.
           IF DC-AUDIO-WAIT-MS <= 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

      *> JP: 現状の wait helper は OS の usleep に委譲し、短い tick 間隔の実験をしやすくします。
      *> EN: The current wait helper delegates to the OS usleep call so short
      *> EN: tick intervals are easy to experiment with.
           COMPUTE WS-SLEEP-US = DC-AUDIO-WAIT-MS * 1000
           CALL STATIC "usleep"
               USING BY VALUE WS-SLEEP-US
               RETURNING WS-SLEEP-STATUS
           END-CALL
           IF WS-SLEEP-STATUS NOT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CLOCK" TO DC-ERROR-CODE
               MOVE "Audio wait helper failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-CLOCK-WAIT.
