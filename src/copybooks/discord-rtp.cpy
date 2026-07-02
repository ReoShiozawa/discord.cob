      *> JP: RTP header、rolling state、完成 packet の固定長構造です。
      *> JP: sequence/timestamp の進行と packet 合成が同じ表現を共有します。
      *> EN: Fixed-size structures for RTP headers, rolling state, and completed packets.
      *> EN: Sequence/timestamp advancement and packet assembly share the same representation here.
       01 DC-RTP-HEADER.
          05 DC-RTP-BYTE-0 PIC X.
          05 DC-RTP-BYTE-1 PIC X.
          05 DC-RTP-SEQUENCE-BYTES PIC X(2).
          05 DC-RTP-TIMESTAMP-BYTES PIC X(4).
          05 DC-RTP-SSRC-BYTES PIC X(4).

       01 DC-RTP-STATE.
          05 DC-RTP-SEQUENCE PIC 9(10) COMP-5.
          05 DC-RTP-TIMESTAMP PIC 9(10) COMP-5.
          05 DC-RTP-SSRC PIC 9(10) COMP-5.
          05 DC-RTP-FRAME-SAMPLES PIC 9(10) COMP-5.

       01 DC-RTP-PACKET.
          05 DC-RTP-PACKET-LENGTH PIC 9(5) COMP-5.
          05 DC-RTP-PACKET-DATA PIC X(8192).
