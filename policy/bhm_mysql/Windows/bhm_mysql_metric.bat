@echo  off

rem set bhm_lib ,add jdom and apache commons and mysql connector/j jar
SET CLASSPATH=%CLASSPATH%;%OvDataDir%\bin\instrumentation\jdom.jar;%OvDataDir%\bin\instrumentation\commons-cli-1.2.jar;%OvDataDir%\bin\instrumentation\mysql-connector-java-5.1.17-bin.jar;
SET EXECUTEDIR=%OvDataDir%\bin\instrumentation

rem set for local test,delete this after test
rem SET EXECUTEDIR=F:\BHM\policy\bhm_tomcat\Windows
rem SET CLASSPATH=%CLASSPATH%;%EXECUTEDIR%\jdom.jar;%EXECUTEDIR%\commons-cli-1.2.jar;

chdir /D %EXECUTEDIR%

SET CLASSFILE="%EXECUTEDIR%\wlsConnectRemote.class"

rem recompile first time

if NOT EXIST %CLASSFILE% (
	"%JAVA_HOME%\bin\javac" wlsConnectRemote.java
)

"%JAVA_HOME%\bin\java.exe" -Xms256M -Xmx512M -cp "%CLASSPATH%" wlsConnectRemote %*

:END