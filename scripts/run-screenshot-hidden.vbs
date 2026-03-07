' Runs the screenshot PowerShell script without showing a console window.
' Scheduled Task should run this via: wscript.exe //B //NoLogo <this.vbs>

Option Explicit

Dim shell, ps, cmd
Set shell = CreateObject("WScript.Shell")

ps = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
cmd = """" & ps & """" & " -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File " & _
      """E:\OpenClawAI_bot\workspace\scripts\desktop-screenshot.ps1""" & _
      " -OutPath """ & "E:\OpenClawAI_bot\workspace\media\desktop_screenshot.png""""

' 0 = hidden window, True = wait until finished
shell.Run cmd, 0, True
