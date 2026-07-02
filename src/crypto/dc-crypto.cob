       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CRYPTO-ENCRYPT-VOICE.
       *> JP: voice transport 向け暗号化の高水準入口です。
       *> JP: RTP packet と鍵素材を受け、Discord voice wire format に近い形へまとめます。
       *> EN: High-level encryption entry point for voice transport.
       *> EN: It takes RTP-oriented input plus key material and prepares data close to Discord voice wire format.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-crypto.cpy".
       78 DC-VOICE-HEADER-BYTES VALUE 12.
       78 DC-VOICE-NONCE-SUFFIX-BYTES VALUE 4.
       01 WS-PACKET-OFFSET PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-RTP-HEADER
           DC-OPUS-FRAME
           DC-RTP-PACKET
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-VS-ENCRYPTION-MODE)
               NOT = "aead_xchacha20_poly1305_rtpsize"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "Voice encryption mode is not supported yet."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-OPUS-LENGTH < 0 OR DC-OPUS-LENGTH > 4096
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "Voice Opus frame length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-AEAD-CONTEXT
           MOVE DC-VS-SECRET-KEY(1:32) TO DC-AEAD-KEY
           MOVE 32 TO DC-AEAD-KEY-LENGTH
           MOVE DC-RTP-HEADER TO DC-AEAD-AAD(1:12)
           MOVE DC-VOICE-HEADER-BYTES TO DC-AEAD-AAD-LENGTH
           IF DC-OPUS-LENGTH > 0
               MOVE DC-OPUS-DATA(1:DC-OPUS-LENGTH)
                   TO DC-AEAD-PLAINTEXT(1:DC-OPUS-LENGTH)
           END-IF
           MOVE DC-OPUS-LENGTH TO DC-AEAD-PLAINTEXT-LENGTH

           INITIALIZE DC-NONCE-STATE
           MOVE DC-VS-MEDIA-NONCE TO DC-NONCE-COUNTER
           CALL "DC-NONCE-NEXT"
               USING DC-NONCE-STATE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE DC-NONCE-BUFFER TO DC-AEAD-NONCE
           MOVE 24 TO DC-AEAD-NONCE-LENGTH
           CALL "DC-AEAD-ENCRYPT"
               USING DC-AEAD-CONTEXT
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           COMPUTE DC-RTP-PACKET-LENGTH =
               DC-VOICE-HEADER-BYTES
               + DC-AEAD-CIPHERTEXT-LENGTH
               + DC-AEAD-TAG-LENGTH
               + DC-VOICE-NONCE-SUFFIX-BYTES
           IF DC-RTP-PACKET-LENGTH > 8192
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "Encrypted voice packet exceeded the packet buffer."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-RTP-PACKET-DATA
           MOVE DC-RTP-HEADER TO DC-RTP-PACKET-DATA(1:12)
           MOVE 13 TO WS-PACKET-OFFSET
           IF DC-AEAD-CIPHERTEXT-LENGTH > 0
               MOVE DC-AEAD-CIPHERTEXT(1:DC-AEAD-CIPHERTEXT-LENGTH)
                   TO DC-RTP-PACKET-DATA(
                       WS-PACKET-OFFSET:DC-AEAD-CIPHERTEXT-LENGTH)
               ADD DC-AEAD-CIPHERTEXT-LENGTH TO WS-PACKET-OFFSET
           END-IF
           IF DC-AEAD-TAG-LENGTH > 0
               MOVE DC-AEAD-TAG(1:DC-AEAD-TAG-LENGTH)
                   TO DC-RTP-PACKET-DATA(
                       WS-PACKET-OFFSET:DC-AEAD-TAG-LENGTH)
               ADD DC-AEAD-TAG-LENGTH TO WS-PACKET-OFFSET
           END-IF
           MOVE DC-NONCE-BUFFER(1:4)
               TO DC-RTP-PACKET-DATA(
                   WS-PACKET-OFFSET:DC-VOICE-NONCE-SUFFIX-BYTES)

           MOVE DC-NONCE-COUNTER TO DC-VS-MEDIA-NONCE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-CRYPTO-ENCRYPT-VOICE.
