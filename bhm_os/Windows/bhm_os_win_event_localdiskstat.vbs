'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' FILENAME:     bhm_os_win_event_localdiskstat.vbs
'' VERSION:      1.0
'' DESCRIPTION:  The script can be used to check bad status of local hard disk .
''               
'' USAGE:        cscript bhm_os_win_event_localdiskstat.vbs
''               
'' LANGUAGE:     VBScript
''
'' author:		yangshengcheng@gzcss.net
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
 On Error Resume Next

Function msg(msg_text,msg_app,msg_grp,msg_obj,msg_severity)
	Dim msgObj
	Set msgObj = CreateObject("OVOAutomation.Opcmsg")
	
	msgObj.MessageText = msg_text
	msgObj.Application = msg_app
			
	msgObj.MessageGroup = msg_grp
	msgObj.Object = msg_obj
	msgObj.Severity = msg_severity
			
	msgObj.Send()
End Function


Rem main process start 

	Dim  strComputer,m_text,m_app,m_grp,m_obj,m_severity
	
	m_app = "bhm_os_win_localdiskstat.vbs"
	m_grp = "BHM:WINOS:EVENT"
	m_obj = "physicaldisk"
	m_severity = "critical"
	strComputer = "."
	
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	
	Set diskstat = objWMIService.ExecQuery("Select Caption,Status from Win32_DiskDrive",,48)
	
	For Each objitem in diskstat
		If objitem.Status <> "OK"  Then
				m_text = "hard disk have a bad status,"& objitem.Caption & " : "& objitem.Status
				Call msg(m_text,m_app,m_grp,m_obj,m_severity)					  
		End If     
	Next

Rem End of main process