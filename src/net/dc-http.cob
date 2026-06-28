       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-PARSE-STATUS.

       DATA DIVISION.
       LINKAGE SECTION.
       01 DC-HTTP-RAW-RESPONSE PIC X(8192).
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-RAW-RESPONSE
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           IF DC-HTTP-RAW-RESPONSE(1:5) NOT = "HTTP/"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_HTTP" TO DC-ERROR-CODE
               MOVE "HTTP response does not start with HTTP/."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           COMPUTE DC-HTTP-STATUS-CODE =
               FUNCTION NUMVAL(DC-HTTP-RAW-RESPONSE(10:3))
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-HTTP-PARSE-STATUS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-GET.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-GET.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-POST.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-POST.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-PATCH.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-PATCH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-HTTP-DELETE.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-net.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-HTTP-REQUEST
           DC-HTTP-RESPONSE
           DC-RESULT.
       MAIN.
           MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
           MOVE "DC_ERR_HTTP_NOT_IMPLEMENTED" TO DC-ERROR-CODE
           MOVE "HTTP transport is not implemented yet."
               TO DC-ERROR-MESSAGE
           GOBACK.
       END PROGRAM DC-HTTP-DELETE.
