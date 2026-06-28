       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-UDP-DISCOVERY-BUILD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-UDP-DISCOVERY DC-RESULT.
       MAIN.
           MOVE LOW-VALUE TO DC-UD-PACKET
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-UDP-DISCOVERY-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SEND-FRAME.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-RTP-STATE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           IF DC-VS-READY-FLAG NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
               MOVE "Voice session is not ready." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_UDP_SOCKET" TO DC-ERROR-CODE
           MOVE "UDP voice frame sending is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-SEND-FRAME.
