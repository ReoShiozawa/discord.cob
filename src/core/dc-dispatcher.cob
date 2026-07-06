       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-ON.
       *> JP: event 名と handler program 名を結び、実際に dispatch する core 入口です。
       *> JP: 登録表の更新と呼び出しの責務をここにまとめています。
       *> EN: Core entry point that binds event names to handler program names and dispatches them.
       *> EN: Registration-table updates and actual invocation live together here.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       LINKAGE SECTION.
       COPY "discord-client.cpy".
       01 DC-IN-EVENT-NAME PIC X(64).
       01 DC-IN-PROGRAM-NAME PIC X(64).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-CLIENT
           DC-IN-EVENT-NAME
           DC-IN-PROGRAM-NAME
           DC-RESULT.
       MAIN.
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-HANDLER-COUNT
               IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-IN-EVENT-NAME)
      *> JP: event ごとの dispatch slot は 1 本なので、同名再登録は追加ではなく差し替えます。
      *> EN: Each event has a single dispatch slot, so re-registering the same
      *> EN: event replaces the existing program instead of appending another row.
                   MOVE DC-IN-PROGRAM-NAME
                       TO DC-HANDLER-PROGRAM(WS-IDX)
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               END-IF
           END-PERFORM

           IF DC-HANDLER-COUNT >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_TABLE_FULL" TO DC-ERROR-CODE
               MOVE "Event handler table is full." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           ADD 1 TO DC-HANDLER-COUNT
           MOVE DC-IN-EVENT-NAME
               TO DC-HANDLER-EVENT-NAME(DC-HANDLER-COUNT)
           MOVE DC-IN-PROGRAM-NAME
               TO DC-HANDLER-PROGRAM(DC-HANDLER-COUNT)
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-ON.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-DISPATCH.
       *> JP: event 名と handler program 名を結び、実際に dispatch する core 入口です。
       *> JP: 登録表の更新と呼び出しの責務をここにまとめています。
       *> EN: Core entry point that binds event names to handler program names and dispatches them.
       *> EN: Registration-table updates and actual invocation live together here.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FOUND-FLAG PIC 9.
       01 WS-PROGRAM-NAME PIC X(64).

       LINKAGE SECTION.
       COPY "discord-client.cpy".
       COPY "discord-event.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-CLIENT DC-EVENT DC-RESULT.
       MAIN.
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-HANDLER-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-HANDLER-EVENT-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-EVENT-NAME)
                   MOVE DC-HANDLER-PROGRAM(WS-IDX)
                       TO WS-PROGRAM-NAME
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM

           IF WS-FOUND-FLAG = 0
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_HANDLER_NOT_FOUND" TO DC-ERROR-CODE
               MOVE "No handler registered for event."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL WS-PROGRAM-NAME USING DC-CLIENT DC-EVENT DC-RESULT
           GOBACK.
       END PROGRAM DC-DISPATCH.
