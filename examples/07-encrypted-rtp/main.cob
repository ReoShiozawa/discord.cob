       IDENTIFICATION DIVISION.
       PROGRAM-ID. EXAMPLE-ENCRYPTED-RTP.
       *> JP: negotiated Voice 情報を環境変数から受け、暗号化済み無音 frame を送ります。
       *> EN: Sends one encrypted silence frame from negotiated Voice parameters.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-PORT-TEXT PIC X(16).
       01 WS-SSRC-TEXT PIC X(16).
       01 WS-KEY-HEX PIC X(64).
       01 WS-KEY-POS PIC 9(3) COMP-5.
       01 WS-BYTE-POS PIC 9(3) COMP-5.
       01 WS-HIGH PIC 9(3) COMP-5.
       01 WS-LOW PIC 9(3) COMP-5.
       01 WS-HEX-CHAR PIC X.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-VOICE-SESSION DC-UDP-SESSION DC-RTP-STATE
           ACCEPT DC-VS-IP FROM ENVIRONMENT "DISCORD_VOICE_IP"
           ACCEPT WS-PORT-TEXT FROM ENVIRONMENT "DISCORD_VOICE_PORT"
           ACCEPT WS-SSRC-TEXT FROM ENVIRONMENT "DISCORD_VOICE_SSRC"
           ACCEPT WS-KEY-HEX FROM ENVIRONMENT "DISCORD_VOICE_SECRET_KEY_HEX"
           IF FUNCTION TRIM(DC-VS-IP) = SPACES
              OR FUNCTION TRIM(WS-PORT-TEXT) = SPACES
              OR FUNCTION TRIM(WS-SSRC-TEXT) = SPACES
              OR FUNCTION LENGTH(FUNCTION TRIM(WS-KEY-HEX)) NOT = 64
               DISPLAY "voice IP, port, SSRC, and a 64-digit secret key are required"
               STOP RUN RETURNING 2
           END-IF
           MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-PORT-TEXT)) TO DC-VS-PORT
           MOVE FUNCTION NUMVAL(FUNCTION TRIM(WS-SSRC-TEXT)) TO DC-VS-SSRC
           PERFORM DECODE-KEY

           MOVE DC-VS-IP TO DC-UDP-REMOTE-HOST
           MOVE DC-VS-PORT TO DC-UDP-REMOTE-PORT
           CALL "DC-UDP-OPEN" USING DC-UDP-SESSION DC-RESULT
           PERFORM REQUIRE-OK
           MOVE DC-UDP-HANDLE TO DC-VS-UDP-HANDLE
           MOVE 1 TO DC-VS-READY-FLAG DC-VS-UDP-READY-FLAG
           MOVE "aead_xchacha20_poly1305_rtpsize" TO DC-VS-ENCRYPTION-MODE

           MOVE 1 TO DC-RTP-SEQUENCE
           MOVE 960 TO DC-RTP-TIMESTAMP DC-RTP-FRAME-SAMPLES
           MOVE DC-VS-SSRC TO DC-RTP-SSRC
           CALL "DC-OPUS-BUILD-SILENCE" USING DC-OPUS-FRAME DC-RESULT
           PERFORM REQUIRE-OK
           CALL "DC-VOICE-SEND-FRAME"
               USING DC-VOICE-SESSION DC-RTP-STATE DC-OPUS-FRAME DC-RESULT
           PERFORM REQUIRE-OK
           DISPLAY "encrypted RTP silence frame sent"
           STOP RUN RETURNING 0.

       DECODE-KEY.
           PERFORM VARYING WS-BYTE-POS FROM 1 BY 1
               UNTIL WS-BYTE-POS > 32
               COMPUTE WS-KEY-POS = ((WS-BYTE-POS - 1) * 2) + 1
               MOVE WS-KEY-HEX(WS-KEY-POS:1) TO WS-HEX-CHAR
               PERFORM HEX-VALUE
               MOVE WS-LOW TO WS-HIGH
               MOVE WS-KEY-HEX(WS-KEY-POS + 1:1) TO WS-HEX-CHAR
               PERFORM HEX-VALUE
               COMPUTE WS-LOW = (WS-HIGH * 16) + WS-LOW
               MOVE FUNCTION CHAR(WS-LOW + 1)
                   TO DC-VS-SECRET-KEY(WS-BYTE-POS:1)
           END-PERFORM.
       HEX-VALUE.
           EVALUATE TRUE
               WHEN WS-HEX-CHAR >= "0" AND <= "9"
                   COMPUTE WS-LOW = FUNCTION ORD(WS-HEX-CHAR)
                       - FUNCTION ORD("0")
               WHEN WS-HEX-CHAR >= "A" AND <= "F"
                   COMPUTE WS-LOW = FUNCTION ORD(WS-HEX-CHAR)
                       - FUNCTION ORD("A") + 10
               WHEN WS-HEX-CHAR >= "a" AND <= "f"
                   COMPUTE WS-LOW = FUNCTION ORD(WS-HEX-CHAR)
                       - FUNCTION ORD("a") + 10
               WHEN OTHER
                   DISPLAY "secret key contains a non-hex character"
                   STOP RUN RETURNING 2
           END-EVALUATE.
       REQUIRE-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY FUNCTION TRIM(DC-ERROR-CODE)
               DISPLAY FUNCTION TRIM(DC-ERROR-MESSAGE)
               STOP RUN RETURNING 1
           END-IF.
       END PROGRAM EXAMPLE-ENCRYPTED-RTP.
