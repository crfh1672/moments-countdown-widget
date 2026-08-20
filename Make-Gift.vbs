' הפעלה בלחיצה כפולה - פותח את יוצר המתנה ללא חלון מסוף
q = Chr(34)
Set sh = CreateObject("WScript.Shell")
me_ = WScript.ScriptFullName
dir = Left(me_, InStrRev(me_, "\"))
sh.CurrentDirectory = dir
cmd = "powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File " & q & dir & "Make-Gift.ps1" & q
sh.Run cmd, 0, False
