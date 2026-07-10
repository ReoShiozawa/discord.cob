       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CHACHA20-BLOCK.
       *> JP: XChaCha20 の先頭 64-byte keystream block を生成します。
       *> EN: Generates the first 64-byte XChaCha20 keystream block.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC S9(9) COMP-5.
       01 WS-INIT-STATUS PIC S9(9) COMP-5.
       01 WS-OUTPUT-LENGTH PIC 9(18) COMP-5 VALUE 64.

       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           IF DC-AEAD-KEY-LENGTH NOT = 32
              OR DC-AEAD-NONCE-LENGTH NOT = 24
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_INPUT" TO DC-ERROR-CODE
               MOVE "XChaCha20 requires a 32-byte key and 24-byte nonce."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL STATIC "sodium_init" RETURNING WS-INIT-STATUS END-CALL
           IF WS-INIT-STATUS < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "libsodium initialization failed." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE SPACES TO DC-AEAD-CIPHERTEXT
           CALL STATIC "crypto_stream_xchacha20"
               USING BY REFERENCE DC-AEAD-CIPHERTEXT
                     BY VALUE WS-OUTPUT-LENGTH
                     BY REFERENCE DC-AEAD-NONCE
                     BY REFERENCE DC-AEAD-KEY
               RETURNING WS-STATUS
           END-CALL
           IF WS-STATUS NOT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "XChaCha20 block generation failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE 64 TO DC-AEAD-CIPHERTEXT-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-CHACHA20-BLOCK.
