      *> JP: Discord interaction 1 件を framework 内で扱いやすい固定長構造に写したものです。
      *> EN: A single Discord interaction normalized into a fixed-width framework structure.
       01 DC-INTERACTION.
      *> JP: callback / webhook 応答に必須の識別子です。
      *> EN: Identifiers required for callback and webhook responses.
          05 DC-INTERACTION-ID PIC X(32).
          05 DC-INTERACTION-TOKEN PIC X(256).
          05 DC-INTERACTION-TYPE PIC 9(4) COMP-5.
      *> JP: routing や music command で使う guild/channel/user 文脈です。
      *> EN: Guild/channel/user context used by routing and music commands.
          05 DC-GUILD-ID PIC X(32).
          05 DC-CHANNEL-ID PIC X(32).
          05 DC-USER-ID PIC X(32).
          05 DC-USER-VOICE-CHANNEL-ID PIC X(32).
      *> JP: slash command か component/modal かで使う主キー群です。
      *> EN: Primary routing keys depending on command vs component/modal flows.
          05 DC-COMMAND-NAME PIC X(64).
          05 DC-INTERACTION-CUSTOM-ID PIC X(128).
          05 DC-INTERACTION-COMPONENT-TYPE PIC 9(4) COMP-5.
      *> JP: slash command option は name/value の平坦な一覧として保持します。
      *> EN: Slash-command options are stored as a flat name/value list.
          05 DC-COMMAND-OPTION-COUNT PIC 9(4) COMP-5.
          05 DC-COMMAND-OPTION OCCURS 25 TIMES.
             10 DC-COMMAND-OPTION-NAME PIC X(64).
             10 DC-COMMAND-OPTION-VALUE PIC X(512).
      *> JP: select menu や modal input の値も同様に平坦化して保持します。
      *> EN: Select-menu and modal-input values are flattened in the same way.
          05 DC-INTERACTION-VALUE-COUNT PIC 9(4) COMP-5.
          05 DC-INTERACTION-VALUE OCCURS 25 TIMES.
             10 DC-INTERACTION-VALUE-NAME PIC X(128).
             10 DC-INTERACTION-VALUE-TEXT PIC X(512).
