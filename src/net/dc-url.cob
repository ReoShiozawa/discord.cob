       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-URL-BUILD-WSS.
       *> JP: WebSocket 用 URL の build / split を担う helper 群です。
       *> JP: Gateway endpoint を host/path/port に分ける共通手順をここへ寄せています。
       *> EN: Helpers for building and splitting WebSocket-oriented URLs.
       *> EN: Common logic for turning Gateway endpoints into host/path/port parts lives here.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-VERSION-TEXT PIC Z9.

       LINKAGE SECTION.
       01 DC-URL-ENDPOINT PIC X(256).
       01 DC-URL-VERSION PIC 9(2) COMP-5.
       01 DC-URL-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-URL-ENDPOINT
           DC-URL-VERSION
           DC-URL-OUT
           DC-RESULT.
       MAIN.
           MOVE DC-URL-VERSION TO WS-VERSION-TEXT
           MOVE SPACES TO DC-URL-OUT
           STRING
               "wss://" DELIMITED BY SIZE
               FUNCTION TRIM(DC-URL-ENDPOINT) DELIMITED BY SIZE
               "/?v=" DELIMITED BY SIZE
               FUNCTION TRIM(WS-VERSION-TEXT) DELIMITED BY SIZE
               INTO DC-URL-OUT
           END-STRING
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-URL-BUILD-WSS.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-URL-SPLIT-WSS.
       *> JP: WebSocket 用 URL の build / split を担う helper 群です。
       *> JP: Gateway endpoint を host/path/port に分ける共通手順をここへ寄せています。
       *> EN: Helpers for building and splitting WebSocket-oriented URLs.
       *> EN: Common logic for turning Gateway endpoints into host/path/port parts lives here.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-URL-LEN PIC 9(4) COMP-5.
       01 WS-IDX PIC 9(4) COMP-5.
       01 WS-HOST-LEN PIC 9(4) COMP-5.
       01 WS-PATH-LEN PIC 9(4) COMP-5.
       01 WS-SLASH-POS PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-URL-IN PIC X(512).
       01 DC-URL-HOST-OUT PIC X(256).
       01 DC-URL-PATH-OUT PIC X(512).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-URL-IN
           DC-URL-HOST-OUT
           DC-URL-PATH-OUT
           DC-RESULT.
       MAIN.
           MOVE SPACES TO DC-URL-HOST-OUT
           MOVE SPACES TO DC-URL-PATH-OUT
           MOVE FUNCTION LENGTH(FUNCTION TRIM(DC-URL-IN TRAILING))
               TO WS-URL-LEN
           IF WS-URL-LEN < 7
              OR FUNCTION LOWER-CASE(DC-URL-IN(1:6)) NOT = "wss://"
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_URL" TO DC-ERROR-CODE
               MOVE "WSS URL must start with wss://."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE 0 TO WS-SLASH-POS
           PERFORM VARYING WS-IDX FROM 7 BY 1 UNTIL WS-IDX > WS-URL-LEN
               IF DC-URL-IN(WS-IDX:1) = "/"
                   MOVE WS-IDX TO WS-SLASH-POS
                   EXIT PERFORM
               END-IF
           END-PERFORM

           IF WS-SLASH-POS = 0
               COMPUTE WS-HOST-LEN = WS-URL-LEN - 6
               MOVE DC-URL-IN(7:WS-HOST-LEN) TO DC-URL-HOST-OUT(1:WS-HOST-LEN)
               MOVE "/" TO DC-URL-PATH-OUT
           ELSE
               COMPUTE WS-HOST-LEN = WS-SLASH-POS - 7
               IF WS-HOST-LEN > 0
                   MOVE DC-URL-IN(7:WS-HOST-LEN)
                       TO DC-URL-HOST-OUT(1:WS-HOST-LEN)
               END-IF
               COMPUTE WS-PATH-LEN = WS-URL-LEN - WS-SLASH-POS + 1
               IF WS-PATH-LEN > 0
                   MOVE DC-URL-IN(WS-SLASH-POS:WS-PATH-LEN)
                       TO DC-URL-PATH-OUT(1:WS-PATH-LEN)
               END-IF
           END-IF

           IF FUNCTION TRIM(DC-URL-HOST-OUT) = SPACES
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_URL" TO DC-ERROR-CODE
               MOVE "WSS URL host was empty."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-URL-SPLIT-WSS.
