      *> JP: audio source、Opus handle、1 frame 分の payload など audio/opus 共通 DTO を定義します。
      *> JP: reader、player、packetizer の境界をまたいで受け渡す最小単位です。
      *> EN: Defines shared audio/Opus DTOs such as audio sources, Opus handles, and one-frame payloads.
      *> EN: These are the minimal units passed across reader, player, and packetizing boundaries.
       01 DC-AUDIO-SOURCE PIC X(512).

       01 DC-OPUS-HANDLE.
          05 DC-OPUS-HANDLE-ID PIC 9(10) COMP-5.
          05 DC-OPUS-SOURCE PIC X(512).
          05 DC-OPUS-EOF-FLAG PIC 9.

       01 DC-OPUS-FRAME.
          05 DC-OPUS-LENGTH PIC 9(5) COMP-5.
          05 DC-OPUS-DATA PIC X(4096).
          05 DC-OPUS-DURATION-MS PIC 9(3) COMP-5.
