rem On Error Resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This script check  iis basic information 
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_iis_check.vbs AppPools or sites
'
' author:yangshengcheng@gzcss.net
' timestamp : 2011/01/12
' --------------------------------------------------------------------------
Option Explicit
On Error Resume Next

Sub main
	On Error Resume Next
	Dim objArgs, IISObj
	Dim OSVer, WinVerRegVal
	
	Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
	WinVerRegVal="HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\CurrentVersion"
	
	OSVer = WshShell.RegRead(WinVerRegVal)
		
	If (OSVer < 5.2) Then 
		WScript.Echo "Error: Launch the tool on node with IIS 6.0 or IIS 7.0 server running"
		WScript.Quit 1
	Else
rem 		WScript.Echo OSVer	
	End If	
	
	Set objArgs = WScript.Arguments
	If objArgs.Count <> 1 Then
		Usage
		Wscript.Quit(1)
	End If

	IISObj = UCase(objArgs(0))

	Select Case IISObj
	
		Case "APPPOOLS"
				CheckAppPoolsStatus(OSVer)
		
		Case "SITES"
				CheckWebSitesStatus(OSVer)
		
		Case Else
			Usage
			WScript.Quit(1)
	
	End Select

End Sub

Sub CheckWebSitesStatus(version)
	
	On Error Resume Next
	Dim locatorObj, providerObj
	Dim ServiceObj, strQuery
	Dim Servers, Server		
	
	Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
	Dim WshNetwork : Set WshNetwork = WScript.CreateObject("WScript.Network")
	
	WScript.Echo "Machine : " & WshNetwork.ComputerName & "." &	 WshNetwork.UserDomain & "; IISversion :" & version & VbNewLine 
	
	' Status
	Const SERVER_STATE_STARTING    = "starting"
	Const SERVER_STATE_STARTED     = "running"
	Const SERVER_STATE_STOPPING    = "stopping"
	Const SERVER_STATE_STOPPED     = "stopped"
	Const SERVER_STATE_PAUSING     = "pausing"
	Const SERVER_STATE_PAUSED      = "paused"
	Const SERVER_STATE_CONTINUING  = "continuing"
	
	Dim Status
	Status = Array  ("",_
			SERVER_STATE_STARTING,_
			SERVER_STATE_STARTED,_
			SERVER_STATE_STOPPING,_
			SERVER_STATE_STOPPED,_
			SERVER_STATE_PAUSING,_
			SERVER_STATE_PAUSED,_
			SERVER_STATE_CONTINUING)
	
	'Connect to WMI 
	Set locatorObj= CreateObject("WbemScripting.SWbemLocator")  	
	Set providerObj = locatorObj.ConnectServer(".","root/MicrosoftIISv2")
	Set ServiceObj = providerObj.Get("IIsWebService='W3SVC'")
	
	strQuery = "select Name, ServerComment, ServerBindings from IIsWebServerSetting"
	
	Set Servers = providerObj.ExecQuery(strQuery, , &H30)
	
	WScript.Echo "Site Name (Identifier)" & Space(50-(Len("Site Name (Identifier)")) + 4)_
						     & "Status" & space(12 - Len("Status"))_
						     & "IP" & space(20-Len("IP")) &_
						     "Port" & space(8-Len("Port"))_
					     & "Hostname"
	WScript.Echo "====================================================================================================="
	
	For Each Server in Servers
		
		Dim ServerObj, bindings, obj, i
		Dim ServerComment, ServerName, IP, Port, Hostname, ServerState
		
		Dim width1, width2, width3, width4
		
		Set ServerObj = providerObj.Get("IISWebServer='" & Server.Name & "'")					
		bindings = Server.ServerBindings
		
		ServerComment = Server.ServerComment
		ServerName    = Server.Name
		ServerState   = ServerObj.ServerState
		
		If (IsArray(bindings)) Then
			For i = LBound(bindings) To UBound(bindings)
	
				If (bindings(i).IP <> "") Then
					IP = bindings(i).IP
				Else
					IP = "ALL" 
				End If
			
				Port = bindings(i).Port
				
				If (bindings(i).Hostname <> "") Then
					Hostname = bindings(i).Hostname
				Else
					Hostname = "N/A"
				End If
		
				If (i = LBound(bindings)) Then
			
					width1 = 50-(Len(ServerComment & " (" & ServerName & ") ")) + 4
					width2 = 12 - Len(Status(ServerState))
					width3 = 20-Len(IP)	
					width4 = 8-Len(Port)
	
					If (width1 < 1) Then
						width1 = 1
					End If
	
					If (width2 < 1) Then
						width2 = 1
					End If
	
					If (width3 < 1) Then
						width3 = 1
					End If
	
					If (width4 < 1) Then
						width4 = 1
					End If
	
						WScript.Echo ServerComment & " (" & ServerName & ") "_
						     & Space(width1)_
						     & UCase(Status(ServerState)) & space(width2)_
						     & IP & space(width3) & Port & space(width4)_
						     & Hostname
				Else 
						WScript.Echo space(66) & IP & space(width3) & Port & space(width4)_
						     & Hostname
				End If
			
			Next
				
		End If
	Next	
	
End Sub

Sub CheckAppPoolsStatus(version)

	On Error Resume Next
		
	Dim locatorObj, providerObj
	Dim ServiceObj, strQuery
	Dim Servers, Server
		
	Dim WshShell : Set WshShell = CreateObject("WScript.Shell")
	Dim WshNetwork : Set WshNetwork = WScript.CreateObject("WScript.Network")
	
	WScript.Echo "Machine : " & WshNetwork.ComputerName & "." &	 WshNetwork.UserDomain & "; IISversion :" & version & VbNewLine 
	
	' Status
	Const APPPOOL_STATE_STARTING    = "starting"
	Const APPPOOL_STATE_STARTED     = "running"
	Const APPPOOL_STATE_STOPPING    = "stopping"
	Const APPPOOL_STATE_STOPPED     = "stopped"
	
	Dim AppStatus
	AppStatus = Array  ("",_
			APPPOOL_STATE_STARTING,_
			APPPOOL_STATE_STARTED,_
			APPPOOL_STATE_STOPPING,_
			APPPOOL_STATE_STOPPED)
			
	'Connect to WMI 
	Set locatorObj= CreateObject("WbemScripting.SWbemLocator")  	
	Set providerObj = locatorObj.ConnectServer(".","root/MicrosoftIISv2")
		
	strQuery = "select * from IIsApplicationPoolSetting"
	
	Set Servers = providerObj.ExecQuery(strQuery, , &H30)
	
	WScript.Echo "Application Pool" & Space(34) & "Status" & Space(6) & "MaxProcesses" & space(2) & "AppPoolQueueLength"
	WScript.Echo "=============================================================================================="
	
	Dim item
	For each item in Servers
		WScript.Echo item.Name & Space(50-Len(item.Name)) & AppStatus(item.AppPoolState)_
		& space (12-Len(AppStatus(item.AppPoolState))) & item.MaxProcesses & space (14-Len(item.MaxProcesses))_
		& item.AppPoolQueueLength
	Next
	
End Sub

Sub Usage
	WScript.Echo "bhm_iis_check.vbs <Argument>" & VBCRLF
	WScript.Echo "Parameter:"
	WScript.Echo vbTab & "AppPools : List All Appication Pools "
	Wscript.Echo vbTab & "Sites    : List All Web Sites" & VBCRLF
	
End Sub

main
