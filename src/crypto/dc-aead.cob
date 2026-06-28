       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-AEAD-ENCRYPT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-crypto.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-AEAD-CONTEXT DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
           MOVE "AEAD encryption is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-AEAD-ENCRYPT.
