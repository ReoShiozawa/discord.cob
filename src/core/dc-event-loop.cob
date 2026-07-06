       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-EVENT-LOOP-TICK.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-event.cpy".
       01 WS-GATEWAY-JSON PIC X(8192).
       01 WS-GATEWAY-ACTION PIC X(32).
       01 WS-GATEWAY-PAYLOAD PIC X(8192).
       01 WS-NOW-CS PIC 9(18) COMP-5.
       01 WS-RECV-RESULT.
          05 WS-RECV-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-RECV-ERROR-CODE PIC X(64).
          05 WS-RECV-ERROR-MESSAGE PIC X(256).
       01 WS-DISPATCH-RESULT.
          05 WS-DISPATCH-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-DISPATCH-ERROR-CODE PIC X(64).
          05 WS-DISPATCH-ERROR-MESSAGE PIC X(256).
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
      *> JP: Gateway の 1 tick は recv -> handle/dispatch -> heartbeat poll -> send の順です。
      *> EN: One Gateway tick runs in the order recv -> handle/dispatch -> heartbeat poll -> send.
      *> JP: client 本体には固定長 state だけを置き、WebSocket session は毎 tick load/save します。
      *> EN: The client stores only fixed-width state, so the WebSocket session is load/saved each tick.
           IF DC-CLIENT-GW-WS-OPEN-FLAG NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY" TO DC-ERROR-CODE
               MOVE "Gateway session is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-WS-SESSION
           INITIALIZE DC-WS-FRAME
           INITIALIZE DC-EVENT
           MOVE SPACES TO WS-GATEWAY-JSON
           MOVE SPACES TO WS-GATEWAY-ACTION
           MOVE SPACES TO WS-GATEWAY-PAYLOAD

           CALL "DC-GATEWAY-SESSION-LOAD"
               USING DC-CLIENT
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
      *> JP: 受信できたら、まず session バッファの更新を client へ反映します。
      *> EN: After a successful recv, persist the updated session buffers back into client state.
               CALL "DC-GATEWAY-SESSION-SAVE"
                   USING DC-CLIENT
                         DC-WS-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF

                EVALUATE DC-WS-OPCODE
                    WHEN 1
      *> JP: text frame は Gateway payload として解釈し、必要なら event dispatch まで進めます。
      *> EN: Text frames are interpreted as Gateway payloads and may flow into event dispatch.
                        IF DC-WS-PAYLOAD-LENGTH > 0
                            MOVE DC-WS-PAYLOAD(1:DC-WS-PAYLOAD-LENGTH)
                                TO WS-GATEWAY-JSON(1:DC-WS-PAYLOAD-LENGTH)
                        END-IF
                       CALL "DC-GATEWAY-HANDLE-PAYLOAD"
                           USING DC-CLIENT
                                 WS-GATEWAY-JSON
                                 DC-EVENT
                                 DC-RESULT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                       IF FUNCTION TRIM(DC-EVENT-NAME) NOT = SPACES
                           CALL "DC-DISPATCH"
                               USING DC-CLIENT
                                     DC-EVENT
                                     WS-DISPATCH-RESULT
                           IF WS-DISPATCH-STATUS-CODE
                               NOT = DC-STATUS-OK
                              AND WS-DISPATCH-STATUS-CODE
                                  NOT = DC-STATUS-NOT-FOUND
                               MOVE WS-DISPATCH-STATUS-CODE
                                   TO DC-STATUS-CODE
                               MOVE WS-DISPATCH-ERROR-CODE
                                   TO DC-ERROR-CODE
                               MOVE WS-DISPATCH-ERROR-MESSAGE
                                   TO DC-ERROR-MESSAGE
                               GOBACK
                           END-IF
                           IF FUNCTION TRIM(DC-EVENT-NAME) = "RECONNECT"
                               CALL "DC-GATEWAY-RECONNECT"
                                   USING DC-CLIENT
                                         DC-RESULT
                               GOBACK
                           END-IF
                       END-IF
                    WHEN 8
      *> JP: close frame を受けたら client 側の Gateway state も切断状態へ戻します。
      *> EN: A close frame also tears down the client-side Gateway state.
                        IF FUNCTION TRIM(DC-CLIENT-SESSION-ID) NOT = SPACES
                           AND DC-CLIENT-SEQUENCE > 0
                            CALL "DC-GATEWAY-RECONNECT"
                                USING DC-CLIENT
                                      DC-RESULT
                        ELSE
                            CALL "DC-CLIENT-DISCONNECT"
                                USING DC-CLIENT
                                      DC-RESULT
                        END-IF
                       GOBACK
               END-EVALUATE
           ELSE
               IF WS-RECV-STATUS-CODE = DC-STATUS-EOF
                   IF DC-WS-OPEN-FLAG NOT = 1
                       CALL "DC-GATEWAY-SESSION-SAVE"
                           USING DC-CLIENT
                                 DC-WS-SESSION
                                 DC-RESULT
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           GOBACK
                       END-IF
                       IF FUNCTION TRIM(DC-CLIENT-SESSION-ID) NOT = SPACES
                          AND DC-CLIENT-SEQUENCE > 0
                           CALL "DC-GATEWAY-RECONNECT"
                               USING DC-CLIENT
                                     DC-RESULT
                       ELSE
                           CALL "DC-CLIENT-DISCONNECT"
                               USING DC-CLIENT
                                     DC-RESULT
                       END-IF
                       GOBACK
                   END-IF
               ELSE
                   MOVE WS-RECV-STATUS-CODE TO DC-STATUS-CODE
                   MOVE WS-RECV-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-RECV-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-IF

           CALL "DC-GATEWAY-SESSION-LOAD"
               USING DC-CLIENT
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
               USING DC-CLIENT-GW-HEARTBEAT-INTERVAL
                     DC-CLIENT-GW-AWAITING-ACK
                     DC-CLIENT-GW-HEARTBEAT-NEXT-AT
                     DC-CLIENT-GW-HEARTBEAT-DUE
                     WS-NOW-CS
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

      *> JP: 予定時刻を過ぎても heartbeat ACK が戻らない場合は、
      *> JP: 現在の session を stale とみなして reconnect へ進みます。
      *> EN: If the scheduled heartbeat deadline has passed and no ACK has arrived,
      *> EN: treat the current session as stale and reconnect.
           IF DC-CLIENT-GW-AWAITING-ACK = 1
              AND DC-CLIENT-GW-HEARTBEAT-NEXT-AT > 0
              AND WS-NOW-CS >= DC-CLIENT-GW-HEARTBEAT-NEXT-AT
               CALL "DC-GATEWAY-RECONNECT"
                   USING DC-CLIENT
                         DC-RESULT
               GOBACK
           END-IF

           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT
                     WS-GATEWAY-ACTION
                     WS-GATEWAY-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF FUNCTION TRIM(WS-GATEWAY-ACTION) NOT = SPACES
              AND FUNCTION TRIM(WS-GATEWAY-PAYLOAD) NOT = SPACES
      *> JP: 次に送る payload は identify/resume/heartbeat/queued command のどれかです。
      *> EN: The next outbound payload is one of identify/resume/heartbeat/queued command.
               CALL "DC-WS-SEND-TEXT"
                   USING DC-WS-SESSION
                         WS-GATEWAY-PAYLOAD
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF FUNCTION TRIM(WS-GATEWAY-ACTION) = "HEARTBEAT"
                   CALL "DC-HEARTBEAT-DEFER"
                       USING DC-CLIENT-GW-HEARTBEAT-INTERVAL
                             DC-CLIENT-GW-HEARTBEAT-NEXT-AT
                             DC-CLIENT-GW-HEARTBEAT-DUE
                             WS-NOW-CS
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
               CALL "DC-GATEWAY-SESSION-SAVE"
                   USING DC-CLIENT
                         DC-WS-SESSION
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-EVENT-LOOP-TICK.
