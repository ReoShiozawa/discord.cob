       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FROM-JSON.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PATH PIC X(128).
       01 WS-TEXT PIC X(512).
       01 WS-JSON-LEN PIC 9(5) COMP-5.
       01 WS-ROOT-WRAPPED-FLAG PIC 9.
       01 WS-OPTIONS-PATH PIC X(128).
       01 WS-VALUES-PATH PIC X(128).
       01 WS-COMPONENTS-PATH PIC X(128).
       01 WS-JSON-VALUE-POS PIC 9(5) COMP-5.
       01 WS-CURSOR PIC 9(5) COMP-5.
       01 WS-OBJECT-START PIC 9(5) COMP-5.
       01 WS-OBJECT-LENGTH PIC 9(5) COMP-5.
       01 WS-OBJECT-START-STACK.
          05 WS-OBJECT-START-ENTRY OCCURS 10 TIMES
             PIC 9(5) COMP-5.
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
       01 WS-VALUE-NAME PIC X(128).
       01 WS-TYPE-NUM PIC S9(18) COMP-5.
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
      *> JP: 1. JSON を妥当性検証し、raw payload か Gateway event の wrapped payload かを判定します。
      *> EN: 1. Validate JSON, then decide whether it is a raw payload or a Gateway-wrapped payload.
      *> JP: 2. 共通ヘッダ(id/token/type)と command/component/modal 固有フィールドを平坦構造へ写します。
      *> EN: 2. Copy shared headers and command/component/modal-specific fields into a flat structure.
      *> JP: 3. 後続の router が扱いやすいよう option/value を固定長テーブルへ正規化します。
      *> EN: 3. Normalize options/values into fixed tables so downstream routers can stay simple.
           INITIALIZE DC-INTERACTION
           CALL "DC-JSON-VALIDATE"
               USING DC-INTERACTION-JSON
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           PERFORM FIND-JSON-LENGTH

      *> JP: Gateway の INTERACTION_CREATE は $.d 以下に本体を持ち、fixture や REST 直入力は root 直下です。
      *> EN: Gateway INTERACTION_CREATE payloads live under $.d, while fixtures/direct payloads live at root.
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

           PERFORM LOAD-INTERACTION-TYPE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF DC-INTERACTION-TYPE = 2
              AND FUNCTION TRIM(DC-COMMAND-NAME) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Application command name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       FIND-JSON-LENGTH.
      *> JP: 固定長バッファの末尾空白を落として、実データ長だけを扱います。
      *> EN: Trim trailing padding from the fixed-width buffer so scans use only meaningful bytes.
           MOVE 8192 TO WS-JSON-LEN
           PERFORM UNTIL WS-JSON-LEN = 0
               OR DC-INTERACTION-JSON(WS-JSON-LEN:1) NOT = SPACE
               SUBTRACT 1 FROM WS-JSON-LEN
           END-PERFORM.

       LOAD-INTERACTION-TYPE.
      *> JP: type は router 分岐の基準なので、見つからない場合は 0 扱いにして後段で unsupported とします。
      *> EN: type drives routing; if absent we coerce it to 0 and let downstream code report unsupported input.
           MOVE 0 TO WS-TYPE-NUM
           IF WS-ROOT-WRAPPED-FLAG = 1
               MOVE "$.d.type" TO WS-PATH
           ELSE
               MOVE "$.type" TO WS-PATH
           END-IF
           CALL "DC-JSON-GET-NUMBER"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TYPE-NUM
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TYPE-NUM TO DC-INTERACTION-TYPE
           ELSE
               MOVE 0 TO DC-INTERACTION-TYPE
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT.

       LOAD-WRAPPED-INTERACTION.
      *> JP: Wrapped payload 用の field path を使って本体を取り込みます。
      *> EN: Load fields using the wrapped-payload paths.
           PERFORM LOAD-WRAPPED-FIELDS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "$.d.data.options" TO WS-OPTIONS-PATH
           MOVE "$.d.data.values" TO WS-VALUES-PATH
           MOVE "$.d.data.components" TO WS-COMPONENTS-PATH
           PERFORM PARSE-OPTIONS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-VALUE-ARRAY
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-COMPONENT-VALUES.

       LOAD-RAW-INTERACTION.
      *> JP: Raw payload 用の field path を使って本体を取り込みます。
      *> EN: Load fields using the raw-payload paths.
           PERFORM LOAD-RAW-FIELDS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           MOVE "$.data.options" TO WS-OPTIONS-PATH
           MOVE "$.data.values" TO WS-VALUES-PATH
           MOVE "$.data.components" TO WS-COMPONENTS-PATH
           PERFORM PARSE-OPTIONS
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-VALUE-ARRAY
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-COMPONENT-VALUES.

       LOAD-WRAPPED-FIELDS.
      *> JP: 必須項目(id/token)は失敗扱い、interaction 種別依存の項目は見つかれば取り込みます。
      *> EN: Required fields (id/token) are fatal when missing; type-specific fields are loaded opportunistically.
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
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-COMMAND-NAME
           END-IF

           MOVE "$.d.data.custom_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-INTERACTION-CUSTOM-ID
           END-IF

           MOVE "$.d.data.component_type" TO WS-PATH
           MOVE 0 TO WS-TYPE-NUM
           CALL "DC-JSON-GET-NUMBER"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TYPE-NUM
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TYPE-NUM TO DC-INTERACTION-COMPONENT-TYPE
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
      *> JP: Raw payload 版も wrapped と同じ意味ですが path だけが異なります。
      *> EN: The raw variant has the same semantics as wrapped parsing, only with different JSON paths.
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
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-COMMAND-NAME
           END-IF

           MOVE "$.data.custom_id" TO WS-PATH
           MOVE SPACES TO WS-TEXT
           CALL "DC-JSON-GET-STRING"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TEXT
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TEXT TO DC-INTERACTION-CUSTOM-ID
           END-IF

           MOVE "$.data.component_type" TO WS-PATH
           MOVE 0 TO WS-TYPE-NUM
           CALL "DC-JSON-GET-NUMBER"
               USING DC-INTERACTION-JSON
                     WS-PATH
                     WS-TYPE-NUM
                     WS-LOCAL-RESULT
           IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
               MOVE WS-TYPE-NUM TO DC-INTERACTION-COMPONENT-TYPE
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

       PARSE-VALUE-ARRAY.
      *> JP: Select menu の values は ["a","b"] のような単純配列なので、
      *> JP: custom_id か汎用名 "value" をキーとして平坦テーブルへ積みます。
      *> EN: Select-menu values arrive as a simple array like ["a","b"].
      *> EN: We flatten them into the value table using custom_id or the generic key "value".
           MOVE 0 TO DC-INTERACTION-VALUE-COUNT
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-INTERACTION-JSON
                     WS-VALUES-PATH
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
               MOVE "Interaction values must be a JSON array."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           MOVE WS-JSON-VALUE-POS TO WS-CURSOR
           ADD 1 TO WS-CURSOR
           PERFORM UNTIL WS-CURSOR > WS-JSON-LEN
               MOVE DC-INTERACTION-JSON(WS-CURSOR:1) TO WS-CHAR
               EVALUATE WS-CHAR
                   WHEN SPACE
                   WHEN X"09"
                   WHEN X"0A"
                   WHEN X"0D"
                   WHEN ","
                       CONTINUE
                   WHEN "]"
                       EXIT PERFORM
                   WHEN QUOTE
                       COMPUTE WS-VALUE-POS = WS-CURSOR + 1
                       MOVE WS-VALUE-POS TO WS-VALUE-END
                       PERFORM UNTIL WS-VALUE-END > WS-JSON-LEN
                           MOVE DC-INTERACTION-JSON(WS-VALUE-END:1)
                               TO WS-CHAR
                           IF WS-CHAR = QUOTE
                              AND DC-INTERACTION-JSON(
                                  WS-VALUE-END - 1:1) NOT = "\"
                               EXIT PERFORM
                           END-IF
                           ADD 1 TO WS-VALUE-END
                       END-PERFORM
                       IF WS-VALUE-END > WS-JSON-LEN
                           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                           MOVE "DC_ERR_INTERACTION_PARSE"
                               TO DC-ERROR-CODE
                           MOVE "Interaction value string was not terminated."
                               TO DC-ERROR-MESSAGE
                           EXIT PARAGRAPH
                       END-IF
                       COMPUTE WS-VALUE-LEN = WS-VALUE-END - WS-VALUE-POS
                       MOVE SPACES TO WS-VALUE-NAME
                       MOVE SPACES TO WS-OPTION-VALUE
                       IF FUNCTION TRIM(DC-INTERACTION-CUSTOM-ID) = SPACES
                           MOVE "value" TO WS-VALUE-NAME
                       ELSE
                           MOVE DC-INTERACTION-CUSTOM-ID TO WS-VALUE-NAME
                       END-IF
                       IF WS-VALUE-LEN > 512
                           MOVE 512 TO WS-VALUE-LEN
                       END-IF
                       IF WS-VALUE-LEN > 0
                           MOVE DC-INTERACTION-JSON(
                               WS-VALUE-POS:WS-VALUE-LEN)
                               TO WS-OPTION-VALUE(1:WS-VALUE-LEN)
                       END-IF
                       PERFORM ADD-INTERACTION-VALUE
                       IF DC-STATUS-CODE NOT = DC-STATUS-OK
                           EXIT PARAGRAPH
                       END-IF
                       MOVE WS-VALUE-END TO WS-CURSOR
                   WHEN OTHER
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
                       MOVE "Interaction values currently support string items only."
                           TO DC-ERROR-MESSAGE
                       EXIT PARAGRAPH
               END-EVALUATE
               ADD 1 TO WS-CURSOR
           END-PERFORM
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PARSE-COMPONENT-VALUES.
      *> JP: Modal submit では components 配列の深い位置に input value が入るため、
      *> JP: ここでは最小限の JSON 走査を行って custom_id/value を持つ object だけ拾います。
      *> EN: Modal submits place input values deep inside the components array,
      *> EN: so this paragraph performs a minimal JSON walk and captures only objects with custom_id/value.
           CALL "DC-JSON-LOCATE-PATH"
               USING DC-INTERACTION-JSON
                     WS-COMPONENTS-PATH
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
               MOVE "Interaction components must be a JSON array."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           INITIALIZE WS-OBJECT-START-STACK
           MOVE WS-JSON-VALUE-POS TO WS-CURSOR
           MOVE 0 TO WS-IN-STRING
           MOVE 0 TO WS-ESCAPE-FLAG
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
                           IF WS-OBJECT-DEPTH >= 10
                               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                               MOVE "DC_ERR_INTERACTION_PARSE"
                                   TO DC-ERROR-CODE
                               MOVE "Interaction component nesting exceeded the parser limit."
                                   TO DC-ERROR-MESSAGE
                               EXIT PARAGRAPH
                           END-IF
                           ADD 1 TO WS-OBJECT-DEPTH
                           MOVE WS-CURSOR
                               TO WS-OBJECT-START-ENTRY(WS-OBJECT-DEPTH)
                       WHEN "}"
                           IF WS-OBJECT-DEPTH > 0
                               MOVE WS-OBJECT-START-ENTRY(
                                   WS-OBJECT-DEPTH)
                                   TO WS-OBJECT-START
                               COMPUTE WS-OBJECT-LENGTH =
                                   WS-CURSOR - WS-OBJECT-START + 1
                               PERFORM PARSE-COMPONENT-OBJECT
                               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                                   EXIT PARAGRAPH
                               END-IF
                               SUBTRACT 1 FROM WS-OBJECT-DEPTH
                           END-IF
                   END-EVALUATE
               END-IF
               ADD 1 TO WS-CURSOR
           END-PERFORM
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PARSE-COMPONENT-OBJECT.
      *> JP: 1 個の object 文字列から custom_id と value を抜き出し、見つかった時だけ値テーブルへ加えます。
      *> EN: Extract custom_id and value from one object slice and append it only when both matter.
           IF WS-OBJECT-LENGTH > 1024
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF

           MOVE SPACES TO WS-OPTION-JSON
           MOVE SPACES TO WS-VALUE-NAME
           MOVE SPACES TO WS-OPTION-VALUE
           IF WS-OBJECT-LENGTH > 0
               MOVE DC-INTERACTION-JSON(
                   WS-OBJECT-START:WS-OBJECT-LENGTH)
                   TO WS-OPTION-JSON(1:WS-OBJECT-LENGTH)
           END-IF

           MOVE "custom_id" TO WS-FIELD-LABEL
           MOVE 9 TO WS-FIELD-LABEL-LEN
           PERFORM LOCATE-OPTION-FIELD
           IF WS-FIELD-POS = 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-STRING-FIELD-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-VALUE-LEN > 128
               MOVE 128 TO WS-VALUE-LEN
           END-IF
           IF WS-VALUE-LEN > 0
               MOVE WS-OPTION-JSON(WS-VALUE-POS:WS-VALUE-LEN)
                   TO WS-VALUE-NAME(1:WS-VALUE-LEN)
           END-IF

           MOVE "value" TO WS-FIELD-LABEL
           MOVE 5 TO WS-FIELD-LABEL-LEN
           PERFORM LOCATE-OPTION-FIELD
           IF WS-FIELD-POS = 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               EXIT PARAGRAPH
           END-IF
           PERFORM PARSE-STRING-FIELD-VALUE
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               EXIT PARAGRAPH
           END-IF
           IF WS-VALUE-LEN > 512
               MOVE 512 TO WS-VALUE-LEN
           END-IF
           IF WS-VALUE-LEN > 0
               MOVE WS-OPTION-JSON(WS-VALUE-POS:WS-VALUE-LEN)
                   TO WS-OPTION-VALUE(1:WS-VALUE-LEN)
           END-IF
           PERFORM ADD-INTERACTION-VALUE.

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

       ADD-INTERACTION-VALUE.
      *> JP: interaction values は select/modal 共通の lookup テーブルです。
      *> EN: Interaction values form the shared lookup table used by both select and modal flows.
           IF DC-INTERACTION-VALUE-COUNT >= 25
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction value count exceeded the supported limit."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           ADD 1 TO DC-INTERACTION-VALUE-COUNT
           MOVE WS-VALUE-NAME
               TO DC-INTERACTION-VALUE-NAME(
                   DC-INTERACTION-VALUE-COUNT)
           MOVE WS-OPTION-VALUE
               TO DC-INTERACTION-VALUE-TEXT(
                   DC-INTERACTION-VALUE-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT.

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
       01 WS-NOWPLAYING-TEXT PIC X(2000).
       01 WS-FILE-OPTION PIC X(64) VALUE "file".
       01 WS-INDEX-OPTION PIC X(64) VALUE "index".
       01 WS-OPTION-VALUE PIC X(512).
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
      *> JP: 高水準 handler です。parse -> dispatch -> success/error fallback reply の順で進みます。
      *> EN: High-level handler flow: parse -> dispatch -> success/error fallback reply.
      *> JP: custom handler が payload を直接埋めた場合は、その payload を尊重して再構築しません。
      *> EN: If a custom handler already produced a payload, we preserve it and avoid rebuilding it.
           MOVE SPACES TO DC-REPLY-PAYLOAD
           MOVE SPACES TO WS-REPLY-CONTENT
           INITIALIZE WS-CMD-RESULT
           CALL "DC-INTERACTION-FROM-JSON"
               USING DC-INTERACTION-JSON
                     DC-INTERACTION
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-DISPATCH"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-REPLY-PAYLOAD
                     WS-CMD-RESULT

           IF WS-CMD-STATUS-CODE = DC-STATUS-OK
               IF FUNCTION TRIM(DC-REPLY-PAYLOAD) = SPACES
                   PERFORM BUILD-SUCCESS-REPLY
               END-IF
           ELSE
               PERFORM BUILD-ERROR-REPLY
           END-IF

           IF FUNCTION TRIM(DC-REPLY-PAYLOAD) = SPACES
               CALL "DC-INTERACTION-BUILD-REPLY"
                   USING WS-REPLY-CONTENT
                         DC-REPLY-PAYLOAD
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       BUILD-SUCCESS-REPLY.
      *> JP: built-in command だけを使う古い経路でも、最低限わかる確認文を返せるようにしています。
      *> EN: This keeps a human-readable confirmation message even for older built-in command flows.
           IF DC-INTERACTION-TYPE = 3
               MOVE "Component handled." TO WS-REPLY-CONTENT
               EXIT PARAGRAPH
           END-IF
           IF DC-INTERACTION-TYPE = 5
               MOVE "Modal submitted." TO WS-REPLY-CONTENT
               EXIT PARAGRAPH
           END-IF

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
               WHEN "/pause"
                   MOVE "Paused playback." TO WS-REPLY-CONTENT
               WHEN "/resume"
                   MOVE "Resumed playback." TO WS-REPLY-CONTENT
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
                       CALL "DC-QUEUE-FORMAT"
                           USING DC-MUSIC-QUEUE
                                 WS-REPLY-CONTENT
                                 WS-LOCAL-RESULT
                   ELSE
                       MOVE "Queue inspected." TO WS-REPLY-CONTENT
                   END-IF
               WHEN "/remove"
                   MOVE SPACES TO WS-OPTION-VALUE
                   CALL "DC-INTERACTION-GET-OPTION"
                       USING DC-INTERACTION
                             WS-INDEX-OPTION
                             WS-OPTION-VALUE
                             WS-LOCAL-RESULT
                   IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                       STRING
                           "Removed queue item " DELIMITED BY SIZE
                           FUNCTION TRIM(WS-OPTION-VALUE)
                               DELIMITED BY SIZE
                           "." DELIMITED BY SIZE
                           INTO WS-REPLY-CONTENT
                       END-STRING
                   ELSE
                       MOVE "Removed queued track." TO WS-REPLY-CONTENT
                   END-IF
               WHEN "/clearqueue"
                   MOVE "Cleared queued tracks." TO WS-REPLY-CONTENT
               WHEN "/nowplaying"
                   INITIALIZE DC-MUSIC-TRACK
                   MOVE SPACES TO WS-NOWPLAYING-TEXT
                   CALL "DC-MUSIC-NOWPLAYING"
                       USING DC-CLIENT
                             DC-GUILD-ID
                             DC-MUSIC-TRACK
                             WS-LOCAL-RESULT
                   IF WS-LOCAL-STATUS-CODE = DC-STATUS-OK
                       CALL "DC-NOWPLAYING-FORMAT"
                           USING DC-MUSIC-TRACK
                                 WS-NOWPLAYING-TEXT
                                 WS-LOCAL-RESULT
                       MOVE WS-NOWPLAYING-TEXT TO WS-REPLY-CONTENT
                   ELSE
                       MOVE "Playback inspected." TO WS-REPLY-CONTENT
                   END-IF
               WHEN OTHER
                   MOVE "Command handled." TO WS-REPLY-CONTENT
           END-EVALUATE.

       BUILD-ERROR-REPLY.
      *> JP: user 向けには message を優先し、なければ error code を露出します。
      *> EN: Prefer a human-readable message for users; fall back to the error code when needed.
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
      *> JP: Gateway dispatch から来た event が本当に INTERACTION_CREATE かをまず確認します。
      *> EN: First verify that the incoming Gateway event is actually INTERACTION_CREATE.
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
      *> JP: dispatcher 登録用の薄い adapter です。
      *> EN: Thin adapter intended to be registered with the central dispatcher.
      *> JP: 返信 payload が空なら HTTP callback を送らず、そのまま成功扱いで終わります。
      *> EN: If the reply payload is empty, no HTTP callback is sent and the handler still succeeds.
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
      *> JP: framework 既定の interaction adapter を INTERACTION_CREATE にひも付けます。
      *> EN: Register the framework's default interaction adapter for INTERACTION_CREATE.
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
      *> JP: Discord の /interactions/{id}/{token}/callback 向け HTTP request を組み立てます。
      *> EN: Build the HTTP request for Discord's /interactions/{id}/{token}/callback endpoint.
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
      *> JP: callback request を送信し、Discord が 200/204 を返したら成功とみなします。
      *> EN: Send the callback request and treat HTTP 200/204 as success.
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

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-DEFER.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-DEFERRED-PAYLOAD PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: deferred reply は builder に委譲し、そのまま通常 callback 経路で送信します。
      *> EN: Deferred replies are built first and then sent through the normal callback path.
           MOVE SPACES TO WS-DEFERRED-PAYLOAD
           CALL "DC-INTERACTION-BUILD-DEFERRED"
               USING WS-DEFERRED-PAYLOAD
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-REPLY"
               USING DC-INTERACTION
                     WS-DEFERRED-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-DEFER.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-RESOLVE-APP-ID.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-APPLICATION-ID PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-APPLICATION-ID
           DC-RESULT.
       MAIN.
      *> JP: webhook 系 endpoint では application id が必要です。
      *> EN: Webhook-family endpoints require an application id.
      *> JP: client id を優先し、未設定時だけ user id を代替値として使います。
      *> EN: Prefer client id, and only fall back to user id when the client id is still unset.
           MOVE SPACES TO DC-APPLICATION-ID
           IF FUNCTION TRIM(DC-CLIENT-ID) NOT = SPACES
               MOVE DC-CLIENT-ID TO DC-APPLICATION-ID
           ELSE
               MOVE DC-CLIENT-USER-ID TO DC-APPLICATION-ID
           END-IF
           IF FUNCTION TRIM(DC-APPLICATION-ID) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Application id is required for interaction webhook requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-RESOLVE-APP-ID.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FOLLOWUP-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).
       01 WS-BODY-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: follow-up create は webhook POST です。
      *> EN: A follow-up create operation is a webhook POST.
           INITIALIZE LK-HTTP-REQUEST
           MOVE SPACES TO WS-APPLICATION-ID

           CALL "DC-INTERACTION-RESOLVE-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for follow-up requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up payload is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD TRAILING))
               TO WS-BODY-LENGTH
           MOVE "POST" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v10/webhooks/" DELIMITED BY SIZE
               FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           MOVE "application/json" TO LK-HTTP-CONTENT-TYPE
           MOVE WS-BODY-LENGTH TO LK-HTTP-BODY-LENGTH
           IF WS-BODY-LENGTH > 0
               MOVE DC-FOLLOWUP-PAYLOAD(1:WS-BODY-LENGTH)
                   TO LK-HTTP-BODY(1:WS-BODY-LENGTH)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FOLLOWUP-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FOLLOWUP.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: build と execute を分け、request の検査テストを書きやすくしています。
      *> EN: Build and execute are separated so request-shape tests stay easy to write.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FOLLOWUP-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-PAYLOAD
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

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction follow-up did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FOLLOWUP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-WAIT-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).
       01 WS-BODY-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: wait=true 付き follow-up create は作成された message を即座に返してほしい場合に使います。
      *> EN: A follow-up create with wait=true is used when the caller wants the
      *> EN: created message returned immediately.
           INITIALIZE LK-HTTP-REQUEST
           MOVE SPACES TO WS-APPLICATION-ID

           CALL "DC-INTERACTION-RESOLVE-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for follow-up wait requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up wait payload is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD TRAILING))
               TO WS-BODY-LENGTH
           MOVE "POST" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v10/webhooks/" DELIMITED BY SIZE
               FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               "?wait=true" DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           MOVE "application/json" TO LK-HTTP-CONTENT-TYPE
           MOVE WS-BODY-LENGTH TO LK-HTTP-BODY-LENGTH
           IF WS-BODY-LENGTH > 0
               MOVE DC-FOLLOWUP-PAYLOAD(1:WS-BODY-LENGTH)
                   TO LK-HTTP-BODY(1:WS-BODY-LENGTH)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-WAIT-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-WAIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: wait-mode 実行も build と execute を分け、request 形状を独立に検証しやすくしています。
      *> EN: The wait-mode executor also splits build and execute so request
      *> EN: shape can be tested independently.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-WAIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-PAYLOAD
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

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction follow-up wait did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-WAIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-WAIT-ID.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       01 DC-FOLLOWUP-MESSAGE-ID-OUT PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-FOLLOWUP-MESSAGE-ID-OUT
           DC-RESULT.
       MAIN.
      *> JP: wait=true follow-up を送信し、返ってきた message JSON から id までまとめて取り出します。
      *> EN: Send a wait=true follow-up and extract the returned message id from
      *> EN: the response JSON in the same call.
      *>
      *> JP: 「作る -> id を抜く -> すぐ edit/delete する」というよくある流れを
      *> JP: 呼び出し側で分解しなくて済むようにする補助です。
      *> EN: This is a small convenience helper for the common
      *> EN: create -> read id -> edit/delete flow.
           MOVE SPACES TO DC-FOLLOWUP-MESSAGE-ID-OUT
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-WAIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-GET-MESSAGE-ID"
               USING LK-HTTP-RESPONSE-BODY
                     DC-FOLLOWUP-MESSAGE-ID-OUT
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-WAIT-ID.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-GET-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: follow-up 取得は /messages/{message-id} への GET です。
      *> EN: Follow-up retrieval is a GET against /messages/{message-id}.
           INITIALIZE LK-HTTP-REQUEST
           MOVE SPACES TO WS-APPLICATION-ID

           CALL "DC-INTERACTION-RESOLVE-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for follow-up get requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up message id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE "GET" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v10/webhooks/" DELIMITED BY SIZE
               FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               "/messages/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-GET-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-GET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: Discord 側が 2xx を返せば follow-up の取得成功とみなします。
      *> EN: Any 2xx response from Discord is treated as a successful follow-up retrieval.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-GET-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-MESSAGE-ID-IN
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-GET"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction follow-up get did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-GET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-EDIT-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).
       01 WS-BODY-LENGTH PIC 9(5) COMP-5.

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: follow-up edit は /messages/{message-id} への PATCH です。
      *> EN: Follow-up edit is a PATCH against /messages/{message-id}.
           INITIALIZE LK-HTTP-REQUEST
           MOVE SPACES TO WS-APPLICATION-ID

           CALL "DC-INTERACTION-RESOLVE-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for follow-up edit requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up message id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up edit payload is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE FUNCTION LENGTH(
               FUNCTION TRIM(DC-FOLLOWUP-PAYLOAD TRAILING))
               TO WS-BODY-LENGTH
           MOVE "PATCH" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v10/webhooks/" DELIMITED BY SIZE
               FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               "/messages/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           MOVE "application/json" TO LK-HTTP-CONTENT-TYPE
           MOVE WS-BODY-LENGTH TO LK-HTTP-BODY-LENGTH
           IF WS-BODY-LENGTH > 0
               MOVE DC-FOLLOWUP-PAYLOAD(1:WS-BODY-LENGTH)
                   TO LK-HTTP-BODY(1:WS-BODY-LENGTH)
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-EDIT-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-EDIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: edit 実行側も build と execute を分離して同じ検証パターンを保ちます。
      *> EN: The edit executor also keeps build/execute separate for the same testing pattern.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-EDIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-MESSAGE-ID-IN
                     DC-FOLLOWUP-PAYLOAD
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-PATCH"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction follow-up edit did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-EDIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-EDIT-MSG.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FOLLOWUP-MESSAGE-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-JSON PIC X(8192).
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-JSON
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: すでに受け取っている follow-up message JSON から id を引き直し、
      *> JP: そのまま edit まで進める高水準 helper です。
      *> EN: High-level helper that re-extracts the id from an already available
      *> EN: follow-up message JSON and proceeds directly into edit.
           MOVE SPACES TO WS-FOLLOWUP-MESSAGE-ID
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-GET-MESSAGE-ID"
               USING DC-FOLLOWUP-MESSAGE-JSON
                     WS-FOLLOWUP-MESSAGE-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-FUP-EDIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-ID
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-EDIT-MSG.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-WAIT-EDIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FOLLOWUP-MESSAGE-JSON PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 DC-EDIT-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           DC-EDIT-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: wait=true で作った follow-up を、その返却 message を使って即座に edit します。
      *> EN: Create a wait=true follow-up, then immediately edit it using the
      *> EN: returned message JSON.
           MOVE SPACES TO WS-FOLLOWUP-MESSAGE-JSON
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-WAIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE LK-HTTP-RESPONSE-BODY TO WS-FOLLOWUP-MESSAGE-JSON
           CALL "DC-INTERACTION-FUP-EDIT-MSG"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-JSON
                     DC-EDIT-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-WAIT-EDIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-DEL-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-APPLICATION-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: follow-up delete は body を持たない DELETE request を組み立てます。
      *> EN: Follow-up delete builds a body-less DELETE request.
           INITIALIZE LK-HTTP-REQUEST
           MOVE SPACES TO WS-APPLICATION-ID

           CALL "DC-INTERACTION-RESOLVE-APP-ID"
               USING DC-CLIENT
                     WS-APPLICATION-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-INTERACTION-TOKEN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Interaction token is required for follow-up delete requests."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_PARSE" TO DC-ERROR-CODE
               MOVE "Follow-up message id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE "DELETE" TO LK-HTTP-METHOD
           MOVE "discord.com" TO LK-HTTP-HOST
           STRING
               "/api/v10/webhooks/" DELIMITED BY SIZE
               FUNCTION TRIM(WS-APPLICATION-ID) DELIMITED BY SIZE
               "/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-INTERACTION-TOKEN) DELIMITED BY SIZE
               "/messages/" DELIMITED BY SIZE
               FUNCTION TRIM(DC-FOLLOWUP-MESSAGE-ID-IN) DELIMITED BY SIZE
               INTO LK-HTTP-PATH
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-DEL-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-DEL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-net.cpy".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-ID-IN PIC X(32).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-ID-IN
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: Discord 側が 2xx を返せば削除成功とみなします。
      *> EN: Any 2xx response from Discord is treated as a successful delete.
           INITIALIZE DC-HTTP-REQUEST
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-DEL-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-MESSAGE-ID-IN
                     DC-HTTP-REQUEST
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-HTTP-DELETE"
               USING DC-HTTP-REQUEST
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           IF LK-HTTP-STATUS-CODE < 200
              OR LK-HTTP-STATUS-CODE >= 300
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "Interaction follow-up delete did not return success."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-DEL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-DEL-MSG.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FOLLOWUP-MESSAGE-ID PIC X(32).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-MESSAGE-JSON PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-MESSAGE-JSON
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: follow-up message JSON をそのまま delete に渡せる高水準 helper です。
      *> EN: High-level helper that lets callers pass a follow-up message JSON
      *> EN: directly into delete.
           MOVE SPACES TO WS-FOLLOWUP-MESSAGE-ID
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-GET-MESSAGE-ID"
               USING DC-FOLLOWUP-MESSAGE-JSON
                     WS-FOLLOWUP-MESSAGE-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           CALL "DC-INTERACTION-FUP-DEL"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-ID
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-DEL-MSG.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-FUP-WAIT-DEL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-FOLLOWUP-MESSAGE-JSON PIC X(8192).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: wait=true で作った follow-up を、その返却 message を使って即座に delete します。
      *> EN: Create a wait=true follow-up, then immediately delete it using the
      *> EN: returned message JSON.
           MOVE SPACES TO WS-FOLLOWUP-MESSAGE-JSON
           INITIALIZE LK-HTTP-RESPONSE

           CALL "DC-INTERACTION-FUP-WAIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           MOVE LK-HTTP-RESPONSE-BODY TO WS-FOLLOWUP-MESSAGE-JSON
           CALL "DC-INTERACTION-FUP-DEL-MSG"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-FOLLOWUP-MESSAGE-JSON
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-FUP-WAIT-DEL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-EDIT-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
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
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: original response は follow-up API の特殊 ID "@original" で表現します。
      *> EN: The original response is expressed through the special follow-up id "@original".
           CALL "DC-INTERACTION-FUP-EDIT-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-EDIT-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-EDIT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 DC-FOLLOWUP-PAYLOAD PIC X(8192).
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           DC-FOLLOWUP-PAYLOAD
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: 実装重複を避けるため、original edit も汎用 follow-up edit に委譲します。
      *> EN: To avoid duplication, original edit delegates to the generic follow-up edit helper.
           CALL "DC-INTERACTION-FUP-EDIT"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     DC-FOLLOWUP-PAYLOAD
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-EDIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-GET-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
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
           DC-CLIENT
           DC-INTERACTION
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: original response 取得も follow-up get の特殊 ID 版です。
      *> EN: Original-response retrieval is the special-id variant of follow-up get.
           CALL "DC-INTERACTION-FUP-GET-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-GET-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-GET.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: original response 取得実行も汎用 follow-up get helper に委譲します。
      *> EN: Original-response retrieval also delegates to the generic follow-up get helper.
           CALL "DC-INTERACTION-FUP-GET"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-GET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-DEL-BUILD.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
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
           DC-CLIENT
           DC-INTERACTION
           LK-HTTP-REQUEST
           DC-RESULT.
       MAIN.
      *> JP: original delete も "@original" を使うだけで、wire format 自体は同じです。
      *> EN: Original delete only swaps in "@original"; the wire format is otherwise identical.
           CALL "DC-INTERACTION-FUP-DEL-BUILD"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     LK-HTTP-REQUEST
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-DEL-BUILD.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ORIG-DEL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-MESSAGE-ID PIC X(32) VALUE "@original".

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       01 LK-HTTP-RESPONSE.
          05 LK-HTTP-STATUS-CODE PIC 9(3) COMP-5.
          05 LK-HTTP-HEADER-LENGTH PIC 9(5) COMP-5.
          05 LK-HTTP-RAW-HEADERS PIC X(4096).
          05 LK-HTTP-RESPONSE-BODY-LENGTH PIC 9(9) COMP-5.
          05 LK-HTTP-RESPONSE-BODY PIC X(8192).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-INTERACTION
           LK-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
      *> JP: original delete 実行も汎用 follow-up delete helper に委譲します。
      *> EN: Original delete execution also delegates to the generic follow-up delete helper.
           CALL "DC-INTERACTION-FUP-DEL"
               USING DC-CLIENT
                     DC-INTERACTION
                     WS-ORIGINAL-MESSAGE-ID
                     LK-HTTP-RESPONSE
                     DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ORIG-DEL.
