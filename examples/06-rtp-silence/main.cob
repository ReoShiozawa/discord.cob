       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-RTP-SILENCE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-RTP-STATE
           MOVE 1 TO DC-RTP-SEQUENCE
           MOVE 960 TO DC-RTP-TIMESTAMP
           MOVE 1234 TO DC-RTP-SSRC
           MOVE 960 TO DC-RTP-FRAME-SAMPLES

           CALL "DC-OPUS-BUILD-SILENCE"
               USING DC-OPUS-FRAME DC-RESULT
           CALL "DC-RTP-BUILD-PACKET"
               USING DC-RTP-STATE
                     DC-OPUS-FRAME
                     DC-RTP-PACKET
                     DC-RESULT

           DISPLAY "rtp packet length: " DC-RTP-PACKET-LENGTH
           STOP RUN.
       END PROGRAM EXAMPLE-RTP-SILENCE.
