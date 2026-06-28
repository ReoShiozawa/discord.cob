       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-POLY1305-TAG.

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
