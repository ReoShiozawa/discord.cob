       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-PROC-SPAWN.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-PIPE-TO-CHILD.
          05 WS-PIPE-TO-CHILD-FD OCCURS 2 TIMES PIC S9(9) COMP-5.
       01 WS-PIPE-FROM-CHILD.
          05 WS-PIPE-FROM-CHILD-FD OCCURS 2 TIMES PIC S9(9) COMP-5.
       01 WS-STATUS PIC S9(9) COMP-5.
       01 WS-CHILD-PID PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 DC-PROC-COMMAND PIC X(512).
       01 DC-PROC-READ-FD PIC S9(9) COMP-5.
       01 DC-PROC-WRITE-FD PIC S9(9) COMP-5.
       01 DC-PROC-PID PIC S9(9) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PROC-COMMAND
           DC-PROC-READ-FD
           DC-PROC-WRITE-FD
           DC-PROC-PID
           DC-RESULT.
       MAIN.
           MOVE -1 TO DC-PROC-READ-FD
           MOVE -1 TO DC-PROC-WRITE-FD
           MOVE 0 TO DC-PROC-PID
           INITIALIZE WS-PIPE-TO-CHILD
           INITIALIZE WS-PIPE-FROM-CHILD

           IF FUNCTION TRIM(DC-PROC-COMMAND) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process command is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL STATIC "pipe"
               USING BY REFERENCE WS-PIPE-TO-CHILD
               RETURNING WS-STATUS
           END-CALL
           IF WS-STATUS NOT = 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Failed to create stdin pipe for child process."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL STATIC "pipe"
               USING BY REFERENCE WS-PIPE-FROM-CHILD
               RETURNING WS-STATUS
           END-CALL
           IF WS-STATUS NOT = 0
               CALL STATIC "close"
                   USING BY VALUE WS-PIPE-TO-CHILD-FD(1)
               END-CALL
               CALL STATIC "close"
                   USING BY VALUE WS-PIPE-TO-CHILD-FD(2)
               END-CALL
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Failed to create stdout pipe for child process."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "CBL_GC_FORK" RETURNING WS-CHILD-PID END-CALL
           EVALUATE TRUE
               WHEN WS-CHILD-PID = 0
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(2)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(1)
                   END-CALL
                   CALL STATIC "dup2"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(1)
                             BY VALUE 0
                       RETURNING WS-STATUS
                   END-CALL
                   IF WS-STATUS < 0
                       CALL STATIC "_exit" USING BY VALUE 126 END-CALL
                   END-IF
                   CALL STATIC "dup2"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(2)
                             BY VALUE 1
                       RETURNING WS-STATUS
                   END-CALL
                   IF WS-STATUS < 0
                       CALL STATIC "_exit" USING BY VALUE 126 END-CALL
                   END-IF
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(1)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(2)
                   END-CALL
                   CALL "SYSTEM" USING DC-PROC-COMMAND END-CALL
                   CALL STATIC "_exit" USING BY VALUE 0 END-CALL
               WHEN WS-CHILD-PID > 0
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(1)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(2)
                   END-CALL
                   MOVE WS-PIPE-FROM-CHILD-FD(1) TO DC-PROC-READ-FD
                   MOVE WS-PIPE-TO-CHILD-FD(2) TO DC-PROC-WRITE-FD
                   MOVE WS-CHILD-PID TO DC-PROC-PID
                   CALL "DC-RESULT-OK" USING DC-RESULT
                   GOBACK
               WHEN OTHER
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(1)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-TO-CHILD-FD(2)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(1)
                   END-CALL
                   CALL STATIC "close"
                       USING BY VALUE WS-PIPE-FROM-CHILD-FD(2)
                   END-CALL
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
                   MOVE "Failed to fork child process."
                       TO DC-ERROR-MESSAGE
                   GOBACK
           END-EVALUATE.
       END PROGRAM DC-PROC-SPAWN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-PROC-WRITE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BYTES-WRITTEN PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 DC-PROC-FD PIC S9(9) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PROC-FD
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           IF DC-PROC-FD < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process write descriptor is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-HTTP-BUFFER-LENGTH < 0 OR DC-HTTP-BUFFER-LENGTH > 16384
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process write buffer length is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-HTTP-BUFFER-LENGTH = 0
               CALL "DC-RESULT-OK" USING DC-RESULT
               GOBACK
           END-IF

           CALL STATIC "write"
               USING BY VALUE DC-PROC-FD
                     BY REFERENCE DC-HTTP-BUFFER-DATA
                     BY VALUE DC-HTTP-BUFFER-LENGTH
               RETURNING WS-BYTES-WRITTEN
           END-CALL

           IF WS-BYTES-WRITTEN < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process write failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-BYTES-WRITTEN NOT = DC-HTTP-BUFFER-LENGTH
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process write was incomplete."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-PROC-WRITE.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-PROC-READ.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-BYTES-READ PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 DC-PROC-FD PIC S9(9) COMP-5.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PROC-FD
           DC-HTTP-BUFFER
           DC-RESULT.
       MAIN.
           MOVE 0 TO DC-HTTP-BUFFER-LENGTH
           MOVE SPACES TO DC-HTTP-BUFFER-DATA

           IF DC-PROC-FD < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process read descriptor is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           CALL STATIC "read"
               USING BY VALUE DC-PROC-FD
                     BY REFERENCE DC-HTTP-BUFFER-DATA
                     BY VALUE 16384
               RETURNING WS-BYTES-READ
           END-CALL

           IF WS-BYTES-READ < 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_PROCESS" TO DC-ERROR-CODE
               MOVE "Process read failed."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF WS-BYTES-READ = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "Process stream reached EOF."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE WS-BYTES-READ TO DC-HTTP-BUFFER-LENGTH
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-PROC-READ.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-PROC-CLOSE.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-WAIT-STATUS PIC S9(9) COMP-5.
       01 WS-WAIT-DETAIL PIC S9(9) COMP-5.

       LINKAGE SECTION.
       01 DC-PROC-PID PIC S9(9) COMP-5.
       01 DC-PROC-READ-FD PIC S9(9) COMP-5.
       01 DC-PROC-WRITE-FD PIC S9(9) COMP-5.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-PROC-PID
           DC-PROC-READ-FD
           DC-PROC-WRITE-FD
           DC-RESULT.
       MAIN.
           IF DC-PROC-WRITE-FD >= 0
               CALL STATIC "close"
                   USING BY VALUE DC-PROC-WRITE-FD
               END-CALL
           END-IF

           IF DC-PROC-READ-FD >= 0
               CALL STATIC "close"
                   USING BY VALUE DC-PROC-READ-FD
               END-CALL
           END-IF

           IF DC-PROC-PID > 0
               CALL STATIC "waitpid"
                   USING BY VALUE DC-PROC-PID
                         BY REFERENCE WS-WAIT-DETAIL
                         BY VALUE 0
                   RETURNING WS-WAIT-STATUS
               END-CALL
           END-IF

           MOVE -1 TO DC-PROC-READ-FD
           MOVE -1 TO DC-PROC-WRITE-FD
           MOVE 0 TO DC-PROC-PID
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-PROC-CLOSE.
