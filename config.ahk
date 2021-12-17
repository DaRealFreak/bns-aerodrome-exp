#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is primarily used for specific keys or optional settings like speedhack, cross server etc
*/
class Configuration 
{
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
    AerodromeStage()
    {
        return 53
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
    ExpectedExpPerRun()
    {
        ; 21 dummies * x exp, big dummy gives 0 exp
        config := {}
        config.Insert(52, 21 * 78 100)
        config.Insert(53, 21 * 91 443)
        config.Insert(54, 21 * 106 175)
        config.Insert(55, 21 * 123 130)

        selectedStage := Configuration.AerodromeStage()
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
        return 6
    }

    ToggleAutoCombat()
    {
        send {ShiftDown}{f4 down}
        sleep 250
        send {ShiftUp}{f4 up}
    }

    ; enable movement speed hack (sanic or normal ce speedhack)
    EnableMovementSpeedhack()
    {
        send {Numpad7}
    }

    ; disable movement speed hack (sanic or normal ce speedhack)
    DisableMovementSpeedhack()
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
        return 5.0
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
}