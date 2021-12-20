#Persistent
#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%
#MaxThreadsPerHotkey, 99

OnExit(ObjBindMethod(Aerodrome, "Exiting"))

#IfWinActive ahk_class UnrealWindow
F1::
    MouseGetPos, mouseX, mouseY
    color := Utility.GetColor(mouseX, mouseY, r, g, b)
    tooltip, Coordinate: %mouseX%`, %mouseY% `nHexColor: %color%`nR:%r% G:%g% B:%b%
    Clipboard := "Utility.GetColor(" mouseX "," mouseY ") == `""" color "`"""
    SetTimer, RemoveToolTip, -5000
    return

RemoveToolTip:
    tooltip
    return

#IfWinActive ahk_class UnrealWindow
Numpad0::
    global log := new LogClass("aerodrome")
    log.initalizeNewLogFile(1)
    log.addLogEntry("$time: starting aerodrome exp farm")

    loop {
        if (!Aerodrome.EnterLobby(false)) {
            break
        }
        sleep 250
    }

    return

Numpad1::
    global log := new LogClass("aerodrome_leech")
    log.initalizeNewLogFile(1)
    log.addLogEntry("$time: starting aerodrome exp farm")

    loop {
        if (!Aerodrome.EnterLobby(true)) {
            break
        }
        sleep 250
    }

    return

Numpad2::
    global log := new LogClass("aerodrome")
    log.initalizeNewLogFile(1)
    log.addLogEntry("$time: starting aerodrome exp farm")

    loop {
        if (!Aerodrome.EnterLobby(true, true)) {
            break
        }
        sleep 250
    }

    return

*NumPadDot::
    Utility.ReleaseAllKeys()
    Reload
    return

*NumPadEnter::
    Utility.ReleaseAllKeys()
    ExitApp