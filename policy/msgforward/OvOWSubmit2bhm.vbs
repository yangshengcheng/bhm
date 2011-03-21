On Error resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This  script use for  forward messages to bhm common collect
' It has to be started on the OVO Management Server
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript OvOWSubmit2bhm.vbs 6623fda0-0ef8-71d4-1d6e-0f887b3e0000 
'
' author:yangshengcheng@gzcss.net
' --------------------------------------------------------------------------

Sub Usage ()
  Wscript.Echo "Usage: OvOWSubmit2bhm <Id>" & CRLF & CRLF &_
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
 
' --------------------------------------------------------------------------
' Construct the Message ID name and get the object. Also get the node
' where the message came from.
' --------------------------------------------------------------------------

Const WMIMsg  = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_Message.Id="
Const WMINode = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_ManagedNode.Name="

MsgPath = WMIMsg & """" & MsgId & """"
Set OV_Message = GetObject(MsgPath)

TimeCreated = Mid(OV_Message.TimeCreated, 9, 2)  & ":" &_
              Mid(OV_Message.TimeCreated, 11, 2) & ":" &_
              Mid(OV_Message.TimeCreated, 13, 2)
DateCreated = Left(OV_Message.TimeCreated, 4)   & "-" &_
              Mid(OV_Message.TimeCreated, 5, 2) & "-" &_
              Mid(OV_Message.TimeCreated, 7, 2)

State	= OV_Message.State
'UserOfStateChange = OV_Message.UserOfStateChange
rem  TimeReceivedTimeStamp = OV_Message.TimeReceived
MessageGroup = OV_Message.MessageGroup
Object =OV_Message.Object
Application =OV_Message.Application
Severity	= OV_Message.Severity
'TimeFirstReceivedTimeStamp	=OV_Message.TimeFirstReceived
Source	=OV_Message.Source

Text        = OV_Message.Text

NodeId      = OV_Message.NodeName
TimeCreateTimeStamp =   OV_Message.TimeCreated

NodePath = WMINode & """" & NodeId & """"
Set OV_ManagedNode = GetObject(NodePath)
rem  Caption = OV_ManagedNode.Caption
Primary = OV_ManagedNode.PrimaryNodeName

'Wscript.Echo "manageNodeCaption:" & Primary
'Wscript.Echo "State: " & State
'Wscript.Echo "CreatedAt:" & DateCreated & " " &TimeCreated
'Wscript.Echo "MessageGroup:" & MessageGroup
'Wscript.Echo "Object:" & Object
'Wscript.Echo "Application:" & Application
'Wscript.Echo "Severity:" & Severity
'Wscript.Echo "Source:" & Source
'Wscript.Echo "Text:" &  Text

syslog4bhm = Primary &"##"& State & "##" & DateCreated & " " &TimeCreated & "##"&MessageGroup & "##"&Object & "##"&Application & "##" & Severity & "##"&Source & "##" & Text
rem  Wscript.Echo syslog4bhm

rem set timestamp
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

rem log the bhm forword syslog message
Dim oFSO, oTS,bhmlog

Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")

bhmlog = "D:\Program Files\HP\HP BTO Software\bin\bhm\bhm_"&timestamp&".log"

If oFSO.FileExists(bhmlog) Then 
	Set oTS = oFSO.OpenTextFile(bhmlog,8)
	oTS.WriteLine(syslog4bhm)
	oTS.close
Else
	Set oTS = oFSO.CreateTextFile(bhmlog,1)
	oTS.WriteLine(bhmlog)
	oTS.close
End If 



Set Sock=CreateObject("MSWinsock.Winsock")
sock.Protocol=1
sock.Connect "10.91.1.230",515
rem Do While True
rem wscript.echo  syslog4bhm
sock.senddata syslog4bhm
If Err <> 0 Then 
	wscript.echo Err.description
End if
rem 	wscript.sleep 100
rem Loop
sock.close

' --------------------------------------------------------------------------
' End of OvOWSubmit2bhm.vbs
' --------------------------------------------------------------------------
