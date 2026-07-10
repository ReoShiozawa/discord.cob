       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-BUILD-SILENCE.
       *> JP: 無音 frame 生成や encode 処理を置く Opus helper 群です。
       *> JP: transport が送れる 1 frame 形へ audio データを寄せる入口になります。
       *> EN: Opus helpers for silence-frame generation and encoding.
       *> EN: They form the entry point that shapes audio data into one transport-ready frame.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-FRAME DC-RESULT.
       MAIN.
           INITIALIZE DC-OPUS-FRAME
           MOVE 3 TO DC-OPUS-LENGTH
           MOVE FUNCTION CHAR(249) TO DC-OPUS-DATA(1:1)
           MOVE FUNCTION CHAR(256) TO DC-OPUS-DATA(2:1)
           MOVE FUNCTION CHAR(255) TO DC-OPUS-DATA(3:1)
           MOVE 20 TO DC-OPUS-DURATION-MS
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-BUILD-SILENCE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OPUS-ENCODE.
       *> JP: 無音 frame 生成や encode 処理を置く Opus helper 群です。
       *> JP: transport が送れる 1 frame 形へ audio データを寄せる入口になります。
       *> EN: Opus helpers for silence-frame generation and encoding.
       *> EN: They form the entry point that shapes audio data into one transport-ready frame.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-FRAME DC-RESULT.
       MAIN.
      *> JP: 旧 API は PCM 入力を持たないため、既存 packet の検証・正規化を行います。
      *> JP: 空 frame は Discord 推奨の 20ms silence packet に変換します。
      *> EN: This legacy API has no PCM input, so it validates and normalizes
      *> EN: an existing Opus packet. An empty frame becomes 20ms silence.
           IF DC-OPUS-LENGTH = 0
               CALL "DC-OPUS-BUILD-SILENCE"
                   USING DC-OPUS-FRAME DC-RESULT
               GOBACK
           END-IF
           IF DC-OPUS-LENGTH < 0 OR DC-OPUS-LENGTH > 4096
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_FRAME" TO DC-ERROR-CODE
               MOVE "Opus frame length must be between 0 and 4096 bytes."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-OPUS-DURATION-MS = 0
               MOVE 20 TO DC-OPUS-DURATION-MS
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-OPUS-ENCODE.
