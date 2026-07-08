      *> JP: slash command 定義を JSON 手組みなしで宣言するための構造化 schema です。
      *> JP: name/description/options を固定長の表として持ち、変換・検証・同期の
      *> JP: 高水準 API 群 (dc-command-schema.cob) がこの形を共有します。
      *> EN: Structured schema for declaring slash commands without hand-written JSON.
      *> EN: It stores name/description/options metadata as fixed-width tables shared
      *> EN: by the high-level conversion, validation, and sync APIs in dc-command-schema.cob.
       78 DC-SCHEMA-MAX-COMMANDS VALUE 25.
       78 DC-SCHEMA-MAX-OPTIONS VALUE 10.

       01 DC-COMMAND-SCHEMA.
          05 DC-SCHEMA-COMMAND-COUNT PIC 9(4) COMP-5.
          05 DC-SCHEMA-COMMAND OCCURS 25 TIMES.
      *> JP: name は Discord 側の制約に合わせて小文字を想定します。
      *> EN: Names are expected in lowercase to match Discord's constraints.
             10 DC-SCHEMA-COMMAND-NAME PIC X(32).
             10 DC-SCHEMA-COMMAND-TYPE PIC 9(4) COMP-5.
             10 DC-SCHEMA-COMMAND-DESC PIC X(100).
      *> JP: option は name/type/description/required の平坦な一覧として保持します。
      *> EN: Options are stored as a flat name/type/description/required list.
             10 DC-SCHEMA-OPTION-COUNT PIC 9(4) COMP-5.
             10 DC-SCHEMA-OPTION OCCURS 10 TIMES.
                15 DC-SCHEMA-OPTION-NAME PIC X(32).
                15 DC-SCHEMA-OPTION-TYPE PIC 9(4) COMP-5.
                15 DC-SCHEMA-OPTION-DESC PIC X(100).
                15 DC-SCHEMA-OPTION-REQUIRED PIC 9(4) COMP-5.
