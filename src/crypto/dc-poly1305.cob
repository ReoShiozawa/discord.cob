       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-POLY1305-TAG.
       *> JP: Poly1305 tag 計算の低レベル helper です。
       *> JP: AEAD 処理の認証部分を単独の program として切り出しています。
       *> EN: Low-level helper for computing Poly1305 tags.
       *> EN: It isolates the authentication step used by the broader AEAD flow.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
           MOVE "Poly1305 is not implemented yet." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-POLY1305-TAG.
