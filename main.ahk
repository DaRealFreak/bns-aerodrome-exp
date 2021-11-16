SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\ui.ahk
#Include %A_ScriptDir%\hotkeys.ahk

class Aerodrome
{
    static runCount := 0

    ; function we can call when we expect a loading screen and want to wait until the loading screen is over
    WaitLoadingScreen()
    {
        log.addLogEntry("$time: wait for loading screen")

        ; just sleep while we're in the loading screen
        while (UserInterface.IsInLoadingScreen()) {
            sleep 5
        }

        ; check any of the skills if they are visible
        while (!UserInterface.IsOutOfLoadingScreen()) {
            sleep 5
        }

        sleep 50
    }

    EnableSpeedHack()
    {
        loop, 5 {
            Configuration.EnableMovementSpeedhack()
            sleep 25
        }
    }

    DisableSpeedHack()
    {
        loop, 5 {
            Configuration.DisableMovementSpeedhack()
            sleep 25
        }
    }

    ; simply check for the buff food and use 
    CheckBuffFood()
    {
        log.addLogEntry("$time: checking buff food")

        ; check if buff food icon is visible
        if (!UserInterface.IsBuffFoodIconVisible()) {
            log.addLogEntry("$time: using buff food")

            Configuration.UseBuffFood()
            sleep 750
            send {w down}
            sleep 50
            send {w up}
            sleep 200
        }
    }

    EnterLobby()
    {
        log.addLogEntry("$time: moving to dungeon")

        Aerodrome.EnableSpeedHack()
        while (!UserInterface.IsInLoadingScreen()) {
            UserInterface.ClickEnterDungeon()
            sleep 25
        }
        Aerodrome.DisableSpeedHack()

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.EnterDungeon()
    }

    EnterDungeon()
    {
        log.addLogEntry("$time: entering dungeon, runs done: " this.runCount)

        send {w down}
        send {Shift}

        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToDummies()
    }

    MoveToDummies()
    {
		sleep 1.5*1000

        Aerodrome.CheckRepair()
        Aerodrome.CheckBuffFood()

        log.addLogEntry("$time: moving to the dummy room")

        Aerodrome.EnableSpeedHack()

        send {w down}
        send {Shift}
        sleep 12*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        send {a down}
        sleep 11*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        sleep 50

        send {w down}
        send {Shift}
        sleep 6*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        send {a down}
        sleep 6*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        sleep 50

        Aerodrome.DisableSpeedHack()

        return Aerodrome.StartAutoCombat()
    }

    StartAutoCombat()
    {
        log.addLogEntry("$time: activating auto combat")

        Configuration.ToggleAutoCombat()

        sleep 5*1000

        while (!UserInterface.IsOutOfCombat() && !UserInterface.IsReviveVisible()) {
            sleep 25
        }

        if (UserInterface.IsReviveVisible()) {
            Aerodrome.Revive()

            return Aerodrome.ExitDungeon()
        }

        Configuration.ToggleAutoCombat()

        return Aerodrome.ExitDungeon()
    }

    Revive()
    {
        Aerodrome.EnableSpeedHack()

        ; ToDo: add timeout
        while (!UserInterface.IsInLoadingScreen()) {
            send 4
            sleep 25
        }

        Aerodrome.DisableSpeedHack()
        Aerodrome.WaitLoadingScreen()
    }

    CheckRepair()
    {
        ; repair weapon after the defined amount of runs
        if (mod(this.runCount, Configuration.UseRepairToolsAfterRunCount()) == 0 || this.runCount == 0) {
            Aerodrome.RepairWeapon()
        }
    }

    ExitDungeon()
    {
        log.addLogEntry("$time: exiting dungeon")

        while (UserInterface.IsOutOfCombat()) {
            if (UserInterface.IsReviveVisible()) {
                Aerodrome.Revive()

                sleep 2*1000
            }

            ; walk a tiny bit so possible confirmation windows (like cd on escape)
            send {w}
            sleep 250

            send {Esc}
            sleep 1*1000

            UserInterface.ClickExit()
            sleep 1*1000
            send y
        }

        while (!UserInterface.IsInLoadingScreen()) {
            if (UserInterface.IsReviveVisible()) {
                log.addLogEntry("$time: died while trying to exit, reviving and trying again")
                Aerodrome.Revive()

                sleep 2*1000

                return Aerodrome.ExitDungeon()
            }


            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        this.runCount += 1

        return Aerodrome.EnterLobby()
    }

    ; repair the weapon
    RepairWeapon()
    {
        log.addLogEntry("$time: repairing weapon")

        start := A_TickCount
        while (A_TickCount < start + 5.5*1000) {
            Configuration.UseRepairTools()
            sleep 5
        }
    }

    Exiting()
    {
        Utility.ReleaseAllKeys()

        if (Configuration.ShutdownComputerAfterCrash()) {
            WinGet, currentProcess, ProcessName, A
            if (currentProcess != "BNSR.exe") {
                ; normal shutdown and force close applications
                Shutdown, 5
            }
        }
    }
}