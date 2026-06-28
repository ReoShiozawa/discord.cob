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
	                   CALL "DC-RESULT-OK" USING DC-RESULT
	                   GOBACK
	               WHEN 11
	                   MOVE "HEARTBEAT_ACK" TO WS-EVENT-NAME
	                   PERFORM BUILD-SYNTHETIC-EVENT
	                   CALL "DC-RESULT-OK" USING DC-RESULT
	                   GOBACK
	               WHEN 9
	                   MOVE "INVALID_SESSION" TO WS-EVENT-NAME
	                   PERFORM BUILD-SYNTHETIC-EVENT
	                   CALL "DC-RESULT-OK" USING DC-RESULT
	                   GOBACK
	               WHEN 7
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
