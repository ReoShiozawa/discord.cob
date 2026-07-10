      *> JP: JSON scanner が返す固定長 token table です。
      *> JP: start/length は元の 8192-byte JSON buffer 上の位置を示します。
      *> EN: Fixed-size token table returned by the JSON scanner.
      *> EN: Start and length refer to positions in the original 8192-byte buffer.
       78 DC-JSON-MAX-TOKENS VALUE 1024.
       78 DC-JT-OBJECT-START VALUE 1.
       78 DC-JT-OBJECT-END VALUE 2.
       78 DC-JT-ARRAY-START VALUE 3.
       78 DC-JT-ARRAY-END VALUE 4.
       78 DC-JT-COLON VALUE 5.
       78 DC-JT-COMMA VALUE 6.
       78 DC-JT-STRING VALUE 7.
       78 DC-JT-NUMBER VALUE 8.
       78 DC-JT-TRUE VALUE 9.
       78 DC-JT-FALSE VALUE 10.
       78 DC-JT-NULL VALUE 11.

       01 DC-JSON-TOKENS.
          05 DC-JT-COUNT PIC 9(5) COMP-5.
          05 DC-JT-TOKEN OCCURS DC-JSON-MAX-TOKENS TIMES.
             10 DC-JT-KIND PIC 9(2) COMP-5.
             10 DC-JT-START PIC 9(5) COMP-5.
             10 DC-JT-LENGTH PIC 9(5) COMP-5.
             10 DC-JT-DEPTH PIC 9(3) COMP-5.
