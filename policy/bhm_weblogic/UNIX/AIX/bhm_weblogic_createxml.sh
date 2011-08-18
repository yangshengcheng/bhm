#!/usr/bin/sh

######################################
#desc: for AIX only
#author: yangshengcheng@gzcss.net
#create : 2011.7.28
#version : 20110728
#modified: create
#####################################

#echo  $@

if [ -z "$JAVA_HOME" ]; then
        #if JAVA_HOME variable is empty ,you should set it below

        JAVA_HOME=
        export JAVA_HOME
fi
# native jar,if use "-c native" you must set this follow jar dir 
wlclient=/var/opt/OV/bin/instrumentation/wlclient.jar
wljmxclient=/var/opt/OV/bin/instrumentation/wljmxclient.jar


CLASSPATH=.:$CLASSPATH:$wlclient:$wljmxclient:/var/opt/OV/bin/instrumentation/jdom.jar:/var/opt/OV/bin/instrumentation/commons-cli-1.2.jar
export CLASSPATH

EXECUTEDIR=/var/opt/OV/bin/instrumentation/

CLASSFILE=/var/opt/OV/bin/instrumentation/wlsCreateMbeanXml.class
REMOTEFILE=/var/opt/OV/bin/instrumentation/wlsConnectRemote.class

cd $EXECUTEDIR

if [ ! -e REMOTEFILE ]; then
        $JAVA_HOME/bin/javac $EXECUTEDIR/wlsConnectRemote.java

fi

if [ ! -e $CLASSFILE ]; then
        $JAVA_HOME/bin/javac $EXECUTEDIR/wlsCreateMbeanXml.java

fi

$JAVA_HOME/bin/java -cp "$CLASSPATH"  wlsCreateMbeanXml $@