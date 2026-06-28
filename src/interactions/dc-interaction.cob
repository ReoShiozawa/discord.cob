       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-INTERACTION-GET-OPTION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-FOUND-FLAG PIC 9.

       LINKAGE SECTION.
       COPY "discord-interaction.cpy".
       01 DC-OPTION-NAME-IN PIC X(64).
       01 DC-OPTION-VALUE-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-INTERACTION
           DC-OPTION-NAME-IN
           DC-OPTION-VALUE-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-OPTION-VALUE-OUT
           MOVE 0 TO WS-FOUND-FLAG
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-COMMAND-OPTION-COUNT
                  OR WS-FOUND-FLAG = 1
               IF FUNCTION TRIM(DC-COMMAND-OPTION-NAME(WS-IDX))
                   = FUNCTION TRIM(DC-OPTION-NAME-IN)
                   MOVE DC-COMMAND-OPTION-VALUE(WS-IDX)
                       TO DC-OPTION-VALUE-OUT
                   MOVE 1 TO WS-FOUND-FLAG
               END-IF
           END-PERFORM
           IF WS-FOUND-FLAG = 1
               CALL "DC-RESULT-OK" USING DC-RESULT
           ELSE
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_INTERACTION_OPTION" TO DC-ERROR-CODE
               MOVE "Interaction option was not found."
                   TO DC-ERROR-MESSAGE
           END-IF
           GOBACK.
       END PROGRAM DC-INTERACTION-GET-OPTION.
