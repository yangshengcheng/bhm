'On  Error Resume Next 
'Option Explicit

' --------------------------------------------------------------------------
' This script query iis performent counters from  wmi 
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_iis_metric.vbs
'
' author:yangshengcheng@gzcss.net
' timestamp : 2011/01/14
' --------------------------------------------------------------------------

rem usage 
Sub Usage ()
  Wscript.Echo "Usage: cscript bhm_iis_metric.vbs" 
  WScript.Quit(1)  
End Sub

Dim temp 
Dim m
temp = Month(Now())
If Len(temp)=1 Then 
	m = "0" & temp 
Else
	m = temp
End If 

Dim d
temp = Day(Now())
If Len(temp)=1 Then 
	d = "0" & temp 
Else
	d= temp
End If

Dim h
temp = Hour(Now())
If Len(temp)=1 Then 
	h = "0" & temp 
Else
	h = temp	
End If

Dim  min
temp = Minute(Now())
If Len(temp)=1 Then 
	min = "0" & temp 
	Else
	min = temp
End If

Dim sec
temp = Second(Now())
If Len(temp)=1 Then 
	sec = "0" & temp 
	Else
	sec = temp
End If

Dim timestamp:timestamp=Year(Now())& m & d & h & min & sec

Dim oShell
Set oShell = WScript.CreateObject( "WScript.Shell" )
OvDataDirStr = oSHell.Environment.Item( "OvDataDir" )

Call checkFolder(OvDataDirStr)
Dim iis_perf_temp:iis_perf_temp=OvDataDirStr & "\bhm\temp\iis_perf.csv"

strComputer = "."
 '''' Connect to server
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
   
Set colItems = objWMIService.ExecQuery("Select * from Win32_PerfRawData_W3SVC_WebService",,48)

Dim  iis_objFSO
Dim iis_file_obj

Set iis_objFSO = CreateObject("Scripting.FileSystemObject")
	
Set iis_file_obj = iis_objFSO.OpenTextFile(iis_perf_temp,8,true)

For Each objItem in colItems

	
	MaximumConnections = timestamp & "|" & "IIS_GLOBAL"&"|" & "MaximumConnections" & "|"& "IISServer " & objItem.Name &"|" &  objItem.MaximumConnections &"|"&"MSWin32"
	PostRequestsPersec = timestamp & "|" & "IIS_GLOBAL"&"|" & "PostRequestsPersec" & "|"& "IISServer " & objItem.Name &"|" &  objItem.PostRequestsPersec &"|"&"MSWin32"
	BytesSentPersec = timestamp & "|" & "IIS_GLOBAL"&"|" & "BytesSentPersec" & "|"& "IISServer " & objItem.Name &"|" &  objItem.BytesSentPersec &"|"&"MSWin32"
	BytesReceivedPersec = timestamp & "|" & "IIS_GLOBAL"&"|" & "BytesReceivedPersec" & "|"& "IISServer " & objItem.Name &"|" &  objItem.BytesReceivedPersec &"|"&"MSWin32"
	GetRequestsPersec = timestamp & "|" & "IIS_GLOBAL"&"|" &"GetRequestsPersec" & "|"& "IISServer " & objItem.Name &"|" &  objItem.GetRequestsPersec &"|"&"MSWin32"
	CurrentAnonymousUsers = timestamp & "|" & "IIS_GLOBAL"&"|" & "CurrentAnonymousUsers" & "|"& "IISServer " & objItem.Name &"|" &  objItem.CurrentAnonymousUsers &"|"&"MSWin32"
	TotalNotFoundErrors = timestamp & "|" & "IIS_GLOBAL"&"|" & "TotalNotFoundErrors" & "|"& "IISServer " & objItem.Name &"|" &  objItem.TotalNotFoundErrors &"|"&"MSWin32"
	CurrentConnections = timestamp & "|" & "IIS_GLOBAL"&"|" & "CurrentConnections" & "|"& "IISServer " & objItem.Name &"|" &  objItem.CurrentConnections &"|"&"MSWin32"
	BytesTotalPersec = timestamp & "|" & "IIS_GLOBAL"&"|" & "BytesTotalPersec" & "|"& "IISServer " & objItem.Name &"|" &  objItem.BytesTotalPersec &"|"&"MSWin32"
'	Wscript.Echo MaximumConnections
'	Wscript.Echo PostRequestsPersec
'	Wscript.Echo BytesSentPersec
'	Wscript.Echo BytesReceivedPersec
'	Wscript.Echo GetRequestsPersec
'	Wscript.Echo CurrentAnonymousUsers
'	Wscript.Echo TotalNotFoundErrors
'	Wscript.Echo CurrentConnections
'	Wscript.Echo BytesTotalPersec
rem log  in the perf temp  file
	iis_file_obj.WriteLine(MaximumConnections)
	iis_file_obj.WriteLine(PostRequestsPersec)
	iis_file_obj.WriteLine(BytesSentPersec)
	iis_file_obj.WriteLine(BytesReceivedPersec)
	iis_file_obj.WriteLine(GetRequestsPersec)
	iis_file_obj.WriteLine(CurrentAnonymousUsers)
	iis_file_obj.WriteLine(TotalNotFoundErrors)
	iis_file_obj.WriteLine(CurrentConnections)
	iis_file_obj.WriteLine(BytesTotalPersec)
'		Wscript.Echo "-------------Name: " & objItem.Name & "------------------"
'        Wscript.Echo "MaximumConnections: " & objItem.MaximumConnections
'		Wscript.Echo "BytesReceivedPersec: " & objItem.BytesReceivedPersec
'		Wscript.Echo "BytesSentPersec: " & objItem.BytesSentPersec
'		Wscript.Echo "BytesTotalPersec: " & objItem.BytesTotalPersec
'		Wscript.Echo "GetRequestsPersec: " & objItem.GetRequestsPersec
'		Wscript.Echo "PostRequestsPersec: " & objItem.PostRequestsPersec
'		Wscript.Echo "CurrentAnonymousUsers: " & objItem.CurrentAnonymousUsers
'		Wscript.Echo "LogonAttemptsPersec: " & objItem.LogonAttemptsPersec
'		Wscript.Echo "CurrentConnections: " & objItem.CurrentConnections
''		Wscript.Echo "BytesSentPersec: " & objItem.BytesSentPersec
''		Wscript.Echo "BytesSentPersec: " & objItem.BytesSentPersec

Next

iis_file_obj.close
rem copy temp file to  dsi directory
Dim filename:filename="iis_"& h & min&".csv"
Dim  dest :dest = OvDataDirStr & "\bhm\dsi\"&filename
Dim objFSO
Set objFSO = CreateObject("Scripting.FileSystemObject")

objFSO.MoveFile iis_perf_temp,dest

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