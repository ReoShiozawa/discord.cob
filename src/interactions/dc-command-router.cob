       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ON-COMMAND.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-COMMAND-NAME-IN PIC X(128).
       01 DC-PROGRAM-NAME-IN PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-COMMAND-NAME-IN
           DC-PROGRAM-NAME-IN
           DC-RESULT.
       MAIN.
      *> JP: Slash command 名と handler program 名の対応を client に登録します。
      *> EN: Register the mapping from slash-command name to handler program on the client.
           IF FUNCTION TRIM(DC-COMMAND-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction command name is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-PROGRAM-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction command handler program is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-COMMAND-COUNT
               IF FUNCTION TRIM(DC-IA-COMMAND-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-COMMAND-NAME-IN)
                   MOVE DC-PROGRAM-NAME-IN
                       TO DC-IA-COMMAND-PROGRAM(WS-IDX)
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM
           IF DC-IA-COMMAND-COUNT >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_TABLE_FULL" TO DC-ERROR-CODE
               MOVE "Interaction command handler table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-IA-COMMAND-COUNT
           MOVE DC-COMMAND-NAME-IN
               TO DC-IA-COMMAND-NAME(DC-IA-COMMAND-COUNT)
           MOVE DC-PROGRAM-NAME-IN
               TO DC-IA-COMMAND-PROGRAM(DC-IA-COMMAND-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ON-COMMAND.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ON-COMPONENT.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-COMPONENT-ID-IN PIC X(128).
       01 DC-PROGRAM-NAME-IN PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-COMPONENT-ID-IN
           DC-PROGRAM-NAME-IN
           DC-RESULT.
       MAIN.
      *> JP: Button/select など component custom_id 用の handler を登録します。
      *> EN: Register a handler for component custom_id values such as buttons/selects.
           IF FUNCTION TRIM(DC-COMPONENT-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction component id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-PROGRAM-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction component handler program is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-COMPONENT-COUNT
               IF FUNCTION TRIM(DC-IA-COMPONENT-ID(WS-IDX))
                   = FUNCTION TRIM(DC-COMPONENT-ID-IN)
                   MOVE DC-PROGRAM-NAME-IN
                       TO DC-IA-COMPONENT-PROGRAM(WS-IDX)
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM
           IF DC-IA-COMPONENT-COUNT >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_TABLE_FULL" TO DC-ERROR-CODE
               MOVE "Interaction component handler table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-IA-COMPONENT-COUNT
           MOVE DC-COMPONENT-ID-IN
               TO DC-IA-COMPONENT-ID(DC-IA-COMPONENT-COUNT)
           MOVE DC-PROGRAM-NAME-IN
               TO DC-IA-COMPONENT-PROGRAM(DC-IA-COMPONENT-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ON-COMPONENT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-ON-MODAL.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-MODAL-ID-IN PIC X(128).
       01 DC-PROGRAM-NAME-IN PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-MODAL-ID-IN
           DC-PROGRAM-NAME-IN
           DC-RESULT.
       MAIN.
      *> JP: Modal submit custom_id 用の handler を登録します。
      *> EN: Register a handler for modal-submit custom_id values.
           IF FUNCTION TRIM(DC-MODAL-ID-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction modal id is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           IF FUNCTION TRIM(DC-PROGRAM-NAME-IN) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NAME" TO DC-ERROR-CODE
               MOVE "Interaction modal handler program is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-MODAL-COUNT
               IF FUNCTION TRIM(DC-IA-MODAL-ID(WS-IDX))
                   = FUNCTION TRIM(DC-MODAL-ID-IN)
                   MOVE DC-PROGRAM-NAME-IN
                       TO DC-IA-MODAL-PROGRAM(WS-IDX)
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM
           IF DC-IA-MODAL-COUNT >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_TABLE_FULL" TO DC-ERROR-CODE
               MOVE "Interaction modal handler table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-IA-MODAL-COUNT
           MOVE DC-MODAL-ID-IN
               TO DC-IA-MODAL-ID(DC-IA-MODAL-COUNT)
           MOVE DC-PROGRAM-NAME-IN
               TO DC-IA-MODAL-PROGRAM(DC-IA-MODAL-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-INTERACTION-ON-MODAL.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-DISPATCH.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FOUND-FLAG PIC 9.
       01 WS-PROGRAM-NAME PIC X(64).

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
      *> JP: Interaction type ごとに登録済み handler を探し、見つかればその program を呼びます。
      *> EN: Resolve the registered handler by interaction type and call it if found.
      *> JP: Command は custom handler を優先し、未登録なら built-in router へフォールバックします。
      *> JP: autocomplete(type=4) も command 名ベースの custom handler を再利用します。
      *> EN: Commands prefer custom handlers and fall back to the built-in router when absent.
      *> EN: Autocomplete interactions (type=4) reuse command-name custom handlers.
           MOVE SPACES TO WS-PROGRAM-NAME
           MOVE 0 TO WS-FOUND-FLAG

           EVALUATE DC-INTERACTION-TYPE
               WHEN 2
                   PERFORM FIND-COMMAND-HANDLER
                   IF WS-FOUND-FLAG = 1
                       CALL WS-PROGRAM-NAME
                           USING DC-CLIENT
                                 DC-INTERACTION
                                 DC-REPLY-PAYLOAD
                                 DC-RESULT
                   ELSE
                       CALL "DC-COMMAND-ROUTE"
                           USING DC-CLIENT
                                 DC-INTERACTION
                                 DC-RESULT
                   END-IF
               WHEN 3
                   PERFORM FIND-COMPONENT-HANDLER
                   IF WS-FOUND-FLAG = 1
                       CALL WS-PROGRAM-NAME
                           USING DC-CLIENT
                                 DC-INTERACTION
                                 DC-REPLY-PAYLOAD
                                 DC-RESULT
                   ELSE
                       MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                       MOVE "DC_ERR_COMPONENT_NOT_FOUND" TO DC-ERROR-CODE
                       MOVE "Component interaction is not registered."
                           TO DC-ERROR-MESSAGE
                   END-IF
               WHEN 4
                   PERFORM FIND-COMMAND-HANDLER
                   IF WS-FOUND-FLAG = 1
                       CALL WS-PROGRAM-NAME
                           USING DC-CLIENT
                                 DC-INTERACTION
                                 DC-REPLY-PAYLOAD
                                 DC-RESULT
                   ELSE
                       MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                       MOVE "DC_ERR_AUTOCOMPLETE_NOT_FOUND"
                           TO DC-ERROR-CODE
                       MOVE "Autocomplete interaction is not registered."
                           TO DC-ERROR-MESSAGE
                   END-IF
               WHEN 5
                   PERFORM FIND-MODAL-HANDLER
                   IF WS-FOUND-FLAG = 1
                       CALL WS-PROGRAM-NAME
                           USING DC-CLIENT
                                 DC-INTERACTION
                                 DC-REPLY-PAYLOAD
                                 DC-RESULT
                   ELSE
                       MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                       MOVE "DC_ERR_MODAL_NOT_FOUND" TO DC-ERROR-CODE
                       MOVE "Modal interaction is not registered."
                           TO DC-ERROR-MESSAGE
                   END-IF
               WHEN OTHER
                   MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                   MOVE "DC_ERR_INTERACTION_TYPE" TO DC-ERROR-CODE
                   MOVE "Interaction type is not supported by the dispatcher."
                       TO DC-ERROR-MESSAGE
           END-EVALUATE
           GOBACK.

       FIND-COMMAND-HANDLER.
      *> JP: slash command 名の完全一致で先頭から探索します。
      *> EN: Linear search by exact slash-command name match.
           MOVE SPACES TO WS-PROGRAM-NAME
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-COMMAND-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-IA-COMMAND-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-COMMAND-NAME)
                   MOVE DC-IA-COMMAND-PROGRAM(WS-IDX)
                       TO WS-PROGRAM-NAME
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM.

       FIND-COMPONENT-HANDLER.
      *> JP: component custom_id の完全一致で探索します。
      *> EN: Linear search by exact component custom_id match.
           MOVE SPACES TO WS-PROGRAM-NAME
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-COMPONENT-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-IA-COMPONENT-ID(WS-IDX))
                   = FUNCTION TRIM(DC-INTERACTION-CUSTOM-ID)
                   MOVE DC-IA-COMPONENT-PROGRAM(WS-IDX)
                       TO WS-PROGRAM-NAME
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM.

       FIND-MODAL-HANDLER.
      *> JP: modal submit custom_id の完全一致で探索します。
      *> EN: Linear search by exact modal-submit custom_id match.
           MOVE SPACES TO WS-PROGRAM-NAME
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-IA-MODAL-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-IA-MODAL-ID(WS-IDX))
                   = FUNCTION TRIM(DC-INTERACTION-CUSTOM-ID)
                   MOVE DC-IA-MODAL-PROGRAM(WS-IDX)
                       TO WS-PROGRAM-NAME
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM.
       END PROGRAM DC-INTERACTION-DISPATCH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-COMMAND-ROUTE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-interaction.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-INTERACTION DC-RESULT.
       MAIN.
      *> JP: ここは framework 内蔵の slash command 群への最終フォールバックです。
      *> EN: This is the final fallback router for built-in framework slash commands.
           EVALUATE FUNCTION TRIM(DC-COMMAND-NAME)
               WHEN "/join"
                   CALL "DC-MUSIC-CMD-JOIN"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/leave"
                   CALL "DC-MUSIC-CMD-LEAVE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/play"
                   CALL "DC-MUSIC-CMD-PLAY"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/skip"
                   CALL "DC-MUSIC-CMD-SKIP"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/pause"
                   CALL "DC-MUSIC-CMD-PAUSE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/resume"
                   CALL "DC-MUSIC-CMD-RESUME"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/stop"
                   CALL "DC-MUSIC-CMD-STOP"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/queue"
                   CALL "DC-MUSIC-CMD-QUEUE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/remove"
                   CALL "DC-MUSIC-CMD-REMOVE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/clearqueue"
                   CALL "DC-MUSIC-CMD-CLEARQUEUE"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN "/nowplaying"
                   CALL "DC-MUSIC-CMD-NOWPLAYING"
                       USING DC-CLIENT
                             DC-INTERACTION
                             DC-RESULT
               WHEN OTHER
                   MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
                   MOVE "DC_ERR_COMMAND_NOT_FOUND" TO DC-ERROR-CODE
                   MOVE "Slash command is not registered."
                       TO DC-ERROR-MESSAGE
           END-EVALUATE
           GOBACK.
       END PROGRAM DC-COMMAND-ROUTE.
