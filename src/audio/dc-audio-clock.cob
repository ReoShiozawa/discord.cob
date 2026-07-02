       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AUDIO-CLOCK-WAIT.
       *> JP: audio frame の pacing に使う待機 helper をまとめたファイルです。
       *> JP: 送信 tick が音声フレーム長から大きくずれないよう時間差を吸収します。
       *> EN: Collects wait helpers used for audio-frame pacing.
       *> EN: These helpers absorb timing drift so send ticks stay close to the intended frame duration.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-AUDIO-WAIT-MS PIC 9(10) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AUDIO-WAIT-MS DC-RESULT.
       MAIN.
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AUDIO-CLOCK-WAIT.
