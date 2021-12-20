#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

class Camera
{
    static fullTurn := 3174

    Spin(degrees)
    {
        pxls := this.fullTurn / 360 * degrees
        ; you have to experiment a little with your settings here due to your DPI, ingame sensitivity etc
        DllCall("mouse_event", "UInt", 0x0001, "UInt", pxls, "UInt", 0)
    }
}