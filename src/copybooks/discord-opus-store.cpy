      *> JP: Opus/Ogg 読み取り中の registry 状態を保持する EXTERNAL ストアです。
      *> JP: ファイル由来の buffer、page cursor、packet の途中状態を slot ごとに残します。
      *> EN: EXTERNAL store for Opus/Ogg reader registry state.
      *> EN: Each slot keeps file-backed buffers, page cursors, and in-progress packet state.
       78 DC-OPUS-MAX-HANDLES VALUE 8.
       78 DC-OPUS-BUFFER-MAX-BYTES VALUE 262144.

       01 DC-OPUS-REGISTRY-STORE EXTERNAL.
          05 DC-OPUS-REGISTRY-ENTRY OCCURS DC-OPUS-MAX-HANDLES TIMES.
             10 DC-OPUS-ENTRY-IN-USE PIC 9.
             10 DC-OPUS-ENTRY-SOURCE PIC X(512).
             10 DC-OPUS-ENTRY-BUFFER-LENGTH PIC 9(9) COMP-5.
             10 DC-OPUS-ENTRY-BUFFER PIC X(262144).
             10 DC-OPUS-ENTRY-NEXT-PAGE-POS PIC 9(9) COMP-5.
             10 DC-OPUS-ENTRY-PAGE-ACTIVE PIC 9.
             10 DC-OPUS-ENTRY-PAGE-SEGMENT-COUNT PIC 9(4) COMP-5.
             10 DC-OPUS-ENTRY-PAGE-SEGMENT-INDEX PIC 9(4) COMP-5.
             10 DC-OPUS-ENTRY-PAGE-TABLE-POS PIC 9(9) COMP-5.
             10 DC-OPUS-ENTRY-PAGE-BODY-POS PIC 9(9) COMP-5.
             10 DC-OPUS-ENTRY-PAGE-END-POS PIC 9(9) COMP-5.
             10 DC-OPUS-ENTRY-PACKET-LENGTH PIC 9(5) COMP-5.
             10 DC-OPUS-ENTRY-PACKET-DATA PIC X(4096).
