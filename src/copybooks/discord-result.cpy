      *> JP: モジュール横断で使う共通 result 契約です。
      *> JP: status code と error text の形をここで固定し、呼び出し側は同じ流儀で判定します。
      *> EN: Common result contract used across modules.
      *> EN: It standardizes the status-code and error-text shape so callers can handle every API uniformly.
       78 DC-STATUS-OK VALUE 0.
       78 DC-STATUS-ERROR VALUE 1.
       78 DC-STATUS-NOT-FOUND VALUE 2.
       78 DC-STATUS-EOF VALUE 3.

       01 DC-RESULT.
          05 DC-STATUS-CODE PIC S9(9) COMP-5.
          05 DC-ERROR-CODE PIC X(64).
          05 DC-ERROR-MESSAGE PIC X(256).
