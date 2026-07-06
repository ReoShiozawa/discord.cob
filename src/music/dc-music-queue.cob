       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-INIT.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       01 DC-MQ-GUILD-ID-IN PIC X(32).
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MQ-GUILD-ID-IN
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-QUEUE
           MOVE DC-MQ-GUILD-ID-IN TO DC-MQ-GUILD-ID
           MOVE 1 TO DC-MQ-HEAD
           MOVE 0 TO DC-MQ-TAIL
           MOVE 0 TO DC-MQ-SIZE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-INIT.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-PUSH.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           IF DC-MQ-SIZE >= 100
               MOVE DC-STATUS-ERROR TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_QUEUE_FULL" TO DC-ERROR-CODE
               MOVE "Music queue is full." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-MQ-TAIL >= 100
               MOVE 1 TO DC-MQ-TAIL
           ELSE
               ADD 1 TO DC-MQ-TAIL
           END-IF

           MOVE DC-TRACK-ID TO DC-MQ-TRACK-ID(DC-MQ-TAIL)
           MOVE DC-TRACK-TITLE TO DC-MQ-TITLE(DC-MQ-TAIL)
           MOVE DC-TRACK-SOURCE TO DC-MQ-SOURCE(DC-MQ-TAIL)
           MOVE DC-TRACK-REQUESTER-ID
               TO DC-MQ-REQUESTER-ID(DC-MQ-TAIL)
           MOVE DC-TRACK-STATUS TO DC-MQ-STATUS(DC-MQ-TAIL)
           ADD 1 TO DC-MQ-SIZE
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-PUSH.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-POP.
       *> JP: music queue の初期化・push・pop を行う基礎 helper 群です。
       *> JP: guild ごとの track 順序を固定長リングに近い形で扱います。
       *> EN: Foundational helpers for initializing, pushing to, and popping from the music queue.
       *> EN: They manage guild-scoped track order in a fixed-size queue structure.

       DATA DIVISION.
       LINKAGE SECTION.
       COPY "discord-music.cpy".
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE
           DC-MUSIC-TRACK
           DC-RESULT.
       MAIN.
           IF DC-MQ-SIZE = 0
               MOVE DC-STATUS-EOF TO DC-STATUS-CODE
               MOVE "DC_EOF" TO DC-ERROR-CODE
               MOVE "Music queue is empty." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-MQ-TRACK-ID(DC-MQ-HEAD) TO DC-TRACK-ID
           MOVE DC-MQ-TITLE(DC-MQ-HEAD) TO DC-TRACK-TITLE
           MOVE DC-MQ-SOURCE(DC-MQ-HEAD) TO DC-TRACK-SOURCE
           MOVE DC-MQ-REQUESTER-ID(DC-MQ-HEAD)
               TO DC-TRACK-REQUESTER-ID
           MOVE DC-MQ-STATUS(DC-MQ-HEAD) TO DC-TRACK-STATUS

           IF DC-MQ-HEAD >= 100
               MOVE 1 TO DC-MQ-HEAD
           ELSE
               ADD 1 TO DC-MQ-HEAD
           END-IF
           SUBTRACT 1 FROM DC-MQ-SIZE
           IF DC-MQ-SIZE = 0
               MOVE 1 TO DC-MQ-HEAD
               MOVE 0 TO DC-MQ-TAIL
           END-IF
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-POP.

       IDENTIFICATION DIVISION.
       PROGRAM-ID. DC-MUSIC-QUEUE-REMOVE-AT.
       *> JP: queue の 1-based 位置を指定して track を 1 つ取り除く helper です。
       *> JP: リング添字を直接ずらす代わりに、一度 pop して rebuild することで
       *> JP: contributor が追いやすい単純な手順にしています。
       *> EN: Remove one track from the queue by a 1-based position.
       *> EN: Instead of mutating ring indices in place, it pops and rebuilds
       *> EN: the queue so the flow stays simple for contributors.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01 WS-ORIGINAL-QUEUE.
          05 WS-OQ-GUILD-ID PIC X(32).
          05 WS-OQ-SIZE PIC 9(4) COMP-5.
          05 WS-OQ-HEAD PIC 9(4) COMP-5.
          05 WS-OQ-TAIL PIC 9(4) COMP-5.
          05 WS-OQ-TRACK OCCURS 100 TIMES.
             10 WS-OQ-TRACK-ID PIC X(64).
             10 WS-OQ-TITLE PIC X(128).
             10 WS-OQ-SOURCE PIC X(512).
             10 WS-OQ-REQUESTER-ID PIC X(32).
             10 WS-OQ-STATUS PIC 9.
       01 WS-REBUILT-QUEUE.
          05 WS-RQ-GUILD-ID PIC X(32).
          05 WS-RQ-SIZE PIC 9(4) COMP-5.
          05 WS-RQ-HEAD PIC 9(4) COMP-5.
          05 WS-RQ-TAIL PIC 9(4) COMP-5.
          05 WS-RQ-TRACK OCCURS 100 TIMES.
             10 WS-RQ-TRACK-ID PIC X(64).
             10 WS-RQ-TITLE PIC X(128).
             10 WS-RQ-SOURCE PIC X(512).
             10 WS-RQ-REQUESTER-ID PIC X(32).
             10 WS-RQ-STATUS PIC 9.
       01 WS-WORK-TRACK.
          05 WS-WORK-TRACK-ID PIC X(64).
          05 WS-WORK-TRACK-TITLE PIC X(128).
          05 WS-WORK-TRACK-SOURCE PIC X(512).
          05 WS-WORK-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-WORK-TRACK-REQUESTER-ID PIC X(32).
          05 WS-WORK-TRACK-STATUS PIC 9.
       01 WS-REMOVED-TRACK.
          05 WS-REMOVED-TRACK-ID PIC X(64).
          05 WS-REMOVED-TRACK-TITLE PIC X(128).
          05 WS-REMOVED-TRACK-SOURCE PIC X(512).
          05 WS-REMOVED-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 WS-REMOVED-TRACK-REQUESTER-ID PIC X(32).
          05 WS-REMOVED-TRACK-STATUS PIC 9.
       01 WS-ORIGINAL-SIZE PIC 9(4) COMP-5.
       01 WS-INDEX PIC 9(4) COMP-5.

       LINKAGE SECTION.
       01 DC-MUSIC-QUEUE-IN.
          05 DC-MQ-GUILD-ID PIC X(32).
          05 DC-MQ-SIZE PIC 9(4) COMP-5.
          05 DC-MQ-HEAD PIC 9(4) COMP-5.
          05 DC-MQ-TAIL PIC 9(4) COMP-5.
          05 DC-MQ-TRACK OCCURS 100 TIMES.
             10 DC-MQ-TRACK-ID PIC X(64).
             10 DC-MQ-TITLE PIC X(128).
             10 DC-MQ-SOURCE PIC X(512).
             10 DC-MQ-REQUESTER-ID PIC X(32).
             10 DC-MQ-STATUS PIC 9.
       01 DC-MQ-REMOVE-POSITION PIC 9(4) COMP-5.
       01 DC-MUSIC-TRACK-OUT.
          05 DC-TRACK-ID PIC X(64).
          05 DC-TRACK-TITLE PIC X(128).
          05 DC-TRACK-SOURCE PIC X(512).
          05 DC-TRACK-DURATION-MS PIC 9(12) COMP-5.
          05 DC-TRACK-REQUESTER-ID PIC X(32).
          05 DC-TRACK-STATUS PIC 9.
       COPY "discord-result.cpy".

       PROCEDURE DIVISION USING
           DC-MUSIC-QUEUE-IN
           DC-MQ-REMOVE-POSITION
           DC-MUSIC-TRACK-OUT
           DC-RESULT.
       MAIN.
           INITIALIZE DC-MUSIC-TRACK-OUT
           IF DC-MQ-SIZE <= 0
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_QUEUE_EMPTY" TO DC-ERROR-CODE
               MOVE "Music queue is empty." TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           IF DC-MQ-REMOVE-POSITION <= 0
              OR DC-MQ-REMOVE-POSITION > DC-MQ-SIZE
               MOVE DC-STATUS-NOT-FOUND TO DC-STATUS-CODE
               MOVE "DC_ERR_MUSIC_QUEUE_INDEX" TO DC-ERROR-CODE
               MOVE "Music queue position was not found."
                   TO DC-ERROR-MESSAGE
               GOBACK
           END-IF

           MOVE DC-MUSIC-QUEUE-IN TO WS-ORIGINAL-QUEUE
           MOVE WS-OQ-SIZE TO WS-ORIGINAL-SIZE
           CALL "DC-MUSIC-QUEUE-INIT"
               USING WS-REBUILT-QUEUE
                     DC-MQ-GUILD-ID
                     DC-RESULT
           IF DC-STATUS-CODE NOT = DC-STATUS-OK
               GOBACK
           END-IF

           PERFORM VARYING WS-INDEX FROM 1 BY 1
               UNTIL WS-INDEX > WS-ORIGINAL-SIZE
               INITIALIZE WS-WORK-TRACK
               CALL "DC-MUSIC-QUEUE-POP"
                   USING WS-ORIGINAL-QUEUE
                         WS-WORK-TRACK
                         DC-RESULT
               IF DC-STATUS-CODE NOT = DC-STATUS-OK
                   GOBACK
               END-IF

               IF WS-INDEX = DC-MQ-REMOVE-POSITION
                   MOVE WS-WORK-TRACK TO WS-REMOVED-TRACK
               ELSE
                   CALL "DC-MUSIC-QUEUE-PUSH"
                       USING WS-REBUILT-QUEUE
                             WS-WORK-TRACK
                             DC-RESULT
                   IF DC-STATUS-CODE NOT = DC-STATUS-OK
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           MOVE WS-REBUILT-QUEUE TO DC-MUSIC-QUEUE-IN
           MOVE WS-REMOVED-TRACK TO DC-MUSIC-TRACK-OUT
           CALL "DC-RESULT-OK" USING DC-RESULT
           GOBACK.
       END PROGRAM DC-MUSIC-QUEUE-REMOVE-AT.
