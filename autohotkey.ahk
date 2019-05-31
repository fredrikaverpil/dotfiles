FileEncoding, UTF-8 ; This file needs to be saved/encoded with "UTF-8 with BOM"

; Use Swedish characters on US-English keyboard
![:: Send, å
!+{:: Send, Å
!':: Send, ä
!+':: Send, Ä
!;:: Send, ö
!+;:: Send, Ö  ; does not work

; HHKB settings to mimic macOS behavior on Windows
; Leave righ hand side modifier keys at their defaults

LWin::LControl

LWin & Tab:: Send {LAlt down}{Tab}
LWin Up:: Send {Alt up}

LWin & Up:: Send, {PgUp}
LWin & Down:: Send, {PgDn}
LWin & Left:: Send, {Home}
LWin & Right:: Send, {End}