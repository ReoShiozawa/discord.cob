      *> JP: autocomplete choices を構造化して積むための固定長テーブルです。
      *> EN: Fixed-width table used to accumulate structured autocomplete choices.
       78 DC-IA-CHOICES-MAX VALUE 25.

       01 DC-INTERACTION-CHOICES.
          05 DC-IA-CHOICE-COUNT PIC 9(4) COMP-5.
          05 DC-IA-CHOICE OCCURS 25 TIMES.
      *> JP: Discord autocomplete choice は name/value の組だけを扱います。
      *> EN: A Discord autocomplete choice is represented as a name/value pair.
             10 DC-IA-CHOICE-NAME PIC X(100).
             10 DC-IA-CHOICE-VALUE PIC X(100).
