       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-POLY1305-TAG.
       *> JP: context の plaintext に対する 16-byte Poly1305 tag を計算します。
       *> EN: Computes a 16-byte Poly1305 tag over the context plaintext.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-STATUS PIC S9(9) COMP-5.
       01 WS-INIT-STATUS PIC S9(9) COMP-5.
       01 WS-MESSAGE-LENGTH PIC 9(18) COMP-5.

       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           IF DC-AEAD-KEY-LENGTH NOT = 32
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_INPUT" TO DC-ERROR-CODE
               MOVE "Poly1305 requires a 32-byte one-time key."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF DC-AEAD-PLAINTEXT-LENGTH < 0
              OR DC-AEAD-PLAINTEXT-LENGTH > 4096
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_INPUT" TO DC-ERROR-CODE
               MOVE "Poly1305 message length is invalid."
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
           MOVE DC-AEAD-PLAINTEXT-LENGTH TO WS-MESSAGE-LENGTH
           MOVE SPACES TO DC-AEAD-TAG
           CALL STATIC "crypto_onetimeauth_poly1305"
               USING BY REFERENCE DC-AEAD-TAG
                     BY REFERENCE DC-AEAD-PLAINTEXT
                     BY VALUE WS-MESSAGE-LENGTH
                     BY REFERENCE DC-AEAD-KEY
               RETURNING WS-STATUS
           END-CALL
           IF WS-STATUS NOT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
               MOVE "Poly1305 tag generation failed." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE 16 TO DC-AEAD-TAG-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-POLY1305-TAG.
