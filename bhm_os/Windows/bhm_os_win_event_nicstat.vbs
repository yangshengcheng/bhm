'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'' FILENAME:     bhm_os_win_event_nicstat.vbs
'' VERSION:      1.0
'' DESCRIPTION:  The script can be used to check network interface card status.
''               
'' USAGE:        cscript bhm_os_win_event_nicstat.vbs
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

	Dim  strComputer,m_text,m_app,m_grp,m_obj,m_severity,NicStatus
	
	m_app = "bhm_os_win_event_nicstat.vbs"
	m_grp = "BHM:WINOS:EVENT"
	m_obj = "physicaldisk"
	m_severity = "critical"
	strComputer = "."
	
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	
	Set nicinfo = objWMIService.ExecQuery("Select Manufacturer,AdapterTypeID,Caption,Availability,Status from Win32_NetworkAdapter",,48)
	
	For Each objitem in nicinfo
		If objitem.Manufacturer <> "Microsoft" and objitem.AdapterTypeID = 0 and objitem.Availability <> 3  Then
			
				Select Case objitem.Availability
					Case 1
						NicStatus = "Other"
					Case 2
						NicStatus = "Unknown"
					Case 3
						NicStatus = "Running or Full Power"
					Case 4
						NicStatus = "Warning"
					Case 5
						NicStatus = "In Test"
					Case 6
						NicStatus = "Not Applicable"
					Case 7
						NicStatus = "Power Off"
					Case 8
						NicStatus = "Off Line"
					Case 9
						NicStatus = "Off Duty"
					Case 10
						NicStatus = "Degraded"
					Case 11
						NicStatus = "Not Installed"
					Case 12
						NicStatus = "Install Error"
					Case 13
						NicStatus = "Power Save - Unknown"
					Case 14
						NicStatus = "Power Save - Low Power Mode"
					Case 15
						NicStatus = "Power Save - Standby"
					Case 16
						NicStatus = "Power Cycle"
					Case 17
						NicStatus = "Power Save - Warning"
				End Select 
				
				m_text = "network interface card have a bad status,"& objitem.Caption & " : "& NicStatus
				Call msg(m_text,m_app,m_grp,m_obj,m_severity)					  
		End If     
	Next

Rem End of main process