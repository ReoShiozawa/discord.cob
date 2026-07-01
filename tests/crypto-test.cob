       IDENTIFICATION DIVISION.
       PROGRAM-ID. CRYPTO-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-AEAD-CONTEXT
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 32
               MOVE FUNCTION CHAR(WS-IDX + 1) TO DC-AEAD-KEY(WS-IDX:1)
           END-PERFORM
           MOVE 32 TO DC-AEAD-KEY-LENGTH
           MOVE LOW-VALUE TO DC-AEAD-NONCE
           MOVE 24 TO DC-AEAD-NONCE-LENGTH
           MOVE X"807800020000078000001092" TO DC-AEAD-AAD(1:12)
           MOVE 12 TO DC-AEAD-AAD-LENGTH
           MOVE X"F8FFFE" TO DC-AEAD-PLAINTEXT(1:3)
           MOVE 3 TO DC-AEAD-PLAINTEXT-LENGTH

           CALL "DC-AEAD-ENCRYPT"
               USING DC-AEAD-CONTEXT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "crypto-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF

           IF DC-AEAD-CIPHERTEXT-LENGTH NOT = 3
               DISPLAY "crypto-test: ciphertext length mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-AEAD-TAG-LENGTH NOT = 16
               DISPLAY "crypto-test: tag length mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-AEAD-CIPHERTEXT(1:3) NOT = X"AD868A"
               DISPLAY "crypto-test: ciphertext mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-AEAD-TAG(1:16)
               NOT = X"DF913373B6916738BC5D3F662C59EAB6"
               DISPLAY "crypto-test: tag mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF

           INITIALIZE DC-VOICE-SESSION
           MOVE "aead_xchacha20_poly1305_rtpsize"
               TO DC-VS-ENCRYPTION-MODE
           MOVE 0 TO DC-VS-MEDIA-NONCE
           PERFORM VARYING WS-IDX FROM 1 BY 1 UNTIL WS-IDX > 32
               MOVE FUNCTION CHAR(WS-IDX + 1)
                   TO DC-VS-SECRET-KEY(WS-IDX:1)
           END-PERFORM
           MOVE X"80" TO DC-RTP-BYTE-0
           MOVE X"78" TO DC-RTP-BYTE-1
           MOVE X"0002" TO DC-RTP-SEQUENCE-BYTES
           MOVE X"00000780" TO DC-RTP-TIMESTAMP-BYTES
           MOVE X"00001092" TO DC-RTP-SSRC-BYTES
           INITIALIZE DC-OPUS-FRAME
           MOVE 3 TO DC-OPUS-LENGTH
           MOVE X"F8FFFE" TO DC-OPUS-DATA(1:3)

           CALL "DC-CRYPTO-ENCRYPT-VOICE"
               USING DC-VOICE-SESSION
                     DC-RTP-HEADER
                     DC-OPUS-FRAME
                     DC-RTP-PACKET
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "crypto-test: voice packet result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-VS-MEDIA-NONCE NOT = 1
               DISPLAY "crypto-test: voice nonce mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-RTP-PACKET-LENGTH NOT = 35
               DISPLAY "crypto-test: voice packet length mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF
           IF DC-RTP-PACKET-DATA(1:35)
               NOT = X"807800020000078000001092AD868ADF913373B6916738BC5D3F662C59EAB600000000"
               DISPLAY "crypto-test: voice packet mismatch"
               MOVE 1 TO WS-EXIT-CODE
               STOP RUN RETURNING WS-EXIT-CODE
           END-IF

           DISPLAY "crypto-test ok"
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM CRYPTO-TEST.
