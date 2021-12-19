﻿SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\ui.ahk
#Include %A_ScriptDir%\hotkeys.ahk

class Aerodrome
{
    static runCount := 0

    static successfulRuns := []
    static failedRuns := []

    static diedInRun := false
    static runStartTimeStamp := 0

    ; function we can call when we expect a loading screen and want to wait until the loading screen is over
    WaitLoadingScreen()
    {
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

        this.runStartTimeStamp := A_TickCount
        this.diedInRun := false

        Aerodrome.EnableSpeedHack()

        ; sometimes stage selection is out of focus, so we try to set it twice
        stage := Configuration.AerodromeStage()
        loop, 2 {
            UserInterface.EditStage()
            sleep 250
            send %stage%
            sleep 250
        }

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
        log.addLogEntry("$time: entering dungeon")

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
        sleep 4*1000 / (Configuration.MovementSpeedhackValue())

        send {a down}
        sleep 5*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        send {w up}
        sleep 50

        Aerodrome.DisableSpeedHack()

        return Aerodrome.StartAutoCombat()
    }

    StartAutoCombat()
    {
        log.addLogEntry("$time: activating auto combat")

        Configuration.ToggleAutoCombat()
        Configuration.EnableAnimationSpeedhack()

        sleep 5*1000

        start := A_TickCount

        while (!UserInterface.IsOutOfCombat() && !UserInterface.IsReviveVisible()) {
            if (Utility.GameActive()) {
                ; use talisman if in the game
                Configuration.UseTalisman()

                if (UserInterface.IsHpBelowCritical()) {
                    Configuration.CriticalHpAction()
                }

                sleep 25
            }

            if (A_TickCount > (start + 6*60*1000)) {
                ; timeout for autocombat are 6 minutes, probably being stuck somewhere, safety exit over lobby which works even when dead
                Configuration.DisableAnimationSpeedhack()
                return Aerodrome.ExitOverLobby()
            }

            if (UserInterface.IsInLoadingScreen()) {
                ; autocombat pressed 4 without ahk noticing
                this.diedInRun := true
                Aerodrome.WaitLoadingScreen()

                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        if (UserInterface.IsReviveVisible()) {
            Configuration.DisableAnimationSpeedhack()

            this.diedInRun := true
            Aerodrome.Revive()

            return Aerodrome.ExitDungeon()
        }

        Configuration.DisableAnimationSpeedhack()
        Configuration.ToggleAutoCombat()

        return Aerodrome.ExitDungeon()
    }

    Revive()
    {
        log.addLogEntry("$time: died, reviving")

        Aerodrome.EnableSpeedHack()

        ; ToDo: add timeout
        while (!UserInterface.IsInLoadingScreen()) {
            ; autocombat could revive successfully
            if (UserInterface.IsOutOfCombat()) {
                return
            }

            Configuration.UseRevive()
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

    ExitOverLobby()
    {
        log.addLogEntry("$time: exiting over lobby")
        while (!UserInterface.IsInLoadingScreen()) {
            if (!Utility.GameActive()) {
                log.addLogEntry("$time: couldn't find game process, exiting")
                ExitApp
            }

            UserInterface.LeaveParty()
        }

        UserInterface.WaitLoadingScreen()

        return Aerodrome.ExitDungeon()
    }

    ExitDungeon()
    {
        log.addLogEntry("$time: exiting dungeon")

        while (!UserInterface.IsInF8Lobby()) {
            if (!Utility.GameActive()) {
                log.addLogEntry("$time: couldn't find game process, exiting")
                ExitApp
            }

            if (UserInterface.IsReviveVisible()) {
                this.diedInRun := true
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

        if (!this.diedInRun) {
            log.addLogEntry("$time: run took " Utility.RoundDecimal(((A_TickCount - this.runStartTimeStamp) / 1000)) " seconds")
            this.successfulRuns.Push(((A_TickCount - this.runStartTimeStamp) / 1000))
        } else {
            log.addLogEntry("$time: failed run after " Utility.RoundDecimal(((A_TickCount - this.runStartTimeStamp) / 1000)) " seconds")
            this.failedRuns.Push(((A_TickCount - this.runStartTimeStamp) / 1000))
        }

        this.runCount += 1

        Aerodrome.LogStatistics()

        return true
    }

    LogStatistics()
    {
        failedRuns := this.failedRuns.Length()
        failedRate := (failedRuns / this.runCount)
        successRate := 1.0 - failedRate

        averageRunTime := 0
        for _, v in this.successfulRuns {
            averageRunTime += v
        }
        averageRunTime /= this.successfulRuns.Length()

        if (!averageRunTime) {
            averageRunTime := 0
        }

        averageFailRunTime := 0
        for _, v in this.failedRuns {
            averageFailRunTime += v
        }
        averageFailRunTime /= this.failedRuns.Length()

        if (!averageFailRunTime) {
            averageFailRunTime := 0
        }

        averageRunsHour := 3600 / (averageRunTime * successRate + averageFailRunTime * failedRate)
        expectedSuccessfulRunsPerHour := averageRunsHour * successRate
        expectedExpPerHour := (Configuration.ExpectedExpPerRun()) * expectedSuccessfulRunsPerHour

        log.addLogEntry("$time: runs done: " this.runCount " (died in " (failedRuns) " out of " this.runCount " runs (" Utility.RoundDecimal(failedRate * 100) "%), average run time: " Utility.RoundDecimal(averageRunTime) " seconds)")
        log.addLogEntry("$time: accumulated exp: " Utility.ThousandsSep(Round(this.successfulRuns.Length() * Configuration.ExpectedExpPerRun(), 2)) ", expected exp/hr: " Utility.ThousandsSep(Round(expectedExpPerHour, 2)))
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