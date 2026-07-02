       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OGG-OPUS-OPEN.
       *> JP: Ogg Opus ファイルを開き、1 frame ずつ読み、閉じる reader helper 群です。
       *> JP: file container 側の段取りを music playback から切り離す役割があります。
       *> EN: Reader helpers that open Ogg Opus files, read one frame at a time, and close them.
       *> EN: They separate container-level file handling from the higher-level music playback flow.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-opus-store.cpy".
       COPY "discord-net.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-PROC-READ-FD PIC S9(9) COMP-5.
       01 WS-PROC-WRITE-FD PIC S9(9) COMP-5.
       01 WS-PROC-PID PIC S9(9) COMP-5.
       01 WS-COMMAND PIC X(1024).
       01 WS-DOUBLE-QUOTE PIC X VALUE X"22".
       01 WS-TOTAL-LENGTH PIC 9(9) COMP-5.
       01 WS-READ-RESULT.
          05 WS-READ-STATUS PIC S9(9) COMP-5.
          05 WS-READ-ERROR-CODE PIC X(64).
          05 WS-READ-ERROR-MESSAGE PIC X(256).
       01 WS-CLOSE-RESULT.
          05 WS-CLOSE-STATUS PIC S9(9) COMP-5.
          05 WS-CLOSE-ERROR-CODE PIC X(64).
          05 WS-CLOSE-ERROR-MESSAGE PIC X(256).

       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-AUDIO-SOURCE
           DC-OPUS-HANDLE
           DC-RESULT.
       MAIN.
           INITIALIZE DC-OPUS-HANDLE
           IF FUNCTION TRIM(DC-AUDIO-SOURCE) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_SOURCE" TO DC-ERROR-CODE
               MOVE "Opus source path is required."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-IDX
           PERFORM VARYING WS-IDX FROM 1 BY 1
               UNTIL WS-IDX > DC-OPUS-MAX-HANDLES
                  OR DC-OPUS-ENTRY-IN-USE(WS-IDX) = 0
               CONTINUE
           END-PERFORM

           IF WS-IDX > DC-OPUS-MAX-HANDLES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_POOL_FULL" TO DC-ERROR-CODE
               MOVE "Opus reader table is full."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           INITIALIZE DC-OPUS-REGISTRY-ENTRY(WS-IDX)
           MOVE 1 TO DC-OPUS-ENTRY-IN-USE(WS-IDX)
           MOVE DC-AUDIO-SOURCE TO DC-OPUS-ENTRY-SOURCE(WS-IDX)

           MOVE SPACES TO WS-COMMAND
           STRING
               "cat " DELIMITED BY SIZE
               WS-DOUBLE-QUOTE DELIMITED BY SIZE
               FUNCTION TRIM(DC-AUDIO-SOURCE) DELIMITED BY SIZE
               WS-DOUBLE-QUOTE DELIMITED BY SIZE
               INTO WS-COMMAND
           END-STRING

           CALL "DC-PROC-SPAWN"
               USING WS-COMMAND
                     WS-PROC-READ-FD
                     WS-PROC-WRITE-FD
                     WS-PROC-PID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               INITIALIZE DC-OPUS-REGISTRY-ENTRY(WS-IDX)
               GOBACK
           END-IF

       MOVE 0 TO WS-TOTAL-LENGTH
       MOVE 0 TO WS-READ-STATUS
       PERFORM UNTIL WS-READ-STATUS = DC-STATUS-EOF
           CALL "DC-PROC-READ"
               USING WS-PROC-READ-FD
                     DC-HTTP-BUFFER
                     WS-READ-RESULT
               IF WS-READ-STATUS = DC-STATUS-OK
                   IF WS-TOTAL-LENGTH + DC-HTTP-BUFFER-LENGTH
                       > DC-OPUS-BUFFER-MAX-BYTES
                       CALL "DC-PROC-CLOSE"
                           USING WS-PROC-PID
                                 WS-PROC-READ-FD
                                 WS-PROC-WRITE-FD
                                 WS-CLOSE-RESULT
                       INITIALIZE DC-OPUS-REGISTRY-ENTRY(WS-IDX)
                       MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                       MOVE "DC_ERR_OPUS_TOO_LARGE" TO DC-ERROR-CODE
                       MOVE "Opus source exceeded the reader buffer."
                           TO DC-ERROR-MESSAGE
                       GOBACK
                   END-IF
                   IF DC-HTTP-BUFFER-LENGTH > 0
                       MOVE DC-HTTP-BUFFER-DATA(1:DC-HTTP-BUFFER-LENGTH)
                           TO DC-OPUS-ENTRY-BUFFER(WS-IDX)(
                               WS-TOTAL-LENGTH + 1:DC-HTTP-BUFFER-LENGTH)
                       ADD DC-HTTP-BUFFER-LENGTH TO WS-TOTAL-LENGTH
                   END-IF
               ELSE
                   IF WS-READ-STATUS = DC-STATUS-EOF
                       EXIT PERFORM
                   END-IF
                   CALL "DC-PROC-CLOSE"
                       USING WS-PROC-PID
                             WS-PROC-READ-FD
                             WS-PROC-WRITE-FD
                             WS-CLOSE-RESULT
                   INITIALIZE DC-OPUS-REGISTRY-ENTRY(WS-IDX)
                   MOVE WS-READ-STATUS TO DC-STATUS-CODE
                   MOVE WS-READ-ERROR-CODE TO DC-ERROR-CODE
                   MOVE WS-READ-ERROR-MESSAGE TO DC-ERROR-MESSAGE
                   GOBACK
               END-IF
           END-PERFORM

           CALL "DC-PROC-CLOSE"
               USING WS-PROC-PID
                     WS-PROC-READ-FD
                     WS-PROC-WRITE-FD
                     WS-CLOSE-RESULT

           IF WS-TOTAL-LENGTH = 0
               INITIALIZE DC-OPUS-REGISTRY-ENTRY(WS-IDX)
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_SOURCE" TO DC-ERROR-CODE
               MOVE "Opus source file was empty or unreadable."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE WS-TOTAL-LENGTH TO DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
           MOVE 1 TO DC-OPUS-ENTRY-NEXT-PAGE-POS(WS-IDX)
           MOVE 0 TO DC-OPUS-ENTRY-PAGE-ACTIVE(WS-IDX)
           MOVE 0 TO DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
           MOVE SPACES TO DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)

           MOVE WS-IDX TO DC-OPUS-HANDLE-ID
           MOVE DC-AUDIO-SOURCE TO DC-OPUS-SOURCE
           MOVE 0 TO DC-OPUS-EOF-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-OGG-OPUS-OPEN.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OGG-OPUS-READ-FRAME.
       *> JP: Ogg Opus ファイルを開き、1 frame ずつ読み、閉じる reader helper 群です。
       *> JP: file container 側の段取りを music playback から切り離す役割があります。
       *> EN: Reader helpers that open Ogg Opus files, read one frame at a time, and close them.
       *> EN: They separate container-level file handling from the higher-level music playback flow.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-opus-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-PAGE-POS PIC 9(9) COMP-5.
       01 WS-SEGMENT-IDX PIC 9(4) COMP-5.
       01 WS-SEGMENT-LENGTH PIC 9(4) COMP-5.
       01 WS-PAGE-BODY-LENGTH PIC 9(9) COMP-5.
       01 WS-PACKET-READY PIC 9.

       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-OPUS-HANDLE
           DC-OPUS-FRAME
           DC-RESULT.
       MAIN.
           INITIALIZE DC-OPUS-FRAME
           MOVE 0 TO WS-PACKET-READY
           MOVE DC-OPUS-HANDLE-ID TO WS-IDX
           IF WS-IDX < 1 OR WS-IDX > DC-OPUS-MAX-HANDLES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_HANDLE" TO DC-ERROR-CODE
               MOVE "Opus handle is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-OPUS-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_HANDLE" TO DC-ERROR-CODE
               MOVE "Opus handle is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-OPUS-EOF-FLAG = 1
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "Opus stream reached EOF."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           PERFORM UNTIL WS-PACKET-READY = 1
               IF DC-OPUS-ENTRY-PAGE-ACTIVE(WS-IDX) NOT = 1
                   PERFORM LOAD-NEXT-PAGE
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       IF DC-STATUS-CODE = DC-STATUS-EOF
                           MOVE 1 TO DC-OPUS-EOF-FLAG
                       END-IF
                       GOBACK
                   END-IF
               END-IF

               PERFORM PARSE-PAGE-SEGMENTS
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   IF DC-STATUS-CODE = DC-STATUS-EOF
                       MOVE 1 TO DC-OPUS-EOF-FLAG
                   END-IF
                   GOBACK
               END-IF
           END-PERFORM

           MOVE 0 TO DC-OPUS-EOF-FLAG
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.

       LOAD-NEXT-PAGE.
           MOVE DC-OPUS-ENTRY-NEXT-PAGE-POS(WS-IDX) TO WS-PAGE-POS
           IF WS-PAGE-POS < 1
              OR WS-PAGE-POS > DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "Opus stream reached EOF."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           IF WS-PAGE-POS + 26 > DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_PARSE" TO DC-ERROR-CODE
               MOVE "Ogg page header was truncated."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           IF DC-OPUS-ENTRY-BUFFER(WS-IDX)(WS-PAGE-POS:4) NOT = "OggS"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_PARSE" TO DC-ERROR-CODE
               MOVE "Ogg page signature was invalid."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           COMPUTE DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT(WS-IDX) =
               FUNCTION ORD(
                   DC-OPUS-ENTRY-BUFFER(WS-IDX)(WS-PAGE-POS + 26:1)) - 1
           MOVE 1 TO DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX(WS-IDX)
           COMPUTE DC-OPUS-ENTRY-PAGE-TABLE-POS(WS-IDX) = WS-PAGE-POS + 27
           COMPUTE DC-OPUS-ENTRY-PAGE-BODY-POS(WS-IDX) =
               DC-OPUS-ENTRY-PAGE-TABLE-POS(WS-IDX)
               + DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT(WS-IDX)

           MOVE 0 TO WS-PAGE-BODY-LENGTH
           PERFORM VARYING WS-SEGMENT-IDX FROM 1 BY 1
               UNTIL WS-SEGMENT-IDX
                   > DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT(WS-IDX)
               COMPUTE WS-SEGMENT-LENGTH =
                   FUNCTION ORD(
                       DC-OPUS-ENTRY-BUFFER(WS-IDX)(
                           DC-OPUS-ENTRY-PAGE-TABLE-POS(WS-IDX)
                           + WS-SEGMENT-IDX - 1:1)) - 1
               ADD WS-SEGMENT-LENGTH TO WS-PAGE-BODY-LENGTH
           END-PERFORM

           COMPUTE DC-OPUS-ENTRY-PAGE-END-POS(WS-IDX) =
               DC-OPUS-ENTRY-PAGE-BODY-POS(WS-IDX)
               + WS-PAGE-BODY-LENGTH - 1

           IF DC-OPUS-ENTRY-PAGE-END-POS(WS-IDX)
               > DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_PARSE" TO DC-ERROR-CODE
               MOVE "Ogg page body was truncated."
                   TO DC-ERROR-MESSAGE
               EXIT PARAGRAPH
           END-IF

           COMPUTE DC-OPUS-ENTRY-NEXT-PAGE-POS(WS-IDX) =
               DC-OPUS-ENTRY-PAGE-END-POS(WS-IDX) + 1
           MOVE 1 TO DC-OPUS-ENTRY-PAGE-ACTIVE(WS-IDX)
           CALL "DC-RESULT-OK" USING DC-RESULT.

       PARSE-PAGE-SEGMENTS.
           PERFORM UNTIL WS-PACKET-READY = 1
               IF DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX(WS-IDX)
                   > DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT(WS-IDX)
                   MOVE 0 TO DC-OPUS-ENTRY-PAGE-ACTIVE(WS-IDX)
                   IF DC-OPUS-ENTRY-NEXT-PAGE-POS(WS-IDX)
                       > DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
                      AND DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) = 0
                       MOVE DC-STATUS-EOF TO DC-STATUS-CODE
                       MOVE "DC_EOF" TO DC-ERROR-CODE
                       MOVE "Opus stream reached EOF."
                           TO DC-ERROR-MESSAGE
                   ELSE
                       CALL "DC-RESULT-OK" USING DC-RESULT
                   END-IF
                   EXIT PARAGRAPH
               END-IF

               COMPUTE WS-SEGMENT-LENGTH =
                   FUNCTION ORD(
                       DC-OPUS-ENTRY-BUFFER(WS-IDX)(
                           DC-OPUS-ENTRY-PAGE-TABLE-POS(WS-IDX)
                           + DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX(WS-IDX)
                           - 1:1)) - 1
               IF DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) + WS-SEGMENT-LENGTH
                   > 4096
                   MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
                   MOVE "DC_ERR_OPUS_PARSE" TO DC-ERROR-CODE
                   MOVE "Ogg Opus packet exceeded the frame buffer."
                       TO DC-ERROR-MESSAGE
                   EXIT PARAGRAPH
               END-IF

               IF WS-SEGMENT-LENGTH > 0
                   MOVE DC-OPUS-ENTRY-BUFFER(WS-IDX)(
                       DC-OPUS-ENTRY-PAGE-BODY-POS(WS-IDX):
                       WS-SEGMENT-LENGTH)
                       TO DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)(
                           DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) + 1:
                           WS-SEGMENT-LENGTH)
               END-IF
               ADD WS-SEGMENT-LENGTH TO DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
               ADD WS-SEGMENT-LENGTH TO DC-OPUS-ENTRY-PAGE-BODY-POS(WS-IDX)
               ADD 1 TO DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX(WS-IDX)

               IF WS-SEGMENT-LENGTH < 255
                   PERFORM COMPLETE-PACKET
                   IF WS-PACKET-READY = 1
                       EXIT PARAGRAPH
                   END-IF
               END-IF
           END-PERFORM

           CALL "DC-RESULT-OK" USING DC-RESULT.

       COMPLETE-PACKET.
           IF DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) >= 8
              AND DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)(1:8) = "OpusHead"
               MOVE 0 TO DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
               MOVE SPACES TO DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)
               EXIT PARAGRAPH
           END-IF

           IF DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) >= 8
              AND DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)(1:8) = "OpusTags"
               MOVE 0 TO DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
               MOVE SPACES TO DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)
               EXIT PARAGRAPH
           END-IF

           MOVE DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX) TO DC-OPUS-LENGTH
           IF DC-OPUS-LENGTH > 0
               MOVE DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)(1:DC-OPUS-LENGTH)
                   TO DC-OPUS-DATA(1:DC-OPUS-LENGTH)
           END-IF
           MOVE 20 TO DC-OPUS-DURATION-MS
           MOVE 0 TO DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
           MOVE SPACES TO DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)
           MOVE 1 TO WS-PACKET-READY.
       END PROGRAM DC-OGG-OPUS-READ-FRAME.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-OGG-OPUS-CLOSE.
       *> JP: Ogg Opus ファイルを開き、1 frame ずつ読み、閉じる reader helper 群です。
       *> JP: file container 側の段取りを music playback から切り離す役割があります。
       *> EN: Reader helpers that open Ogg Opus files, read one frame at a time, and close them.
       *> EN: They separate container-level file handling from the higher-level music playback flow.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "discord-opus-store.cpy".
       01 WS-IDX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       COPY "discord-opus.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING DC-OPUS-HANDLE DC-RESULT.
       MAIN.
           IF DC-OPUS-HANDLE-ID <= 0
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_HANDLE" TO DC-ERROR-CODE
               MOVE "Opus handle is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-OPUS-HANDLE-ID TO WS-IDX
           IF WS-IDX > DC-OPUS-MAX-HANDLES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_HANDLE" TO DC-ERROR-CODE
               MOVE "Opus handle is invalid."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-OPUS-ENTRY-IN-USE(WS-IDX) NOT = 1
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_OPUS_HANDLE" TO DC-ERROR-CODE
               MOVE "Opus handle is not open."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO DC-OPUS-ENTRY-IN-USE(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-SOURCE(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-BUFFER-LENGTH(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-BUFFER(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-NEXT-PAGE-POS(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-ACTIVE(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-TABLE-POS(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-BODY-POS(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PAGE-END-POS(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PACKET-LENGTH(WS-IDX)
           INITIALIZE DC-OPUS-ENTRY-PACKET-DATA(WS-IDX)
           INITIALIZE DC-OPUS-HANDLE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-OGG-OPUS-CLOSE.
