rem On Error Resume Next
'Option Explicit

' --------------------------------------------------------------------------
' This script check  veritas netbackup  log file 
'
' use cscript to get output on the command prompt: 
' example: 
' 
'   cscript bhm_veritas_findlog.vbs 
'
' author:yangshengcheng@gzcss.net
' timestamp : 2011/03/03
' --------------------------------------------------------------------------
Dim dir 
set oArgs=wscript.arguments
  
If oArgs.Count <> 1 Then 
rem   Usage () 
else
  dir = oArgs.item(0)
rem   wscript.echo site
End If

Function timestamp()
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

	timestamp=y& m & d 

End Function


rem  find the newest log file
Function fileFilter(filedir,k)
	Dim fso ,Folder,files,file,s,tmp,tmpname
	s = 0
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set Folder = fso.GetFolder(filedir)
	Set ofiles = Folder.files
	For Each File In oFiles 
 		If InStr(1,File,k,1) > 0 Then
			If s =0 Then 
				tmp = File.DateCreated
				tmpname = File.path
				s= 1
			Else
				If File.DateCreated > tmp Then 
					tmpname = File.path
				End if
			End if

 		End If 
    Next 
	fileFilter = tmpname
End Function

Dim keyword : keyword = timestamp()
Dim file:file = fileFilter(dir,keyword)

rem Dim logfile: logfile = "ex"&timestamp &".log"
Dim path: path=file

wscript.echo Chr(34) & path & Chr(34)

wscript.quit 0