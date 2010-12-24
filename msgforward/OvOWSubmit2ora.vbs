On Error resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This is a sample script to forward messages to an oracle database
' It has to be started on the OVO Management Server
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript OvOWSubmit2ora.vbs 6623fda0-0ef8-71d4-1d6e-0f887b3e0000 
'
' author:yangshengcheng
' --------------------------------------------------------------------------

Sub Usage ()
  Wscript.Echo "Usage: SubmitTT <Id>" & CRLF & CRLF &_
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
DateCreated = Left(OV_Message.TimeCreated, 4)   & "/" &_
              Mid(OV_Message.TimeCreated, 5, 2) & "/" &_
              Mid(OV_Message.TimeCreated, 7, 2)

State	= OV_Message.State
'UserOfStateChange = OV_Message.UserOfStateChange
TimeReceivedTimeStamp = OV_Message.TimeReceived
MessageGroup = OV_Message.MessageGroup
Object =OV_Message.Object
Application =OV_Message.Application
Severity	= OV_Message.Severity
'TimeFirstReceivedTimeStamp	=OV_Message.TimeFirstReceived
Source	=OV_Message.Source
'special char replace
Source = Replace(Source,"'","''")
Source = Replace(Source,"&","''&''")
Text        = OV_Message.Text
Text = Replace(Text,"'","''")
Text = Replace(Text,"&","''&''")
NodeId      = OV_Message.NodeName
'TimeCreateTimeStamp =   OV_Message.TimeCreated

NodePath = WMINode & """" & NodeId & """"
Set OV_ManagedNode = GetObject(NodePath)
Caption = OV_ManagedNode.Caption
'Primary = OV_ManagedNode.PrimaryNodeName


'Wscript.Echo "State: " & State
'Wscript.Echo "UserOfStateChange:" & UserOfStateChange
'Wscript.Echo "TimeReceivedTimeStamp:" & TimeReceivedTimeStamp
'Wscript.Echo "MessageGroup:" & MessageGroup
'Wscript.Echo "Object:" & Object
'Wscript.Echo "Application:" & Application
'Wscript.Echo "Severity:" & Severity
'Wscript.Echo "TimeFirstReceivedTimeStamp:" & TimeFirstReceivedTimeStamp
'Wscript.Echo "Source:" & Source
'Wscript.Echo "NodeId:" & NodeId
'Wscript.Echo "CreatedAt:" & CreatedAt
'Wscript.Echo "Text:" &  Text

strSql = "insert into T_ALARMINFO_TEMP(ID,NODE_NAME,STATE,RECEIVEDTIMESTAMP,MESSAGE_GROUP,OBJECT,APPLICATION,SEVERITY,SOURCE,TEXT) values("
strSql = strSql & "" &"SEQ_ALARM_TEMP.NEXTVAL" &","
strSql = strSql & "'" &Caption & "',"
strSql = strSql & "" &State &","
'strSql = strSql & "'" &UserOfStateChange &"',"
strSql = strSql & "'" &TimeReceivedTimeStamp &"',"
strSql = strSql & "'" &MessageGroup &"',"
strSql = strSql & "'" &Object &"',"
strSql = strSql & "'" &Application &"',"
strSql = strSql & "" &Severity &","
'strSql = strSql & "'" &TimeFirstReceivedTimeStamp &"',"
strSql = strSql & "'" &Source &"',"
'strSql = strSql & "'" &TimeCreateTimeStamp &"',"
strSql = strSql & "'" &Text &"')"

'wscript.echo  strSql

' connect to  oracle  and submitt the msg 

Dim strCon: strCon = "Driver={Microsoft ODBC for Oracle}; " & _
					 "CONNECTSTRING=(DESCRIPTION=" & _
					 "(ADDRESS=(PROTOCOL=TCP)" & _
					 "(HOST=172.16.11.102)(PORT=1521))" & _
					 "(CONNECT_DATA=(SERVER = DEDICATED)(SERVICE_NAME=bhm))); uid=bhm;pwd=bhm;"

Dim oCon: Set oCon = WScript.CreateObject("ADODB.Connection")
'oCon.connectionstring=strCon
oCon.open strCon
If oCon.state = 1 Then
'	wscript.echo  strSql
	oCon.Execute strSql
	If oCon.Errors.count > 0 Then
		For Each adoErr In oCon.Errors
'		wscript.echo adoErr.SQLState&"	"&adoErr.description
		Next
	End if
	oCon.Errors.clear
Else
	dim filesys, filetxt
	Const ForReading = 1, ForWriting = 2, ForAppending = 8 
	Set filesys = CreateObject("Scripting.FileSystemObject")
	Set filetxt = filesys.OpenTextFile("c:\insertLog.txt", ForAppending, True)

	For Each errs  In oCon.errors
	test = Now & "	"&errs.description
	filetxt.WriteLine(test)
	Next
	
	filetxt.Close
End If


'If oCon.Errors.count > 0 Then
'	For Each adoErr In oCon.Errors
'		wscript.echo adoErr.SQLState&"	"&adoErr.description
'	Next
'	oCon.Errors.clear
'	wscript.quit(-1)
'End if 



'If Err <> 0 Then
'	dim filesys, filetxt
'	Const ForReading = 1, ForWriting = 2, ForAppending = 8 
'	test=Now &"	"& Err.description
'	Set filesys = CreateObject("Scripting.FileSystemObject")
'	Set filetxt = filesys.OpenTextFile("c:\insertLog.txt", ForAppending, True) 
'	filetxt.WriteLine(test)
'	filetxt.Close
'Else
	'wscript.echo  recaffected & "	rows affected"
	
'End if


oCon.Close
Set oCon = Nothing
'Set oRs = Nothing
'Set OV_Message = Nothing


' --------------------------------------------------------------------------
' End of Submit2ora.vbs
' --------------------------------------------------------------------------
