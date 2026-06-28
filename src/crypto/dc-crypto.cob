       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-CRYPTO-ENCRYPT-VOICE.

       DATA DIVISION.
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
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_CRYPTO_FAILED" TO DC-ERROR-CODE
           MOVE "Voice encryption is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-CRYPTO-ENCRYPT-VOICE.
