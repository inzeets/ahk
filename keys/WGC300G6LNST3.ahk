; Laptop workarounds
$*Ins::Send("{Blind}{Home}")

; Win key app select
^+Esc:: {
  if WinExist("ahk_exe SystemInformer.exe ahk_class MainWindowClassName") {
    WinShow()
    WinActivate()
  }
}
#t:: try WinActivate("ahk_exe ms-teams.exe ahk_class TeamsWebView")
#e:: try WinActivate("ahk_exe msedge.exe")
#d:: {
  SetTitleMatchMode(2)
  try WinActivate("AKLEYMEN@ford ahk_exe OUTLOOK.exe")
}
#a:: try WinActivate("ahk_exe Picasa3.exe")
#n:: try WinActivate("ahk_exe ONENOTE.EXE")
#r:: try WinActivate("ahk_exe vncviewer.exe")
#i:: try WinActivate("ahk_exe Picasa3.exe")
#c:: try WinActivate("Calculator ahk_class ApplicationFrameWindow ahk_exe ApplicationFrameHost.exe")

; vim:ft=autohotkey:ts=2:sw=2:sts=2:et
