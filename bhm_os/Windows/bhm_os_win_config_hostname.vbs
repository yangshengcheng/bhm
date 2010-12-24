'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' FILENAME:     bhm_os_win_config_hostname.vbs
'' VERSION:      1.0
'' DESCRIPTION:  The script can be used to check  hostname and compare with  last time.
''               
'' USAGE:        cscript bhm_os_win_config_hostname.vbs
''               
'' LANGUAGE:     VBScript
''
'' author:		yangshengcheng@gzcss.net
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
 On Error Resume Next
 
Function checkFolder(parentFolder)
	Dim objFSO,BhmDir,f
	BhmDir = parentFolder & "\bhm"
	
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	If not objFSO.FolderExists(BhmDir) Then
		Set f = objFSO.CreateFolder(BhmDir)
    checkFolder = f.Path
	End If
End Function


Function  CompareHostname(last,current)
	Rem	wscript.echo "last:" & last & "   curr:" & current
	CompareHostname = StrComp(last,current,1)
End Function

Function  GetLast(curr)
	
		Set objFSO = CreateObject("Scripting.FileSystemObject")
	If objFSO.FileExists(FilePath) Then
	   Set objFile = objFSO.GetFile(FilePath)
	   If objFile.Size > 0 Then
Rem	   	wscript.echo "exits and large then 0"
	   	Set file = objFSO.OpenTextFile(FilePath,1)
	   	GetLast = file.Readline
	   	Rem wscript.echo  GetLast
	   	file.Close
	   Else
Rem	   	wscript.echo "less  then 0"
	   	
	   Set	file = objFSO.OpenTextFile(FilePath,2)
	   	file.WriteLine(curr)
	   	file.Close

	   End If
	   	
	Else
Rem			wscript.echo "file is not exist"
	   Set file = objFSO.CreateTextFile(FilePath,1)
	    file.WriteLine(curr)
	    file.Close

			Rem  first  Time monitor	
			wscript.echo "first time monitor"
			wscript.Quit 0
	End If
	
End Function

Function  getCurr()
	Rem query  hostname 
	Dim  strComputer
	strComputer = "."
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	
	Set system = objWMIService.ExecQuery("Select * from Win32_ComputerSystem",,48)
	
	For Each objitem in system
					getCurr = objitem.Name
	Rem     wscript.echo  "hostname: " & hostname        
	Next

End Function

Function saveCurr(curr)
		Set objFSO = CreateObject("Scripting.FileSystemObject")
	  Set	file = objFSO.OpenTextFile(FilePath,2)
	  file.WriteLine(curr)
	  file.Close
End Function

Rem main process start 
Dim  currHostname,lastHostname,rezult,FilePath

Set oShell = WScript.CreateObject( "WScript.Shell" )

OvDataDirStr = oSHell.Environment.Item( "OvDataDir" )


Rem  create bhm Dir
Call checkFolder(OvDataDirStr)


FilePath = OvDataDirStr & "\bhm\bhm_OsConfig_hostname.txt"  

currHostname = getCurr()
Rem  wscript.echo  currHostname 
lastHostname = GetLast(currHostname)

rezult = CompareHostname(lastHostname,currHostname)

If rezult <> 0 Then
	wscript.echo  "hostname change"
	
	msg_text = "hostname had been change ,last:" & lastHostname & " current:" &currHostname
	msg_app = "bhm_os_win_config_hostname.vbs"
	msg_grp = "BHM:WINOS:CONFIG"
	msg_obj = "hostname"
	msg_severity = "normal"
	
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
	
	Rem Then  Save the  current hostname 
	Call	saveCurr(currHostname)
	
End If

Rem End of main process