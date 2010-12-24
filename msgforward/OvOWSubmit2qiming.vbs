On Error resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This is a sample script to forward messages to an oracle database
' It has to be started on the OVO Management Server
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript OvOWSubmit2qiming.vbs 6623fda0-0ef8-71d4-1d6e-0f887b3e0000 
'
' author:yangshengcheng
' change:
' qiming syslog format chang.
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
' --------------------------------------------------------------------------
' Construct the Message ID name and get the object. Also get the node
' where the message came from.
' --------------------------------------------------------------------------

Const WMIMsg  = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_Message.Id="
Const WMINode = "WinMgmts:{impersonationLevel=impersonate}!root/HewlettPackard/OpenView/Data:OV_ManagedNode.Name="

MsgPath = WMIMsg & """" & MsgId & """"
Set OV_Message = GetObject(MsgPath)


rem original  text 
originaltext = OV_Message.originaltext
originaltext = Replace(originaltext,Chr(10),Chr(32))
originaltext = Replace(originaltext,Chr(9),"")
rem wscript.echo originaltext

rem event  log 日期
DateCreated = Left(OV_Message.TimeCreated, 4)   & "-" &_
              Mid(OV_Message.TimeCreated, 5, 2) & "-" &_
              Mid(OV_Message.TimeCreated, 7, 2)

rem  event log 时间
TimeCreated = Mid(OV_Message.TimeCreated, 9, 2)  & ":" &_
              Mid(OV_Message.TimeCreated, 11, 2) & ":" &_
              Mid(OV_Message.TimeCreated, 13, 2)



rem event log  type(type)
Object =OV_Message.Object

rem  event log  user(user)
user = OV_Message.userOfstatechange

rem  event  log  domain(domain)
domain = ""

rem  event log 来源(source)
source =OV_Message.Application

rem event log computername(hostname)
temp = RegExpTest("Computer:\s+(\S+)\s+",originaltext)
temp = RegExpTest("\S+",temp)
temp = Replace(temp,"Computer:","")
Trim(Replace(temp," ","") )

hostname = temp

rem event log level (level)
level = ""

rem event log 类型(subtype)
subtype = OV_Message.Type

rem  event log  event  ID(eid)
temp = RegExpTest("ID:\s+\d+\s+",originaltext)
temp = RegExpTest("\d+",temp)
temp = Replace(temp," ","")
eid = temp

rem event log class (class) 
event_class = ""
rem  event log  description (msg) 
temp = RegExpTest("Description:.*",originaltext)
rem wscript.echo  "temp:" & temp
temp = Replace(temp,"Description:","")
rem Trim(Replace(temp," ","") )
msg = temp

rem event log  ip(hostIP)
NodeId      = OV_Message.NodeName
NodePath = WMINode & """" & NodeId & """"
Set OV_ManagedNode = GetObject(NodePath)
' Caption = OV_ManagedNode.Caption
hostIP = OV_ManagedNode.PrimaryNodeName

'Wscript.Echo "type: " & eventType
'Wscript.Echo "date:" & DateCreated
'Wscript.Echo "time:" & TimeCreated
'Wscript.Echo "Application:" & Application
'Wscript.Echo "Object:"& Object
'Wscript.Echo "eventID:" & eventID
'Wscript.Echo "user:" & user
'Wscript.Echo "ComputerName:" & ComputerName
'Wscript.Echo "description:" & description

rem  wscript.echo eventType&","&DateCreated&","&TimeCreated&","&Application&","&Object&","&eventID&","&user& ","&ComputerName & ","&description
qiming ="Microsoft: Windows time="&DateCreated&" "&TimeCreated&" "&"hostIp="&hostIP&" "&"type="&Object&" "&"user="&user&" "&"domain="&domain& " "&"source="&source & " "&"hostName="&hostname & " "& "level="&level & " "& "subType=" & subType & " "& "eid="& eid &" "&"class="&event_class&" "&"msg="&msg

rem log the qiming syslog message
Dim oFSO, oTS,qimingLog

Set oFSO = WScript.CreateObject("Scripting.FileSystemObject")

qimingLog = "D:\Program Files\HP\HP BTO Software\bin\bhm\qiming.log"

If oFSO.FileExists(qimingLog) Then 
	Set oTS = oFSO.OpenTextFile(qimingLog,8)
	oTS.WriteLine(qiming)
	oTS.close
Else
	Set oTS = oFSO.CreateTextFile(qimingLog,1)
	oTS.WriteLine(qiming)
	oTS.close
End If 



rem send windows event to  qiming soc 
Set Sock=CreateObject("MSWinsock.Winsock")
sock.Protocol=1
rem  the  soc ip is 10.91.1.233,guo wen long pc 's ip  is 10.91.14.110
sock.Connect "10.91.14.110",514
rem  Do While True
rem wscript.echo  syslog4bhm
sock.senddata qiming
If Err <> 0 Then 
	wscript.echo Err.description
End if
rem  	wscript.sleep 1000
rem  Loop
sock.close


rem ack the message after sent
 Dim ackObj
 Set ackObj = CreateObject("OVOAutomation.Opcmack")
 ackObj.MessageId = MsgId
 ackObj.Acknowledge()
' --------------------------------------------------------------------------
' End of Submit2qiming.vbs
' --------------------------------------------------------------------------
