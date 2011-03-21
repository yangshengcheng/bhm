On Error Resume Next
rem author: yangshengcheng@gzcss.net
rem 2011/03/08
Dim  strKeyPath
set oArgs=wscript.arguments
  
If oArgs.Count <> 1 Then 
  wscript.echo "error arguments" 
else
  strKeyPath = oArgs.item(0)
rem wscript.echo strKeyPath
End If

oo = "SQLEXPRESS"

Dim OperationRegistry 
Set OperationRegistry=WScript.CreateObject("WScript.Shell") 
Dim data1
rem Dim regstr: regstr = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\" & oo & "\Setup\SQLPath"
Dim regstr: regstr = strKeyPath
data1=OperationRegistry.RegRead(regstr) 

wscript.echo  data1 & "\log\ERRORLOG"