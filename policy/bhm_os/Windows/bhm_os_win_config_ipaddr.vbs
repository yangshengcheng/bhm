'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' FILENAME:     bhm_os_win_config_ipaddr.vbs
'' VERSION:      1.0
'' DESCRIPTION:  The script can be used to check  ip address and compare with  last time.
''               
'' USAGE:        cscript bhm_os_win_config_ipaddr.vbs
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


Function  CompareIpAddr()
	Rem	wscript.echo "last:" & last & "   curr:" & current
	Dim flag
	flag = 1
	For i=LBound(currIpaddr) to UBound(currIpaddr)
		If currIpaddr(i) <> "" Then
			For j=LBound(lastIpaddr) to UBound(lastIpaddr)
				If lastIpaddr(j) <> "" Then
Rem					wscript.echo currIpaddr(i) & "###" &lastIpaddr(j)
					flag = StrComp(currIpaddr(i),lastIpaddr(j),1)
Rem					wscript.echo  flag
					If flag = 0 Then
						Exit For
					End If
				Else
					Exit For
				End If
			Next
			If flag <> 0 Then
				CompareIpAddr = flag
				Exit For 
			End If			
		Else
			Exit For
		End If
	Next 
	
Rem 	wscript.echo  flag
	CompareIpAddr =  flag
End Function

Function  GetLast()
	
		Set objFSO = CreateObject("Scripting.FileSystemObject")
	If objFSO.FileExists(FilePath) Then
	   Set objFile = objFSO.GetFile(FilePath)
	   If objFile.Size > 0 Then
	   	i = 0
Rem	   	wscript.echo "exist and large then 0"
	   	Set file = objFSO.OpenTextFile(FilePath,1)
	   	Do Until file.AtEndOfStream
	   		lastIpaddr(i) = file.Readline
Rem	   		wscript.echo  last(i)
	   		i = i + 1
	   	Loop 
	   	file.Close
	   Else
Rem	   	wscript.echo "less  then 0"
	   	
	   Set	file = objFSO.OpenTextFile(FilePath,2)
	   
	   	For i=LBound(currIpaddr) to UBound(currIpaddr)
	   		file.WriteLine(currIpaddr(i))
	 		Next
	  
	   	file.Close

	   End If
	   	
	Else
Rem			wscript.echo "file is not exist"
	   Set file = objFSO.CreateTextFile(FilePath,1)
	   	For k=LBound(currIpaddr) to UBound(currIpaddr)
	   		file.WriteLine(currIpaddr(k))
	 		Next
	 		
	    file.Close
	    
			Rem  first  Time monitor	
			wscript.echo "first time monitor"
			wscript.Quit 0
			
	End If
	
End Function

Function  getcurr()
	Dim  strComputer,j
	j = 0
	strComputer = "."
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	Set IPConfigSet = objWMIService.ExecQuery("Select IPAddress from Win32_NetworkAdapterConfiguration where IPEnabled=TRUE")
	
	For Each IPConfig in IPConfigSet
    If Not IsNull(IPConfig.IPAddress) Then 
     For i=LBound(IPConfig.IPAddress) to UBound(IPConfig.IPAddress)
       currIpaddr(j) = IPConfig.IPAddress(i)
     Next
    End If
   j = j + 1
	Next
	
	
End Function


Function saveCurr()
		Set objFSO = CreateObject("Scripting.FileSystemObject")
	  Set	file = objFSO.OpenTextFile(FilePath,2)
	  For k=LBound(currIpaddr) to UBound(currIpaddr)
	 	 file.WriteLine(currIpaddr(k))
		Next
	  file.Close
End Function

''''''''''''''''''''''''''''''''''''''
Rem main process start 

Dim  currIpaddr(10),lastIpaddr(10),rezult,FilePath

Set oShell = WScript.CreateObject( "WScript.Shell" )

OvDataDirStr = oSHell.Environment.Item( "OvDataDir" )

Rem  create bhm Dir
Call checkFolder(OvDataDirStr)



FilePath = OvDataDirStr & "\bhm\bhm_OsConfig_ipaddr.txt" 

Call getCurr() 


Call GetLast()

rezult = CompareIpAddr()

If rezult <> 0 Then
	wscript.echo  "ip address change"
	
	Dim last_text ,curr_text
	curr_text = "current: "
	last_text = "last: "
	For k=LBound(currIpaddr) to UBound(currIpaddr)
		curr_text = curr_text &" " & currIpaddr(k)
	Next
	
	For k=LBound(lastIpaddr) to UBound(lastIpaddr)
		last_text = last_text &" " & lastIpaddr(k)
	Next
	
	msg_text = "ip address had been change," & " " & last_text & " " & curr_text
	msg_app = "bhm_os_win_config_ipaddr.vbs"
	msg_grp = "BHM:WINOS:CONFIG"
	msg_obj = "ipaddr"
	msg_severity = "major"
	
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
	
	Rem  Save current
	Call saveCurr()
End If

Rem End of main process