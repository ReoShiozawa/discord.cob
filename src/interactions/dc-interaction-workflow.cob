       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FROM-JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).
       01 WS-TEXT PIC X(512).
       01 WS-JSON-LEN PIC 9(5) COMP-5.
       01 WS-ROOT-WRAPPED-FLAG PIC 9.
       01 WS-OPTIONS-PATH PIC X(128).
       01 WS-JSON-VALUE-POS PIC 9(5) COMP-5.
       01 WS-CURSOR PIC 9(5) COMP-5.
       01 WS-OBJECT-START PIC 9(5) COMP-5.
       01 WS-OBJECT-LENGTH PIC 9(5) COMP-5.
       01 WS-CHAR PIC X.
       01 WS-IN-STRING PIC 9.
       01 WS-ESCAPE-FLAG PIC 9.
       01 WS-ARRAY-DEPTH PIC 9(4) COMP-5.
       01 WS-OBJECT-DEPTH PIC 9(4) COMP-5.
       01 WS-VALUE-POS PIC 9(5) COMP-5.
       01 WS-VALUE-END PIC 9(5) COMP-5.
       01 WS-VALUE-LEN PIC 9(5) COMP-5.
       01 WS-FIELD-POS PIC 9(5) COMP-5.
       01 WS-FIELD-LABEL PIC X(16).
       01 WS-FIELD-LABEL-LEN PIC 9(2) COMP-5.
       01 WS-OPTION-JSON PIC X(1024).
       01 WS-OPTION-NAME PIC X(64).
       01 WS-OPTION-VALUE PIC X(512).
       01 WS-OPTION-TABLE-FULL PIC 9.
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       01 DC-INTERACTION-JSON PIC X(8192).
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION-JSON
           DC-INTERACTION
           DC-RESULT.
       MAIN.
           INITIALIZE DC-INTERACTION
           CALL "DC-JSON-VALIDATE"
               USING DC-INTERACTION-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           PERFORM FIND-JSON-LENGTH

           MOVE 0 TO WS-ROOT-WRAPPED-FLAG
           MOVE "$.d.id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE 1 TO WS-ROOT-WRAPPED-FLAG
               PERFORM LOAD-WRAPPED-INTERACTION
           ELSE
               PERFORM LOAD-RAW-INTERACTION
           END-IF
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF FUNCTION TRIM(DC-COMMAND-NAME) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction command name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       FIND-JSON-LENGTH.
           MOVE 8192 TO WS-JSON-LEN
           PERFORM UNTIL WS-JSON-LEN = 0
               OR DC-INTERACTION-JSON(WS-JSON-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-JSON-LEN
           END-PERFORM.

       LOAD-WRAPPED-INTERACTION.
           PERFORM LOAD-WRAPPED-FIELDS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "$.d.data.options" TO WS-OPTIONS-PATH
           PERFORM PARSE-OPTIONS.

       LOAD-RAW-INTERACTION.
           PERFORM LOAD-RAW-FIELDS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "$.data.options" TO WS-OPTIONS-PATH
           PERFORM PARSE-OPTIONS.

       LOAD-WRAPPED-FIELDS.
           MOVE "$.d.id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-INTERACTION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Wrapped interaction id was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.d.token" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-INTERACTION-TOKEN
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Wrapped interaction token was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.d.data.name" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-COMMAND-NAME
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Wrapped interaction command name was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.d.guild_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-GUILD-ID
           END-IF

           MOVE "$.d.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-CHANNEL-ID
           END-IF

           MOVE "$.d.member.user.id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-USER-ID
           END-IF
           IF FUNCTION TRIM(DC-USER-ID) = SPACES
               MOVE "$.d.user.id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-ID
               END-IF
           END-IF
           MOVE "$.d.member.voice.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE "$.d.member.voice_channel_id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
               END-IF
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE "$.d.user_voice_channel_id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
               END-IF
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       LOAD-RAW-FIELDS.
           MOVE "$.id" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-INTERACTION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Raw interaction id was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.token" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-INTERACTION-TOKEN
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Raw interaction token was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.data.name" TO WS-PATH
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     DC-COMMAND-NAME
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Raw interaction command name was not found."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE "$.guild_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-GUILD-ID
           END-IF

           MOVE "$.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-CHANNEL-ID
           END-IF

           MOVE "$.member.user.id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-USER-ID
           END-IF
           IF FUNCTION TRIM(DC-USER-ID) = SPACES
               MOVE "$.user.id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-ID
               END-IF
           END-IF
           MOVE "$.member.voice.channel_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE "$.member.voice_channel_id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
               END-IF
           END-IF
           IF FUNCTION TRIM(DC-USER-VOICE-CHANNEL-ID) = SPACES
               MOVE "$.user_voice_channel_id" TO WS-PATH
               MOVE SPACES TO WS-TEXT
               CALL "DC-JSON-GET-STRING"
                   USING DC-INTERACTION-JSON
                         WS-PATH
                         WS-TEXT
                         WS-LOCAL-RESULT
               IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                   MOVE WS-TEXT TO DC-USER-VOICE-CHANNEL-ID
               END-IF
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PARSE-OPTIONS.
           MOVE 0 TO DC-COMMAND-OPTION-COUNT
           MOVE 0 TO WS-OPTION-TABLE-FULL
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-INTERACTION-JSON
                     WS-OPTIONS-PATH
                     WS-JSON-VALUE-POS
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-NOT-FOUND
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF
           IF WS-LOCAL-STATUS-CODE NOT = DC-STATUS-OK
               MOVE WS-LOCAL-STATUS-CODE TO DC-STATUS-CODE
               MOVE WS-LOCAL-ERROR-CODE TO DC-ERROR-CODE
               MOVE WS-LOCAL-ERROR-MESSAGE TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           IF DC-INTERACTION-JSON(WS-JSON-VALUE-POS:1) NOT = "["
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction options must be a JSON array."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE WS-JSON-VALUE-POS TO WS-CURSOR
           MOVE 0 TO WS-IN-STRING
           MOVE 0 TO WS-ESCAPE-FLAG
           MOVE 0 TO WS-OBJECT-START
           MOVE 1 TO WS-ARRAY-DEPTH
           MOVE 0 TO WS-OBJECT-DEPTH
           ADD 1 TO WS-CURSOR

           PERFORM UNTIL WS-CURSOR > WS-JSON-LEN
               MOVE DC-INTERACTION-JSON(WS-CURSOR:1) TO WS-CHAR
               IF WS-IN-STRING = 1
                   IF WS-ESCAPE-FLAG = 1
                       MOVE 0 TO WS-ESCAPE-FLAG
                   ELSE
                       IF WS-CHAR = "\"
                           MOVE 1 TO WS-ESCAPE-FLAG
                       ELSE
                           IF WS-CHAR = QUOTE
                               MOVE 0 TO WS-IN-STRING
                           END-IF
                       END-IF
                   END-IF
               ELSE
                   EVALUATE WS-CHAR
                       WHEN QUOTE
                           MOVE 1 TO WS-IN-STRING
                       WHEN "["
                           ADD 1 TO WS-ARRAY-DEPTH
                       WHEN "]"
                           SUBTRACT 1 FROM WS-ARRAY-DEPTH
                           IF WS-ARRAY-DEPTH = 0
                               EXIT PERFORM
                           END-IF
                       WHEN "{"
                           IF WS-ARRAY-DEPTH = 1
                              AND WS-OBJECT-DEPTH = 0
                               MOVE WS-CURSOR TO WS-OBJECT-START
                           END-IF
                           ADD 1 TO WS-OBJECT-DEPTH
                       WHEN "}"
                           IF WS-OBJECT-DEPTH > 0
                               SUBTRACT 1 FROM WS-OBJECT-DEPTH
                               IF WS-ARRAY-DEPTH = 1
                                  AND WS-OBJECT-DEPTH = 0
                                   COMPUTE WS-OBJECT-LENGTH =
                                       WS-CURSOR - WS-OBJECT-START + 1
                                   PERFORM PARSE-OPTION-OBJECT
                                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                                       EXIT PERFORM
                                   END-IF
                               END-IF
                           END-IF
                   END-EVALUATE
               END-IF
               ADD 1 TO WS-CURSOR
           END-PERFORM

           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PARSE-OPTION-OBJECT.
           IF DC-COMMAND-OPTION-COUNT >= 25
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option count exceeded the supported limit."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           IF WS-OBJECT-LENGTH > 1024
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option object exceeded the parser buffer."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-OPTION-JSON
           MOVE SPACES TO WS-OPTION-NAME
           MOVE SPACES TO WS-OPTION-VALUE
           IF WS-OBJECT-LENGTH > 0
               MOVE DC-INTERACTION-JSON(
                   WS-OBJECT-START:WS-OBJECT-LENGTH)
                   TO WS-OPTION-JSON(1:WS-OBJECT-LENGTH)
           END-IF

           MOVE "name" TO WS-FIELD-LABEL
           MOVE 4 TO WS-FIELD-LABEL-LEN
           PERFORM LOCATE-OPTION-FIELD
           IF WS-FIELD-POS = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option name field was missing."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-STRING-FIELD-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-VALUE-LEN > 64
               MOVE 64 TO WS-VALUE-LEN
           END-IF
           IF WS-VALUE-LEN > 0
               MOVE WS-OPTION-JSON(WS-VALUE-POS:WS-VALUE-LEN)
                   TO WS-OPTION-NAME(1:WS-VALUE-LEN)
           END-IF

           MOVE "value" TO WS-FIELD-LABEL
           MOVE 5 TO WS-FIELD-LABEL-LEN
           PERFORM PARSE-OPTION-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF

           ADD 1 TO DC-COMMAND-OPTION-COUNT
           MOVE WS-OPTION-NAME
               TO DC-COMMAND-OPTION-NAME(DC-COMMAND-OPTION-COUNT)
           MOVE WS-OPTION-VALUE
               TO DC-COMMAND-OPTION-VALUE(DC-COMMAND-OPTION-COUNT).

       PARSE-OPTION-VALUE.
           PERFORM LOCATE-OPTION-FIELD
           IF WS-FIELD-POS = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option value field was missing."
                   TO DC-ERROR-MESSAGE
                   EXIT PARAGRAPH
           END-IF

           PERFORM POSITION-FIELD-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF

           IF WS-OPTION-JSON(WS-VALUE-POS:1) = QUOTE
               PERFORM PARSE-STRING-FIELD-VALUE
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   EXIT PARAGRAPH
               END-IF
               IF WS-VALUE-LEN > 0
                   MOVE WS-OPTION-JSON(WS-VALUE-POS:WS-VALUE-LEN)
                       TO WS-OPTION-VALUE(1:WS-VALUE-LEN)
               END-IF
           ELSE
               MOVE WS-VALUE-POS TO WS-VALUE-END
               PERFORM UNTIL WS-VALUE-END > 1024
                   MOVE WS-OPTION-JSON(WS-VALUE-END:1) TO WS-CHAR
                   IF WS-CHAR = ","
                      OR WS-CHAR = "}"
                      OR WS-CHAR = SPACE
                      OR WS-CHAR = X"09"
                      OR WS-CHAR = X"0A"
                      OR WS-CHAR = X"0D"
                       EXIT PERFORM
                   END-IF
                   ADD 1 TO WS-VALUE-END
               END-PERFORM
               COMPUTE WS-VALUE-LEN = WS-VALUE-END - WS-VALUE-POS
               IF WS-VALUE-LEN > 512
                   MOVE 512 TO WS-VALUE-LEN
               END-IF
               IF WS-VALUE-LEN > 0
                   MOVE WS-OPTION-JSON(WS-VALUE-POS:WS-VALUE-LEN)
                       TO WS-OPTION-VALUE(1:WS-VALUE-LEN)
               END-IF
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       LOCATE-OPTION-FIELD.
           MOVE 0 TO WS-FIELD-POS
           PERFORM VARYING WS-CURSOR FROM 1 BY 1
               UNTIL WS-CURSOR >
                     WS-OBJECT-LENGTH - WS-FIELD-LABEL-LEN - 1
                  OR WS-FIELD-POS > 0
               IF WS-OPTION-JSON(WS-CURSOR:1) = QUOTE
                  AND WS-OPTION-JSON(
                      WS-CURSOR + 1:WS-FIELD-LABEL-LEN)
                      = WS-FIELD-LABEL(1:WS-FIELD-LABEL-LEN)
                  AND WS-OPTION-JSON(
                      WS-CURSOR + WS-FIELD-LABEL-LEN + 1:1) = QUOTE
                   MOVE WS-CURSOR TO WS-FIELD-POS
               END-IF
           END-PERFORM.

       POSITION-FIELD-VALUE.
           COMPUTE WS-VALUE-POS =
               WS-FIELD-POS + WS-FIELD-LABEL-LEN + 2
           PERFORM UNTIL WS-VALUE-POS > WS-OBJECT-LENGTH
               OR WS-OPTION-JSON(WS-VALUE-POS:1) = ":"
               ADD 1 TO WS-VALUE-POS
           END-PERFORM
           IF WS-VALUE-POS > WS-OBJECT-LENGTH
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option field separator was missing."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-VALUE-POS
           PERFORM UNTIL WS-VALUE-POS > WS-OBJECT-LENGTH
               OR (WS-OPTION-JSON(WS-VALUE-POS:1) NOT = SPACE
               AND WS-OPTION-JSON(WS-VALUE-POS:1) NOT = X"09"
               AND WS-OPTION-JSON(WS-VALUE-POS:1) NOT = X"0A"
               AND WS-OPTION-JSON(WS-VALUE-POS:1) NOT = X"0D")
               ADD 1 TO WS-VALUE-POS
           END-PERFORM
           IF WS-VALUE-POS > WS-OBJECT-LENGTH
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option field value was missing."
                   TO DC-ERROR-MESSAGE
           END-IF.

       PARSE-STRING-FIELD-VALUE.
           PERFORM POSITION-FIELD-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-OPTION-JSON(WS-VALUE-POS:1) NOT = QUOTE
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option field was not a string."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           ADD 1 TO WS-VALUE-POS
           MOVE WS-VALUE-POS TO WS-VALUE-END
           PERFORM UNTIL WS-VALUE-END > WS-OBJECT-LENGTH
               MOVE WS-OPTION-JSON(WS-VALUE-END:1) TO WS-CHAR
               IF WS-CHAR = QUOTE
                  AND WS-OPTION-JSON(WS-VALUE-END - 1:1) NOT = "\"
                   EXIT PERFORM
               END-IF
               ADD 1 TO WS-VALUE-END
           END-PERFORM
           IF WS-VALUE-END > WS-OBJECT-LENGTH
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction option string was not terminated."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF
           COMPUTE WS-VALUE-LEN = WS-VALUE-END - WS-VALUE-POS
           CALL "DC-RESULT-OK" USING DC-RESULT.
       END PROGRAM DC-INTERACTION-FROM-JSON.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-HANDLE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-music.cpy".
       01 WS-REPLY-CONTENT PIC X(2000).
       01 WS-FILE-OPTION PIC X(64) VALUE "file".
       01 WS-OPTION-VALUE PIC X(512).
       01 WS-COUNT-TEXT PIC ZZZ9.
       01 WS-CMD-RESULT.
          05 WS-CMD-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-CMD-ERROR-CODE PIC X(64).
          05 WS-CMD-ERROR-MESSAGE PIC X(256).
       01 WS-LOCAL-RESULT.
          05 WS-LOCAL-STATUS-CODE PIC S9(9) COMP-5.
          05 WS-LOCAL-ERROR-CODE PIC X(64).
          05 WS-LOCAL-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-INTERACTION-JSON PIC X(8192).
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION-JSON
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-REPLY-PAYLOAD
           MOVE SPACES TO WS-REPLY-CONTENT
           CALL "DC-INTERACTION-FROM-JSON"
               USING DC-INTERACTION-JSON
                     DC-INTERACTION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-COMMAND-ROUTE"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-CMD-RESULT

           IF WS-CMD-STATUS-CODE = DC-STATUS-OK
               PERFORM BUILD-SUCCESS-REPLY
           ELSE
               PERFORM BUILD-ERROR-REPLY
           END-IF

           CALL "DC-INTERACTION-BUILD-REPLY"
               USING WS-REPLY-CONTENT
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       BUILD-SUCCESS-REPLY.
           EVALUATE FUNCTION TRIM(DC-COMMAND-NAME)
               WHEN "/play"
                   MOVE SPACES TO WS-OPTION-VALUE
                   CALL "DC-INTERACTION-GET-OPTION"
                       USING DC-INTERACTION
                             WS-FILE-OPTION
                             WS-OPTION-VALUE
                             WS-LOCAL-RESULT
                   IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                       STRING
                           "Queued: " DELIMITED BY SIZE
                           FUNCTION TRIM(WS-OPTION-VALUE)
                               DELIMITED BY SIZE
                           INTO WS-REPLY-CONTENT
                       END-STRING
                   ELSE
                       MOVE "Queued track." TO WS-REPLY-CONTENT
                   END-IF
               WHEN "/join"
                   MOVE "Queued voice join." TO WS-REPLY-CONTENT
               WHEN "/leave"
                   MOVE "Queued voice leave." TO WS-REPLY-CONTENT
               WHEN "/skip"
                   MOVE "Skipped current track." TO WS-REPLY-CONTENT
               WHEN "/stop"
                   MOVE "Stopped playback." TO WS-REPLY-CONTENT
               WHEN "/queue"
                   INITIALIZE DC-MUSIC-QUEUE
                   CALL "DC-MUSIC-QUEUE-LIST"
                       USING DC-CLIENT
                             DC-GUILD-ID
                             DC-MUSIC-QUEUE
                             WS-LOCAL-RESULT
                   IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                       MOVE DC-MQ-SIZE TO WS-COUNT-TEXT
                       STRING
                           "Queue items: " DELIMITED BY SIZE
                           FUNCTION TRIM(WS-COUNT-TEXT)
                               DELIMITED BY SIZE
                           INTO WS-REPLY-CONTENT
                       END-STRING
                   ELSE
                       MOVE "Queue inspected." TO WS-REPLY-CONTENT
                   END-IF
               WHEN OTHER
                   MOVE "Command handled." TO WS-REPLY-CONTENT
           END-EVALUATE.

       BUILD-ERROR-REPLY.
           MOVE SPACES TO WS-REPLY-CONTENT
           IF FUNCTION TRIM(WS-CMD-ERROR-MESSAGE) NOT = SPACES
               STRING
                   "Error: " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-CMD-ERROR-MESSAGE)
                       DELIMITED BY SIZE
                   INTO WS-REPLY-CONTENT
               END-STRING
           ELSE
               STRING
                   "Error: " DELIMITED BY SIZE
                   FUNCTION TRIM(WS-CMD-ERROR-CODE)
                       DELIMITED BY SIZE
                   INTO WS-REPLY-CONTENT
               END-STRING
           END-IF.
       END PROGRAM DC-INTERACTION-HANDLE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-HANDLE-EVENT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-INTERACTION-JSON PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-EVENT
           DC-REPLY-PAYLOAD
           DC-RESULT.
       MAIN.
           IF FUNCTION TRIM(DC-EVENT-NAME) NOT = "INTERACTION_CREATE"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Gateway event was not INTERACTION_CREATE."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE SPACES TO WS-INTERACTION-JSON
           IF DC-EVENT-PAYLOAD-LENGTH > 0
               MOVE DC-EVENT-PAYLOAD(1:DC-EVENT-PAYLOAD-LENGTH)
                   TO WS-INTERACTION-JSON(1:DC-EVENT-PAYLOAD-LENGTH)
           END-IF

           CALL "DC-INTERACTION-HANDLE"
               USING DC-CLIENT
                     WS-INTERACTION-JSON
                     DC-REPLY-PAYLOAD
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-HANDLE-EVENT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-EVENT-HANDLER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-interaction.cpy".
       COPY "discord-net.cpy".
       01 WS-INTERACTION-JSON PIC X(8192).
       01 WS-REPLY-PAYLOAD PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
           MOVE SPACES TO WS-REPLY-PAYLOAD
           CALL "DC-INTERACTION-HANDLE-EVENT"
               USING DC-CLIENT
                     DC-EVENT
                     WS-REPLY-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(WS-REPLY-PAYLOAD) = SPACES
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           INITIALIZE DC-INTERACTION
           MOVE SPACES TO WS-INTERACTION-JSON
           IF DC-EVENT-PAYLOAD-LENGTH > 0
               MOVE DC-EVENT-PAYLOAD(1:DC-EVENT-PAYLOAD-LENGTH)
                   TO WS-INTERACTION-JSON(1:DC-EVENT-PAYLOAD-LENGTH)
           END-IF
           CALL "DC-INTERACTION-FROM-JSON"
               USING WS-INTERACTION-JSON
                     DC-INTERACTION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           INITIALIZE DC-HTTP-RESPONSE
           CALL "DC-INTERACTION-REPLY"
               USING DC-INTERACTION
                     WS-REPLY-PAYLOAD
                     DC-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-EVENT-HANDLER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-REGISTER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-EVENT-NAME PIC X(64) VALUE "INTERACTION_CREATE".
       01 WS-PROGRAM-NAME PIC X(64)
           VALUE "DC-INTERACTION-EVENT-HANDLER".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-RESULT.
       MAIN.
           CALL "DC-ON"
               USING DC-CLIENT
                     WS-EVENT-NAME
                     WS-PROGRAM-NAME
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-REGISTER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-CALLBACK-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VERSION-TEXT PIC X(2) VALUE "10".
       01 WS-BODY-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       01 LK-HTTP-REQUEST.
          05 LK-HTTP-METHOD PIC X(8).
          05 LK-HTTP-HOST PIC X(256).
          05 LK-HTTP-PATH PIC X(512).
          05 LK-HTTP-AUTHORIZATION PIC X(320).
          05 LK-HTTP-CONTENT-TYPE PIC X(128).
          05 LK-HTTP-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
           INITIALIZE LK-HTTP-REQUEST
           IF FUNCTION TRIM(DC-INTERACTION-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction id is required for callbacks."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for callbacks."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-REPLY-PAYLOAD) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Reply payload is required for callbacks."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE FUNCTION LENGTH(FUNCTION TRIM(DC-REPLY-PAYLOAD TRAILING))
               TO WS-BODY-LENGTH
           MOVE "POST" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v" DELIMITED BY SIZE
               WS-VERSION-TEXT DELIMITED BY SIZE
               "/interactions/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               "/callback" DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           MOVE "application/json" TO LK-HTTP-CONTENT-TYPE
           MOVE WS-BODY-LENGTH TO LK-HTTP-BODY-LENGTH
           IF WS-BODY-LENGTH > 0
               MOVE DC-REPLY-PAYLOAD(1:WS-BODY-LENGTH)
                   TO LK-HTTP-BODY(1:WS-BODY-LENGTH)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-CALLBACK-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-REPLY.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 DC-REPLY-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           DC-REPLY-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE
           CALL "DC-INTERACTION-CALLBACK-BUILD"
               USING DC-INTERACTION
                     DC-REPLY-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-POST"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE NOT = 200
              AND LK-HTTP-STATUS-CODE NOT = 204
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction callback did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-REPLY.
