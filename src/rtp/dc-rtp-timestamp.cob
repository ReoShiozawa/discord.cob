       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-TIMESTAMP-ADVANCE.
       *> JP: RTP timestamp を frame samples 分だけ進める helper です。
       *> JP: audio clock と transport clock の接点を小さな API に閉じ込めます。
       *> EN: Helper that advances the RTP timestamp by one frame-sample step.
       *> EN: It keeps the contact point between the audio clock and transport clock small and explicit.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-RTP-STATE DC-RESULT.
       MAIN.
           IF DC-RTP-FRAME-SAMPLES = ZERO
               MOVE 960 TO DC-RTP-FRAME-SAMPLES
           END-IF
           ADD DC-RTP-FRAME-SAMPLES TO DC-RTP-TIMESTAMP
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-RTP-TIMESTAMP-ADVANCE.
