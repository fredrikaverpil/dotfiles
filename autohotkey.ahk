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
LWin::LCtrl
<^Right:: Send, {End}
<^Left:: Send, {Home}
<^Up:: Send, {PgUp}
<^Down:: Send, {PgDn}
<^Tab::Send {LWin down}{Tab}{LWin up}