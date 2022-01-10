SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\camera.ahk
#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\game.ahk
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

    EnterLobby()
    {
        ; clear logs evey 10 runs due to performance getting worse over time, possibly log related?
        if (this.runCount > 0 && mod(this.runCount, 10) == 0) {
            log.initalizeNewLogFile(1)
        }

        log.addLogEntry("$time: moving to dungeon")

        this.runStartTimeStamp := A_TickCount
        this.diedInRun := false

        inGroup := false

        while (true) {
            Game.SwitchToWindow(Game.GetStartingWindowHwid())

            if (UserInterface.IsDuoReady()) {
                break
            }

            ; main invites leecher
            loop, 3 {
                UserInterface.ClickChat()
                sleep 150
            }

            Configuration.InviteDuo()
            send {Enter}

            ; every leecher accepts
            for index, hwnd in Game.GetOtherWindowHwids()
            {
                Game.SwitchToWindow(hwnd)
                
                ; while we don't have a party member just normally loop
                if (!UserInterface.HasPartyMemberInLobby()) {
                    loop, 5 {
                        UserInterface.ClickReady()
                        send y
                        sleep 100
                    }

                    if (UserInterface.HasPartyMemberInLobby()) {
                        ; else ready up
                        while (!UserInterface.IsReady()) {
                            ; click ready
                            UserInterface.ClickReady()
                            sleep 1*1000
                        }
                    }
                } else {
                    ; safety activation if we skipped the initial one
                    while (!UserInterface.IsReady()) {
                        ; click ready
                        UserInterface.ClickReady()
                        sleep 1*1000
                    }
                }
            }

            Game.SwitchToWindow(Game.GetStartingWindowHwid())

            ; break if duo is ready or sleep 3 seconds before next invite cycle
            lastInvite := 0
            while (!UserInterface.IsDuoReady()) {
                if (lastInvite + 3*1000 <= A_TickCount) {
                    break
                }
                sleep 25
            }
        }

        Aerodrome.EnableSpeedHack()

        while (!UserInterface.IsInLoadingScreen()) {
            ; sometimes stage selection is out of focus, so we try to set it twice
            stage := Configuration.AerodromeStage()
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

        ; move into the dungeon
        ; every leecher runs in first
        for index, hwnd in Game.GetOtherWindowHwids()
        {
            Game.SwitchToWindow(hwnd)
            Aerodrome.WaitLoadingScreen()
            Aerodrome.EnterDungeon()
        }

        ; now run in with main account
        Game.SwitchToWindow(Game.GetStartingWindowHwid())
        Aerodrome.WaitLoadingScreen()
        Aerodrome.EnterDungeon()


        ; move to dummies
        ; every leecher runs in first
        for index, hwnd in Game.GetOtherWindowHwids()
        {
            Game.SwitchToWindow(hwnd)
            Aerodrome.WaitLoadingScreen()
            Aerodrome.MoveToDummies(true)
        }

        ; now run in with main account
        Game.SwitchToWindow(Game.GetStartingWindowHwid())
        Aerodrome.WaitLoadingScreen()
        Aerodrome.MoveToDummies(false)

        return Aerodrome.PullDummies()
    }

    EnterDungeon()
    {
        log.addLogEntry("$time: entering dungeon")

        send {w down}
        send {Shift}

        sleep 250

        start := A_TickCount
        while (!UserInterface.IsInLoadingScreen()) {
            if (mod(Round(A_TickCount / 1000), 5) == 0) {
                Random, rand, 1, 10
                if (rand >= 5) {
                    send {Space down}
                    sleep 200
                    send {Space up}
                }
                ; sleep 0.5 seconds so we don't run into the modulo check again in this cycle
                sleep 1000
            }

            sleep 25
        }
    }

    MoveToDummies(leecher := false)
    {
        if (!leecher) {
            Aerodrome.CheckRepair()
        }

		sleep 1*1000

        Aerodrome.CheckBuffFood()

        if (!leecher) {
            sleep 0.5*1000
            Aerodrome.CheckHealth()
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
        sleep 1*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        if (leecher) {
            ; continue running for a while to get rid of mobs
            send {w down}
            send {Shift}
            sleep 5*1000 / (Configuration.MovementSpeedhackValue())
            send {w up}
            sleep 250

            while (UserInterface.IsSuperJumpAvailable() && Utility.GameActive()) {
                Configuration.UseSuperJumpSkill()
                sleep 5
            }

            return
        }

        return
    }

    PullDummies()
    {
        ; get into combat for reliable pulling of mobs
        while (!UserInterface.IsBlockOnCooldown()) {
            if (UserInterface.IsReviveVisible()) {
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
        sleep 2.5*1000 / (Configuration.MovementSpeedhackValue())
        send {s up}

        while (!UserInterface.IsSsAvailable()) {
            if (UserInterface.IsReviveVisible()) {
                this.diedInRun := true
                return Aerodrome.ExitDungeon()
            }

            Configuration.DefaultSpam()
        }

        start := A_TickCount
        while (A_TickCount < start + 0.8*1000) {
            Configuration.DefaultSpam()
        }

        while (UserInterface.IsSsAvailable()) {
            send ss
            sleep 5
        }

        ; wait for ss animation
        sleep 300

        ; get unstuck
        send {w down}
        sleep 0.1*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; walk right
        send {d down}
        sleep 1*1000 / (Configuration.MovementSpeedhackValue())
        send {d up}

        send {s down}
        sleep 0.4*1000 / (Configuration.MovementSpeedhackValue())
        send {s up}

        send {d down}
        sleep 0.35*1000 / (Configuration.MovementSpeedhackValue())
        send {d up}

        ; turn camera 27° to the left since we walked a bit to the right
        Camera.Spin(-27)

        start := A_TickCount
        while (start + 0.8*1000 >= A_TickCount) {
            ; trigger iframe while we wait
            send z
            sleep 25
            Configuration.DefaultSpam()
        }

        send {s down}
        sleep 0.1*1000 / (Configuration.MovementSpeedhackValue())
        send {s up}

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

        ; walk tiny bit in case we can't use jump at that position
        send {w down}
        sleep 0.1*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}

        ; use superjump to exit to lobby faster until we get out of combat
        while (UserInterface.IsSuperJumpAvailable() && !UserInterface.IsOutOfCombat() && Utility.GameActive()) {
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
        ; every leecher runs in first
        for index, hwnd in Game.GetOtherWindowHwids()
        {
            Game.SwitchToWindow(hwnd)
            Aerodrome.ExitDungeonSingleClient()
        }

        ; now run in with main account
        Game.SwitchToWindow(Game.GetStartingWindowHwid())
        Aerodrome.ExitDungeonSingleClient()

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

    ExitDungeonSingleClient()
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
        accumulatedExp := this.successfulRuns.Length() * Configuration.ExpectedExpPerRun()

        if (!Configuration.IsWarlockTest()) {
            ; if we're running in duo exp is reduced to 60% of the original
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