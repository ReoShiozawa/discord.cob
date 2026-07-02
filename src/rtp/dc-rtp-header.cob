       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-RTP-BUILD-HEADER.
       *> JP: RTP header を組み立てる helper です。
       *> JP: sequence、timestamp、ssrc を wire bytes へ落とす責務を単独化しています。
       *> EN: Helper that builds RTP headers.
       *> EN: It isolates the step that turns sequence, timestamp, and SSRC into wire bytes.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-B1 PIC 9(10) COMP-5.
       01 WS-B2 PIC 9(10) COMP-5.
       01 WS-B3 PIC 9(10) COMP-5.
       01 WS-B4 PIC 9(10) COMP-5.

       LINKAGE SECTION.
       COPY "discord-rtp.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-RTP-STATE
           DC-RTP-HEADER
           DC-RESULT.
       MAIN.
           MOVE X"80" TO DC-RTP-BYTE-0
           MOVE X"78" TO DC-RTP-BYTE-1

           PERFORM STORE-SEQUENCE
           PERFORM STORE-TIMESTAMP
           PERFORM STORE-SSRC

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       STORE-SEQUENCE.
           COMPUTE WS-B1 = FUNCTION INTEGER(DC-RTP-SEQUENCE / 256)
           COMPUTE WS-B2 = DC-RTP-SEQUENCE - (WS-B1 * 256)
           MOVE FUNCTION CHAR(WS-B1 + 1)
               TO DC-RTP-SEQUENCE-BYTES(1:1)
           MOVE FUNCTION CHAR(WS-B2 + 1)
               TO DC-RTP-SEQUENCE-BYTES(2:1).

       STORE-TIMESTAMP.
           COMPUTE WS-B1 =
               FUNCTION INTEGER(DC-RTP-TIMESTAMP / 16777216)
           COMPUTE WS-B2 =
               FUNCTION INTEGER((DC-RTP-TIMESTAMP
                   - (WS-B1 * 16777216)) / 65536)
           COMPUTE WS-B3 =
               FUNCTION INTEGER((DC-RTP-TIMESTAMP
                   - (WS-B1 * 16777216)
                   - (WS-B2 * 65536)) / 256)
           COMPUTE WS-B4 =
               DC-RTP-TIMESTAMP
               - (WS-B1 * 16777216)
               - (WS-B2 * 65536)
               - (WS-B3 * 256)
           MOVE FUNCTION CHAR(WS-B1 + 1)
               TO DC-RTP-TIMESTAMP-BYTES(1:1)
           MOVE FUNCTION CHAR(WS-B2 + 1)
               TO DC-RTP-TIMESTAMP-BYTES(2:1)
           MOVE FUNCTION CHAR(WS-B3 + 1)
               TO DC-RTP-TIMESTAMP-BYTES(3:1)
           MOVE FUNCTION CHAR(WS-B4 + 1)
               TO DC-RTP-TIMESTAMP-BYTES(4:1).

       STORE-SSRC.
           COMPUTE WS-B1 = FUNCTION INTEGER(DC-RTP-SSRC / 16777216)
           COMPUTE WS-B2 =
               FUNCTION INTEGER((DC-RTP-SSRC
                   - (WS-B1 * 16777216)) / 65536)
           COMPUTE WS-B3 =
               FUNCTION INTEGER((DC-RTP-SSRC
                   - (WS-B1 * 16777216)
                   - (WS-B2 * 65536)) / 256)
           COMPUTE WS-B4 =
               DC-RTP-SSRC
               - (WS-B1 * 16777216)
               - (WS-B2 * 65536)
               - (WS-B3 * 256)
           MOVE FUNCTION CHAR(WS-B1 + 1)
               TO DC-RTP-SSRC-BYTES(1:1)
           MOVE FUNCTION CHAR(WS-B2 + 1)
               TO DC-RTP-SSRC-BYTES(2:1)
           MOVE FUNCTION CHAR(WS-B3 + 1)
               TO DC-RTP-SSRC-BYTES(3:1)
           MOVE FUNCTION CHAR(WS-B4 + 1)
               TO DC-RTP-SSRC-BYTES(4:1).
       END PROGRAM DC-RTP-BUILD-HEADER.
