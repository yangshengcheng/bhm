' author : yangshengcheng@gzcss.net
' 2010-4-12 13:58
' usage : shs_perl  bhm_os_perf_uptime_5min.pl 
' descript : get unix platform 's uptime in  seconds
' output : uncommect the print line to trace warning or error

On Error Resume Next

strComputer = "."
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")

Set colOSItems = objWMIService.ExecQuery("SELECT * FROM Win32_OperatingSystem")
For Each objOSItem In colOSItems
  wscript.echo  objOSItem.LastBootUpTime
Next