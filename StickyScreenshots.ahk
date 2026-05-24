; StickyScreenshots.ahk — AutoHotkey v2
#Requires AutoHotkey v2.0
Persistent

TraySetIcon(A_ScriptDir "\StickyScreenshots.ico")

global guis    := []
global guiMeta := []
global visible := true
global images  := []

SaveFile    := A_AppData "\StickyScreenshots\images.txt"
PosFile     := A_AppData "\StickyScreenshots\positions.ini"
OpacityFile := A_AppData "\StickyScreenshots\opacity.ini"
DirCreate(A_AppData "\StickyScreenshots")

if FileExist(SaveFile) {
    loop read SaveFile {
        if (Trim(A_LoopReadLine) != "")
            images.Push(Trim(A_LoopReadLine))
    }
}

if (images.Length > 0)
    SpawnStickies()
else
    BrowsePath()

#HotIf StickyUnderCursor()
^o::     BrowsePath()
^Up::    ZoomSticky(1.1)
^Down::  ZoomSticky(0.909)
^Left::  AdjustOpacity(-20)
^Right:: AdjustOpacity(20)
#HotIf

#j:: Reload()

#h:: {
    global visible
    visible := !visible
    for g in guis
        visible ? g.Show("NoActivate") : g.Hide()
}

; ── DPI API ──────────────────────────────────────────────────────────────────
; All internal state is physical pixels (Win32).
; AHK controls (pic.Move, g.Show) need logical pixels — use PhysToLog().
; Win32 calls (SetWindowPos, GetWindowRect, GetClientRect) use physical.

PhysToLog(px) => Round(px * 96 / A_ScreenDPI)
LogToPhys(lx) => Round(lx * A_ScreenDPI / 96)

WinRectPhys(hwnd, &x, &y, &w, &h) {
    rc := Buffer(16)
    DllCall("GetWindowRect", "Ptr", hwnd, "Ptr", rc)
    x := NumGet(rc,  0, "Int"), y := NumGet(rc,  4, "Int")
    w := NumGet(rc,  8, "Int") - x, h := NumGet(rc, 12, "Int") - y
}

ClientRectPhys(hwnd, &w, &h) {
    rc := Buffer(16)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rc)
    w := NumGet(rc, 8, "Int"), h := NumGet(rc, 12, "Int")
}

CursorPhys(&x, &y) {
    pt := Buffer(8)
    DllCall("GetCursorPos", "Ptr", pt)
    x := NumGet(pt, 0, "Int"), y := NumGet(pt, 4, "Int")
}

MoveWinPhys(hwnd, x, y, w, h) {
    DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0,
        "Int", x, "Int", y, "Int", w, "Int", h, "UInt", 0x0014)
}

SetWinLayered(hwnd, opacity) {
    DllCall("SetLayeredWindowAttributes", "Ptr", hwnd,
        "UInt", 0xFF00FF, "UChar", opacity, "UInt", 0x3)
}


; ── Persistence ──────────────────────────────────────────────────────────────

IniKey(imgPath) => StrReplace(imgPath, "\", "/")

LoadPos(imgPath) {
    global PosFile
    k := IniKey(imgPath)
    x := IniRead(PosFile, k, "x", "")
    if (x = "")
        return 0
    return { x: Integer(x),
             y: Integer(IniRead(PosFile, k, "y", 0)),
             w: Integer(IniRead(PosFile, k, "w", 0)),
             h: Integer(IniRead(PosFile, k, "h", 0)) }
}

SavePos(imgPath, x, y, w, h) {
    global PosFile
    k := IniKey(imgPath)
    IniWrite(x, PosFile, k, "x")
    IniWrite(y, PosFile, k, "y")
    IniWrite(w, PosFile, k, "w")
    IniWrite(h, PosFile, k, "h")
}

LoadOpacity(imgPath) {
    global OpacityFile
    return Integer(IniRead(OpacityFile, IniKey(imgPath), "opacity", 255))
}

SaveOpacity(imgPath, opacity) {
    global OpacityFile
    IniWrite(opacity, OpacityFile, IniKey(imgPath), "opacity")
}

DeleteSavedState(imgPath) {
    global PosFile, OpacityFile
    k := IniKey(imgPath)
    try IniDelete(PosFile, k)
    try IniDelete(OpacityFile, k)
}

; ── Sticky Windows ───────────────────────────────────────────────────────────

SpawnStickies() {
    global guis, guiMeta, images

    for i, imgPath in images {
        ; Measure natural image size in logical px via probe GUI
        probe := Gui()
        pic   := probe.AddPicture("x0 y0", imgPath)
        pic.GetPos(,, &iw, &ih)   ; logical px
        probe.Destroy()

        pos     := LoadPos(imgPath)   ; physical px or 0
        opacity := LoadOpacity(imgPath)

        g := Gui("+AlwaysOnTop -Caption +ToolWindow +Resize", "Sticky_" i)
        g.MarginX := 0, g.MarginY := 0
        g.BackColor := "FF00FF"
        p := g.AddPicture("x0 y0 w" iw " h" ih " +0x40", imgPath)
        g.Show("w" iw " h" ih " NoActivate")   ; logical px — AHK call

        ; Apply layered attributes: color key (magenta) + opacity
        WinSetExStyle("+0x80000", g.Hwnd)
        SetWinLayered(g.Hwnd, opacity)

        meta := { path: imgPath, g: g, hwnd: g.Hwnd, pic: p, opacity: opacity }
        g.OnEvent("Size", MakeSizeHandler(meta))

        if (pos)
            MoveWinPhys(g.Hwnd, pos.x, pos.y, pos.w, pos.h)  ; physical px — Win32 call

        FillPic(meta)   ; sync pic control to actual window client area

        guiMeta.Push(meta)
        guis.Push(g)
    }
}

; Fill pic control to cover client area exactly.
; Reads physical client size, converts to logical for pic.Move.
FillPic(meta) {
    ClientRectPhys(meta.hwnd, &cw, &ch)
    meta.pic.Move(0, 0, PhysToLog(cw), PhysToLog(ch))
    SetTimer(() => (meta.pic.Value := meta.path), -150)
}

; Called by Size event (w,h are logical from AHK) and by ZoomSticky.
; Either way, FillPic reads the real client rect so it's always accurate.
MakeSizeHandler(meta) {
    return (gObj, minMax, w, h) => (
        FillPic(meta),
        SetTimer(() => SaveWinPos(meta), -200)
    )
}

SaveWinPos(meta) {
    try {
        WinRectPhys(meta.hwnd, &x, &y, &w, &h)   ; physical px
        SavePos(meta.path, x, y, w, h)
    }
}

BrowsePath(*) {
    global images, guis, guiMeta
    selected := FileSelect("M3",, "Select images", "Images (*.png; *.jpg; *.jpeg; *.bmp; *.gif)")
    if (selected.Length = 0)
        return
    for p in selected
        images.Push(p)
    SaveList()
    for meta in guiMeta
        meta.g.Destroy()
    guis := [], guiMeta := []
    SpawnStickies()
}

SaveList() {
    global SaveFile, images
    txt := ""
    for p in images
        txt .= p "`n"
    try FileDelete(SaveFile)
    FileAppend(txt, SaveFile)
}

CloseSticky(meta) {
    global guiMeta, guis, images
    savedHwnd := meta.hwnd
    savedPath := meta.path
    try meta.g.Destroy()
    for idx, m in guiMeta {
        if (m.hwnd = savedHwnd) {
            images.RemoveAt(idx)
            guiMeta.RemoveAt(idx)
            guis.RemoveAt(idx)
            break
        }
    }
    DeleteSavedState(savedPath)
    SaveList()
}

; ── Zoom & Opacity ───────────────────────────────────────────────────────────

ZoomSticky(factor) {
    meta := StickyUnderCursor()
    if (meta = 0)
        return
    WinRectPhys(meta.hwnd, &wx, &wy, &ww, &wh)
    nw := Max(50, Round(ww * factor))
    nh := Max(50, Round(wh * factor))
    MoveWinPhys(meta.hwnd, wx, wy, nw, nh)   ; physical px — triggers Size event
}

AdjustOpacity(delta) {
    meta := StickyUnderCursor()
    if (meta = 0)
        return
    meta.opacity := Max(20, Min(255, meta.opacity + delta))
    SetWinLayered(meta.hwnd, meta.opacity)
    SaveOpacity(meta.path, meta.opacity)
}

; ── Cursor hit-test ──────────────────────────────────────────────────────────

StickyUnderCursor() {
    global guiMeta
    CursorPhys(&cx, &cy)
    pt64 := cx | (cy << 32)
    hwnd := DllCall("WindowFromPoint", "Int64", pt64, "Ptr")
    loop 5 {
        parent := DllCall("GetParent", "Ptr", hwnd, "Ptr")
        if (parent = 0)
            break
        hwnd := parent
    }
    for meta in guiMeta {
        if (hwnd = meta.hwnd)
            return meta
    }
    return 0
}

; ── Message handlers ─────────────────────────────────────────────────────────

OnMessage(0x201, DragHandler)
OnMessage(0x203, DblClickHandler)
OnMessage(0x232, MoveSizeEndHandler)

DragHandler(wParam, lParam, msg, hwnd) {
    global guiMeta
    parent := DllCall("GetParent", "Ptr", hwnd, "Ptr")
    for meta in guiMeta {
        if (hwnd = meta.hwnd || parent = meta.hwnd) {
            PostMessage(0xA1, 2,, meta.hwnd)
            return
        }
    }
}

DblClickHandler(wParam, lParam, msg, hwnd) {
    global guiMeta
    parent := DllCall("GetParent", "Ptr", hwnd, "Ptr")
    for meta in guiMeta {
        if (hwnd = meta.hwnd || parent = meta.hwnd) {
            CloseSticky(meta)
            return
        }
    }
}

MoveSizeEndHandler(wParam, lParam, msg, hwnd) {
    global guiMeta
    for meta in guiMeta {
        if (hwnd = meta.hwnd) {
            SaveWinPos(meta)
            return
        }
    }
}
