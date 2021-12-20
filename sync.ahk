#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

; very easy sync system over empty files
class Sync
{
    ClearStates()
    {
        dir := A_ScriptDir "\sync\"
        FileRemoveDir, %dir%, 1
        FileCreateDir, %dir%
    }

    WaitForState(state, timeout=0)
    {
        tmpFile := A_ScriptDir "\sync\" state
        timeoutTimestamp := A_TickCount + timeout

        while (!FileExist(tmpFile)) {
            if (timeout > 0 && A_TickCount >= timeoutTimestamp) {
                return
            }
            sleep 25
        }

        DllCall("SetLastError", "UInt", 0)
        FileDelete, %tmpFile%

        if (A_LastError != 0) {
            MsgBox % "couldn't remove file" . A_LastError
        }
    }

    HasState(state)
    {
        tmpFile := A_ScriptDir "\sync\" state
        return FileExist(tmpFile)
    }

    SetState(state) {
        tmpFile := A_ScriptDir "\sync\" state
        FileAppend, "state set", %tmpFile%

        return true
    }
}