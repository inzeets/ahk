; https://superuser.com/questions/1374974/shortcut-to-jump-mouse-cursor-from-one-screen-to-another-in-windows-10

if not A_IsAdmin
{
    Run *RunAs "%A_AhkPath%" "%A_ScriptFullPath%"
    ExitApp
}

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


Menu, Tray, Add, Recalibrate, calibrate
Menu, Tray, Icon, display_shifter.ico
Process, priority,, BelowNormal
EmptyMem()
CoordMode, Mouse, Screen ; mouse coordinates relative to the Screen

; Init global var
EnvGet, vUserProfile, USERPROFILE ; C:\Windows\System32\config\systemprofile\display_shifter.ini 
init_file_path = %vUserProfile%\display_shifter.ini
global init_file = init_file_path
global disp1_x_min
global disp1_y_min
global disp1_x_max
global disp1_y_max
global disp1_mid_x
global disp1_mid_y
global disp1_last_x
global disp1_last_y

global disp2_x_min
global disp2_y_min
global disp2_x_max
global disp2_y_max
global disp2_mid_x
global disp2_mid_y
global disp2_last_x
global disp2_last_y

global x
global y

; storing dict of {"window title": id}
global window_ids = Object()
; storing dict of {"window title": Icon Handle}
global window_icons = Object()

global window_list_menu

; setup for DllCall to retrieve window icons
global WM_GETICON = 0x007F
global ICON_SMALL = 0
global ICON_BIG = 1
global GCLP_HICON = -14
global GCLP_HICONSM = -34

; if display_shifter.ini file exist we load it, otherwise we initiate calibration
if FileExist(init_file){
	IniRead, disp1_x_min, %init_file%, display_1, x_min
	IniRead, disp1_y_min, %init_file%, display_1, y_min
	IniRead, disp1_x_max, %init_file%, display_1, x_max
	IniRead, disp1_y_max, %init_file%, display_1, y_max
	IniRead, disp1_mid_x, %init_file%, display_1, x_mid
	IniRead, disp1_mid_y, %init_file%, display_1, y_mid
	disp1_last_x := disp1_mid_x
	disp1_last_y := disp1_mid_y

	IniRead, disp2_x_min, %init_file%, display_2, x_min
	IniRead, disp2_y_min, %init_file%, display_2, y_min
	IniRead, disp2_x_max, %init_file%, display_2, x_max
	IniRead, disp2_y_max, %init_file%, display_2, y_max
	IniRead, disp2_mid_x, %init_file%, display_2, x_mid
	IniRead, disp2_mid_y, %init_file%, display_2, y_mid
	disp2_last_x := disp2_mid_x
	disp2_last_y := disp2_mid_y

}
else{
	calibrate()
}

calibrate(){
	global
	disp1_x_min = 0
	disp1_y_min = 0
	disp1_x_max = 0
	disp1_y_max = 0
	disp1_mid_x = 0
	disp1_mid_y = 0
	disp1_last_x = 0
	disp1_last_y = 0

	disp2_x_min = 0
	disp2_y_min = 0
	disp2_x_max = 0
	disp2_y_max = 0
	disp2_mid_x = 0
	disp2_mid_y = 0
	disp2_last_x = 0
	disp2_last_y = 0
	create_window_menu()
	; Msgbox, Select a window Maximized on display 1
	Menu, window_list_menu, Show
	; Msgbox, display 1: (%disp1_x_min%, %disp1_y_min%) - (%disp1_x_max%, %disp1_y_max%) `n display 2: (%disp2_x_min%, %disp2_y_min%) - (%disp2_x_max%, %disp2_y_max%) `n`n saved position disp_1 (%disp1_last_x%, %disp1_last_y%) `n saved position disp_2 (%disp2_last_x%, %disp2_last_y%)
	save_to_init()
}

; retrieve list of opened Window and create menu from it
create_window_menu(){
	WinGet, id, List,,,Start|Program Manager|^$
	Loop %id%
	{
		this_id := id%A_Index%
		WinGet, minMax, MinMax, ahk_id %id%
		WinGetTitle, this_title, ahk_id %this_id%
		; get icons
		SendMessage, WM_GETICON, ICON_SMALL, 96, , ahk_id %this_id%
		if (ErrorLevel != "FAIL")
		{
			IconHwnd := ErrorLevel
		}
		if (IconHwnd = 0)
		{
			IconHwnd := DllCall("GetClassLongPtr", "Ptr", this_id, "Int", GCLP_HICONSM)
		}
		; skip window not in taskbar
		If (minMax != -1) and (this_title != "Program manager") {   ; -1 = minimized

			WinGetPos,,,,height  , ahk_id %this_id%

			If (height) {
				WinGetTitle, this_title, ahk_id %this_id%
				window_ids.Insert(this_title, this_id)
				If (IconHwnd) {
					window_icons.Insert(this_title, IconHwnd)
				}
			}

		}
	}
	; delete any previously populated menu items
	if (window_list_menu){
		Menu, window_list_menu, DeleteAll
	}
	; create menu listing of all open windows
	for title, hid in window_ids {
		try {
			Menu, window_list_menu, Add, %title% , SetDisplayExtend
			If (window_icons.HasKey(title)){
				icon_hdl := window_icons[title]
				Menu, window_list_menu, Icon, %title%, HICON:*%icon_hdl%
			}
		} catch e{
			continue
		}
	}
}

offsetter(value, offset) {
	if (value < 0)
		newval := value - offset
	else
		newval := value + offset

return newval
}

; set display extend from selected maximized window
SetDisplayExtend() {
	if (disp1_mid_x == 0){
		win_id := window_ids[A_ThisMenuItem]
		WinGetPos, Xw, Yw, Ww, Hw, ahk_id %win_id%
		; Xw := offsetter(Xw, 25)
		; Yw := offsetter(Hw, 25)
		disp1_x_min := Xw
		disp1_x_min := disp1_x_min + 9
		disp1_y_min := Yw
		disp1_y_min := disp1_y_min + 9
		disp1_x_max := Xw + Ww
		disp1_y_max := Yw + Hw
		disp1_y_max := disp1_y_max + 25

		disp1_mid_x :=  Round(disp1_x_min + ((disp1_x_max - disp1_x_min) / 2))
		disp1_mid_y := Round(disp1_y_min + ((disp1_y_max - disp1_y_min) / 2))
		disp1_last_x := disp1_mid_x
		disp1_last_y := disp1_mid_y

		; Msgbox, Select a window Maximized on display 2
		Menu, window_list_menu, Show
	} else {
		win_id := window_ids[A_ThisMenuItem]
		WinGetPos, Xw, Yw, Ww, Hw, ahk_id %win_id%
		; Xw := offsetter(Xw, 20)
		; Yw := offsetter(Yw, 20)
		disp2_x_min := Xw
		disp2_y_min := Yw
		disp2_x_max := Xw + Ww
		disp2_y_max := Yw + Hw

		disp2_mid_x :=  Round(disp2_x_min + ((disp2_x_max - disp2_x_min) / 2))
		disp2_mid_y := Round(disp2_y_min + ((disp2_y_max - disp2_y_min) / 2))
		disp2_last_x := disp2_mid_x
		disp2_last_y := disp2_mid_y
	}
}

; save display extend to file in USERPROFILE
save_to_init(){
	Msgbox, display 1 extend: `(%disp1_x_min%`, %disp1_y_min%`) - `(%disp1_x_max%`, %disp1_y_max%`) `ndisplay 2 extend: `(%disp2_x_min%`, %disp2_y_min%`) - `(%disp2_x_max%`, %disp2_y_max%`) `n`nSaved to`:`n`"%init_file%`"
	IniWrite, %disp1_x_min%, %init_file%, display_1, x_min
	IniWrite, %disp1_y_min%, %init_file%, display_1, y_min
	IniWrite, %disp1_x_max%, %init_file%, display_1, x_max
	IniWrite, %disp1_y_max%, %init_file%, display_1, y_max
	IniWrite, %disp1_mid_x%, %init_file%, display_1, x_mid
	IniWrite, %disp1_mid_y%, %init_file%, display_1, y_mid

	IniWrite, %disp2_x_min%, %init_file%, display_2, x_min
	IniWrite, %disp2_y_min%, %init_file%, display_2, y_min
	IniWrite, %disp2_x_max%, %init_file%, display_2, x_max
	IniWrite, %disp2_y_max%, %init_file%, display_2, y_max
	IniWrite, %disp2_mid_x%, %init_file%, display_2, x_mid
	IniWrite, %disp2_mid_y%, %init_file%, display_2, y_mid
}

; reload script
^XButton1::
	Reload
	return

; triggers the shifting
; XButton1
; !Space::
; ^LButton::
XButton1::
	MouseGetPos, MouseX, MouseY

    y := MouseY
    x := MouseX

	if ( (MouseX >= disp1_x_min and MouseY >= disp1_y_min) and (MouseX <= disp1_x_max and MouseY <= disp1_y_max)) { ; Mouse is on monitor #1
		;MsgBox, Mouse`: %MouseX%x%MouseY% `n Display1 Min %disp1_x_min%x%disp1_y_min% `n Display1 Max %disp1_x_max%x%disp1_y_max% `n Display2 Min %disp2_x_min%x%disp2_y_min% `n Display2 Max %disp2_x_max%x%disp2_y_max% `n therefor belong to screen 1 -> moving to saved position on screen 2 %disp2_last_x%, %disp2_last_y%
		disp1_last_y := MouseY
		disp1_last_x := MouseX
		;MouseMove, disp2_last_x, disp2_last_y
		;MouseMove, disp2_last_x, disp2_last_y
		SetTimer, hp_true, 5
		DllCall("SetCursorPos", "int", disp2_last_x, "int", disp2_last_y)
		;SetTimer, hp_false, 5

	} else { ; Mouse is on monitor #1
		;MsgBox, Mouse`: %MouseX%x%MouseY% `n Display1 Min %disp1_x_min%x%disp1_y_min% `n Display1 Max %disp1_x_max%x%disp1_y_max% `n Display2 Min %disp2_x_min%x%disp2_y_min% `n Display2 Max %disp2_x_max%x%disp2_y_max% `n therefor belong to screen 2 -> moving to saved position on screen 1 %disp1_last_x%, %disp1_last_y%
		disp2_last_y := MouseY
		disp2_last_x := MouseX
		;MouseMove, disp1_last_x, disp1_last_y
		SetTimer, hp_true, 5
 		MouseMove, disp1_last_x, disp1_last_y
		;DllCall("SetCursorPos", "int", disp1_last_x,, "int", disp1_last_y)
		;SetTimer, hp_false, 5
	}
return

hp_false:
highlight_pos(false)
SetTimer, hp_false, Off
return

hp_true:
highlight_pos(true)
SetTimer, hp_true, Off
return

; display a red circle at the cursor's arrival position for easier spotting
highlight_pos(bye)
{
	GetKeyState, state, LButton
	if (state = "U")
	{
        name := bye ? "Aqua" : "Red" ; "Lime"
		Gui, %name%:Destroy
        Gui, %name%:New, -Caption +ToolWindow +AlwaysOnTop
        Gui, %name%:Color, %name%
        Gui, %name%:+LastFound
		GuiHwnd := WinExist()
		DetectHiddenWindows, On
		WinSet, Transparent, 100, ahk_id %GuiHwnd%
		WinSet, Region, 0-0 W100 H100 E, ahk_id %GuiHwnd%  ; An ellipse instead of a rectangle.
        if (!bye) {
		    MouseGetPos, x, y
        }
        posX := x - 50
        posY := y - 50
		Gui, Show, w500 h500 x%posX% y%posY%
        if (bye) {
            SetTimer, hp_false, 5
            sleep 300
        } else {
            sleep 500
        }
        Gui, %name%:Destroy
	}
}

; Reduce memory footprint from 2MB to 0.3
EmptyMem(PID="AHK Rocks"){
    pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
    h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
    DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
    DllCall("CloseHandle", "Int", h)
}
