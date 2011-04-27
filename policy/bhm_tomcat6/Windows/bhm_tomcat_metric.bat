@echo  off

rem add jdom and apache commons jar
SET CLASSPATH=%CLASSPATH%;%OvDataDir%\bin\instrumentation\jdom.jar;%OvDataDir%\bin\instrumentation\commons-cli-1.2.jar;
SET EXECUTEDIR=%OvDataDir%\bin\instrumentation

rem set for local test,delete this after test
rem SET EXECUTEDIR=F:\BHM\policy\bhm_tomcat6\Windows
rem SET CLASSPATH=%CLASSPATH%;%EXECUTEDIR%\jdom.jar;%EXECUTEDIR%\commons-cli-1.2.jar;

chdir /D %EXECUTEDIR%

SET JMXDIR="%EXECUTEDIR%\jmx

IF NOT EXIST %JMXDIR% (
	MKDIR %JMXDIR%
)

SET CLASSFILE="%EXECUTEDIR%\jmx\TomcatMbeanQuery.class"

rem recompile first time

if NOT EXIST %CLASSFILE% (
	"%JAVA_HOME%\bin\javac" TomcatMbeanQuery.java
	copy /Y "%EXECUTEDIR%\TomcatMbeanQuery.class" "%EXECUTEDIR%\jmx\TomcatMbeanQuery.class"
)

"%JAVA_HOME%\bin\java.exe" jmx.TomcatMbeanQuery -p %1 -f bhm_tomcat6_mbean.xml 

:END