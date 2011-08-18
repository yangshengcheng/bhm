@echo  off

rem set bhm_lib ,add jdom ,apache commons jar,wlclient.jar,wljmxclient.jar

SET wlclient=%OvDataDir%\bin\instrumentation\wlclient.jar
SET wljmxclient=%OvDataDir%\bin\instrumentation\wljmxclient.jar

rem set classpath
SET CLASSPATH=%CLASSPATH%;%wlclient%;%wljmxclient%;%OvDataDir%\bin\instrumentation\jdom.jar;%OvDataDir%\bin\instrumentation\commons-cli-1.2.jar;

SET EXECUTEDIR=%OvDataDir%\bin\instrumentation

chdir /D %EXECUTEDIR%

SET CLASSFILE="%EXECUTEDIR%\wlsCreateMbeanXml.class"

SET REMOTEFILE="%EXECUTEDIR%\wlsConnectRemote.class"

rem compile first time

if NOT EXIST %REMOTEFILE% (
	"%JAVA_HOME%\bin\javac" wlsConnectRemote.java
)

if NOT EXIST %CLASSFILE% (
	"%JAVA_HOME%\bin\javac" wlsCreateMbeanXml.java
)

"%JAVA_HOME%\bin\java.exe" -Xms256M -Xmx512M -cp "%CLASSPATH%" wlsCreateMbeanXml %*

:END