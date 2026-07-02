       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CHACHA20-BLOCK.
       *> JP: ChaCha20 block 生成の低レベル helper です。
       *> JP: 上位の voice 暗号化 helper から使われる基礎プリミティブとして置かれています。
       *> EN: Low-level helper for generating ChaCha20 blocks.
       *> EN: It exists as a primitive that higher-level voice-encryption helpers build on.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
           MOVE "ChaCha20 is not implemented yet." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-CHACHA20-BLOCK.
