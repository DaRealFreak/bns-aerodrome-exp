#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is used for differences in the user interfaces.
If the resolution and ClientConfiguration.xml are not identical you'll always have to change these settings
*/
class UserInterface
{
    ClickExit()
    {
        MouseClick, left, 1770, 870
    }

    ; start holding mouse right side of the stage number and release it left of the stage number to edit
    EditStage()
    {
        MouseClick, Left, 1738, 476
        click down
        sleep 150
        MouseMove, 1717, 476
        click up
    }

    LeaveParty()
    {
        send {AltDown}
        sleep 150
        MouseClick, Left, 318, 78
        sleep 150
        send {AltUp}

        sleep 500
        send y
    }

    ClickReady()
    {
        MouseClick, left, 962, 1035
    }

    ClickChat()
    {
        MouseClick, left, 158, 887
    }

    ClickEnterDungeon()
    {
        MouseClick, left, 1032, 1034
    }

    IsDuoReady()
    {
        return Utility.GetColor(984,120) == "0x38D454"
    }

    IsLfpButtonVisible()
    {
        return Utility.GetColor(860,1040) == "0x214475"
    }

    IsSuperJumpVisible()
    {
        return Utility.GetColor(1276,888) == "0x867877"
    }

    IsSuperJumpAvailable()
    {
        return Utility.GetColor(1277,888) == "0xBCB9B1"
    }

    IsBlockOnCooldown()
    {
        return Utility.GetColor(892,887) == "0x611B1C"
    }

    IsSsAvailable()
    {
        return Utility.GetColor(695,951) == "0xD8A4B3"
    }

    IsHpBelowCritical()
    {
        return Utility.GetColor(1038,795) != "0xE0280C"
    }

    ; whenever you want to refresh your exp buff food (basically one of the last pixels which will become darker)
    IsBuffFoodIconVisible()
    {
        return Utility.GetColor(21,7) == "0x866C33"
    }

    ; some of the filled out bar in the loading screen on the bottom of the screen
    IsInLoadingScreen()
    {
        return Utility.GetColor(20,1063) == "0xFF7C00"
    }

    ; literally any UI element in lobby and ingame, just used for checking if we're out of the loading screen, I'm using here my unity bar and enter button
    IsOutOfLoadingScreen()
    {
        return Utility.GetColor(67,1054) == "0x000001" || UserInterface.IsInF8Lobby()
    }

    IsInF8Lobby()
    {
        return Utility.GetColor(1043,1025) == "0x214475"
    }

    ; any pixel on the revive skil
    IsReviveVisible()
    {
        return Utility.GetColor(1038,899) == "0x6F542B"
    }

    ; sprint bar to check if we're out of combat
    IsOutOfCombat()
    {
		col := Utility.GetColor(809,836)
        return col == "0xA6B721" || col == "0xA5B721"
    }
}