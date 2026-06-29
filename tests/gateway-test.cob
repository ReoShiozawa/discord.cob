       IDENTIFICATION DIVISION.
       PROGRAM-ID. GATEWAY-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".
       01 WS-JSON PIC X(8192).
       01 WS-PAYLOAD PIC X(8192).
       01 WS-QUEUED-PAYLOAD PIC X(8192).
       01 WS-QUEUED-ACTION PIC X(32) VALUE "VOICE_STATE_UPDATE".
       COPY "discord-net.cpy".
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           INITIALIZE DC-CONFIG
           MOVE "token" TO DC-BOT-TOKEN
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
	           PERFORM CHECK-OK
           PERFORM TEST-HELLO
           PERFORM TEST-NEXT-IDENTIFY
           PERFORM TEST-READY
           PERFORM TEST-GATEWAY-URL-REQUEST
           PERFORM TEST-GATEWAY-URL-RESPONSE
           PERFORM TEST-GATEWAY-WS-REQUEST
           PERFORM TEST-QUEUE-PAYLOAD
           PERFORM TEST-NEXT-HEARTBEAT
           PERFORM TEST-NEXT-RESUME
           PERFORM TEST-HEARTBEAT-BUILD
           PERFORM TEST-IDENTIFY-BUILD
           PERFORM TEST-RESUME-BUILD
           PERFORM TEST-SYNTHETIC-OPS
           PERFORM FINISH-TEST.

       TEST-HELLO.
           MOVE '{"op":10,"d":{"heartbeat_interval":41250}}'
               TO WS-JSON
           INITIALIZE DC-EVENT
           CALL "DC-GATEWAY-HANDLE-PAYLOAD"
               USING DC-CLIENT WS-JSON DC-EVENT DC-RESULT
           PERFORM CHECK-OK
           IF DC-CLIENT-GW-HEARTBEAT-INTERVAL NOT = 41250
               DISPLAY "gateway-test: heartbeat interval mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-NEXT-IDENTIFY.
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT DC-EVENT-NAME WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "IDENTIFY"
               DISPLAY "gateway-test: next identify action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-GW-IDENTIFY-NEEDED NOT = 0
               DISPLAY "gateway-test: identify flag not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-READY.
           MOVE '{"op":0,"t":"READY","s":42,"d":{"session_id":"sess-1","user":{"id":"user-1"}}}'
               TO WS-JSON
           INITIALIZE DC-EVENT
           CALL "DC-GATEWAY-HANDLE-PAYLOAD"
               USING DC-CLIENT WS-JSON DC-EVENT DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "READY"
               DISPLAY "gateway-test: event name mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-CLIENT-SESSION-ID) NOT = "sess-1"
               DISPLAY "gateway-test: session id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-CLIENT-USER-ID) NOT = "user-1"
               DISPLAY "gateway-test: user id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-SEQUENCE NOT = 42
               DISPLAY "gateway-test: sequence mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-STATE NOT = 2
               DISPLAY "gateway-test: client state was not ready"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-GATEWAY-URL-REQUEST.
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-GATEWAY-BUILD-URL-REQUEST"
               USING DC-CLIENT DC-HTTP-REQUEST DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "GET"
               DISPLAY "gateway-test: gateway url method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-HOST) NOT = "discord.com"
               DISPLAY "gateway-test: gateway url host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH) NOT = "/api/v10/gateway/bot"
               DISPLAY "gateway-test: gateway url path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-AUTHORIZATION) NOT = "Bot token"
               DISPLAY "gateway-test: gateway url auth mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-GATEWAY-URL-RESPONSE.
           INITIALIZE DC-HTTP-RESPONSE
           MOVE 200 TO DC-HTTP-STATUS-CODE
           MOVE '{"url":"wss://gateway.discord.gg"}'
               TO DC-HTTP-RESPONSE-BODY
           CALL "DC-GATEWAY-APPLY-URL-RESPONSE"
               USING DC-CLIENT DC-HTTP-RESPONSE DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-CLIENT-GATEWAY-ENDPOINT)
               NOT = "gateway.discord.gg"
               DISPLAY "gateway-test: gateway endpoint mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-GATEWAY-WS-REQUEST.
           INITIALIZE DC-WS-REQUEST
           CALL "DC-GATEWAY-BUILD-WS-REQUEST"
               USING DC-CLIENT DC-WS-REQUEST DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-WS-HOST) NOT = "gateway.discord.gg"
               DISPLAY "gateway-test: ws host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-PATH) NOT = "/?v=10"
               DISPLAY "gateway-test: ws path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SEC-KEY) = SPACES
               DISPLAY "gateway-test: ws key missing"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-QUEUE-PAYLOAD.
           MOVE
               '{"op":4,"d":{"guild_id":"guild-1","channel_id":"chan-1","self_mute":false,"self_deaf":false}}'
               TO WS-QUEUED-PAYLOAD
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-GATEWAY-QUEUE-PAYLOAD"
               USING DC-CLIENT
                     WS-QUEUED-ACTION
                     WS-QUEUED-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-CLIENT-GW-COMMAND-QUEUED NOT = 1
               DISPLAY "gateway-test: queue flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT DC-EVENT-NAME WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "VOICE_STATE_UPDATE"
               DISPLAY "gateway-test: queued action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":"chan-1","self_mute":false,"self_deaf":false}}'
               DISPLAY "gateway-test: queued payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-GW-COMMAND-QUEUED NOT = 0
               DISPLAY "gateway-test: queue flag not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-NEXT-HEARTBEAT.
           MOVE 1 TO DC-CLIENT-GW-HEARTBEAT-DUE
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT DC-EVENT-NAME WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "HEARTBEAT"
               DISPLAY "gateway-test: next heartbeat action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-GW-AWAITING-ACK NOT = 1
               DISPLAY "gateway-test: heartbeat ack flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-NEXT-RESUME.
           MOVE 1 TO DC-CLIENT-GW-RESUME-REQUESTED
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT DC-EVENT-NAME WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "RESUME"
               DISPLAY "gateway-test: next resume action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-CLIENT-GW-RESUME-REQUESTED NOT = 0
               DISPLAY "gateway-test: resume flag not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

	       TEST-HEARTBEAT-BUILD.
	           MOVE SPACES TO WS-PAYLOAD
	           CALL "DC-HEARTBEAT-BUILD"
	               USING DC-CLIENT-SEQUENCE WS-PAYLOAD DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(WS-PAYLOAD)
	               NOT = '{"op":1,"d":42}'
	               DISPLAY "gateway-test: heartbeat payload mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF.

	       TEST-IDENTIFY-BUILD.
	           MOVE SPACES TO WS-PAYLOAD
	           MOVE 513 TO DC-CLIENT-INTENTS
	           CALL "DC-IDENTIFY-BUILD"
	               USING DC-CLIENT WS-PAYLOAD DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(WS-PAYLOAD)
	               NOT = '{"op":2,"d":{"token":"token","intents":513,"properties":{"os":"cobol","browser":"discord.cob","device":"discord.cob"}}}'
	               DISPLAY "gateway-test: identify payload mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF.

	       TEST-RESUME-BUILD.
	           MOVE SPACES TO WS-PAYLOAD
	           CALL "DC-RESUME-BUILD"
	               USING DC-CLIENT WS-PAYLOAD DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(WS-PAYLOAD)
	               NOT = '{"op":6,"d":{"token":"token","session_id":"sess-1","seq":42}}'
	               DISPLAY "gateway-test: resume payload mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF.

	       TEST-SYNTHETIC-OPS.
	           MOVE '{"op":11}' TO WS-JSON
	           INITIALIZE DC-EVENT
	           CALL "DC-GATEWAY-HANDLE-PAYLOAD"
	               USING DC-CLIENT WS-JSON DC-EVENT DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "HEARTBEAT_ACK"
	               DISPLAY "gateway-test: heartbeat ack event mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF

	           MOVE '{"op":7}' TO WS-JSON
	           INITIALIZE DC-EVENT
	           CALL "DC-GATEWAY-HANDLE-PAYLOAD"
	               USING DC-CLIENT WS-JSON DC-EVENT DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "RECONNECT"
	               DISPLAY "gateway-test: reconnect event mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF

	           MOVE '{"op":9,"d":false}' TO WS-JSON
	           INITIALIZE DC-EVENT
	           CALL "DC-GATEWAY-HANDLE-PAYLOAD"
	               USING DC-CLIENT WS-JSON DC-EVENT DC-RESULT
	           PERFORM CHECK-OK
	           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "INVALID_SESSION"
	               DISPLAY "gateway-test: invalid session event mismatch"
	               ADD 1 TO WS-FAILURES
	           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "gateway-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "gateway-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "gateway-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM GATEWAY-TEST.
