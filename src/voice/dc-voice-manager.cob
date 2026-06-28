       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-JOIN.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       01 DC-VOICE-CHANNEL-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-CHANNEL-ID-IN
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
           MOVE "Voice join is not implemented yet." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-JOIN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-LEAVE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_MUSIC_NOT_CONNECTED" TO DC-ERROR-CODE
           MOVE "Voice session is not connected." TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-VOICE-LEAVE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-SESSION-INIT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-voice.cpy".
       01 DC-VOICE-GUILD-ID-IN PIC X(32).
       01 DC-VOICE-CHANNEL-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-VOICE-SESSION
           DC-VOICE-GUILD-ID-IN
           DC-VOICE-CHANNEL-ID-IN
           DC-RESULT.
       MAIN.
           INITIALIZE DC-VOICE-SESSION
           MOVE DC-VOICE-GUILD-ID-IN TO DC-VS-GUILD-ID
           MOVE DC-VOICE-CHANNEL-ID-IN TO DC-VS-CHANNEL-ID
           MOVE 1 TO DC-VS-STATE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-SESSION-INIT.
