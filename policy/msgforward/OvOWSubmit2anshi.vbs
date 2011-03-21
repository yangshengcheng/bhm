On Error resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This is a sample script to forward messages to an oracle database
' It has to be started on the OVO Management Server
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript OvOWSubmit2anshi.vbs 6623fda0-0ef8-71d4-1d6e-0f887b3e0000 
'
' author:yangshengcheng@gzcss.net
' --------------------------------------------------------------------------

Sub Usage ()
  Wscript.Echo "Usage: OvOWSubmit2anshi.vbs <Id>" & CRLF & CRLF &_
               "       <Id>          = Id of the OV_Message instance " & CRLF                      
  WScript.Quit(1)  
End Sub


' --------------------------------------------------------------------------
' Check arguments. The message ID is mandatory.
' --------------------------------------------------------------------------

CRLF = Chr(13) & Chr(10)

set oArgs=wscript.arguments
  
If oArgs.Count <> 1 Then 
  Usage () 
else
  MsgId = oArgs.item(0)
End If
 
rem  the regexp 
Function RegExpTest(patrn, strng)

  Dim regEx, Match, Matches 

  Set regEx = New RegExp 

  regEx.Pattern = patrn 

  regEx.IgnoreCase = true    

  regEx.Global = True       

  Set Matches = regEx.Execute(strng)   

  For Each Match in Matches
rem 	wscript.echo Match.Value
	retstr = Match.Value
  Next
	Trim(retstr)
  RegExpTest = retstr

End Function

' submatch 
Function SubMatchTest(inpStr,pattern)
  Dim oRe, oMatch, oMatches
  Set oRe = New RegExp
  oRe.Pattern = pattern
  Set oMatches = oRe.Execute(inpStr)
  Set oMatch = oMatches(0)
  retStr = oMatch.SubMatches(1)
  SubMatchTest = retStr
End Function
' --------------------------------------------------------------------------
' Construct the Message ID name and get the object. Also get the node
' where the message came from.
' --------------------------------------------------------------------------

Const WMIMsg  = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_Message.Id="
Const WMINode = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_ManagedNode.Name="

MsgPath = WMIMsg & """" & MsgId & """"
Set OV_Message = GetObject(MsgPath)

	rem event  log 日期
	DateCreated = Left(OV_Message.TimeCreated, 4)   & "-" &_
				  Mid(OV_Message.TimeCreated, 5, 2) & "-" &_
				  Mid(OV_Message.TimeCreated, 7, 2)

	rem  event log 时间
	TimeCreated = Mid(OV_Message.TimeCreated, 9, 2)  & ":" &_
				  Mid(OV_Message.TimeCreated, 11, 2) & ":" &_
				  Mid(OV_Message.TimeCreated, 13, 2)


Dim messageGroup : messageGroup = OV_Message.MessageGroup
Dim win:win = "WINOS"
Dim anshi

If InStr(1,messageGroup,win,1) Then 
	
	rem original  text 
	originaltext = OV_Message.originaltext
	originaltext = Replace(originaltext,Chr(10),Chr(32))
	originaltext = Replace(originaltext,Chr(9),"")
	rem wscript.echo originaltext

	rem event log  type(type)
	Object = OV_Message.Object
	
	rem ovo Severity
	Severity = OV_Message.Severity
	rem Application
	Application =OV_Message.Application

	rem type
	mtype = OV_Message.Type

	rem event log  ip(hostIP)
	NodeId      = OV_Message.NodeName
	NodePath = WMINode & """" & NodeId & """"
	Set OV_ManagedNode = GetObject(NodePath)
	' Caption = OV_ManagedNode.Caption
	hostIP = OV_ManagedNode.PrimaryNodeName

	anshi = DateCreated&" "&TimeCreated&"|"&hostIP&"|"&Object&"|"&Severity&"|"&Application&"|"&mtype&"|"&originaltext
rem	wscript.echo anshi
Else
		rem event log  ip(hostIP)
	NodeId = OV_Message.NodeName
	NodePath = WMINode & """" & NodeId & """"
	Set OV_ManagedNode = GetObject(NodePath)
	' Caption = OV_ManagedNode.Caption
	hostIP = OV_ManagedNode.PrimaryNodeName

		rem event log  type(type)
	Object = OV_Message.Object
	
	rem ovo Severity
	Severity = OV_Message.Severity
	rem Application
	Application =OV_Message.Application

	rem type
	mtype = OV_Message.Type

rem	anshiclass = SubMatchTest(messageGroup,"(\w+):(\w+)")

	anshi =DateCreated&" "&TimeCreated &"|"&hostIP &"|"&Object&"|"&Severity&"|"&Application&"|"&mtype&"|"& OV_Message.Text

End if

Dim temp 
Dim y
temp = Year(Now())
If Len(temp)=4 Then
	y = Right(temp,2)
Else
	y = temp
End if
	
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

Dim timestamp:timestamp=y&m&d

	rem log the anshi syslog message
	Dim oFSO, oTS,anshiLog

	Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")

	anshiLog = "D:\Program Files\HP\HP BTO Software\bin\bhm\anshi_"&timestamp&".log"

	If oFSO.FileExists(anshiLog) Then 
		Set oTS = oFSO.OpenTextFile(anshiLog,8)
		oTS.WriteLine(anshi)
		oTS.close
	Else
		Set oTS = oFSO.CreateTextFile(anshiLog,1)
		oTS.WriteLine(anshi)
		oTS.close
	End If 



	rem send windows event to  anshi soc 
	Set Sock=CreateObject("MSWinsock.Winsock")
	sock.Protocol=1
	rem  change the ip follow 
	sock.Connect "10.91.1.233",514
	rem  Do While True
	rem wscript.echo  syslog4bhm
	sock.senddata anshi
	If Err <> 0 Then 
		wscript.echo Err.description
	End if
	rem  	wscript.sleep 1000
	rem  Loop
	sock.close



rem ack the message after sent
' Dim ackObj
' Set ackObj = CreateObject("OVOAutomation.Opcmack")
' ackObj.MessageId = MsgId
' ackObj.Acknowledge()
' --------------------------------------------------------------------------
' End of Submit2anshi.vbs
' --------------------------------------------------------------------------
