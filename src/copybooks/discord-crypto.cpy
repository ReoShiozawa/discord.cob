      *> JP: Voice 暗号化まわりで受け渡す固定長ワーク領域です。
      *> JP: AEAD 入出力、nonce 進行、DAVE 交渉状態を動的確保なしでまとめます。
      *> EN: Fixed-size work areas for voice-encryption flows.
      *> EN: They group AEAD input/output, nonce progression, and DAVE negotiation state without dynamic allocation.
       01 DC-AEAD-CONTEXT.
          05 DC-AEAD-KEY PIC X(64).
          05 DC-AEAD-KEY-LENGTH PIC 9(5) COMP-5.
          05 DC-AEAD-NONCE PIC X(24).
          05 DC-AEAD-NONCE-LENGTH PIC 9(5) COMP-5.
          05 DC-AEAD-AAD PIC X(64).
          05 DC-AEAD-AAD-LENGTH PIC 9(5) COMP-5.
          05 DC-AEAD-PLAINTEXT PIC X(4096).
          05 DC-AEAD-PLAINTEXT-LENGTH PIC 9(5) COMP-5.
          05 DC-AEAD-CIPHERTEXT PIC X(4096).
          05 DC-AEAD-CIPHERTEXT-LENGTH PIC 9(5) COMP-5.
          05 DC-AEAD-TAG PIC X(32).
          05 DC-AEAD-TAG-LENGTH PIC 9(5) COMP-5.

       01 DC-NONCE-STATE.
          05 DC-NONCE-COUNTER PIC 9(18) COMP-5.
          05 DC-NONCE-BUFFER PIC X(24).

       01 DC-DAVE-STATE.
          05 DC-DAVE-ENABLED-FLAG PIC 9.
          05 DC-DAVE-PROTOCOL-VERSION PIC 9(4) COMP-5.
          05 DC-DAVE-KEY-MATERIAL PIC X(512).
          05 DC-DAVE-READY-FLAG PIC 9.
