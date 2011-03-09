rem On Error Resume Next
rem Option Explicit

' --------------------------------------------------------------------------
' This script read sql strings from a file, and query the result from  mssql  ,then  write the result to a file
' execute in the servers  which  run a mssql service
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_db_mssql_makesql.vbs bhm_mssql_makesql_datafiles.sql  bhm_mssql_perf_datafiles.sql
'
' author:yangshengcheng@gzcss.net
' timestamp : 2010/12/20
' --------------------------------------------------------------------------

rem usage 
Sub Usage ()
  Wscript.Echo "Usage: cscript bhm_db_mssql_makesql.vbs <sql_file> " & " <dest_sql_file>"
  WScript.Quit(1)  
End Sub

rem analyse the argument
Dim  filename
Dim  sqlfile
Dim oArgs
set oArgs=wscript.arguments
  
If oArgs.Count <> 2 Then 
  Usage () 
else
  filename = oArgs.item(0)
  sqlfile = oArgs.item(1)
rem   wscript.echo filename
End If

rem  read sql strings from file
rem  Dim arrFileLines()
rem  i = 0
Dim objFSO
Dim  objFile
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFile = objFSO.OpenTextFile(filename, 1)

strcontent = objFile.ReadAll
rem open file  error

'Do Until objFile.AtEndOfStream
'Redim Preserve arrFileLines(i)
'arrFileLines(i) = objFile.ReadLine
'i = i + 1
'Loop
objFile.Close

'If Ubound(arrFileLines) < 0 Then 
'	WScript.echo  "empty file"
'	WScript.Quit(1)
'End if
'For l =  LBound(arrFileLines)  to Ubound(arrFileLines) Step 1
'	Wscript.Echo arrFileLines(l)
'Next


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

rem log result to  file 
	Dim mssql_perf_filepath
	Dim line
	Dim timestamp:timestamp=Year(Now())&Month(Now())&Day(Now())&Hour(Now())&Minute(Now())&Second(Now())
	Set oShell = WScript.CreateObject( "WScript.Shell" )
	OvDataDirStr = oSHell.Environment.Item( "OvDataDir" )

	Call checkFolder(OvDataDirStr)
	mssql_perf_filepath = OvDataDirStr & "\bin\instrumentation\" & sqlfile

	Set mssql_objFSO = CreateObject("Scripting.FileSystemObject")
	
	Set mssql_file_obj = mssql_objFSO.OpenTextFile(mssql_perf_filepath,2,true)


rem loop  all sql  strings in the arrFileLines
rem For l =  LBound(arrFileLines)  to Ubound(arrFileLines) Step 1
	Dim rez: rez = CreateObject("ADODB.Recordset")
	Set rez = cnt.execute(strcontent)

	rem  wscript.echo "execute finish !"
	rem wscript.echo "total line:" & rez.RecordCount 


	On Error Resume Next
	Dim  i :i=0
	rez.MoveFirst
	Do While Not rez.eof
	If i > 100 Then 
		Exit Do
	End if
	WScript.Echo rez("sql")
	rem WScript.Echo rez("timestamp") & "|" & rez("class") & "|" & rez("metric")& "|" & rez("instance")& "|" &  rez("value")& "|" & rez("ostype")
	rem line = rez("timestamp") & "|" & rez("class") & "|" & rez("metric")& "|" & rez("instance")& "|" &  rez("value")& "|" & rez("ostype")
	line = rez("sql")
	mssql_file_obj.WriteLine(line)
	i = i + 1
	  rez.MoveNext
	Loop
	rez = Nothing
rem  Next 

rem close the log file
mssql_file_obj.close


If cnt.State = adStateOpen then
	cnt.Close
End If


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


rem check if the dir exists
Function checkFolder(parentFolder)
	Dim objFSO,BhmDir,f
	BhmDir = parentFolder & "\bhm\dsi"
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	If not objFSO.FolderExists(BhmDir) Then
		Set f = objFSO.CreateFolder(BhmDir)
    checkFolder = f.Path
	End If
End Function