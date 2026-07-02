       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AEAD-ENCRYPT.
       *> JP: Voice packet 暗号化で使う AEAD 処理の入口です。
       *> JP: key、nonce、AAD、payload を固定長 context から受け取り結果を返します。
       *> EN: Entry point for AEAD processing used in voice-packet encryption.
       *> EN: It consumes key, nonce, AAD, and payload from the fixed-size context and returns the result.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       78 DC-AEAD-KEY-BYTES VALUE 32.
       78 DC-AEAD-NONCE-BYTES VALUE 24.
       78 DC-AEAD-TAG-BYTES VALUE 16.
       01 WS-SODIUM-STATUS PIC S9(9) COMP-5.
       01 WS-SODIUM-INIT-STATUS PIC S9(9) COMP-5.
       01 WS-AAD-LENGTH PIC 9(18) COMP-5.
       01 WS-PLAINTEXT-LENGTH PIC 9(18) COMP-5.
       01 WS-CIPHERTEXT-LENGTH PIC 9(18) COMP-5.
       01 WS-TAG-LENGTH PIC 9(18) COMP-5.

       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           IF DC-AEAD-KEY-LENGTH NOT = DC-AEAD-KEY-BYTES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "AEAD key length must be 32 bytes."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-AEAD-NONCE-LENGTH NOT = DC-AEAD-NONCE-BYTES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "AEAD nonce length must be 24 bytes."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-AEAD-AAD-LENGTH < 0 OR DC-AEAD-AAD-LENGTH > 64
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "AEAD AAD length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-AEAD-PLAINTEXT-LENGTH < 0
              OR DC-AEAD-PLAINTEXT-LENGTH > 4096
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "AEAD plaintext length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL STATIC "sodium_init"
               RETURNING WS-SODIUM-INIT-STATUS
           END-CALL
           IF WS-SODIUM-INIT-STATUS < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "libsodium initialization failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO DC-AEAD-CIPHERTEXT
           MOVE 0 TO DC-AEAD-CIPHERTEXT-LENGTH
           MOVE SPACES TO DC-AEAD-TAG
           MOVE 0 TO DC-AEAD-TAG-LENGTH
           MOVE DC-AEAD-AAD-LENGTH TO WS-AAD-LENGTH
           MOVE DC-AEAD-PLAINTEXT-LENGTH TO WS-PLAINTEXT-LENGTH
           MOVE 0 TO WS-CIPHERTEXT-LENGTH
           MOVE 0 TO WS-TAG-LENGTH

           CALL STATIC "crypto_aead_xchacha20poly1305_ietf_encrypt_detached"
               USING BY REFERENCE DC-AEAD-CIPHERTEXT
                     BY REFERENCE DC-AEAD-TAG
                     BY REFERENCE WS-TAG-LENGTH
                     BY REFERENCE DC-AEAD-PLAINTEXT
                     BY VALUE WS-PLAINTEXT-LENGTH
                     BY REFERENCE DC-AEAD-AAD
                     BY VALUE WS-AAD-LENGTH
                     BY VALUE 0
                     BY REFERENCE DC-AEAD-NONCE
                     BY REFERENCE DC-AEAD-KEY
               RETURNING WS-SODIUM-STATUS
           END-CALL
           IF WS-SODIUM-STATUS NOT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "XChaCha20-Poly1305 encryption failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-AEAD-PLAINTEXT-LENGTH TO DC-AEAD-CIPHERTEXT-LENGTH
           MOVE WS-TAG-LENGTH TO DC-AEAD-TAG-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-AEAD-ENCRYPT.
