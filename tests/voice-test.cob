       IDENTIFICATION DIVISION.
       PROGRAM-ID. VOICE-TEST.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-voice.cpy".
       COPY "discord-net.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-ACCEPT PIC X(64).
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-CHANNEL-ID PIC X(32) VALUE "chan-1".
       01 WS-EMPTY-CHANNEL PIC X(32).
       01 WS-VOICE-HOST PIC X(256) VALUE "voice.example.test".
       01 WS-VOICE-UDP-HOST PIC X(256) VALUE "127.0.0.1".
       01 WS-VOICE-DISCOVERED-IP PIC X(64) VALUE "198.51.100.10".
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-VOICE-UDP-PORT PIC 9(5) COMP-5 VALUE 5000.
       01 WS-VOICE-DISCOVERED-PORT PIC 9(5) COMP-5 VALUE 62000.
       01 WS-ACTION PIC X(32).
       01 WS-CLOCK-CS PIC 9(18) COMP-5.
       01 WS-JSON PIC X(8192).
       01 WS-PAYLOAD PIC X(8192).
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM TEST-SESSION-INIT
           PERFORM TEST-STATE-UPDATE
           PERFORM TEST-SERVER-UPDATE
           PERFORM TEST-VOICE-NEXT-IDENTIFY
           PERFORM TEST-VOICE-STATE-UPDATE-BUILD
           PERFORM TEST-VOICE-IDENTIFY-BUILD
           PERFORM TEST-SELECT-PROTOCOL-BUILD
           PERFORM TEST-SPEAKING-BUILD
           PERFORM TEST-VOICE-WS-REQUEST
           PERFORM TEST-VOICE-GATEWAY-CONNECT
           PERFORM TEST-VOICE-EVENT-LOOP
           PERFORM TEST-VOICE-JOIN-LEAVE
           PERFORM TEST-VOICE-HANDLE-PAYLOAD
           PERFORM TEST-VOICE-NEXT-HEARTBEAT
           PERFORM TEST-VOICE-HEARTBEAT-SCHEDULE
           PERFORM TEST-UDP-DISCOVERY
           PERFORM TEST-VOICE-UDP-DISCOVERY-APPLY
           PERFORM TEST-VOICE-SEND-FRAME
           PERFORM TEST-VOICE-NEXT-RESUME
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

       TEST-VOICE-NEXT-IDENTIFY.
           MOVE "user-1" TO DC-CLIENT-USER-ID
           MOVE SPACES TO WS-PAYLOAD
           MOVE SPACES TO WS-ACTION
           CALL "DC-VOICE-NEXT-PAYLOAD"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "IDENTIFY"
               DISPLAY "voice-test: next voice identify mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-IDENTIFY-NEEDED NOT = 0
               DISPLAY "voice-test: voice identify flag not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-STATE-UPDATE-BUILD.
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-STATE-UPDATE-BUILD"
               USING WS-GUILD-ID
                     WS-CHANNEL-ID
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":"chan-1","self_mute":false,"self_deaf":false}}'
               DISPLAY "voice-test: voice state update payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-STATE-UPDATE-BUILD"
               USING WS-GUILD-ID
                     WS-EMPTY-CHANNEL
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":null,"self_mute":false,"self_deaf":false}}'
               DISPLAY "voice-test: voice leave payload mismatch"
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

       TEST-VOICE-WS-REQUEST.
           INITIALIZE DC-CONFIG
           MOVE 8 TO DC-VOICE-GATEWAY-VERSION
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-WS-REQUEST
           CALL "DC-VOICE-BUILD-WS-REQUEST"
               USING DC-CLIENT DC-VOICE-SESSION DC-WS-REQUEST DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-WS-HOST) NOT = "voice.example.test"
               DISPLAY "voice-test: voice ws host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-PATH) NOT = "/?v=8"
               DISPLAY "voice-test: voice ws path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-WS-SEC-KEY) = SPACES
               DISPLAY "voice-test: voice ws key missing"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-GATEWAY-CONNECT.
           PERFORM INIT-LIVE-VOICE-SESSION
           CALL "DC-VOICE-GATEWAY-CONNECT"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-STATE NOT = 2
               DISPLAY "voice-test: voice connect state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-WS-OPEN-FLAG NOT = 1
               DISPLAY "voice-test: voice session not open"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-WS-LIVE-FLAG NOT = 1
               DISPLAY "voice-test: voice session not live"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-VS-WS-HOST) NOT = "voice.example.test"
               DISPLAY "voice-test: live voice host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:16) NOT = "GET /?v=8 HTTP/1"
               DISPLAY "voice-test: voice handshake request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-EVENT-LOOP.
           PERFORM INIT-LIVE-VOICE-SESSION
           CALL "DC-VOICE-GATEWAY-CONNECT"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE '{"op":8,"d":{"heartbeat_interval":1337}}' TO WS-JSON
           PERFORM INJECT-VOICE-TEXT-FRAME
           CALL "DC-VOICE-EVENT-LOOP-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-HEARTBEAT-INTERVAL NOT = 1337
               DISPLAY "voice-test: live hello heartbeat mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM ASSERT-LAST-VOICE-FRAME
           IF FUNCTION TRIM(DC-WS-PAYLOAD)
               NOT = '{"op":0,"d":{"server_id":"guild-1","user_id":"user-1","session_id":"voice-sess","token":"voice-token","max_dave_protocol_version":0}}'
               DISPLAY "voice-test: live identify payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM PREPARE-VOICE-UDP-DISCOVERY-FIXTURE
           MOVE '{"op":2,"d":{"ssrc":4242,"ip":"127.0.0.1","port":5000},"seq":9}'
               TO WS-JSON
           PERFORM INJECT-VOICE-TEXT-FRAME
           CALL "DC-VOICE-EVENT-LOOP-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-STATE NOT = 3
               DISPLAY "voice-test: live ready state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-SSRC NOT = 4242
               DISPLAY "voice-test: live ready ssrc mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-VS-DISCOVERED-IP)
               NOT = "198.51.100.10"
               DISPLAY "voice-test: live discovery ip mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-DISCOVERED-PORT NOT = 62000
               DISPLAY "voice-test: live discovery port mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-UDP-HANDLE = 0
               DISPLAY "voice-test: live udp handle mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-LENGTH NOT = 74
               DISPLAY "voice-test: live udp discovery length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION HEX-OF(DC-UDP-PACKET-DATA(1:8))
               NOT = "0001004600001092"
               DISPLAY "voice-test: live udp discovery request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM ASSERT-LAST-VOICE-FRAME
           IF FUNCTION TRIM(DC-WS-PAYLOAD)
               NOT = '{"op":1,"d":{"protocol":"udp","data":{"address":"198.51.100.10","port":62000,"mode":"aead_xchacha20_poly1305_rtpsize"}}}'
               DISPLAY "voice-test: live select protocol payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM PREPARE-VOICE-SESSION-DESCRIPTION
           PERFORM INJECT-VOICE-TEXT-FRAME
           CALL "DC-VOICE-EVENT-LOOP-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-READY-FLAG NOT = 1
               DISPLAY "voice-test: live session description ready mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION ORD(DC-VS-SECRET-KEY(1:1)) - 1 NOT = 1
               DISPLAY "voice-test: live secret key first byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION ORD(DC-VS-SECRET-KEY(32:1)) - 1 NOT = 32
               DISPLAY "voice-test: live secret key last byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-STATE NOT = 4
               DISPLAY "voice-test: live session description state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE 1 TO DC-SPEAKING-FLAG
           MOVE 0 TO DC-SPEAKING-DELAY
           MOVE 4242 TO DC-SPEAKING-SSRC
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-SPEAKING-BUILD"
               USING DC-SPEAKING-PAYLOAD
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "SPEAKING" TO WS-ACTION
           CALL "DC-VOICE-QUEUE-PAYLOAD"
               USING DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE '{"op":6}' TO WS-JSON
           PERFORM INJECT-VOICE-TEXT-FRAME
           CALL "DC-VOICE-EVENT-LOOP-TICK"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM ASSERT-LAST-VOICE-FRAME
           IF FUNCTION TRIM(DC-WS-PAYLOAD)
               NOT = '{"op":5,"d":{"speaking":1,"delay":0,"ssrc":4242}}'
               DISPLAY "voice-test: live speaking payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-JOIN-LEAVE.
           INITIALIZE DC-CONFIG
           MOVE "token" TO DC-BOT-TOKEN
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK
           MOVE 2 TO DC-CLIENT-STATE

           MOVE SPACES TO WS-ACTION
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-JOIN"
               USING DC-CLIENT
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-CLIENT-GW-COMMAND-QUEUED NOT = 1
               DISPLAY "voice-test: voice join queue flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "VOICE_STATE_UPDATE"
               DISPLAY "voice-test: voice join action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":"chan-1","self_mute":false,"self_deaf":false}}'
               DISPLAY "voice-test: voice join queued payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-ACTION
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-LEAVE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-GATEWAY-NEXT-PAYLOAD"
               USING DC-CLIENT
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "VOICE_STATE_UPDATE"
               DISPLAY "voice-test: voice leave action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":4,"d":{"guild_id":"guild-1","channel_id":null,"self_mute":false,"self_deaf":false}}'
               DISPLAY "voice-test: voice leave queued payload mismatch"
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

           PERFORM PREPARE-VOICE-SESSION-DESCRIPTION
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
           IF FUNCTION ORD(DC-VS-SECRET-KEY(1:1)) - 1 NOT = 1
               DISPLAY "voice-test: voice secret key first byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION ORD(DC-VS-SECRET-KEY(32:1)) - 1 NOT = 32
               DISPLAY "voice-test: voice secret key last byte mismatch"
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

       TEST-VOICE-NEXT-HEARTBEAT.
           MOVE 1 TO DC-VS-HEARTBEAT-DUE
           MOVE 0 TO DC-VS-HEARTBEAT-NONCE
           MOVE SPACES TO WS-PAYLOAD
           MOVE SPACES TO WS-ACTION
           CALL "DC-VOICE-NEXT-PAYLOAD"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "HEARTBEAT"
               DISPLAY "voice-test: next voice heartbeat mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-HEARTBEAT-NONCE NOT = 1
               DISPLAY "voice-test: voice heartbeat nonce mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-AWAITING-ACK NOT = 1
               DISPLAY "voice-test: voice heartbeat ack flag mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-HEARTBEAT-SCHEDULE.
           MOVE 1337 TO DC-VS-HEARTBEAT-INTERVAL
           MOVE 0 TO DC-VS-HEARTBEAT-NEXT-AT
           MOVE 0 TO DC-VS-HEARTBEAT-DUE
           MOVE 0 TO DC-VS-AWAITING-ACK
           MOVE 2000 TO WS-CLOCK-CS
           CALL "DC-HEARTBEAT-POLL"
               USING DC-VS-HEARTBEAT-INTERVAL
                     DC-VS-AWAITING-ACK
                     DC-VS-HEARTBEAT-NEXT-AT
                     DC-VS-HEARTBEAT-DUE
                     WS-CLOCK-CS
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-HEARTBEAT-NEXT-AT NOT = 2134
               DISPLAY "voice-test: voice heartbeat next-at mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-HEARTBEAT-DUE NOT = 0
               DISPLAY "voice-test: voice heartbeat due armed too early"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE 2134 TO WS-CLOCK-CS
           CALL "DC-HEARTBEAT-POLL"
               USING DC-VS-HEARTBEAT-INTERVAL
                     DC-VS-AWAITING-ACK
                     DC-VS-HEARTBEAT-NEXT-AT
                     DC-VS-HEARTBEAT-DUE
                     WS-CLOCK-CS
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-HEARTBEAT-DUE NOT = 1
               DISPLAY "voice-test: voice heartbeat due not triggered"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-HEARTBEAT-DEFER"
               USING DC-VS-HEARTBEAT-INTERVAL
                     DC-VS-HEARTBEAT-NEXT-AT
                     DC-VS-HEARTBEAT-DUE
                     WS-CLOCK-CS
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-HEARTBEAT-DUE NOT = 0
               DISPLAY "voice-test: voice heartbeat due not cleared"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-HEARTBEAT-NEXT-AT NOT = 2268
               DISPLAY "voice-test: voice heartbeat defer mismatch"
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

       TEST-VOICE-UDP-DISCOVERY-APPLY.
           INITIALIZE DC-VOICE-SESSION
           MOVE 0 TO DC-VS-COMMAND-QUEUED
           MOVE SPACES TO DC-VS-ENCRYPTION-MODE
           INITIALIZE DC-UDP-DISCOVERY
           MOVE "203.0.113.5" TO DC-UD-DISCOVERED-IP
           MOVE 65000 TO DC-UD-DISCOVERED-PORT
           CALL "DC-VOICE-UDP-DISCOVERY-APPLY"
               USING DC-VOICE-SESSION
                     DC-UDP-DISCOVERY
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-VS-DISCOVERED-IP) NOT = "203.0.113.5"
               DISPLAY "voice-test: voice discovered ip mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-DISCOVERED-PORT NOT = 65000
               DISPLAY "voice-test: voice discovered port mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-COMMAND-QUEUED NOT = 1
               DISPLAY "voice-test: voice select protocol queue mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           MOVE SPACES TO WS-ACTION
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-NEXT-PAYLOAD"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "SELECT_PROTOCOL"
               DISPLAY "voice-test: voice select protocol action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":1,"d":{"protocol":"udp","data":{"address":"203.0.113.5","port":65000,"mode":"aead_xchacha20_poly1305_rtpsize"}}}'
               DISPLAY "voice-test: voice select protocol queued payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-SEND-FRAME.
           INITIALIZE DC-VOICE-SESSION
           MOVE 1 TO DC-VS-READY-FLAG
           MOVE WS-VOICE-UDP-HOST TO DC-VS-IP
           MOVE WS-VOICE-UDP-PORT TO DC-VS-PORT
           MOVE WS-VOICE-DISCOVERED-IP TO DC-VS-DISCOVERED-IP
           MOVE WS-VOICE-DISCOVERED-PORT TO DC-VS-DISCOVERED-PORT

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-SET-RESPONSE"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-UDP-SESSION
           MOVE WS-VOICE-UDP-HOST TO DC-UDP-REMOTE-HOST
           MOVE WS-VOICE-UDP-PORT TO DC-UDP-REMOTE-PORT
           MOVE WS-VOICE-DISCOVERED-IP TO DC-UDP-LOCAL-IP
           MOVE WS-VOICE-DISCOVERED-PORT TO DC-UDP-LOCAL-PORT
           CALL "DC-UDP-OPEN"
               USING DC-UDP-SESSION
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-UDP-HANDLE TO DC-VS-UDP-HANDLE
           MOVE 1 TO DC-VS-UDP-READY-FLAG

           INITIALIZE DC-RTP-STATE
           MOVE 1 TO DC-RTP-SEQUENCE
           MOVE 960 TO DC-RTP-TIMESTAMP
           MOVE 4242 TO DC-RTP-SSRC
           MOVE 960 TO DC-RTP-FRAME-SAMPLES
           CALL "DC-OPUS-BUILD-SILENCE"
               USING DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-VOICE-SEND-FRAME"
               USING DC-VOICE-SESSION
                     DC-RTP-STATE
                     DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-RTP-SEQUENCE NOT = 2
               DISPLAY "voice-test: voice send frame sequence mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-RTP-TIMESTAMP NOT = 1920
               DISPLAY "voice-test: voice send frame timestamp mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-LENGTH NOT = 15
               DISPLAY "voice-test: voice send frame length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UDP-PACKET-DATA(1:1) NOT = X"80"
               DISPLAY "voice-test: voice send frame RTP byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UDP-PACKET-DATA(2:1) NOT = X"78"
               DISPLAY "voice-test: voice send frame payload byte mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UDP-PACKET-DATA(13:3) NOT = DC-OPUS-DATA(1:3)
               DISPLAY "voice-test: voice send frame opus payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           PERFORM PREPARE-VOICE-SESSION-DESCRIPTION
           CALL "DC-VOICE-HANDLE-PAYLOAD"
               USING DC-VOICE-SESSION
                     WS-JSON
                     DC-RESULT
           PERFORM CHECK-OK

           CALL "DC-VOICE-SEND-FRAME"
               USING DC-VOICE-SESSION
                     DC-RTP-STATE
                     DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-RTP-SEQUENCE NOT = 3
               DISPLAY "voice-test: encrypted send sequence mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-RTP-TIMESTAMP NOT = 2880
               DISPLAY "voice-test: encrypted send timestamp mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-MEDIA-NONCE NOT = 1
               DISPLAY "voice-test: encrypted send nonce mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-LENGTH NOT = 35
               DISPLAY "voice-test: encrypted send length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-UDP-PACKET-DATA(1:35)
               NOT = X"807800020000078000001092AD868ADF913373B6916738BC5D3F662C59EAB600000000"
               DISPLAY "voice-test: encrypted send packet mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-VOICE-SEND-FRAME"
               USING DC-VOICE-SESSION
                     DC-RTP-STATE
                     DC-OPUS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-VS-MEDIA-NONCE NOT = 2
               DISPLAY "voice-test: encrypted send second nonce mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-UDP-PACKET
           CALL "DC-UDP-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-UDP-PACKET-DATA(1:35)
               NOT = X"8078000300000B4000001092DCF9E2925E8114390CDD85CED58CFF50F9437E00000001"
               DISPLAY "voice-test: encrypted send second packet mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           CALL "DC-UDP-CLOSE"
               USING DC-UDP-SESSION
                     DC-RESULT
           PERFORM CHECK-OK.

       TEST-VOICE-RESUME-BUILD.
           MOVE "guild-1" TO DC-VS-GUILD-ID
           MOVE "voice-sess" TO DC-VS-SESSION-ID
           MOVE "voice-token" TO DC-VS-TOKEN
           MOVE SPACES TO WS-PAYLOAD
           CALL "DC-VOICE-RESUME-BUILD"
               USING DC-VOICE-SESSION WS-PAYLOAD DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-PAYLOAD)
               NOT = '{"op":7,"d":{"server_id":"guild-1","session_id":"voice-sess","token":"voice-token"}}'
               DISPLAY "voice-test: voice resume payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-VOICE-NEXT-RESUME.
           MOVE "guild-1" TO DC-VS-GUILD-ID
           MOVE "voice-sess" TO DC-VS-SESSION-ID
           MOVE "voice-token" TO DC-VS-TOKEN
           MOVE 1 TO DC-VS-RESUME-REQUESTED
           MOVE SPACES TO WS-PAYLOAD
           MOVE SPACES TO WS-ACTION
           CALL "DC-VOICE-NEXT-PAYLOAD"
               USING DC-CLIENT
                     DC-VOICE-SESSION
                     WS-ACTION
                     WS-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-ACTION) NOT = "RESUME"
               DISPLAY "voice-test: next voice resume mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-VS-RESUME-REQUESTED NOT = 0
               DISPLAY "voice-test: voice resume flag not cleared"
               ADD 1 TO WS-FAILURES
           END-IF.

       INIT-LIVE-VOICE-SESSION.
           INITIALIZE DC-CONFIG
           MOVE "token" TO DC-BOT-TOKEN
           MOVE 8 TO DC-VOICE-GATEWAY-VERSION
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG DC-CLIENT DC-RESULT
           PERFORM CHECK-OK
           MOVE "user-1" TO DC-CLIENT-USER-ID
           CALL "DC-VOICE-SESSION-INIT"
               USING DC-VOICE-SESSION
                     WS-GUILD-ID
                     WS-CHANNEL-ID
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE '{"d":{"session_id":"voice-sess"}}' TO WS-JSON
           CALL "DC-VOICE-APPLY-STATE-UPDATE"
               USING WS-JSON DC-VOICE-SESSION DC-RESULT
           PERFORM CHECK-OK
           MOVE '{"d":{"token":"voice-token","endpoint":"voice.example.test"}}'
               TO WS-JSON
           CALL "DC-VOICE-APPLY-SERVER-UPDATE"
               USING WS-JSON DC-VOICE-SESSION DC-RESULT
           PERFORM CHECK-OK
           MOVE "dGhlIHNhbXBsZSBub25jZQ==" TO DC-VS-WS-SEC-KEY
           PERFORM PREPARE-LIVE-VOICE-FIXTURES.

       PREPARE-LIVE-VOICE-FIXTURES.
           MOVE SPACES TO WS-ACCEPT
           CALL "DC-WS-BUILD-ACCEPT"
               USING DC-VS-WS-SEC-KEY(1:24)
                     WS-ACCEPT
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 101 Switching Protocols" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Upgrade: websocket" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Connection: Upgrade" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Sec-WebSocket-Accept: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-ACCEPT) DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-VOICE-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-VOICE-UDP-DISCOVERY-FIXTURE.
           INITIALIZE DC-UDP-PACKET
           MOVE LOW-VALUE TO DC-UDP-PACKET-DATA
           MOVE 74 TO DC-UDP-PACKET-LENGTH
           MOVE FUNCTION CHAR(3) TO DC-UDP-PACKET-DATA(2:1)
           MOVE FUNCTION CHAR(71) TO DC-UDP-PACKET-DATA(4:1)
           MOVE "198.51.100.10" TO DC-UDP-PACKET-DATA(9:13)
           MOVE FUNCTION CHAR(243) TO DC-UDP-PACKET-DATA(73:1)
           MOVE FUNCTION CHAR(49) TO DC-UDP-PACKET-DATA(74:1)
           CALL "DC-UDP-MOCK-SET-RESPONSE"
               USING WS-VOICE-UDP-HOST
                     WS-VOICE-UDP-PORT
                     DC-UDP-PACKET
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-VOICE-SESSION-DESCRIPTION.
           MOVE SPACES TO WS-JSON
           STRING
               '{"op":4,"d":{"mode":"aead_xchacha20_poly1305_rtpsize",' 
                   DELIMITED BY SIZE
               '"secret_key":[1,2,3,4,5,6,7,8,' DELIMITED BY SIZE
               '9,10,11,12,13,14,15,16,' DELIMITED BY SIZE
               '17,18,19,20,21,22,23,24,' DELIMITED BY SIZE
               '25,26,27,28,29,30,31,32]},"seq":10}'
                   DELIMITED BY SIZE
               INTO WS-JSON
           END-STRING.

       INJECT-VOICE-TEXT-FRAME.
           INITIALIZE DC-WS-FRAME
           INITIALIZE DC-WS-BUFFER
           MOVE 1 TO DC-WS-FIN-FLAG
           MOVE 1 TO DC-WS-OPCODE
           MOVE 0 TO DC-WS-MASK-FLAG
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-JSON TRAILING))
               TO DC-WS-PAYLOAD-LENGTH
           IF DC-WS-PAYLOAD-LENGTH > 0
               MOVE WS-JSON(1:DC-WS-PAYLOAD-LENGTH)
                   TO DC-WS-PAYLOAD(1:DC-WS-PAYLOAD-LENGTH)
           END-IF
           CALL "DC-WS-ENCODE-FRAME"
               USING DC-WS-FRAME DC-WS-BUFFER DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-WS-BUFFER-LENGTH TO DC-VS-WS-INBOUND-BUFFER-LENGTH
           MOVE DC-WS-BUFFER-DATA TO DC-VS-WS-INBOUND-BUFFER.

       ASSERT-LAST-VOICE-FRAME.
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-VOICE-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE DC-HTTP-BUFFER-LENGTH TO DC-WS-BUFFER-LENGTH
           MOVE DC-HTTP-BUFFER-DATA TO DC-WS-BUFFER-DATA
           INITIALIZE DC-WS-FRAME
           CALL "DC-WS-DECODE-FRAME"
               USING DC-WS-BUFFER
                     DC-WS-FRAME
                     DC-RESULT
           PERFORM CHECK-OK.

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
