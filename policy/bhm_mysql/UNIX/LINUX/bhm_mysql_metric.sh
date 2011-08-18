#!/bin/sh

######################################
#desc: mysql monitor data for AIX HP-UX LINUX
#author: yangshengcheng@gzcss.net
#create : 2011.08.08
#version : 20110808
#modified: create
#####################################


if [ -z "$JAVA_HOME" ]; then
        #if JAVA_HOME variable is empty ,you should set it below

        JAVA_HOME=
        export JAVA_HOME
fi

CLASSPATH=.:$CLASSPATH:/var/opt/OV/bin/instrumentation/mysql-connector-java-5.1.17-bin.jar:/var/opt/OV/bin/instrumentation/commons-cli-1.2.jar
export CLASSPATH

EXECUTEDIR=/var/opt/OV/bin/instrumentation/

CLASSFILE=/var/opt/OV/bin/instrumentation/bhmMysqlQuery.class

cd $EXECUTEDIR

if [ ! -e $CLASSFILE ]; then
        $JAVA_HOME/bin/javac $EXECUTEDIR/bhmMysqlQuery.java

fi

$JAVA_HOME/bin/java -cp "$CLASSPATH"  bhmMysqlQuery $@
