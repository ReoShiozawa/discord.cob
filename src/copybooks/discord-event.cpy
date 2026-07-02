      *> JP: Gateway から dispatcher へ渡す正規化済み event 1 件の構造です。
      *> JP: event 名、sequence、raw payload をひとまとまりで保持します。
      *> EN: Normalized structure for one event passed from the Gateway layer to the dispatcher.
      *> EN: It keeps the event name, sequence number, and raw payload together.
       01 DC-EVENT.
          05 DC-EVENT-NAME PIC X(64).
          05 DC-EVENT-SEQUENCE PIC S9(10) COMP-5.
          05 DC-EVENT-PAYLOAD-LENGTH PIC 9(5) COMP-5.
          05 DC-EVENT-PAYLOAD PIC X(8192).
