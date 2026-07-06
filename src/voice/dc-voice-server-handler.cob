       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VS-SERVER-HANDLER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".
       01 WS-VOICE-JSON PIC X(8192).
       01 WS-PATH PIC X(128).
       01 WS-GUILD-ID PIC X(32).
       01 WS-EMPTY-CHANNEL PIC X(32).
       01 WS-TEXT PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
      *> JP: VOICE_SERVER_UPDATE を保存済み session へ反映します。
      *> EN: Apply VOICE_SERVER_UPDATE into the stored session.
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "VOICE_SERVER_UPDATE"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Gateway event was not VOICE_SERVER_UPDATE."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-VOICE-JSON
           IF DC-EVENT-PAYLOAD-LENGTH > 0
               MOVE DC-EVENT-PAYLOAD(1:DC-EVENT-PAYLOAD-LENGTH)
                   TO WS-VOICE-JSON(1:DC-EVENT-PAYLOAD-LENGTH)
           END-IF

           MOVE "$.d.guild_id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-GUILD-ID DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-SESSION-LOAD"
               USING WS-GUILD-ID
                     DC-VOICE-SESSION
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-VOICE-SESSION-INIT"
                   USING DC-VOICE-SESSION
                         WS-GUILD-ID
                         WS-EMPTY-CHANNEL
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           ELSE
               IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
                   MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           MOVE "$.d.token" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-TEXT DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE WS-TEXT TO DC-VS-TOKEN

           MOVE "$.d.endpoint" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING WS-VOICE-JSON WS-PATH WS-TEXT DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           MOVE WS-TEXT TO DC-VS-ENDPOINT
           IF FUNCTION TRIM(DC-VS-SESSION-ID) NOT = SPACES
               MOVE 1 TO DC-VS-IDENTIFY-NEEDED
               MOVE 2 TO DC-VS-STATE
           END-IF

           CALL "DC-VOICE-SESSION-SAVE"
               USING WS-GUILD-ID
                     DC-VOICE-SESSION
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-VS-SERVER-HANDLER.
