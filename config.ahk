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

    ; depending on the exp boni you have
    ExpectedExpPerRun()
    {
        config := {}
        ; 21 dummies x 78,100 exp, big dummy gives 0 exp
        config.Insert(52, 1 640 103)
        ; 21 dummies x 91,443 exp
        config.Insert(53, 1 920 303)
        config.Insert(54, 2 229 675)
        config.Insert(55, 2 585 730)

        selectedStage := Configuration.AerodromeStage()
        if (config[selectedStage] > 0) {
            return config[selectedStage]
        } else {
            return 0
        }
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