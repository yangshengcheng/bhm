On Error  Resume Next 

rem ------------------------------------------
rem On Error Resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This script read sql strings from a file, and query the result from  mssql  ,then  write the result to a file
' execute in the servers  which  run a mssql service
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_db_mssql_query.vbs bhm_mssql_config.sql
'
' author:yangshengcheng@gzcss.net
' timestamp : 2010/12/20
' --------------------------------------------------------------------------

rem usage 
Sub Usage ()
  Wscript.Echo "Usage: cscript bhm_mssql_findlog.vbs" 
  WScript.Quit(1)  
End Sub

rem check installed odbc drivers,if SQL Native Client had  been installed ,then use provider=SQLNCLI,else  provider=SQLOLEDB
Dim flag :flag = 0
Dim a

Const HKEY_LOCAL_MACHINE = &H80000002
 
strComputer = "."
 
Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")
 
strKeyPath = "SOFTWARE\ODBC\ODBCINST.INI\ODBC Drivers"
objRegistry.EnumValues HKEY_LOCAL_MACHINE, strKeyPath, arrValueNames, arrValueTypes
 
For i = 0 to UBound(arrValueNames)
    strValueName = arrValueNames(i)
    objRegistry.GetStringValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,strValue    
rem  Wscript.Echo arrValueNames(i) & " -- " & strValue
	a = InStr(arrValueNames(i),"SQL Native Client")
	If a > 0 Then 
rem		Wscript.Echo arrValueNames(i)
		flag = 1
		Exit  for
	End If 
Next

rem judge the provider
Dim DB_provider
If flag=0 Then 
	DB_provider ="SQLOLEDB"
Else
	DB_provider="SQLNCLI"
End if 

rem connect mssql with  os certificate
Dim cnt
Set cnt = CreateObject("ADODB.Connection")
rem 假如遇到 “ADODB.Connection: 未找到提供程序。该程序可能未正确安装” 的错误  ，请将下列连接串的Provider=SQLNCLI;改为Provider=SQLOLEDB;
cnt.ConnectionString= "Provider="&DB_provider&";" & "data source=127.0.0.1;database=master;Integrated Security=SSPI;"
cnt.Open

rem check mssql connect 
Dim errText
If cnt.Errors.count > 0 Then
	For Each adoErr In cnt.Errors
		errText = adoErr.SQLState&" "&adoErr.description
rem 	wscript.echo adoErr.SQLState&"	"&adoErr.description
		Call sendmsg("warning",errText,"ADODB")
	Next
End If

rem 	wscript.echo "connect good !"
rem loop  all sql  strings in the arrFileLines
	arrFileLines = "select @@servicename as  instance"
	Dim rez: rez = CreateObject("ADODB.Recordset")
	Set rez = cnt.execute(arrFileLines)

	rem  wscript.echo "execute finish !"
	rem wscript.echo "total line:" & rez.RecordCount 


	On Error Resume Next
	Dim i :i=0
	Dim oo
	rez.MoveFirst
	Do While Not rez.eof
		If i >=1  Then 
			Exit Do
		End if
	rem	 WScript.Echo rez("timestamp") & "|" & rez("class") & "|" & rez("metric")& "|" & rez("instance")& "|" &  rez("value")& "|" & rez("ostype")
		oo = rez("instance")
		i = i + 1
		 rez.MoveNext
	Loop
	rez = Nothing

If cnt.State = adStateOpen then
	cnt.Close
End If

Dim OperationRegistry 
Set OperationRegistry=WScript.CreateObject("WScript.Shell") 
Dim data1
Dim regstr: regstr = "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft SQL Server\" & oo & "\Setup\SQLPath"
data1=OperationRegistry.RegRead(regstr) 


wscript.echo Chr(34) & data1 & "\log\ERRORLOG" & Chr(34)

rem  ovo  message object
Function sendmsg(sev,msg,obj)
	msg_text = msg
	msg_app = "bhm_db_mssql_monitor.vbs"
	msg_grp = "BHM:MSSQL"
	msg_obj = obj
	msg_severity = sev
	
	Dim msgObj
	Set msgObj = CreateObject("OVOAutomation.Opcmsg")
	
	msgObj.MessageText = msg_text
	msgObj.Application = msg_app
			
	msgObj.MessageGroup = msg_grp
	msgObj.Object = msg_obj
	Rem msgObj.Nodename = "HOSTNAME"
	msgObj.Severity = msg_severity
	Rem  msgObj.ServiceName = "My Service"
			
	msgObj.Send()
End Function

