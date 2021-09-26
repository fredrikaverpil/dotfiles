FileEncoding, UTF-8 ; This file needs to be saved/encoded with "UTF-8 with BOM"

; Use Swedish characters on US-English keyboard
![:: Send, å
!+{:: Send, Å
!':: Send, ä
!+':: Send, Ä
!;:: Send, ö
!+;:: Send, Ö

; HHKB settings to mimic macOS behavior on Windows
LWin::LCtrl  ; this one is better to use SharpKeys for, as it is unreliable here
<^Right:: Send, {End}
<^Left:: Send, {Home}
<^Up:: Send, {PgUp}
<^Down:: Send, {PgDn}
<+^Right:: Send, {LShift down}{End}{LShift up}
<+^Left:: Send, {LShift down}{Home}{LShift up}
<+^Up:: Send, {LShift down}{PgUp}{LShift up}
<+^Down:: Send, {LShift down}{PgDn}{LShift up}

; Windows laptop
AppsKey:: Send, {RWin}
