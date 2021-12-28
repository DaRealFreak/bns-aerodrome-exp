#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is primarily used for specific keys or optional settings like speedhack, cross server etc
*/
class Configuration 
{
    IsWarlockTest()
    {
        return false
    }

    ; shut down the computer if no bns processes are found anymore (dc or maintenance)
    ShutdownComputerAfterCrash()
    {
        return false
    }

    ; should the character even use buff food
    ShouldUseBuffFood()
    {
        return true
    }

    ; which stage to farm
    AerodromeStage(solo)
    {
        if (solo) {
            return 51
        } else {
            return 65
        }
    }

    ; whatever we want to do if health is critical (f.e. hmb/drinking potions)
    CriticalHpAction()
    {
        loop, 15 {
            send f
            sleep 5
        }

        Configuration.UseHealthPotion()
    }

    ; depending on the exp boni you have
    ExpectedExpPerRun(solo)
    {
        ; 21 dummies * x exp, big dummy gives 0 exp
        config := {}
        config.Insert(51, 21 * 66 705)
        config.Insert(52, 21 * 78 100)
        config.Insert(53, 21 * 91 443)
        config.Insert(54, 21 * 106 175)
        config.Insert(55, 21 * 123 130)
        config.Insert(56, 21 * 141 474)
        config.Insert(57, 21 * 155 930)
        config.Insert(58, 21 * 165 102)
        config.Insert(59, 21 * 175 108)
        config.Insert(60, 21 * 184 835)
        config.Insert(61, 21 * 194 286)
        config.Insert(62, 21 * 204 013)
        config.Insert(63, 21 * 214 299)
        config.Insert(64, 21 * 225 139)
        config.Insert(65, 21 * 236 259)
        config.Insert(66, 21 * 248 208)
        config.Insert(67, 21 * 260 438)
        config.Insert(68, 21 * 268 221)
        config.Insert(69, 21 * 276 283)

        selectedStage := Configuration.AerodromeStage(solo)
        if (config[selectedStage] > 0) {
            return config[selectedStage]
        } else {
            return 0
        }
    }

    UseHealthPotion()
    {
        send 5
    }

    ; hotkey where the buff food is placed
    UseBuffFood()
    {
        send 6
    }

    ; hotkey where the field repair hammers are placed
    UseRepairTools()
    {
        send 7
    }

    ; after how many runs should we repair our weapon
    UseRepairToolsAfterRunCount()
    {
        return 4
    }

    ToggleAutoCombat()
    {
        send {ShiftDown}{f4 down}
        sleep 250
        send {ShiftUp}{f4 up}
    }

    ; enable speed hack (sanic or normal ce speedhack)
    EnableLobbySpeedhack()
    {
        send {Numpad7}
    }

    ; disable movement speed hack (sanic or normal ce speedhack)
    DisableLobbySpeedhack()
    {
        send {Numpad3}
    }

    EnableAnimationSpeedhack()
    {
        send {Numpad6}
    }

    DisableAnimationSpeedhack()
    {
        send {Numpad3}
    }

    ; configured speed value
    MovementSpeedhackValue()
    {
        return 5.5
    }

    ; shortcut for shadowplay clip in case we want to debug how we got stuck or got to this point
    ClipShadowPlay()
    {
        send {alt down}{f10 down}
        sleep 1000
        send {alt up}{f10 up}
    }

    UseTalisman()
    {
        send r
    }

    UseRevive()
    {
        send 4
    }

    UseBlockSkill()
    {
        send 1
    }

    UseSuperJumpSkill()
    {
        send g
    }

    DefaultSpam()
    {
        send r
        sleep 5
        send t
        sleep 5
        send f
        sleep 5
    }

    DpsSpam()
    {
        send 2
        sleep 5

        ; bracelet
        send 3
        sleep 5

        ; stance enter and 4
        if (!UserInterface.IsReviveVisible() && UserInterface.IsSuperJumpVisible()) {
            send 4
            sleep 5
        }

        ; warding strike
        send c
        sleep 5

        ; iframe bubble
        send y
        sleep 5

        ; talisman
        send z
        sleep 5
    }

    InviteDuo()
    {
        send /invite "Lunar Tempest"
    }
}