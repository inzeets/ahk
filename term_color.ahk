#Requires AutoHotkey v2.0

#+E::Reload

DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")
dpiValue := A_ScreenDPI
scalingFactor := dpiValue / 96
;CoordMode "Pixel", "Screen"
;CoordMode "Mouse", "Screen"

; ; Create the GUI
; myGui := Gui("+AlwaysOnTop -Caption +ToolWindow +Owner")
; myGui.BackColor := "EEAA99" ; Color to be made transparent
; WinSetTransColor("EEAA99", myGui) ; Make background transparent
; 
; ; Add the icon (replace with your path)
; myGui.Add("Picture", "w32 h32", "C:\\FNV\\zsl\\dots-main\\ws\\AutoHotkey\\z_mouse.png")
; 
; ; Show the GUI initially
; myGui.Show("x0 y0 NoActivate")

myGui := Gui("+AlwaysOnTop -Caption +ToolWindow")
; Set background color to green
;myGui.BackColor := "Olive"
myGui.BackColor := "Yellow"
;myGui.BackColor := "3179ED"
;myGui.BackColor := "White"

; Optional: Hotkey to move it to active window
;^!i:: {
;    if WinExist("A") {
;        WinGetPos(&X, &Y, &W, &H, "A")
;        myGui.Show("x" (X + W - 50) " y" (Y + 20) " NoActivate") ; Top Right
;    }
;}

#Requires AutoHotkey v2
Persistent

framing := ActiveWindowFraming(4, 0xFFAA00)

class ActiveWindowFraming
{
    excludeWinClasses := [
        '#32768',
        'Progman',
        'WorkerW',
        'Shell_TrayWnd',
        'tooltips_class32',
        'TaskListThumbnailWnd'
    ]

    EVENT_OBJECT_SHOW           := 0x8002
    EVENT_OBJECT_HIDE           := 0x8003
    EVENT_OBJECT_FOCUS          := 0x8005
    EVENT_OBJECT_LOCATIONCHANGE := 0x800B

    __New(thickness := 5, color := 'red') {
        this.old := 0
        this.excludePattern := CreatePattern()
        t := thickness
        if !this.hwnd := this.GetActiveWindow() {
            this.frame := ColoredFrame(0, 0, 0, 0, t, color, false)
        } else {
            ActiveWindowFraming.GetWindowPos(&x, &y, &w, &h, this.hwnd)
            this.frame := ColoredFrame(x + t, y + t, w - t * 2, h - t * 2, t, color)
        }
        this.hook := WinEventHook(this.EVENT_OBJECT_SHOW,
                                  this.EVENT_OBJECT_LOCATIONCHANGE,
                                  ObjBindMethod(this, 'HookProc'), 'F')
        this.timer := ObjBindMethod(this, 'SetPos')
        ptr := ObjPtr(this), ObjRelease(ptr), ObjRelease(ptr)

        CreatePattern() {
            for winClass in this.excludeWinClasses {
                pattern .= (A_Index = 1 ? '' : '|') . winClass
            }
            return '^(' . pattern .= ')$'
        }
    }

    GetActiveWindow() {
        try hwnd := WinActive('ahk_exe WINWORD.EXE')
        catch {
            return 0
        }
        if IsSet(hwnd) && hwnd && WinGetClass(hwnd) ~= this.excludePattern {
            return 0
        }
        return hwnd ?? 0
    }

    HookProc(hWinEventHook, event, hwnd, idObject, idChild, dwEventThread, dwmsEventTime) {
        static OBJID_CLIENT := 0xFFFFFFFC, OBJID_WINDOW := 0, counter := 0
        if !(idObject = OBJID_CLIENT || idObject = OBJID_WINDOW) || hwnd = this.frame.hwnd {
            return
        }
        switch event {
            case this.EVENT_OBJECT_SHOW:
                    this.SetPos()
            case this.EVENT_OBJECT_FOCUS:
                        this.SetPos()
             case this.EVENT_OBJECT_LOCATIONCHANGE:
                    this.SetPos()
            case this.EVENT_OBJECT_HIDE: (idObject = OBJID_WINDOW && hwnd = this.hwnd && this.frame.Hide())
        }
    }

    SetPos() {
        ;ActiveWindowFraming.GetWindowPos(&x, &y, &w, &h, this.hwnd)
        ;this.frame.visible := true
        ;t := this.frame.thickness
        ; try this.frame.SetPos(x + t, y + t, w - t * 2, h - t * 2)
		; myGui.Show("x" (x + w - 50) " y" (y + 20) " NoActivate")
        ;MsgBox(11)
        this.hwnd := WinExist("A")
        if (this.hwnd && this.hwnd != this.old) {
            this.old := this.hwnd
            activeProcess := WinGetProcessName("A")
            color := 0
            if (activeProcess == "mintty.exe") {
                color := "White"
                title := WinGetTitle("A")
                if (InStr(title, "term") == 1) {
                    color := "4AFF00"
                } else if (InStr(title, "wsl") == 1) {
                    color := "FFB700"
                    if (InStr(title, "wsl-") == 1) {
                        color := "00BFFF"
                    }
                }
            } else if (activeProcess == "firefox.exe") {
                color := "Yellow"
            }
            if (color) {
                myGui.BackColor := color
                WinGetClientPos(&X, &Y, &W, &H, "A")
                ;MsgBox("x: " X " y: " Y)
                ;myGui.Show("x" (X + W/2-7) " y" (Y + 0) " w14 h1 NoActivate")
                ;myGui.Show("x" (X+16) " y" (Y + 0) " w200 h1 NoActivate")
                ;myGui.Show("x" (X + 35) " y" (Y + 0) " w" (W-35) " h15 NoActivate")
                ;myGui.Show("x" (X + 0) " y" (Y + 0) " w1350 h1 NoActivate")
                ;myGui.Show("x" (X + 0) " y" (Y + 0) " w1 h" H " NoActivate")
                ;myGui.Show("x" (W - 1) " y" (Y + 0) " w1 h" H " NoActivate")
                ;WinSetAlwaysOnTop 1, myGui
                ;myGui.Show("x" (X + 0) " y" (Y + H - 30) " w10 h80 NoActivate")
                ;myGui.Show("x" (X + 0) " y" (Y + H - 2) " w" (W/scalingFactor) " h3 NoActivate")
                myGui.Show("x" (X + 0) " y" (Y + 0) " w" (1) " h32 NoActivate")
                ;WinSetTransparent(100, myGui)
                ;WinSetTransparent(180, myGui)
                ;WinSetAlwaysOnTop 0
                ;WinSet, AlwaysOnTop,  A
            } else {                
                myGui.Hide()
            }
        }
    }

    static GetWindowPos(&x, &y, &w, &h, hwnd) {
        static attr := DWMWA_EXTENDED_FRAME_BOUNDS := 9, RECT := Buffer(16)
        try WinGetPos(&x, &y, &w, &h, hwnd)
        hr := DllCall('Dwmapi\DwmGetWindowAttribute', 'Ptr', hwnd, 'UInt', attr, 'Ptr', RECT, 'UInt', 16)
        if (hr = 0) {
            dX := NumGet(RECT, 0, 'Int') - x
            dY := NumGet(RECT, 4, 'Int') - y
            dW := x + w - NumGet(RECT, 8, 'Int') + dX
            dH := y + h - NumGet(RECT, 12, 'Int') + dY
            x += dX, y += dY, w -= dW, h -= dH
        }
    }

    __Delete() => (this.hook := '', ptr := ObjPtr(this), ObjAddRef(ptr), ObjAddRef(ptr))
}

class WinEventHook
{
    ; Event Constants: https://is.gd/tRT5Wr
    __New(eventMin, eventMax, hookProc, options := '', idProcess := 0, idThread := 0, dwFlags := 0) {
        this.pCallback := CallbackCreate(hookProc, options, 7)
        this.hHook := DllCall('SetWinEventHook', 'UInt', eventMin, 'UInt', eventMax, 'Ptr', 0, 'Ptr', this.pCallback
                                               , 'UInt', idProcess, 'UInt', idThread, 'UInt', dwFlags, 'Ptr')
    }
    __Delete() {
        DllCall('UnhookWinEvent', 'Ptr', this.hHook)
        CallbackFree(this.pCallback)
    }
}

class ColoredFrame
{
    __New(x, y, w, h, thickness, color, show := true, hParent := 0) {
        static style := WS_EX_TRANSPARENT := 0x20
        wnd := Gui((hParent ? 'Parent' . hParent : '') . ' Owner AlwaysOnTop -Caption -DPIScale E' . style)
        this.DefineProp('wnd', {value: wnd})
        WinSetTransparent(255, this.wnd)

        for item in ['x', 'y', 'w', 'h', 'thickness'] {
            this.DefineProp('_' . item, {value: %item%})
        }
        this.color := color
        this.DefineProp('visible', {value: show})
        this.DefineProp('hwnd', {value: this.wnd.hwnd})
        this.SetPos()
    }

    __Set(name, params, value) {
        this.%'_' . name% := value
        if name ~= 'i)^(x|y|w|h|thickness)$' {
            this.SetPos()
        }
    }

    __Get(name, *) => this.%'_' . name%

    color {
        get => this.wnd.BackColor
        set => this.wnd.BackColor := value
    }

    SetPos(x?, y?, w?, h?) {
        for coord in ['x', 'y', 'w', 'h'] {
            IsSet(%coord%) ? this.%'_' . coord% := %coord% : %coord% := this.%'_' . coord%
        }
        t := this._thickness, w += t*2, h += t*2
        dx := w - t, dy := h - t, x -= t, y -= t
        WinSetRegion('0-0 ' . w '-0 ' . w '-' h . ' 0-' h . ' 0-0 '
                    . t '-' t . ' ' . dx '-' t . ' ' . dx '-' dy . ' ' . t '-' dy . ' ' . t '-' t, this.wnd)
        this.wnd.Show((this.visible ? 'NA' : 'Hide') . ' x' . x . ' y' . y . ' w' . w . ' h' . h)
    }

    Show() => (!this.visible && (this.visible := true, this.wnd.Show('NA')))
    Hide() => (this.visible && (this.visible := false, this.wnd.Hide()))

    __Delete() => this.wnd.Destroy()
}
