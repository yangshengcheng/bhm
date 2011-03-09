Dim  strKeyPath
set oArgs=wscript.arguments
  
If oArgs.Count <> 1 Then 
  wscript.echo "error arguments" 
else
  strKeyPath = oArgs.item(0)
rem   wscript.echo filename
End If
  
const HKEY_LOCAL_MACHINE = &H80000002
strComputer = "."
Set StdOut = WScript.StdOut
Set oReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_ 
strComputer & "\root\default:StdRegProv")
rem strKeyPath = "SOFTWARE\Microsoft\Microsoft SQL Server"
oReg.EnumKey HKEY_LOCAL_MACHINE, strKeyPath, arrSubKeys
For Each subkey In arrSubKeys
    StdOut.WriteLine subkey
Next