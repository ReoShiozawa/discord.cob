       IDENTIFICATION DIVISION.
       PROGRAM-ID. INTERACTION-TEST.
       *> JP: interaction parse/dispatch/reply の広い経路をまとめて検証する統合寄りテストです。
       *> JP: 補助 handler program も同居させ、custom command/component/modal の流れまで確認します。
       *> EN: Broad integration-style test for interaction parsing, dispatch, and reply flows.
       *> EN: Helper handler programs live here too so custom command/component/modal flows can be checked end to end.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-event.cpy".
       COPY "discord-music.cpy".
       COPY "discord-rtp.cpy".
       COPY "discord-opus.cpy".
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".
       01 WS-RAW-PLAY-JSON PIC X(8192).
       01 WS-RAW-QUEUE-JSON PIC X(8192).
       01 WS-RAW-NOWPLAYING-JSON PIC X(8192).
       01 WS-RAW-REMOVE-JSON PIC X(8192).
       01 WS-RAW-CLEARQUEUE-JSON PIC X(8192).
       01 WS-RAW-PAUSE-JSON PIC X(8192).
       01 WS-RAW-RESUME-JSON PIC X(8192).
       01 WS-RAW-MUSIC-SKIP-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-PAUSE-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-RESUME-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-QUEUE-VIEW-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-QUEUE-RM1-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-QUEUE-CLEAR-BUTTON-JSON PIC X(8192).
       01 WS-RAW-MUSIC-NP-VIEW-BUTTON-JSON PIC X(8192).
       01 WS-RAW-CUSTOM-CMD-JSON PIC X(8192).
       01 WS-RAW-MISSING-OPTION-JSON PIC X(8192).
       01 WS-RAW-BUTTON-JSON PIC X(8192).
       01 WS-RAW-SELECT-JSON PIC X(8192).
       01 WS-RAW-MODAL-JSON PIC X(8192).
       01 WS-WRAPPED-STOP-JSON PIC X(8192).
       01 WS-REPLY-PAYLOAD PIC X(8192).
       01 WS-EXPECTED-PLAY-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Queued: build/test/sample-opus.ogg"}}'.
       01 WS-EXPECTED-QUEUE-REPLY PIC X(8192).
       01 WS-EXPECTED-NOWPLAYING-REPLY PIC X(8192)
           VALUE SPACES.
       01 WS-EXPECTED-NOWPLAYING-COMPONENT-REPLY PIC X(8192).
       01 WS-EXPECTED-NOWPLAYING-UPDATE PIC X(8192).
       01 WS-EXPECTED-QUEUE-EMPTY-UPDATE PIC X(8192).
       01 WS-EXPECTED-QUEUE-VIEW-UPDATE PIC X(8192).
       01 WS-EXPECTED-REMOVE-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Removed queue item 1."}}'.
       01 WS-EXPECTED-CLEARQUEUE-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Cleared queued tracks."}}'.
       01 WS-EXPECTED-PAUSE-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Paused playback."}}'.
       01 WS-EXPECTED-RESUME-REPLY PIC X(8192)
           VALUE '{"type":4,"data":{"content":"Resumed playback."}}'.
       01 WS-EXPECTED-MUSIC-SKIP-UPDATE PIC X(8192)
           VALUE SPACES.
       01 WS-EXPECTED-MUSIC-PAUSE-UPDATE PIC X(8192).
       01 WS-EXPECTED-MUSIC-RESUME-UPDATE PIC X(8192).
       01 WS-EXPECTED-EMBED-REPLY PIC X(8192).
       01 WS-EXPECTED-EMBED-COMPONENT-REPLY PIC X(8192).
       01 WS-EXPECTED-EMBED-UPDATE PIC X(8192).
       01 WS-EXPECTED-EMBED-UPDATE-COMPONENT-REPLY PIC X(8192).
       01 WS-EXPECTED-MODAL-REPLY PIC X(8192).
       01 WS-EXPECTED-UPDATE-REPLY PIC X(8192).
       01 WS-EXPECTED-COMPONENT-REPLY PIC X(8192).
       01 WS-EXPECTED-UPDATE-COMPONENT-REPLY PIC X(8192).
       01 WS-DEFERRED-PAYLOAD PIC X(8192) VALUE '{"type":5}'.
       01 WS-FOLLOWUP-PAYLOAD PIC X(8192) VALUE '{"content":"Later"}'.
       01 WS-FOLLOWUP-MESSAGE-JSON PIC X(8192)
           VALUE '{"id":"msg-1","content":"Later"}'.
       01 WS-EDIT-PAYLOAD PIC X(8192) VALUE '{"content":"Edited later"}'.
       01 WS-ORIGINAL-EDIT-PAYLOAD PIC X(8192)
           VALUE '{"content":"Edited original"}'.
       01 WS-ORIGINAL-MESSAGE-JSON PIC X(8192)
           VALUE '{"id":"orig-1","content":"Original"}'.
       01 WS-RAW-RESPONSE PIC X(8192).
       01 WS-DISCORD-HOST PIC X(256) VALUE "discord.com".
       01 WS-TLS-PORT PIC 9(5) COMP-5 VALUE 443.
       01 WS-SOURCE-PATH PIC X(512) VALUE "build/test/sample-opus.ogg".
       01 WS-GUILD-ID PIC X(32) VALUE "guild-1".
       01 WS-MESSAGE-ID PIC X(32) VALUE "msg-1".
       01 WS-SECRET-TEXT PIC X(2000) VALUE "Secret".
       01 WS-LATER-TEXT PIC X(2000) VALUE "Later".
       01 WS-UPDATE-TEXT PIC X(2000) VALUE "Updated from button.".
       01 WS-SAVED-TEXT PIC X(2000) VALUE "Saved".
       01 WS-VALUE-NAME PIC X(128).
       01 WS-CUSTOM-CMD-NAME PIC X(128) VALUE "/panel".
       01 WS-COMPONENT-ID PIC X(128) VALUE "btn:skip".
       01 WS-MODAL-ID PIC X(128) VALUE "feedback-modal".
       01 WS-MODAL-TITLE PIC X(128) VALUE "Feedback".
       01 WS-EMBED-TITLE PIC X(128) VALUE "Status".
       01 WS-EMBED-COLOR PIC 9(10) COMP-5 VALUE 16711680.
       01 WS-CMD-HANDLER PIC X(64) VALUE "TEST-IA-CMD-HANDLER".
       01 WS-COMP-HANDLER PIC X(64) VALUE "TEST-IA-COMP-HANDLER".
       01 WS-MODAL-HANDLER PIC X(64) VALUE "TEST-IA-MODAL-HANDLER".
       01 WS-CMD-HANDLER-ALT PIC X(64) VALUE "TEST-IA-CMD-HANDLER-ALT".
       01 WS-COMP-HANDLER-ALT PIC X(64) VALUE "TEST-IA-COMP-HANDLER-ALT".
       01 WS-MODAL-HANDLER-ALT PIC X(64) VALUE "TEST-IA-MODAL-HANDLER-ALT".
       01 WS-MODAL-COMPONENTS-JSON PIC X(4096).
       01 WS-COMPONENT-ROW-JSON PIC X(4096).
       01 WS-MUSIC-CONTROL-ROW-JSON PIC X(4096).
       01 WS-MUSIC-QUEUE-ROW-JSON PIC X(4096).
       01 WS-MUSIC-QUEUE-ROW-DISABLED-JSON PIC X(4096).
       01 WS-COMMAND PIC X(4096).
       01 WS-BODY-LEN-TEXT PIC Z(9).
       01 WS-BODY-START PIC 9(5) COMP-5.
       01 WS-PATH PIC X(128).
       01 WS-TEXT PIC X(512).
       01 WS-MESSAGE-ID-OUT PIC X(32).
       01 WS-POS PIC 9(5) COMP-5.
       01 WS-FAILURES PIC 9(4) COMP-5 VALUE 0.
       01 WS-EXIT-CODE PIC 9(4) COMP-5 VALUE 0.

       PROCEDURE DIVISION.
       MAIN.
           PERFORM WRITE-FIXTURE
           PERFORM INIT-CLIENT
           PERFORM BUILD-JSON-FIXTURES
           PERFORM BUILD-EXPECTED-PAYLOADS
           PERFORM TEST-PARSE-RAW
           PERFORM TEST-PARSE-WRAPPED
           PERFORM TEST-PARSE-COMPONENT
           PERFORM TEST-PARSE-MODAL
           PERFORM TEST-HANDLE-PLAY
           PERFORM TEST-HANDLE-QUEUE
           PERFORM TEST-HANDLE-NOWPLAYING
           PERFORM TEST-HANDLE-NOWPLAYING-PLAYING
           PERFORM TEST-HANDLE-REMOVE
           PERFORM TEST-HANDLE-CLEARQUEUE
           PERFORM TEST-HANDLE-PAUSE
           PERFORM TEST-HANDLE-RESUME
           PERFORM TEST-HANDLE-MUSIC-SKIP-BUTTON
           PERFORM TEST-HANDLE-MUSIC-PAUSE-BUTTON
           PERFORM TEST-HANDLE-MUSIC-RESUME-BUTTON
           PERFORM TEST-HANDLE-MUSIC-QUEUE-VIEW-BUTTON
           PERFORM TEST-HANDLE-MUSIC-QUEUE-RM1-BUTTON
           PERFORM TEST-HANDLE-MUSIC-QUEUE-CLEAR-BUTTON
           PERFORM TEST-HANDLE-MUSIC-NP-VIEW-BUTTON
           PERFORM TEST-HANDLE-ERROR
           PERFORM TEST-HANDLE-EVENT
           PERFORM TEST-BUILD-DEFERRED
           PERFORM TEST-BUILD-EPHEMERAL
           PERFORM TEST-BUILD-FOLLOWUP
           PERFORM TEST-BUILD-FOLLOWUP-WAIT
           PERFORM TEST-BUILD-FOLLOWUP-GET
           PERFORM TEST-BUILD-FOLLOWUP-EDIT
           PERFORM TEST-BUILD-FOLLOWUP-DELETE
           PERFORM TEST-BUILD-ORIGINAL-GET
           PERFORM TEST-BUILD-ORIGINAL-EDIT
           PERFORM TEST-BUILD-ORIGINAL-DELETE
           PERFORM TEST-BUILD-UPDATE
           PERFORM TEST-BUILD-UPDATE-COMPONENT
           PERFORM TEST-BUILD-COMPONENT
           PERFORM TEST-BUILD-EMBED
           PERFORM TEST-BUILD-EMBED-COMPONENT
           PERFORM TEST-BUILD-UPDATE-EMBED
           PERFORM TEST-BUILD-UPDATE-EMBED-COMPONENT
           PERFORM TEST-BUILD-MODAL
           PERFORM TEST-CUSTOM-COMMAND-HANDLER
           PERFORM TEST-CUSTOM-COMPONENT-HANDLER
           PERFORM TEST-CUSTOM-MODAL-HANDLER
           PERFORM TEST-CUSTOM-HANDLER-REPLACE
           PERFORM TEST-CALLBACK-REPLY
           PERFORM TEST-DEFER
           PERFORM TEST-FOLLOWUP
           PERFORM TEST-FOLLOWUP-WAIT
           PERFORM TEST-FOLLOWUP-WAIT-ID
           PERFORM TEST-FOLLOWUP-GET
           PERFORM TEST-GET-MESSAGE-ID
           PERFORM TEST-FOLLOWUP-EDIT
           PERFORM TEST-FOLLOWUP-EDIT-MSG
           PERFORM TEST-FOLLOWUP-WAIT-EDIT
           PERFORM TEST-FOLLOWUP-DELETE
           PERFORM TEST-FOLLOWUP-DELETE-MSG
           PERFORM TEST-FOLLOWUP-WAIT-DELETE
           PERFORM TEST-ORIGINAL-GET
           PERFORM TEST-DISPATCH-HANDLER-REPLY
           PERFORM FINISH-TEST.

       WRITE-FIXTURE.
           MOVE SPACES TO WS-COMMAND
           STRING
               "mkdir -p build/test && printf '" DELIMITED BY SIZE
               "\117\147\147\123\000\002" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\001\023OpusHead\001\002\000\000\200\273\000\000\000"
                   DELIMITED BY SIZE
               "\000\000" DELIMITED BY SIZE
               "\117\147\147\123\000\000" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\001\020OpusTags\000\000\000\000\000\000\000\000"
                   DELIMITED BY SIZE
               "\117\147\147\123\000\004" DELIMITED BY SIZE
               "\000\000\000\000\000\000\000\000" DELIMITED BY SIZE
               "\001\000\000\000" DELIMITED BY SIZE
               "\002\000\000\000" DELIMITED BY SIZE
               "\000\000\000\000" DELIMITED BY SIZE
               "\002\003\003ABCDEF" DELIMITED BY SIZE
               "' > " DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               INTO WS-COMMAND
           END-STRING
           CALL "SYSTEM" USING WS-COMMAND END-CALL.

       INIT-CLIENT.
           INITIALIZE DC-CONFIG
           CALL "DC-CLIENT-INIT"
               USING DC-CONFIG
                     DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE 2 TO DC-CLIENT-STATE
           MOVE "app-1" TO DC-CLIENT-ID
           MOVE "user-1" TO DC-CLIENT-USER-ID
           CALL "DC-MUSIC-INTERACTIONS-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK.

       BUILD-JSON-FIXTURES.
           MOVE SPACES TO WS-RAW-PLAY-JSON
           STRING
               '{"id":"int-1","token":"tok-1","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},' DELIMITED BY SIZE
               '"data":{"name":"/play","options":[{"name":"file","value":"'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '"}]}}' DELIMITED BY SIZE
               INTO WS-RAW-PLAY-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-CUSTOM-CMD-JSON
           STRING
               '{"id":"int-9","token":"tok-9","type":2,"guild_id":"guild-9",'
                   DELIMITED BY SIZE
               '"channel_id":"text-9","member":{"user":{"id":"user-9"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/panel"}}' DELIMITED BY SIZE
               INTO WS-RAW-CUSTOM-CMD-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-QUEUE-JSON
           STRING
               '{"id":"int-6","token":"tok-6","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/queue"}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-QUEUE-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-NOWPLAYING-JSON
           STRING
               '{"id":"int-7","token":"tok-7","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/nowplaying"}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-NOWPLAYING-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-REMOVE-JSON
           STRING
               '{"id":"int-8","token":"tok-8","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/remove","options":[{"name":"index","value":1}]}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-REMOVE-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-CLEARQUEUE-JSON
           STRING
               '{"id":"int-9","token":"tok-9","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/clearqueue"}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-CLEARQUEUE-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-PAUSE-JSON
           STRING
               '{"id":"int-10","token":"tok-10","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/pause"}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-PAUSE-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-RESUME-JSON
           STRING
               '{"id":"int-11","token":"tok-11","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/resume"}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-RESUME-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-SKIP-BUTTON-JSON
           STRING
               '{"id":"int-12","token":"tok-12","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:skip","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-SKIP-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-PAUSE-BUTTON-JSON
           STRING
               '{"id":"int-13","token":"tok-13","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:pause","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-PAUSE-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-RESUME-BUTTON-JSON
           STRING
               '{"id":"int-14","token":"tok-14","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:resume","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-RESUME-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-QUEUE-VIEW-BUTTON-JSON
           STRING
               '{"id":"int-15","token":"tok-15","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:queue:view","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-QUEUE-VIEW-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-QUEUE-RM1-BUTTON-JSON
           STRING
               '{"id":"int-16","token":"tok-16","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:queue:rm1","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-QUEUE-RM1-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-QUEUE-CLEAR-BUTTON-JSON
           STRING
               '{"id":"int-17","token":"tok-17","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:queue:clear","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-QUEUE-CLEAR-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MUSIC-NP-VIEW-BUTTON-JSON
           STRING
               '{"id":"int-18","token":"tok-18","type":3,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"music:np:view","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-MUSIC-NP-VIEW-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MISSING-OPTION-JSON
           STRING
               '{"id":"int-1","token":"tok-1","type":2,"guild_id":"guild-1",'
                   DELIMITED BY SIZE
               '"channel_id":"text-1","member":{"user":{"id":"user-1"},'
                   DELIMITED BY SIZE
               '"voice":{"channel_id":"voice-1"}},' DELIMITED BY SIZE
               '"data":{"name":"/play"}}' DELIMITED BY SIZE
               INTO WS-RAW-MISSING-OPTION-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-BUTTON-JSON
           STRING
               '{"id":"int-3","token":"tok-3","type":3,"guild_id":"guild-3",'
                   DELIMITED BY SIZE
               '"channel_id":"text-3","member":{"user":{"id":"user-3"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"btn:skip","component_type":2}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-BUTTON-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-SELECT-JSON
           STRING
               '{"id":"int-4","token":"tok-4","type":3,"guild_id":"guild-4",'
                   DELIMITED BY SIZE
               '"channel_id":"text-4","member":{"user":{"id":"user-4"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"genre","component_type":3,'
                   DELIMITED BY SIZE
               '"values":["jazz","fusion"]}}'
                   DELIMITED BY SIZE
               INTO WS-RAW-SELECT-JSON
           END-STRING

           MOVE SPACES TO WS-RAW-MODAL-JSON
           STRING
               '{"id":"int-5","token":"tok-5","type":5,"guild_id":"guild-5",'
                   DELIMITED BY SIZE
               '"channel_id":"text-5","member":{"user":{"id":"user-5"}},'
                   DELIMITED BY SIZE
               '"data":{"custom_id":"feedback-modal","components":['
                   DELIMITED BY SIZE
               '{"type":1,"components":[{"type":4,"custom_id":"notes",'
                   DELIMITED BY SIZE
               '"value":"hello world"}]}]}}' DELIMITED BY SIZE
               INTO WS-RAW-MODAL-JSON
           END-STRING

           MOVE SPACES TO WS-WRAPPED-STOP-JSON
           STRING
               '{"op":0,"t":"INTERACTION_CREATE","s":77,"d":{' 
                   DELIMITED BY SIZE
               '"id":"int-2","token":"tok-2","type":2,"guild_id":"guild-2",'
                   DELIMITED BY SIZE
               '"channel_id":"text-2","member":{"user":{"id":"user-2"}},'
                   DELIMITED BY SIZE
               '"data":{"name":"/stop"}}}' DELIMITED BY SIZE
               INTO WS-WRAPPED-STOP-JSON
           END-STRING.

       BUILD-EXPECTED-PAYLOADS.
           MOVE SPACES TO WS-MODAL-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[{"type":4,' DELIMITED BY SIZE
               '"custom_id":"notes","label":"Notes","style":1}]}]'
                   DELIMITED BY SIZE
               INTO WS-MODAL-COMPONENTS-JSON
           END-STRING

           MOVE SPACES TO WS-COMPONENT-ROW-JSON
           STRING
               '[{"type":1,"components":[{"type":2,' DELIMITED BY SIZE
               '"style":2,"label":"Done","custom_id":"done"}]}]'
                   DELIMITED BY SIZE
               INTO WS-COMPONENT-ROW-JSON
           END-STRING

           MOVE SPACES TO WS-MUSIC-CONTROL-ROW-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Skip",'
                   DELIMITED BY SIZE
               '"custom_id":"music:skip"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Pause",'
                   DELIMITED BY SIZE
               '"custom_id":"music:pause"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Resume",'
                   DELIMITED BY SIZE
               '"custom_id":"music:resume"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Queue",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO WS-MUSIC-CONTROL-ROW-JSON
           END-STRING

           MOVE SPACES TO WS-MUSIC-QUEUE-ROW-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Remove First",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:rm1"},' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Clear",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:clear"},' DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Now Playing",'
                   DELIMITED BY SIZE
               '"custom_id":"music:np:view"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Refresh",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO WS-MUSIC-QUEUE-ROW-JSON
           END-STRING

           MOVE SPACES TO WS-MUSIC-QUEUE-ROW-DISABLED-JSON
           STRING
               '[{"type":1,"components":[' DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Remove First",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:rm1","disabled":true},'
                   DELIMITED BY SIZE
               '{"type":2,"style":4,"label":"Clear",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:clear","disabled":true},'
                   DELIMITED BY SIZE
               '{"type":2,"style":1,"label":"Now Playing",'
                   DELIMITED BY SIZE
               '"custom_id":"music:np:view"},' DELIMITED BY SIZE
               '{"type":2,"style":2,"label":"Refresh",'
                   DELIMITED BY SIZE
               '"custom_id":"music:queue:view"}]}]' DELIMITED BY SIZE
               INTO WS-MUSIC-QUEUE-ROW-DISABLED-JSON
           END-STRING

           MOVE SPACES TO WS-EXPECTED-MODAL-REPLY
           STRING
               '{"type":9,"data":{"custom_id":"feedback-modal",'
                   DELIMITED BY SIZE
               '"title":"Feedback","components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MODAL-COMPONENTS-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-MODAL-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-UPDATE-REPLY
           STRING
               '{"type":7,"data":{"content":"Updated from button."}}'
                   DELIMITED BY SIZE
               INTO WS-EXPECTED-UPDATE-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-UPDATE-COMPONENT-REPLY
           STRING
               '{"type":7,"data":{"content":"Saved","components":'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-COMPONENT-ROW-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-UPDATE-COMPONENT-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-COMPONENT-REPLY
           STRING
               '{"type":4,"data":{"content":"Saved","components":'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-COMPONENT-ROW-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-COMPONENT-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-QUEUE-REPLY
           STRING
               '{"type":4,"data":{"embeds":[{"title":"Queue","description":"'
                   DELIMITED BY SIZE
               'Queue (1): 1. '
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '","color":3447003}],"components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-QUEUE-ROW-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-QUEUE-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-NOWPLAYING-REPLY
           STRING
               '{"type":4,"data":{"embeds":[{"title":"Now Playing",'
                   DELIMITED BY SIZE
               '"description":"Up next: ' DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '","color":5814783}]}}' DELIMITED BY SIZE
               INTO WS-EXPECTED-NOWPLAYING-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-NOWPLAYING-COMPONENT-REPLY
           STRING
               '{"type":4,"data":{"embeds":[{"title":"Now Playing",'
                   DELIMITED BY SIZE
               '"description":"Now playing: ' DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '","color":5814783}],"components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-CONTROL-ROW-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-NOWPLAYING-COMPONENT-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-NOWPLAYING-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Now Playing",'
                   DELIMITED BY SIZE
               '"description":"Now playing: ' DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '","color":5814783}],"components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-CONTROL-ROW-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-NOWPLAYING-UPDATE
           END-STRING

           MOVE SPACES TO WS-EXPECTED-QUEUE-EMPTY-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Queue",'
                   DELIMITED BY SIZE
               '"description":"Queue is empty.","color":3447003}],'
                   DELIMITED BY SIZE
               '"components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-QUEUE-ROW-DISABLED-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-QUEUE-EMPTY-UPDATE
           END-STRING

           MOVE SPACES TO WS-EXPECTED-QUEUE-VIEW-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Queue",'
                   DELIMITED BY SIZE
               '"description":"Now playing: '
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               ' | Queue is empty.","color":3447003}],"components":'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-QUEUE-ROW-DISABLED-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-QUEUE-VIEW-UPDATE
           END-STRING

           MOVE SPACES TO WS-EXPECTED-MUSIC-SKIP-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Now Playing",'
                   DELIMITED BY SIZE
               '"description":"Nothing is playing right now.",'
                   DELIMITED BY SIZE
               '"color":5814783}]}}' DELIMITED BY SIZE
               INTO WS-EXPECTED-MUSIC-SKIP-UPDATE
           END-STRING

           MOVE SPACES TO WS-EXPECTED-MUSIC-PAUSE-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Now Playing",'
                   DELIMITED BY SIZE
               '"description":"Now playing: ' DELIMITED BY SIZE
               FUNCTION TRIM(WS-SOURCE-PATH) DELIMITED BY SIZE
               '","color":5814783}],"components":' DELIMITED BY SIZE
               FUNCTION TRIM(WS-MUSIC-CONTROL-ROW-JSON)
                   DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-MUSIC-PAUSE-UPDATE
           END-STRING

           MOVE WS-EXPECTED-MUSIC-PAUSE-UPDATE
               TO WS-EXPECTED-MUSIC-RESUME-UPDATE.

           MOVE SPACES TO WS-EXPECTED-EMBED-REPLY
           STRING
               '{"type":4,"data":{"embeds":[{"title":"Status",'
                   DELIMITED BY SIZE
               '"description":"Saved","color":16711680}]}}'
                   DELIMITED BY SIZE
               INTO WS-EXPECTED-EMBED-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-EMBED-COMPONENT-REPLY
           STRING
               '{"type":4,"data":{"embeds":[{"title":"Status",'
                   DELIMITED BY SIZE
               '"description":"Saved","color":16711680}],"components":'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-COMPONENT-ROW-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-EMBED-COMPONENT-REPLY
           END-STRING

           MOVE SPACES TO WS-EXPECTED-EMBED-UPDATE
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Status",'
                   DELIMITED BY SIZE
               '"description":"Saved","color":16711680}]}}'
                   DELIMITED BY SIZE
               INTO WS-EXPECTED-EMBED-UPDATE
           END-STRING

           MOVE SPACES TO WS-EXPECTED-EMBED-UPDATE-COMPONENT-REPLY
           STRING
               '{"type":7,"data":{"embeds":[{"title":"Status",'
                   DELIMITED BY SIZE
               '"description":"Saved","color":16711680}],"components":'
                   DELIMITED BY SIZE
               FUNCTION TRIM(WS-COMPONENT-ROW-JSON) DELIMITED BY SIZE
               "}}" DELIMITED BY SIZE
               INTO WS-EXPECTED-EMBED-UPDATE-COMPONENT-REPLY
           END-STRING.

       TEST-PARSE-RAW.
           MOVE "$.id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.token" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.data.name" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.member.voice.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE "$.data.options" TO WS-PATH
           MOVE 0 TO WS-POS
           CALL "DC-JSON-LOCATE-PATH"
               USING WS-RAW-PLAY-JSON
                     WS-PATH
                     WS-POS
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-INTERACTION-ID) NOT = "int-1"
               DISPLAY "interaction-test: raw id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) NOT = "tok-1"
               DISPLAY "interaction-test: raw token mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-INTERACTION-TYPE NOT = 2
               DISPLAY "interaction-test: raw type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-GUILD-ID) NOT = "guild-1"
               DISPLAY "interaction-test: raw guild mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) NOT = "voice-1"
               DISPLAY "interaction-test: raw voice channel mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-NAME) NOT = "/play"
               DISPLAY "interaction-test: raw command mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-COMMAND-OPTION-COUNT NOT = 1
               DISPLAY "interaction-test: raw option count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-OPTION-NAME(1)) NOT = "file"
               DISPLAY "interaction-test: raw option name mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-OPTION-VALUE(1))
               NOT = FUNCTION TRIM(WS-SOURCE-PATH)
               DISPLAY "interaction-test: raw option value mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PARSE-WRAPPED.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-WRAPPED-STOP-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-INTERACTION-ID) NOT = "int-2"
               DISPLAY "interaction-test: wrapped id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-INTERACTION-TYPE NOT = 2
               DISPLAY "interaction-test: wrapped type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-COMMAND-NAME) NOT = "/stop"
               DISPLAY "interaction-test: wrapped command mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-GUILD-ID) NOT = "guild-2"
               DISPLAY "interaction-test: wrapped guild mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PARSE-COMPONENT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-BUTTON-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-INTERACTION-TYPE NOT = 3
               DISPLAY "interaction-test: button type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-CUSTOM-ID) NOT = "btn:skip"
               DISPLAY "interaction-test: button custom id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-INTERACTION-COMPONENT-TYPE NOT = 2
               DISPLAY "interaction-test: button component type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-SELECT-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-INTERACTION-VALUE-COUNT NOT = 2
               DISPLAY "interaction-test: select value count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           MOVE "genre" TO WS-VALUE-NAME
           MOVE SPACES TO WS-TEXT
           CALL "DC-INTERACTION-GET-VALUE"
               USING DC-INTERACTION
                     WS-VALUE-NAME
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-TEXT) NOT = "jazz"
               DISPLAY "interaction-test: select first value mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-PARSE-MODAL.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-MODAL-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-INTERACTION-TYPE NOT = 5
               DISPLAY "interaction-test: modal type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-CUSTOM-ID)
               NOT = "feedback-modal"
               DISPLAY "interaction-test: modal custom id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-INTERACTION-VALUE-COUNT NOT = 1
               DISPLAY "interaction-test: modal value count mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           MOVE "notes" TO WS-VALUE-NAME
           MOVE SPACES TO WS-TEXT
           CALL "DC-INTERACTION-GET-VALUE"
               USING DC-INTERACTION
                     WS-VALUE-NAME
                     WS-TEXT
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-TEXT) NOT = "hello world"
               DISPLAY "interaction-test: modal value mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-PLAY.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-CLIENT-GW-COMMAND-NAME)
               NOT = "VOICE_STATE_UPDATE"
               DISPLAY "interaction-test: handle play action mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 1
               DISPLAY "interaction-test: handle play queue size mismatch "
                   DC-MQ-SIZE
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY)
               DISPLAY "interaction-test: handle play reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM RESET-GATEWAY-COMMAND.

       TEST-HANDLE-QUEUE.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-QUEUE-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-QUEUE-REPLY)
               DISPLAY "interaction-test: handle queue reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-NOWPLAYING.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-NOWPLAYING-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-NOWPLAYING-REPLY)
               DISPLAY "interaction-test: handle nowplaying reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-NOWPLAYING-PLAYING.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-NOWPLAYING-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-NOWPLAYING-COMPONENT-REPLY)
               DISPLAY
                   "interaction-test: handle nowplaying playing reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-REMOVE.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-REMOVE-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-REMOVE-REPLY)
               DISPLAY "interaction-test: handle remove reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "interaction-test: handle remove queue mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-CLEARQUEUE.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-CLEARQUEUE-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-CLEARQUEUE-REPLY)
               DISPLAY "interaction-test: handle clearqueue reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           INITIALIZE DC-MUSIC-QUEUE
           CALL "DC-MUSIC-QUEUE-LIST"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE NOT = 0
               DISPLAY "interaction-test: handle clearqueue queue mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-PAUSE.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PAUSE-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-PAUSE-REPLY)
               DISPLAY "interaction-test: handle pause reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM CHECK-PLAYER-STATE-IS-PAUSED.

       TEST-HANDLE-RESUME.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-RESUME-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-RESUME-REPLY)
               DISPLAY "interaction-test: handle resume reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM CHECK-PLAYER-STATE-IS-PLAYING.

       TEST-HANDLE-MUSIC-SKIP-BUTTON.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-SKIP-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-MUSIC-SKIP-UPDATE)
               DISPLAY
                   "interaction-test: handle music skip button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-MUSIC-PAUSE-BUTTON.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-PAUSE-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-MUSIC-PAUSE-UPDATE)
               DISPLAY
                   "interaction-test: handle music pause button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM CHECK-PLAYER-STATE-IS-PAUSED.

       TEST-HANDLE-MUSIC-RESUME-BUTTON.
           PERFORM PREPARE-PLAYING-RUNTIME
           CALL "DC-MUSIC-PAUSE"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-RESUME-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-MUSIC-RESUME-UPDATE)
               DISPLAY
                   "interaction-test: handle music resume button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           PERFORM CHECK-PLAYER-STATE-IS-PLAYING.

       TEST-HANDLE-MUSIC-QUEUE-VIEW-BUTTON.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-QUEUE-VIEW-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-QUEUE-VIEW-UPDATE)
               DISPLAY
                   "interaction-test: handle music queue view button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-MUSIC-QUEUE-RM1-BUTTON.
           PERFORM RESET-MUSIC-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-QUEUE-RM1-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-QUEUE-EMPTY-UPDATE)
               DISPLAY
                   "interaction-test: handle music queue rm1 button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-MUSIC-QUEUE-CLEAR-BUTTON.
           PERFORM RESET-MUSIC-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-PLAY-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-QUEUE-CLEAR-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-QUEUE-EMPTY-UPDATE)
               DISPLAY
                   "interaction-test: handle music queue clear button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-MUSIC-NP-VIEW-BUTTON.
           PERFORM PREPARE-PLAYING-RUNTIME
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MUSIC-NP-VIEW-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-NOWPLAYING-UPDATE)
               DISPLAY
                   "interaction-test: handle music np view button reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-ERROR.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MISSING-OPTION-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Error: Interaction option was not found."}}'
               DISPLAY "interaction-test: handle error reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       PREPARE-PLAYING-RUNTIME.
           CALL "DC-MUSIC-STATE-LOAD"
               USING WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-MQ-SIZE > 0
               CALL "DC-MUSIC-QUEUE-POP"
                   USING DC-MUSIC-QUEUE
                         DC-MUSIC-TRACK
                         DC-RESULT
               PERFORM CHECK-OK
           END-IF
           MOVE 1 TO DC-PLAYER-STATE
           MOVE 1 TO DC-TRACK-STATUS
           IF FUNCTION TRIM(DC-TRACK-TITLE) = SPACES
               MOVE WS-SOURCE-PATH TO DC-TRACK-TITLE
           END-IF
           IF FUNCTION TRIM(DC-TRACK-SOURCE) = SPACES
               MOVE WS-SOURCE-PATH TO DC-TRACK-SOURCE
           END-IF
           CALL "DC-MUSIC-STATE-SAVE"
               USING WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK.

       RESET-MUSIC-RUNTIME.
           CALL "DC-MUSIC-STOP"
               USING DC-CLIENT
                     WS-GUILD-ID
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM RESET-GATEWAY-COMMAND.

       CHECK-PLAYER-STATE-IS-PAUSED.
           CALL "DC-MUSIC-STATE-LOAD"
               USING WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-PLAYER-STATE NOT = 2
               DISPLAY "interaction-test: pause state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       CHECK-PLAYER-STATE-IS-PLAYING.
           CALL "DC-MUSIC-STATE-LOAD"
               USING WS-GUILD-ID
                     DC-MUSIC-QUEUE
                     DC-AUDIO-PLAYER
                     DC-MUSIC-TRACK
                     DC-RTP-STATE
                     DC-OPUS-HANDLE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-PLAYER-STATE NOT = 1
               DISPLAY "interaction-test: resume state mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-HANDLE-EVENT.
           INITIALIZE DC-EVENT
           MOVE "INTERACTION_CREATE" TO DC-EVENT-NAME
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-WRAPPED-STOP-JSON TRAILING))
               TO DC-EVENT-PAYLOAD-LENGTH
           MOVE WS-WRAPPED-STOP-JSON TO DC-EVENT-PAYLOAD
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE-EVENT"
               USING DC-CLIENT
                     DC-EVENT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Stopped playback."}}'
               DISPLAY "interaction-test: handle event reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-DEFERRED.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-DEFERRED"
               USING WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-DEFERRED-PAYLOAD)
               DISPLAY "interaction-test: deferred payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-EPHEMERAL.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-EPHEMERAL"
               USING WS-SECRET-TEXT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Secret","flags":64}}'
               DISPLAY "interaction-test: ephemeral payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-FOLLOWUP.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-FOLLOWUP"
               USING WS-LATER-TEXT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD)
               DISPLAY "interaction-test: followup payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-FOLLOWUP-WAIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-FUP-WAIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "POST"
               DISPLAY "interaction-test: followup wait method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1?wait=true"
               DISPLAY "interaction-test: followup wait path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY
                   "interaction-test: followup wait content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD TRAILING)))
               NOT = FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD)
               DISPLAY "interaction-test: followup wait body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-FOLLOWUP-GET.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-FUP-GET-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "GET"
               DISPLAY "interaction-test: followup get method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/msg-1"
               DISPLAY "interaction-test: followup get path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE) NOT = SPACES
               DISPLAY "interaction-test: followup get content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY-LENGTH NOT = 0
               DISPLAY "interaction-test: followup get body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-FOLLOWUP-EDIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-FUP-EDIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     WS-EDIT-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "PATCH"
               DISPLAY "interaction-test: followup edit method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/msg-1"
               DISPLAY "interaction-test: followup edit path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY "interaction-test: followup edit content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-EDIT-PAYLOAD TRAILING)))
               NOT = FUNCTION TRIM(WS-EDIT-PAYLOAD)
               DISPLAY "interaction-test: followup edit body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-FOLLOWUP-DELETE.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-FUP-DEL-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "DELETE"
               DISPLAY "interaction-test: followup delete method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/msg-1"
               DISPLAY "interaction-test: followup delete path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE) NOT = SPACES
               DISPLAY "interaction-test: followup delete content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY-LENGTH NOT = 0
               DISPLAY "interaction-test: followup delete body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-ORIGINAL-GET.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-ORIG-GET-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "GET"
               DISPLAY "interaction-test: original get method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/@original"
               DISPLAY "interaction-test: original get path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY-LENGTH NOT = 0
               DISPLAY "interaction-test: original get body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-ORIGINAL-EDIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-ORIG-EDIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-EDIT-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "PATCH"
               DISPLAY "interaction-test: original edit method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/@original"
               DISPLAY "interaction-test: original edit path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-ORIGINAL-EDIT-PAYLOAD TRAILING)))
               NOT = FUNCTION TRIM(WS-ORIGINAL-EDIT-PAYLOAD)
               DISPLAY "interaction-test: original edit body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-ORIGINAL-DELETE.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-ORIG-DEL-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "DELETE"
               DISPLAY "interaction-test: original delete method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/webhooks/app-1/tok-1/messages/@original"
               DISPLAY "interaction-test: original delete path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY-LENGTH NOT = 0
               DISPLAY "interaction-test: original delete body length mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-UPDATE.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-UPDATE"
               USING WS-UPDATE-TEXT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-UPDATE-REPLY)
               DISPLAY "interaction-test: update payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-UPDATE-COMPONENT.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-IA-BUILD-UPDATE-COMP"
               USING WS-SAVED-TEXT
                     WS-COMPONENT-ROW-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-UPDATE-COMPONENT-REPLY)
               DISPLAY
                   "interaction-test: update component payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-COMPONENT.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-COMPONENT"
               USING WS-SAVED-TEXT
                     WS-COMPONENT-ROW-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-COMPONENT-REPLY)
               DISPLAY "interaction-test: component payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-EMBED.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-IA-BUILD-EMBED"
               USING WS-EMBED-TITLE
                     WS-SAVED-TEXT
                     WS-EMBED-COLOR
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-EMBED-REPLY)
               DISPLAY "interaction-test: embed payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-EMBED-COMPONENT.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-IA-BUILD-ECOMP"
               USING WS-EMBED-TITLE
                     WS-SAVED-TEXT
                     WS-EMBED-COLOR
                     WS-COMPONENT-ROW-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-EMBED-COMPONENT-REPLY)
               DISPLAY "interaction-test: embed component payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-UPDATE-EMBED.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-IA-BUILD-UEMB"
               USING WS-EMBED-TITLE
                     WS-SAVED-TEXT
                     WS-EMBED-COLOR
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-EMBED-UPDATE)
               DISPLAY "interaction-test: update embed payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-UPDATE-EMBED-COMPONENT.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-IA-BUILD-UECMP"
               USING WS-EMBED-TITLE
                     WS-SAVED-TEXT
                     WS-EMBED-COLOR
                     WS-COMPONENT-ROW-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-EMBED-UPDATE-COMPONENT-REPLY)
               DISPLAY
                   "interaction-test: update embed component payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-BUILD-MODAL.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-BUILD-MODAL"
               USING WS-MODAL-ID
                     WS-MODAL-TITLE
                     WS-MODAL-COMPONENTS-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-MODAL-REPLY)
               DISPLAY "interaction-test: modal payload mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CUSTOM-COMMAND-HANDLER.
           CALL "DC-INTERACTION-ON-COMMAND"
               USING DC-CLIENT
                     WS-CUSTOM-CMD-NAME
                     WS-CMD-HANDLER
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-CUSTOM-CMD-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-MODAL-REPLY)
               DISPLAY "interaction-test: custom command reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CUSTOM-COMPONENT-HANDLER.
           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-COMPONENT-ID
                     WS-COMP-HANDLER
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-UPDATE-REPLY)
               DISPLAY "interaction-test: custom component reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CUSTOM-MODAL-HANDLER.
           CALL "DC-INTERACTION-ON-MODAL"
               USING DC-CLIENT
                     WS-MODAL-ID
                     WS-MODAL-HANDLER
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MODAL-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = FUNCTION TRIM(WS-EXPECTED-COMPONENT-REPLY)
               DISPLAY "interaction-test: custom modal reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CUSTOM-HANDLER-REPLACE.
           CALL "DC-INTERACTION-ON-COMMAND"
               USING DC-CLIENT
                     WS-CUSTOM-CMD-NAME
                     WS-CMD-HANDLER-ALT
                     DC-RESULT
           PERFORM CHECK-OK
           CALL "DC-INTERACTION-ON-COMPONENT"
               USING DC-CLIENT
                     WS-COMPONENT-ID
                     WS-COMP-HANDLER-ALT
                     DC-RESULT
           PERFORM CHECK-OK
           CALL "DC-INTERACTION-ON-MODAL"
               USING DC-CLIENT
                     WS-MODAL-ID
                     WS-MODAL-HANDLER-ALT
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-CUSTOM-CMD-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Alt command"}}'
               DISPLAY "interaction-test: replaced command reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-BUTTON-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":7,"data":{"content":"Alt component"}}'
               DISPLAY "interaction-test: replaced component reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-RAW-MODAL-JSON
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD)
               NOT = '{"type":4,"data":{"content":"Alt modal"}}'
               DISPLAY "interaction-test: replaced modal reply mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-CALLBACK-REPLY.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK

           MOVE WS-EXPECTED-PLAY-REPLY TO WS-REPLY-PAYLOAD
           INITIALIZE DC-HTTP-REQUEST
           CALL "DC-INTERACTION-CALLBACK-BUILD"
               USING DC-INTERACTION
                     WS-REPLY-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(DC-HTTP-METHOD) NOT = "POST"
               DISPLAY "interaction-test: callback method mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-HOST) NOT = "discord.com"
               DISPLAY "interaction-test: callback host mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-CONTENT-TYPE)
               NOT = "application/json"
               DISPLAY "interaction-test: callback content-type mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(DC-HTTP-PATH)
               NOT = "/api/v10/interactions/int-1/tok-1/callback"
               DISPLAY "interaction-test: callback path mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-BODY(1:FUNCTION LENGTH(
               FUNCTION TRIM(WS-REPLY-PAYLOAD TRAILING)))
               NOT = FUNCTION TRIM(WS-REPLY-PAYLOAD)
               DISPLAY "interaction-test: callback body mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-DEFER.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-CALLBACK-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-DEFER"
               USING DC-INTERACTION
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 204
               DISPLAY "interaction-test: defer status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-DEFERRED-PAYLOAD TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "interaction-test: defer body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-DEFERRED-PAYLOAD TRAILING)))
                   NOT = FUNCTION TRIM(WS-DEFERRED-PAYLOAD)
                   DISPLAY "interaction-test: defer body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-FOLLOWUP.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FOLLOWUP"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:43)
               NOT = "POST /api/v10/webhooks/app-1/tok-1 HTTP/1.1"
               DISPLAY "interaction-test: followup request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "interaction-test: followup body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD TRAILING)))
                   NOT = FUNCTION TRIM(WS-FOLLOWUP-PAYLOAD)
                   DISPLAY "interaction-test: followup body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-FOLLOWUP-WAIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-WAIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup wait status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:DC-HTTP-RESPONSE-BODY-LENGTH)
               NOT = WS-FOLLOWUP-MESSAGE-JSON(
                   1:FUNCTION LENGTH(
                       FUNCTION TRIM(WS-FOLLOWUP-MESSAGE-JSON TRAILING)))
               DISPLAY "interaction-test: followup wait response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:53)
               NOT = "POST /api/v10/webhooks/app-1/tok-1?wait=true HTTP/1.1"
               DISPLAY "interaction-test: followup wait request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-WAIT-ID.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           MOVE SPACES TO WS-MESSAGE-ID-OUT
           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-WAIT-ID"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     DC-HTTP-RESPONSE
                     WS-MESSAGE-ID-OUT
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup wait-id status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF FUNCTION TRIM(WS-MESSAGE-ID-OUT) NOT = "msg-1"
               DISPLAY "interaction-test: followup wait-id mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:DC-HTTP-RESPONSE-BODY-LENGTH)
               NOT = WS-FOLLOWUP-MESSAGE-JSON(
                   1:FUNCTION LENGTH(
                       FUNCTION TRIM(WS-FOLLOWUP-MESSAGE-JSON TRAILING)))
               DISPLAY "interaction-test: followup wait-id response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-GET.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-GET"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup get status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:DC-HTTP-RESPONSE-BODY-LENGTH)
               NOT = WS-FOLLOWUP-MESSAGE-JSON(
                   1:FUNCTION LENGTH(
                       FUNCTION TRIM(WS-FOLLOWUP-MESSAGE-JSON TRAILING)))
               DISPLAY "interaction-test: followup get response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:57)
               NOT = "GET /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY "interaction-test: followup get request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-GET-MESSAGE-ID.
           MOVE SPACES TO WS-MESSAGE-ID-OUT
           CALL "DC-INTERACTION-GET-MESSAGE-ID"
               USING WS-FOLLOWUP-MESSAGE-JSON
                     WS-MESSAGE-ID-OUT
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-MESSAGE-ID-OUT) NOT = "msg-1"
               DISPLAY "interaction-test: message id helper mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           MOVE SPACES TO WS-MESSAGE-ID-OUT
           CALL "DC-INTERACTION-GET-MESSAGE-ID"
               USING WS-ORIGINAL-MESSAGE-JSON
                     WS-MESSAGE-ID-OUT
                     DC-RESULT
           PERFORM CHECK-OK
           IF FUNCTION TRIM(WS-MESSAGE-ID-OUT) NOT = "orig-1"
               DISPLAY
                   "interaction-test: original message id helper mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-EDIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-EDIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     WS-EDIT-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup edit status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:59)
               NOT = "PATCH /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY "interaction-test: followup edit request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-EDIT-PAYLOAD TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "interaction-test: followup edit body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-EDIT-PAYLOAD TRAILING)))
                   NOT = FUNCTION TRIM(WS-EDIT-PAYLOAD)
                   DISPLAY "interaction-test: followup edit body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       TEST-FOLLOWUP-EDIT-MSG.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-EDIT-MSG"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-JSON
                     WS-EDIT-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup edit-msg status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:59)
               NOT = "PATCH /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY "interaction-test: followup edit-msg request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-WAIT-EDIT.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-WAIT-EDIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     WS-EDIT-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: followup wait-edit status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:59)
               NOT = "PATCH /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY "interaction-test: followup wait-edit request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-DELETE.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-CALLBACK-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-DEL"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-MESSAGE-ID
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 204
               DISPLAY "interaction-test: followup delete status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:60)
               NOT = "DELETE /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY "interaction-test: followup delete request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-DELETE-MSG.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-CALLBACK-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-DEL-MSG"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-JSON
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 204
               DISPLAY "interaction-test: followup delete-msg status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:60)
               NOT = "DELETE /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY
                   "interaction-test: followup delete-msg request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-FOLLOWUP-WAIT-DELETE.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-FOLLOWUP-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-FUP-WAIT-DEL"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY
                   "interaction-test: followup wait-delete status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:60)
               NOT = "DELETE /api/v10/webhooks/app-1/tok-1/messages/msg-1 HTTP/1.1"
               DISPLAY
                   "interaction-test: followup wait-delete request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-ORIGINAL-GET.
           INITIALIZE DC-INTERACTION
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-RAW-PLAY-JSON
                     DC-INTERACTION
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-ORIGINAL-FIXTURE

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-ORIG-GET"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-HTTP-RESPONSE
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-STATUS-CODE NOT = 200
               DISPLAY "interaction-test: original get status mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           IF DC-HTTP-RESPONSE-BODY(1:DC-HTTP-RESPONSE-BODY-LENGTH)
               NOT = WS-ORIGINAL-MESSAGE-JSON(
                   1:FUNCTION LENGTH(
                       FUNCTION TRIM(WS-ORIGINAL-MESSAGE-JSON TRAILING)))
               DISPLAY "interaction-test: original get response mismatch"
               ADD 1 TO WS-FAILURES
           END-IF

           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:61)
               NOT =
               "GET /api/v10/webhooks/app-1/tok-1/messages/@original HTTP/1.1"
               DISPLAY "interaction-test: original get request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF.

       TEST-DISPATCH-HANDLER-REPLY.
           CALL "DC-INTERACTION-REGISTER"
               USING DC-CLIENT
                     DC-RESULT
           PERFORM CHECK-OK
           PERFORM PREPARE-CALLBACK-FIXTURE
           INITIALIZE DC-EVENT
           MOVE "INTERACTION_CREATE" TO DC-EVENT-NAME
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-PLAY-JSON TRAILING))
               TO DC-EVENT-PAYLOAD-LENGTH
           MOVE WS-RAW-PLAY-JSON TO DC-EVENT-PAYLOAD
           CALL "DC-DISPATCH"
               USING DC-CLIENT
                     DC-EVENT
                     DC-RESULT
           PERFORM CHECK-OK
           INITIALIZE DC-HTTP-BUFFER
           CALL "DC-TLS-MOCK-GET-LAST-REQUEST"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK
           IF DC-HTTP-BUFFER-DATA(1:56)
               NOT = "POST /api/v10/interactions/int-1/tok-1/callback HTTP/1.1"
               DISPLAY "interaction-test: dispatch callback request mismatch"
               ADD 1 TO WS-FAILURES
           END-IF
           COMPUTE WS-BODY-START =
               FUNCTION LENGTH(FUNCTION TRIM(DC-HTTP-BUFFER-DATA TRAILING))
               - FUNCTION LENGTH(
                   FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY TRAILING))
               + 1
           IF WS-BODY-START < 1
               DISPLAY "interaction-test: dispatch callback body offset mismatch"
               ADD 1 TO WS-FAILURES
           ELSE
               IF DC-HTTP-BUFFER-DATA(
                   WS-BODY-START:
                   FUNCTION LENGTH(
                       FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY TRAILING)))
                   NOT = FUNCTION TRIM(WS-EXPECTED-PLAY-REPLY)
                   DISPLAY "interaction-test: dispatch callback body mismatch"
                   ADD 1 TO WS-FAILURES
               END-IF
           END-IF.

       PREPARE-CALLBACK-FIXTURE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 204 No Content" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: 0" DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-FOLLOWUP-FIXTURE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-FOLLOWUP-MESSAGE-JSON TRAILING))
               TO WS-BODY-LEN-TEXT
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-BODY-LEN-TEXT) DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               FUNCTION TRIM(WS-FOLLOWUP-MESSAGE-JSON) DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       PREPARE-ORIGINAL-FIXTURE.
           INITIALIZE DC-HTTP-BUFFER
           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(WS-ORIGINAL-MESSAGE-JSON TRAILING))
               TO WS-BODY-LEN-TEXT
           MOVE SPACES TO WS-RAW-RESPONSE
           STRING
               "HTTP/1.1 200 OK" DELIMITED BY SIZE
               X"0D0A" DELIMITED BY SIZE
               "Content-Length: " DELIMITED BY SIZE
               FUNCTION TRIM(WS-BODY-LEN-TEXT) DELIMITED BY SIZE
               X"0D0A0D0A" DELIMITED BY SIZE
               FUNCTION TRIM(WS-ORIGINAL-MESSAGE-JSON) DELIMITED BY SIZE
               INTO WS-RAW-RESPONSE
           END-STRING
           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-RAW-RESPONSE TRAILING))
               TO DC-HTTP-BUFFER-LENGTH
           MOVE WS-RAW-RESPONSE TO DC-HTTP-BUFFER-DATA
           CALL "DC-TLS-MOCK-SET-RESPONSE"
               USING WS-DISCORD-HOST
                     WS-TLS-PORT
                     DC-HTTP-BUFFER
                     DC-RESULT
           PERFORM CHECK-OK.

       RESET-GATEWAY-COMMAND.
           MOVE 0 TO DC-CLIENT-GW-COMMAND-QUEUED
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-NAME
           MOVE SPACES TO DC-CLIENT-GW-COMMAND-PAYLOAD.

       CHECK-OK.
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               DISPLAY "interaction-test: unexpected result "
                   FUNCTION TRIM(DC-ERROR-CODE)
               END-DISPLAY
               ADD 1 TO WS-FAILURES
           END-IF.

       FINISH-TEST.
           IF WS-FAILURES = 0
               DISPLAY "interaction-test ok"
               MOVE 0 TO WS-EXIT-CODE
           ELSE
               DISPLAY "interaction-test failed"
               MOVE 1 TO WS-EXIT-CODE
           END-IF
           STOP RUN RETURNING WS-EXIT-CODE.
       END PROGRAM INTERACTION-TEST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-CMD-HANDLER.
       *> JP: interaction parse/dispatch/reply の広い経路をまとめて検証する統合寄りテストです。
       *> JP: 補助 handler program も同居させ、custom command/component/modal の流れまで確認します。
       *> EN: Broad integration-style test for interaction parsing, dispatch, and reply flows.
       *> EN: Helper handler programs live here too so custom command/component/modal flows can be checked end to end.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMPONENTS-JSON PIC X(4096).
       01 WS-MODAL-ID PIC X(128) VALUE "feedback-modal".
       01 WS-MODAL-TITLE PIC X(128) VALUE "Feedback".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[{"type":4,' DELIMITED BY SIZE
               '"custom_id":"notes","label":"Notes","style":1}]}]'
                   DELIMITED BY SIZE
               INTO WS-COMPONENTS-JSON
           END-STRING
           CALL "DC-INTERACTION-BUILD-MODAL"
               USING WS-MODAL-ID
                     WS-MODAL-TITLE
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-CMD-HANDLER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-COMP-HANDLER.
       *> JP: interaction parse/dispatch/reply の広い経路をまとめて検証する統合寄りテストです。
       *> JP: 補助 handler program も同居させ、custom command/component/modal の流れまで確認します。
       *> EN: Broad integration-style test for interaction parsing, dispatch, and reply flows.
       *> EN: Helper handler programs live here too so custom command/component/modal flows can be checked end to end.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-UPDATE-TEXT PIC X(2000) VALUE "Updated from button.".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-INTERACTION-BUILD-UPDATE"
               USING WS-UPDATE-TEXT
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-COMP-HANDLER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-MODAL-HANDLER.
       *> JP: interaction parse/dispatch/reply の広い経路をまとめて検証する統合寄りテストです。
       *> JP: 補助 handler program も同居させ、custom command/component/modal の流れまで確認します。
       *> EN: Broad integration-style test for interaction parsing, dispatch, and reply flows.
       *> EN: Helper handler programs live here too so custom command/component/modal flows can be checked end to end.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-COMPONENTS-JSON PIC X(4096).
       01 WS-SAVED-TEXT PIC X(2000) VALUE "Saved".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-COMPONENTS-JSON
           STRING
               '[{"type":1,"components":[{"type":2,' DELIMITED BY SIZE
               '"style":2,"label":"Done","custom_id":"done"}]}]'
                   DELIMITED BY SIZE
               INTO WS-COMPONENTS-JSON
           END-STRING
           CALL "DC-INTERACTION-BUILD-COMPONENT"
               USING WS-SAVED-TEXT
                     WS-COMPONENTS-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-MODAL-HANDLER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-CMD-HANDLER-ALT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TEXT PIC X(2000) VALUE "Alt command".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-INTERACTION-BUILD-REPLY"
               USING WS-TEXT
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-CMD-HANDLER-ALT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-COMP-HANDLER-ALT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TEXT PIC X(2000) VALUE "Alt component".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-INTERACTION-BUILD-UPDATE"
               USING WS-TEXT
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-COMP-HANDLER-ALT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-IA-MODAL-HANDLER-ALT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-TEXT PIC X(2000) VALUE "Alt modal".
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           CALL "DC-INTERACTION-BUILD-REPLY"
               USING WS-TEXT
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM TEST-IA-MODAL-HANDLER-ALT.
