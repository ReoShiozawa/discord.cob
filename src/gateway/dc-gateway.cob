       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-CONNECT.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           MOVE 1 TO DC-CLIENT-STATE
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_WEBSOCKET" TO DC-ERROR-CODE
           MOVE "Gateway WebSocket transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-GATEWAY-CONNECT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-BUILD-URL-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VERSION-TEXT PIC Z9.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           INITIALIZE DC-HTTP-REQUEST
           MOVE DC-CLIENT-GATEWAY-VERSION TO WS-VERSION-TEXT
           MOVE "GET" TO DC-HTTP-METHOD
           MOVE "discord.com" TO DC-HTTP-HOST
           STRING
               "/api/v" DELIMITED BY SIZE
               FUNCTION TRIM(WS-VERSION-TEXT) DELIMITED BY SIZE
               "/gateway/bot" DELIMITED BY SIZE
               INTO DC-HTTP-PATH
           END-STRING
           STRING
               "Bot " DELIMITED BY SIZE
               FUNCTION TRIM(DC-CLIENT-TOKEN) DELIMITED BY SIZE
               INTO DC-HTTP-AUTHORIZATION
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-GATEWAY-BUILD-URL-REQUEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-APPLY-URL-RESPONSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).
       01 WS-URL PIC X(512).
       01 WS-HOST PIC X(256).
       01 WS-PATH-OUT PIC X(512).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           IF DC-HTTP-STATUS-CODE NOT = 200
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Gateway URL response did not return 200."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           MOVE "$.url" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-HTTP-RESPONSE-BODY
                     WS-PATH
                     WS-URL
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-URL-SPLIT-WSS"
               USING WS-URL
                     WS-HOST
                     WS-PATH-OUT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-HOST TO DC-CLIENT-GATEWAY-ENDPOINT
           ELSE
               MOVE FUNCTION TRIM(WS-URL) TO DC-CLIENT-GATEWAY-ENDPOINT
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-GATEWAY-APPLY-URL-RESPONSE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-BUILD-WS-REQUEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ENDPOINT PIC X(256).
       01 WS-URL PIC X(512).
       01 WS-VERSION-TEXT PIC Z9.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-WS-REQUEST
           DC-RESULT.
       MAIN.
           INITIALIZE DC-WS-REQUEST
           IF FUNCTION TRIM(DC-CLIENT-GATEWAY-ENDPOINT) = SPACES
               MOVE "gateway.discord.gg" TO WS-ENDPOINT
           ELSE
               MOVE DC-CLIENT-GATEWAY-ENDPOINT TO WS-ENDPOINT
           END-IF
           CALL "DC-URL-BUILD-WSS"
               USING WS-ENDPOINT
                     DC-CLIENT-GATEWAY-VERSION
                     WS-URL
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-URL-SPLIT-WSS"
               USING WS-URL
                     DC-WS-HOST
                     DC-WS-PATH
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           CALL "DC-WS-GENERATE-KEY"
               USING DC-WS-SEC-KEY DC-RESULT
           GOBACK.
       END PROGRAM DC-GATEWAY-BUILD-WS-REQUEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-QUEUE-PAYLOAD.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GATEWAY-ACTION-IN PIC X(32).
       01 DC-GATEWAY-PAYLOAD-IN PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-GATEWAY-ACTION-IN
           DC-GATEWAY-PAYLOAD-IN
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-GATEWAY-ACTION-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_QUEUE" TO DC-ERROR-CODE
               MOVE "Gateway action name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-GATEWAY-PAYLOAD-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_QUEUE" TO DC-ERROR-CODE
               MOVE "Gateway payload is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-CLIENT-GW-COMMAND-QUEUED = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_GATEWAY_QUEUE_FULL" TO DC-ERROR-CODE
               MOVE "Gateway outbound queue is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 1 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE DC-GATEWAY-ACTION-IN TO DC-CLIENT-GW-COMMAND-NAME
           MOVE DC-GATEWAY-PAYLOAD-IN TO DC-CLIENT-GW-COMMAND-PAYLOAD
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-GATEWAY-QUEUE-PAYLOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-NEXT-PAYLOAD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ACTION PIC X(32).
       01 WS-SEQ-IN PIC S9(10) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GATEWAY-ACTION-OUT PIC X(32).
       01 DC-GATEWAY-PAYLOAD-OUT PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-GATEWAY-ACTION-OUT
           DC-GATEWAY-PAYLOAD-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-GATEWAY-ACTION-OUT
           MOVE SPACES TO DC-GATEWAY-PAYLOAD-OUT

           IF DC-CLIENT-GW-RESUME-REQUESTED = 1
               AND FUNCTION TRIM(DC-CLIENT-SESSION-ID) NOT = SPACES
               CALL "DC-RESUME-BUILD"
                   USING DC-CLIENT DC-GATEWAY-PAYLOAD-OUT DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "RESUME" TO DC-GATEWAY-ACTION-OUT
               MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
               GOBACK
           END-IF

           IF DC-CLIENT-GW-IDENTIFY-NEEDED = 1
               CALL "DC-IDENTIFY-BUILD"
                   USING DC-CLIENT DC-GATEWAY-PAYLOAD-OUT DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "IDENTIFY" TO DC-GATEWAY-ACTION-OUT
               MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
               GOBACK
           END-IF

           IF DC-CLIENT-GW-HEARTBEAT-DUE = 1
               IF DC-CLIENT-SEQUENCE <= 0
                   MOVE -1 TO WS-SEQ-IN
               ELSE
                   MOVE DC-CLIENT-SEQUENCE TO WS-SEQ-IN
               END-IF
               CALL "DC-HEARTBEAT-BUILD"
                   USING WS-SEQ-IN DC-GATEWAY-PAYLOAD-OUT DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               MOVE "HEARTBEAT" TO DC-GATEWAY-ACTION-OUT
               MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-DUE
               MOVE 1 TO DC-CLIENT-GW-AWAITING-ACK
               GOBACK
           END-IF

           IF DC-CLIENT-GW-COMMAND-QUEUED = 1
               MOVE DC-CLIENT-GW-COMMAND-NAME TO DC-GATEWAY-ACTION-OUT
               MOVE DC-CLIENT-GW-COMMAND-PAYLOAD TO DC-GATEWAY-PAYLOAD-OUT
               MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
               MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
               MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-GATEWAY-NEXT-PAYLOAD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-GATEWAY-HANDLE-PAYLOAD.

	       DATA DIVISION.
	       WORKING-STORAGE SECTION.
	       01 WS-PATH PIC X(128).
	       01 WS-OP PIC S9(18) COMP-5.
	       01 WS-SEQ PIC S9(18) COMP-5.
	       01 WS-HB-INTERVAL PIC S9(18) COMP-5.
	       01 WS-TEXT PIC X(512).
	       01 WS-EVENT-NAME PIC X(64).
	       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-GATEWAY-JSON PIC X(8192).
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-GATEWAY-JSON
           DC-EVENT
           DC-RESULT.
       MAIN.
           INITIALIZE DC-EVENT
           MOVE "$.op" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-GATEWAY-JSON WS-PATH WS-OP DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE "$.s" TO WS-PATH
           CALL "DC-JSON-GET-NUMBER"
               USING DC-GATEWAY-JSON WS-PATH WS-SEQ WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-SEQ TO DC-CLIENT-SEQUENCE
           END-IF

	           EVALUATE WS-OP
	               WHEN 10
	                   MOVE "$.d.heartbeat_interval" TO WS-PATH
	                   CALL "DC-JSON-GET-NUMBER"
	                       USING
	                           DC-GATEWAY-JSON
	                           WS-PATH
	                           WS-HB-INTERVAL
	                           DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
                   MOVE WS-HB-INTERVAL TO DC-CLIENT-GW-HEARTBEAT-INTERVAL
                   IF FUNCTION TRIM(DC-CLIENT-SESSION-ID) NOT = SPACES
                      AND DC-CLIENT-SEQUENCE > 0
                       MOVE 1 TO DC-CLIENT-GW-RESUME-REQUESTED
                       MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
                   ELSE
                       MOVE 1 TO DC-CLIENT-GW-IDENTIFY-NEEDED
                       MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
                   END-IF
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               WHEN 11
                   MOVE 0 TO DC-CLIENT-GW-AWAITING-ACK
                   MOVE 0 TO DC-CLIENT-GW-HEARTBEAT-DUE
                   MOVE "HEARTBEAT_ACK" TO WS-EVENT-NAME
                   PERFORM BUILD-SYNTHETIC-EVENT
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               WHEN 9
                   MOVE 1 TO DC-CLIENT-GW-IDENTIFY-NEEDED
                   MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
                   MOVE "INVALID_SESSION" TO WS-EVENT-NAME
                   PERFORM BUILD-SYNTHETIC-EVENT
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               WHEN 7
                   MOVE 1 TO DC-CLIENT-GW-RESUME-REQUESTED
                   MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
                   MOVE 1 TO DC-CLIENT-STATE
                   MOVE "RECONNECT" TO WS-EVENT-NAME
                   PERFORM BUILD-SYNTHETIC-EVENT
                   CALL "DC-RESULT-OK" USING DC-RESULT
	                   GOBACK
	           END-EVALUATE

	           MOVE "$.t" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-GATEWAY-JSON WS-PATH WS-TEXT WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               CALL "DC-GATEWAY-EVENT-FROM-JSON"
                   USING DC-GATEWAY-JSON DC-EVENT DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
               IF FUNCTION TRIM(DC-EVENT-NAME) = "READY"
                   PERFORM APPLY-READY
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

	       APPLY-READY.
	           MOVE "$.d.session_id" TO WS-PATH
	           CALL "DC-JSON-GET-STRING"
	               USING DC-GATEWAY-JSON
	                     WS-PATH
	                     WS-TEXT
	                     WS-LOCAL-RESULT
	           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
	               MOVE WS-TEXT TO DC-CLIENT-SESSION-ID
	           END-IF
	           MOVE "$.d.user.id" TO WS-PATH
	           CALL "DC-JSON-GET-STRING"
	               USING DC-GATEWAY-JSON
	                     WS-PATH
	                     WS-TEXT
	                     WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-CLIENT-USER-ID
               END-IF
               MOVE 0 TO DC-CLIENT-GW-IDENTIFY-NEEDED
               MOVE 0 TO DC-CLIENT-GW-RESUME-REQUESTED
               CALL "DC-CLIENT-SET-READY" USING DC-CLIENT WS-LOCAL-RESULT.

	       BUILD-SYNTHETIC-EVENT.
	           MOVE SPACES TO DC-EVENT-NAME
	           MOVE WS-EVENT-NAME TO DC-EVENT-NAME
	           MOVE WS-SEQ TO DC-EVENT-SEQUENCE
	           MOVE FUNCTION LENGTH(
	               FUNCTION TRIM(DC-GATEWAY-JSON TRAILING))
	               TO DC-EVENT-PAYLOAD-LENGTH
	           MOVE DC-GATEWAY-JSON TO DC-EVENT-PAYLOAD.
	       END PROGRAM DC-GATEWAY-HANDLE-PAYLOAD.
