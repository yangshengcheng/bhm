rem On Error Resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This script check  iis  log file 
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_iis_findlog.vbs 
'
' author:yangshengcheng@gzcss.net
' timestamp : 2011/03/01
' --------------------------------------------------------------------------
Dim site
set oArgs=wscript.arguments
  
If oArgs.Count <> 1 Then 
rem   Usage () 
else
  site = oArgs.item(0)
rem   wscript.echo site
End If


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

Dim timestamp:timestamp=y& m & d 


Dim logfile: logfile = "ex"&timestamp &".log"
Dim path: path="c:\windows\system32\Logfiles\" & site &"\"&logfile

wscript.echo Chr(34) & path & Chr(34)

wscript.quit 0