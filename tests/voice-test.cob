       IDENTIFICATION DIVISION.
       PROGRAM-ID. VOICE-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-CHANNEL-ID PIC X(32) VALUE "chan-1".
       01 WS-JSON PIC X(8192).
       01 WS-PAYLOAD PIC X(8192).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-SESSION-INIT
           PERFORM TEST-STATE-UPDATE
           PERFORM TEST-SERVER-UPDATE
           PERFORM TEST-VOICE-IDENTIFY-BUILD
           PERFORM TEST-SELECT-PROTOCOL-BUILD
           PERFORM TEST-SPEAKING-BUILD
           PERFORM TEST-VOICE-HANDLE-PAYLOAD
           PERFORM TEST-UDP-DISCOVERY
           PERFORM TEST-VOICE-RESUME-BUILD
           PERFORM FINISH-TEST.

       TEST-SESSION-INIT.
           CALL "DC-VOICE-SESSION-INIT"
               USING DC-VOICE-SESSION
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-VS-GUILD-ID) NOT = "guild-1"
               DISPLAY "voice-test: guild id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-VS-CHANNEL-ID) NOT = "chan-1"
               DISPLAY "voice-test: channel id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-STATE NOT = 1
               DISPLAY "voice-test: session state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-STATE-UPDATE.
           MOVE '{"d":{"session_id":"voice-sess"}}' TO WS-JSON
           CALL "DC-VOICE-APPLY-STATE-UPDATE"
               USING WS-JSON DC-VOICE-SESSION DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-VS-SESSION-ID) NOT = "voice-sess"
               DISPLAY "voice-test: voice session id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SERVER-UPDATE.
           MOVE '{"d":{"token":"voice-token","endpoint":"voice.example.test"}}'
               TO WS-JSON
           CALL "DC-VOICE-APPLY-SERVER-UPDATE"
               USING WS-JSON DC-VOICE-SESSION DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-VS-TOKEN) NOT = "voice-token"
               DISPLAY "voice-test: voice token mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-VS-ENDPOINT) NOT = "voice.example.test"
               DISPLAY "voice-test: voice endpoint mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-IDENTIFY-BUILD.
           MOVE "guild-1" TO DC-VI-SERVER-ID
           MOVE "user-1" TO DC-VI-USER-ID
           MOVE "voice-sess" TO DC-VI-SESSION-ID
           MOVE "voice-token" TO DC-VI-TOKEN
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-IDENTIFY-BUILD"
               USING DC-VOICE-IDENTIFY WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":0,"d":{"server_id":"guild-1","user_id":"user-1","session_id":"voice-sess","token":"voice-token","max_dave_protocol_version":0}}'
               DISPLAY "voice-test: voice identify payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SELECT-PROTOCOL-BUILD.
           MOVE "udp" TO DC-SP-PROTOCOL
           MOVE "127.0.0.1" TO DC-SP-ADDRESS
           MOVE 5000 TO DC-SP-PORT
           MOVE "aead_xchacha20_poly1305_rtpsize" TO DC-SP-MODE
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-SELECT-PROTOCOL-BUILD"
               USING DC-SELECT-PROTOCOL WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":1,"d":{"protocol":"udp","data":{"address":"127.0.0.1","port":5000,"mode":"aead_xchacha20_poly1305_rtpsize"}}}'
               DISPLAY "voice-test: select protocol payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-SPEAKING-BUILD.
           MOVE 1 TO DC-SPEAKING-FLAG
           MOVE 0 TO DC-SPEAKING-DELAY
           MOVE 4242 TO DC-SPEAKING-SSRC
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-SPEAKING-BUILD"
               USING DC-SPEAKING-PAYLOAD WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":5,"d":{"speaking":1,"delay":0,"ssrc":4242}}'
               DISPLAY "voice-test: speaking payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-HANDLE-PAYLOAD.
           MOVE '{"op":8,"d":{"heartbeat_interval":1337}}' TO WS-JSON
           CALL "DC-VOICE-HANDLE-PAYLOAD"
               USING DC-VOICE-SESSION WS-JSON DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-HEARTBEAT-INTERVAL NOT = 1337
               DISPLAY "voice-test: voice heartbeat interval mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE '{"op":2,"d":{"ssrc":4242,"ip":"127.0.0.1","port":5000},"seq":9}'
               TO WS-JSON
           CALL "DC-VOICE-HANDLE-PAYLOAD"
               USING DC-VOICE-SESSION WS-JSON DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-SSRC NOT = 4242
               DISPLAY "voice-test: voice ssrc mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-VS-IP) NOT = "127.0.0.1"
               DISPLAY "voice-test: voice ip mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-PORT NOT = 5000
               DISPLAY "voice-test: voice port mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-LAST-SEQ NOT = 9
               DISPLAY "voice-test: voice seq mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-STATE NOT = 3
               DISPLAY "voice-test: voice ready state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE '{"op":4,"d":{"mode":"aead_xchacha20_poly1305_rtpsize"},"seq":10}'
               TO WS-JSON
           CALL "DC-VOICE-HANDLE-PAYLOAD"
               USING DC-VOICE-SESSION WS-JSON DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-VS-ENCRYPTION-MODE)
               NOT = "aead_xchacha20_poly1305_rtpsize"
               DISPLAY "voice-test: voice mode mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-READY-FLAG NOT = 1
               DISPLAY "voice-test: voice ready flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-LAST-SEQ NOT = 10
               DISPLAY "voice-test: voice seq update mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-STATE NOT = 4
               DISPLAY "voice-test: voice connected state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-UDP-DISCOVERY.
           INITIALIZE DC-UDP-DISCOVERY
           MOVE 4242 TO DC-UD-SSRC
           CALL "DC-VOICE-UDP-DISCOVERY-BUILD"
               USING DC-UDP-DISCOVERY DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION HEX-OF(DC-UD-PACKET(1:8)) NOT = "0001004600001092"
               DISPLAY "voice-test: udp discovery packet mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE LOW-VALUE TO DC-UD-PACKET
           MOVE FUNCTION CHAR(3) TO DC-UD-PACKET(2:1)
           MOVE FUNCTION CHAR(71) TO DC-UD-PACKET(4:1)
           MOVE "192.168.0.10" TO DC-UD-PACKET(9:12)
           MOVE FUNCTION CHAR(32) TO DC-UD-PACKET(73:1)
           MOVE FUNCTION CHAR(145) TO DC-UD-PACKET(74:1)
           CALL "DC-VOICE-UDP-DISCOVERY-PARSE"
               USING DC-UDP-DISCOVERY DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-UD-DISCOVERED-IP) NOT = "192.168.0.10"
               DISPLAY "voice-test: udp discovery ip mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UD-DISCOVERED-PORT NOT = 8080
               DISPLAY "voice-test: udp discovery port mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-RESUME-BUILD.
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-RESUME-BUILD"
               USING DC-VOICE-SESSION WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":7,"d":{"server_id":"guild-1","session_id":"voice-sess","token":"voice-token"}}'
               DISPLAY "voice-test: voice resume payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "voice-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "voice-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "voice-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM VOICE-TEST.
