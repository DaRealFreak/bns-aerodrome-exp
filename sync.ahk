#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

; very easy sync system over empty files
class Sync
{
    static mountedNetworkDrive := false

    MountNetworkDrive()
    {
        RunWait %comspec% /c "net use y: \\fritz.box\FRITZ.NAS /user:domain\nas fisch123!",,Hide
        this.mountedNetworkDrive := true
    }

    ClearStates()
    {
        if (!this.mountedNetworkDrive) {
            Sync.MountNetworkDrive()
        }

        dir := "y:\BnS\sync\"
        FileRemoveDir, %dir%, 1
        FileCreateDir, %dir%
    }

    WaitForState(state, timeout=0)
    {
        if (!this.mountedNetworkDrive) {
            Sync.MountNetworkDrive()
        }

        tmpFile := "y:\BnS\sync\" state
        timeoutTimestamp := A_TickCount + timeout

        while (!FileExist(tmpFile)) {
            if (timeout > 0 && A_TickCount >= timeoutTimestamp) {
                return
            }
            sleep 25
        }

        ; sleep to allow other process to close file first
        sleep 500

        DllCall("SetLastError", "UInt", 0)
        FileDelete, %tmpFile%

        if (A_LastError != 0) {
            log.addLogEntry("$time: couldn't remove sync state file")
        }
    }

    HasState(state)
    {
        if (!this.mountedNetworkDrive) {
            Sync.MountNetworkDrive()
        }

        tmpFile := "y:\BnS\sync\" state
        return FileExist(tmpFile)
    }

    SetState(state) {
        if (!this.mountedNetworkDrive) {
            Sync.MountNetworkDrive()
        }

        tmpFile := "y:\BnS\sync\" state
        FileAppend, "state set", %tmpFile%

        return true
    }
}