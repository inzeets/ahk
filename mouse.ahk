Menu, Tray, Icon, z_mouse.png

CoordMode, Mouse, Screen

Loop
{
    ; Move mouse
    MouseMove, 0, 1, 0, R
    ; Replace mouse to its original location
    MouseMove, 0, -1, 0, R
    ; Wait before moving the mouse again
    Sleep, 60000
}
