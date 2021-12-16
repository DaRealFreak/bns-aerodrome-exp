#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

; everything utility related
class Utility
{
    ; return the color at the passed position
    GetColor(x, y, ByRef red:=-1, ByRef green:=-1, ByRef blue:=-1)
    {
        PixelGetColor, color, x, y, RGB
        StringRight color,color,10
        ; only bitshift if the refs actually got passed to the function
        if (red != -1) {
            red := ((color & 0xFF0000) >> 16)
        }
        if (green != -1) {
            green := ((color & 0xFF00) >> 8)
        }
        if (blue != -1) {
            blue := (color & 0xFF)
        }
        Return color
    }

    ; check if BnS is the current active window
    GameActive()
    {
        Return WinActive("ahk_class UnrealWindow")
    }

    ; send up command for every key to remove leftover key press residues
    ReleaseAllKeys()
    {
        loop, 0xFF
        {
            key := Format("VK{:02X}",A_Index)
            if GetKeyState(key) {
                send {%key% Up}
            }
        }
    }

    RoundDecimal(value)
    {
        return RegExReplace(value,"(\.\d{2})\d*","$1")
    }
}