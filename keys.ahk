#Requires AutoHotkey v2.0
#SingleInstance Force

; Admin check
if not A_IsAdmin {
  try {
    Run('*RunAs "' . A_AhkPath . '" "' . A_ScriptFullPath . '"')
  }
  ExitApp
}

; Settings
ListLines(false)
KeyHistory(0)
ProcessSetPriority("H")

; Reload script
#+R::Reload

; Remaps
CapsLock::Insert
#RAlt::AppsKey
RAlt::RCtrl
RShift::End
RShift & /::Send("?")

; Disable Win key opening start menu, use Alt+Win instead
~LWin::Send("{Blind}{vkE8}")
!LWin:: {
  Sleep(50)
  Send("{LWin}")
}

; Launch settings
#k::Run("ms-settings:connecteddevices")

; Navigation
$^Up::Send("^{PgUp}")
$^Down::Send("^{PgDn}")
$!Up::Send("{PgUp}")
$!Down::Send("{PgDn}")

; Window maximize/restore
^#Up:: {
  if WinGetMinMax("A") = 1
    WinRestore("A")
  else
    WinMaximize("A")
}

; Switch active app's windows by Alt-`
!`::
{
  ; 1. Get current window info first
  try {
    OldClass := WinGetClass("A")
    ActiveProcessName := WinGetProcessName("A")
  } catch {
    return ; Exit if no active window found
  }

  ; 2. Get list of all windows belonging to this process
  ids := WinGetList("ahk_exe " ActiveProcessName)
  
  ; If only one window exists, nothing to switch to
  if (ids.Length <= 1)
    return

  ; 3. Perform the rotation
  Loop 2 {
    WinMoveBottom("A")
    try WinActivate("ahk_exe " ActiveProcessName)
    
    NewClass := WinGetClass("A")
    ; Logic for File Explorer (CabinetWClass) handling
    if (OldClass != "CabinetWClass" or NewClass == "CabinetWClass")
      break
  }
}

; switch between last two windows by Alt-q
!q:: SwitchToLast()

SwitchToLast() {
  ids := WinGetList(,, "Program Manager") ; Exclude desktop
  for this_ID in ids {
    if WinActive("ahk_id " . this_ID)
      continue
    title := WinGetTitle("ahk_id " . this_ID)
    if (title = "")
      continue
    if IsWindow(this_ID) {
      try WinActivate("ahk_id " . this_ID)
      break
    }
  }
}

IsWindow(hWnd) {
  dwStyle := WinGetStyle("ahk_id " . hWnd)
  if ((dwStyle & 0x08000000) || !(dwStyle & 0x10000000))
    return false
  dwExStyle := WinGetExStyle("ahk_id " . hWnd)
  if (dwExStyle & 0x00000080)
    return false
  if (WinGetClass("ahk_id " . hWnd) = "TApplication")
    return false
  return true
}

;
; App activations

#f:: try WinActivate("ahk_exe firefox.exe")
#s:: try WinActivate("ahk_exe mintty.exe")
#z:: try WinActivate("ahk_exe sioyek.exe")
^`:: try WinActivate("ahk_exe FAR.exe")
#w:: {
  try WinActivate("ahk_exe RDCMan.exe")
  try ControlFocus(ControlGetHwnd("IHWindowClass1"))
}

; Include local, host-specific, mappings
if FileExist("%A_ScriptDir%\\keys\\%A_ComputerName%.ahk") {
  #Include "%A_ScriptDir%\\keys\\%A_ComputerName%.ahk"
}

; Show host name and copy it to the clipboard
#+n:: {
  MsgBox A_ComputerName . " - copied"
  A_Clipboard := A_ComputerName
}

; Attic
;#s::Run, ms-settings:apps-volume
;#s::Run, C:\Windows\System32\rundll32.exe C:\Windows\System32\shell32.dll`,Control_RunDLL C:\Windows\System32\mmsys.cpl

; vim:ft=autohotkey:ts=2:sw=2:sts=2:et
