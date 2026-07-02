       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-VOICE-EVENT-LOOP-TICK.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       01 WS-VOICE-JSON PIC X(8192).
       01 WS-VOICE-ACTION PIC X(32).
       01 WS-VOICE-PAYLOAD PIC X(8192).
       01 WS-NOW-CS PIC 9(18) COMP-5.
       01 WS-RECV-RESULT.
          05 WS-RECV-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-RECV-ERROR-CODE PIC X(64).
          05 WS-RECV-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-VOICE-SESSION
           DC-RESULT.
       MAIN.
      *> JP: Voice tick も Gateway tick と同様に recv -> state update -> heartbeat/UDP/music -> send の順です。
      *> EN: The Voice tick mirrors the Gateway tick: recv -> state update -> heartbeat/UDP/music -> send.
      *> JP: Voice 側は UDP discovery と media send が混ざるため、状態条件が Gateway より少し多めです。
      *> EN: Voice has more state gates than Gateway because UDP discovery and media send join the flow.
           IF DC-VS-WS-OPEN-FLAG NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_VOICE_GATEWAY" TO DC-ERROR-CODE
               MOVE "Voice Gateway session is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-WS-SESSION
           INITIALIZE DC-WS-FRAME
           MOVE SPACES TO WS-VOICE-JSON
           MOVE SPACES TO WS-VOICE-ACTION
           MOVE SPACES TO WS-VOICE-PAYLOAD

           CALL "DC-VOICE-GATEWAY-SESSION-LOAD"
               USING DC-VOICE-SESSION
                     DC-WS-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-WS-RECV"
               USING DC-WS-SESSION
                     DC-WS-FRAME
                     WS-RECV-RESULT
           IF WS-RECV-STATUS-CODE = DC-STATUS-OK
      *> JP: 受信後はまず session を保存し、そのあと opcode ごとの処理へ入ります。
      *> EN: Persist the session first after recv, then branch by opcode.
               CALL "DC-VOICE-GATEWAY-SESSION-SAVE"
                   USING DC-VOICE-SESSION
                         DC-WS-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF

                EVALUATE DC-WS-OPCODE
                    WHEN 1
      *> JP: text frame は Voice Gateway payload として扱います。
      *> EN: Text frames are treated as Voice Gateway payloads.
                        IF DC-WS-PAYLOAD-LENGTH > 0
                            MOVE DC-WS-PAYLOAD(1:DC-WS-PAYLOAD-LENGTH)
                                TO WS-VOICE-JSON(1:DC-WS-PAYLOAD-LENGTH)
                       END-IF
                       CALL "DC-VOICE-HANDLE-PAYLOAD"
                           USING DC-VOICE-SESSION
                                 WS-VOICE-JSON
                                 DC-RESULT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                    WHEN 8
      *> JP: Voice close frame は voice session 全体の teardown に繋げます。
      *> EN: A Voice close frame tears down the entire voice session.
                        CALL "DC-VOICE-DISCONNECT"
                            USING DC-VOICE-SESSION
                                  DC-RESULT
                       GOBACK
               END-EVALUATE
           ELSE
               IF WS-RECV-STATUS-CODE = DC-STATUS-EOF
                   IF DC-WS-OPEN-FLAG NOT = 1
                       CALL "DC-VOICE-GATEWAY-SESSION-SAVE"
                           USING DC-VOICE-SESSION
                                 DC-WS-SESSION
                                 DC-RESULT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                       CALL "DC-VOICE-DISCONNECT"
                           USING DC-VOICE-SESSION
                                 DC-RESULT
                       GOBACK
                   END-IF
               ELSE
                   MOVE WS-RECV-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-RECV-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-RECV-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-VOICE-GATEWAY-SESSION-LOAD"
               USING DC-VOICE-SESSION
                     DC-WS-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-CLOCK-NOW-CS"
               USING WS-NOW-CS
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HEARTBEAT-POLL"
               USING DC-VS-HEARTBEAT-INTERVAL
                     DC-VS-AWAITING-ACK
                     DC-VS-HEARTBEAT-NEXT-AT
                     DC-VS-HEARTBEAT-DUE
                     WS-NOW-CS
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-VS-STATE = 3
              AND DC-VS-UDP-READY-FLAG = 1
              AND FUNCTION TRIM(DC-VS-DISCOVERED-IP) = SPACES
              AND DC-VS-SSRC > 0
              AND DC-VS-COMMAND-QUEUED = 0
      *> JP: UDP socket が準備済みで discovery 未完了なら、tick が自動で discovery packet を出します。
      *> EN: Once the UDP socket is ready but discovery is unfinished, the tick auto-sends the discovery packet.
               CALL "DC-VOICE-UDP-DISCOVER"
                   USING DC-VOICE-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-MUSIC-VOICE-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-VOICE-NEXT-PAYLOAD"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     WS-VOICE-ACTION
                     WS-VOICE-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF FUNCTION TRIM(WS-VOICE-ACTION) NOT = SPACES
              AND FUNCTION TRIM(WS-VOICE-PAYLOAD) NOT = SPACES
      *> JP: control payload の優先順は NEXT-PAYLOAD 側で決まり、ここは送信だけを担当します。
      *> EN: NEXT-PAYLOAD decides control-payload priority; this paragraph only transmits it.
               CALL "DC-WS-SEND-TEXT"
                   USING DC-WS-SESSION
                         WS-VOICE-PAYLOAD
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF FUNCTION TRIM(WS-VOICE-ACTION) = "HEARTBEAT"
                   CALL "DC-HEARTBEAT-DEFER"
                       USING DC-VS-HEARTBEAT-INTERVAL
                             DC-VS-HEARTBEAT-NEXT-AT
                             DC-VS-HEARTBEAT-DUE
                             WS-NOW-CS
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
               CALL "DC-VOICE-GATEWAY-SESSION-SAVE"
                   USING DC-VOICE-SESSION
                         DC-WS-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-VOICE-EVENT-LOOP-TICK.
