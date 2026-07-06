      *> JP: guild ごとの music runtime を保存する EXTERNAL ストアです。
      *> JP: queue と player の断面を固定長テーブルで持ち、tick 間で再利用します。
      *> EN: EXTERNAL store for guild-scoped music runtimes.
      *> EN: It keeps queue and player snapshots in fixed-size tables so ticks can reload and reuse them.
       78 DC-MUSIC-MAX-RUNTIMES VALUE 8.

       01 DC-MUSIC-RUNTIME-STORE EXTERNAL.
          05 DC-MR-ENTRY OCCURS DC-MUSIC-MAX-RUNTIMES TIMES.
             10 DC-MR-ENTRY-IN-USE PIC 9.
             10 DC-MR-ENTRY-GUILD-ID PIC X(32).
             10 DC-MR-QUEUE.
                15 DC-MR-MQ-GUILD-ID PIC X(32).
                15 DC-MR-MQ-SIZE PIC 9(4) COMP-5.
                15 DC-MR-MQ-HEAD PIC 9(4) COMP-5.
                15 DC-MR-MQ-TAIL PIC 9(4) COMP-5.
                15 DC-MR-MQ-TRACK OCCURS 100 TIMES.
                   20 DC-MR-MQ-TRACK-ID PIC X(64).
                   20 DC-MR-MQ-TITLE PIC X(128).
                   20 DC-MR-MQ-SOURCE PIC X(512).
                   20 DC-MR-MQ-REQUESTER-ID PIC X(32).
                   20 DC-MR-MQ-STATUS PIC 9.
             10 DC-MR-PLAYER.
                15 DC-MR-PLAYER-STATE PIC 9.
                15 DC-MR-PLAYER-GUILD-ID PIC X(32).
                15 DC-MR-PLAYER-TRACK-ID PIC X(64).
                15 DC-MR-PLAYER-FRAME-COUNT PIC 9(10) COMP-5.
                15 DC-MR-PLAYER-VOLUME PIC 9(3).
                15 DC-MR-PLAYER-EOF-FLAG PIC 9.
             10 DC-MR-CURRENT-TRACK.
                15 DC-MR-TRACK-ID PIC X(64).
                15 DC-MR-TRACK-TITLE PIC X(128).
                15 DC-MR-TRACK-SOURCE PIC X(512).
                15 DC-MR-TRACK-DURATION-MS PIC 9(12) COMP-5.
                15 DC-MR-TRACK-REQUESTER-ID PIC X(32).
                15 DC-MR-TRACK-STATUS PIC 9.
             10 DC-MR-RTP-STATE.
                15 DC-MR-RTP-SEQUENCE PIC 9(10) COMP-5.
                15 DC-MR-RTP-TIMESTAMP PIC 9(10) COMP-5.
                15 DC-MR-RTP-SSRC PIC 9(10) COMP-5.
                15 DC-MR-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.
             10 DC-MR-OPUS-HANDLE.
                15 DC-MR-OPUS-HANDLE-ID PIC 9(10) COMP-5.
                15 DC-MR-OPUS-SOURCE PIC X(512).
                15 DC-MR-OPUS-EOF-FLAG PIC 9.
             10 DC-MR-IDLE-TICK-COUNT PIC 9(9) COMP-5.
