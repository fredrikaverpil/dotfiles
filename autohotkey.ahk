FileEncoding, UTF-8 ; This file needs to be saved/encoded with "UTF-8 with BOM"

; Use Swedish characters on US-English keyboard
![:: Send, å
!+{:: Send, Å
!':: Send, ä
!+':: Send, Ä
!;:: Send, ö
!+;:: Send, Ö  ; does not work

; HHKB settings to mimic macOS behavior on Windows
LWin::LCtrl  ; this one is better to use SharpKeys for, as it is unreliable here
<^Right:: Send, {End}
<^Left:: Send, {Home}
<^Up:: Send, {PgUp}
<^Down:: Send, {PgDn}
<+^Up:: Send, {LShift down}{PgUp}{LShift up}
<+^Down:: Send, {LShift down}{PgDn}{LShift up}
<^Tab::Send {LWin down}{Tab}{LWin up}