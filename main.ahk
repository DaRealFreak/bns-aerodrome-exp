SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\camera.ahk
#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\ui.ahk
#Include %A_ScriptDir%\sync.ahk
#Include %A_ScriptDir%\hotkeys.ahk

RmbLmbSpam:
    Configuration.DefaultSpam()
	return

class Aerodrome
{
    static receiver := false
    static solo := false
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
            Configuration.EnableLobbySpeedhack()
            sleep 25
        }
    }

    EnableAnimationSpeedHack()
    {
        loop, 5 {
            Configuration.EnableAnimationSpeedHack()
            sleep 25
        }
    }

    DisableSpeedHack()
    {
        loop, 5 {
            Configuration.DisableLobbySpeedhack()
            sleep 25
        }
    }

    DisableAnimationSpeedHack()
    {
        loop, 5 {
            Configuration.DisableAnimationSpeedhack()
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

    ; function we use for checking if we should check potions
    CheckHealth()
    {
        if (UserInterface.IsHpBelowCritical()) {
            Configuration.UseHealthPotion()
        }
    }

    EnterLobby(receiver, solo = false)
    {
        this.receiver := receiver
        this.solo := solo

        log.addLogEntry("$time: moving to dungeon")

        this.runStartTimeStamp := A_TickCount
        this.diedInRun := false

        if (!this.receiver || this.solo) {
            if (!this.solo) {
                if (!Configuration.IsWarlockTest()) {
                    lastInvite := 0
                    while (!UserInterface.IsDuoReady()) {
                        if (lastInvite + 3*1000 <= A_TickCount) {
                            UserInterface.ClickChat()
                            Configuration.InviteDuo()
                            send {Enter}
                            lastInvite := A_TickCount
                        }
                        sleep 25
                    }

                }
            }

            Aerodrome.EnableSpeedHack()

            while (!UserInterface.IsInLoadingScreen()) {
                ; sometimes stage selection is out of focus, so we try to set it twice
                stage := Configuration.AerodromeStage(this.solo)
                loop, 2 {
                    UserInterface.EditStage()
                    sleep 250
                    send %stage%
                    sleep 250
                }

                UserInterface.ClickEnterDungeon()
                start := A_TickCount

                ; repeat loop every 3 seconds but break as soon as we see the loading screen
                while (start + 3*1000 >= A_TickCount) {
                    if (UserInterface.IsInLoadingScreen()) {
                        break
                    }
                    sleep 25
                }
            }

            Aerodrome.DisableSpeedHack()
        } else {
            ; receiver clears previous states to prevent desyncs
            Sync.ClearStates()

            while (UserInterface.IsLfpButtonVisible()) {
                ; click somewhere so we're not in the chatbox anymore
                UserInterface.ClickReady()
                ; accept invites
                send y
            }

            ; click ready
            UserInterface.ClickReady()
            sleep 1*1000

            Sync.SetState("in_lobby")
        }

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
        if (!this.receiver || this.solo) {
            Aerodrome.CheckRepair()
        }

		sleep 1*1000

        Aerodrome.CheckBuffFood()

        if (!this.receiver || this.solo) {
            sleep 0.5*1000
            Aerodrome.CheckHealth()
        }

        if (this.receiver && !this.solo) {
            Sync.WaitForState("dummyroom")
        }

        log.addLogEntry("$time: moving to the dummy room")

        Aerodrome.EnableAnimationSpeedHack()

        send {w down}
        send {Shift}
        sleep 13*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        send {s down}
        sleep 1.5*1000 / (Configuration.MovementSpeedhackValue())
        send {s up}

        send {a down}
        sleep 11*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        sleep 50

        send {w down}
        send {Shift}
        ; sleep 3.5 seconds for solo action or 4.5 seconds for wl carry run
        sleep 3.5*1000 / (Configuration.MovementSpeedhackValue())
        if (!this.solo) {
            sleep 1*1000 / (Configuration.MovementSpeedhackValue())
        }
        send {w up}
        sleep 50

        if (this.solo) {
            ; walk into the corner
            send {w down}
            send {a down}
            send {Shift}
            sleep 4*1000 / Configuration.MovementSpeedhackValue()
            send {a up}
            send {w up}
            sleep 50

            return Aerodrome.StartAutoCombat()
        }

        if (!this.receiver) {
            ; slave reached dummy room, tell receiver to start moving to dummy room
            Sync.SetState("dummyroom")
        }

        if (this.receiver) {
            ; continue running for a while to get rid of mobs
            send {w down}
            send {Shift}
            sleep 7*1000 / (Configuration.MovementSpeedhackValue())
            send {w up}
            sleep 250

            while (UserInterface.IsSuperJumpAvailable()) {
                Configuration.UseSuperJumpSkill()
                sleep 5
            }

            Sync.WaitForState("exit_dungeon", 90*1000)

            return Aerodrome.ExitDungeon()
        }

        return Aerodrome.PullDummies()
    }

    PullDummies()
    {
        Sync.SetState("dummyroom")

        ; get into combat for reliable pulling of mobs
        while (!UserInterface.IsBlockOnCooldown()) {
            if (UserInterface.IsReviveVisible()) {
                Sync.SetState("exit_dungeon")

                return Aerodrome.ExitDungeon()
            }

            Configuration.UseBlockSkill()
            sleep 5
        }

        Settimer, RmbLmbSpam, 25

        send {a down}
        sleep 4*1000 / (Configuration.MovementSpeedhackValue())
        send {a up}

        send {w down}
        sleep 4*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; spin camera by 90° to the right
        Camera.Spin(90)

        send {a down}
        sleep 4*1000 / (Configuration.MovementSpeedhackValue())
        send {a up}

        send {w down}
        sleep 3.5*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; spin camera by 90° to the right
        Camera.Spin(90)

        send {w down}
        sleep 5*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; pull aggro of last dummy group
        sleep 0.2*1000

        Settimer, RmbLmbSpam, Off

        while (UserInterface.IsSsAvailable()) {
            send ss
            sleep 5
        }

        send {s down}
        sleep 2*1000 / (Configuration.MovementSpeedhackValue())
        send {s up}

        while (!UserInterface.IsSsAvailable()) {
            if (UserInterface.IsReviveVisible()) {
                this.diedInRun := true
                Sync.SetState("exit_dungeon")

                return Aerodrome.ExitDungeon()
            }

            Configuration.DefaultSpam()
        }

        start := A_TickCount
        while (A_TickCount < start + 1.25*1000) {
            Configuration.DefaultSpam()
        }

        send {d down}
        sleep 1.7*1000 / (Configuration.MovementSpeedhackValue())
        send {d up}

        while (UserInterface.IsSsAvailable()) {
            send ss
            sleep 5
        }

        ; turn camera 10 to the left since we walked a bit to the right
        Camera.Spin(-10)

        start := A_TickCount
        while (start + 1.3*1000 >= A_TickCount) {
            ; trigger iframe while we wait
            send z
            sleep 25
        }

        ; walk tiny bit closer to hit the last bronze dummy
        send {w down}
        send {d down}
        sleep 0.2*1000 / (Configuration.MovementSpeedhackValue())
        send {d up}
        ; inch tiny bit closer to hit the last few dummies in all cases
        sleep 0.3*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; turn camera 10° to the left to get the last group of mobs in our ccs
        Camera.Spin(-10)

        usedTd := false
        start := A_TickCount

        ; break combat after 20 seconds since our burst is over
        while (A_TickCount <= start + 20*1000) {
            if (UserInterface.IsReviveVisible() || UserInterface.IsInLoadingScreen()) {
                this.diedInRun := true
                break
            }

            Configuration.DpsSpam()
        }

        ; exit early even if maybe some autocasts would still kill some dummies for faster loading screens
        Sync.SetState("exit_dungeon")

        ; walk tiny bit in case we can't use jump at that position
        send {w down}
        sleep 0.1*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; use superjump to exit to lobby faster until we get out of combat
        while (UserInterface.IsSuperJumpVisible() && !UserInterface.IsOutOfCombat()) {
            Configuration.UseSuperJumpSkill()
            sleep 25
        }

        return Aerodrome.ExitDungeon()
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

        Configuration.ToggleAutoCombat()

        if (UserInterface.IsReviveVisible()) {
            Configuration.DisableAnimationSpeedhack()

            this.diedInRun := true

            return Aerodrome.ExitDungeon()
        }

        Configuration.DisableAnimationSpeedhack()

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

            ; revive to prevent appearing in death logs
            if (UserInterface.IsReviveVisible()) {
                Aerodrome.Revive()
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
        expectedExpPerHour := (Configuration.ExpectedExpPerRun(this.solo)) * expectedSuccessfulRunsPerHour
        accumulatedExp := this.successfulRuns.Length() * Configuration.ExpectedExpPerRun(this.solo)

        if (!this.solo) {
            ; if we're running in solo exp is reduced to 60%
            expectedExpPerHour := expectedExpPerHour * 0.6
            accumulatedExp := accumulatedExp * 0.6
        }

        log.addLogEntry("$time: runs done: " this.runCount " (died in " (failedRuns) " out of " this.runCount " runs (" Utility.RoundDecimal(failedRate * 100) "%), average run time: " Utility.RoundDecimal(averageRunTime) " seconds)")
        log.addLogEntry("$time: accumulated exp: " Utility.ThousandsSep(Round(accumulatedExp, 2)) ", expected exp/hr: " Utility.ThousandsSep(Round(expectedExpPerHour, 2)))
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