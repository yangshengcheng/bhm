//***************************************************************************
//***************************************************************************
// original from IBM db2 demo,edit by yangshengcheng@gzcss.net
// SOURCE FILE NAME: Util.java
//
// desc: Utilities for JDBC programs
//
//         This file has 3 classes:
//         1. Db - Connect to or disconnect from the 'sample' database
//         2. JdbcException - Handle Java Exceptions
//
// JAVA 2 CLASSES USED:
//         DriverManager
//         Connection
//         Exception
//
// OUTPUT FILE: None
//**************************************************************************/

import java.lang.*;
import java.util.*;
import java.sql.*;


class Db
{
  public String alias;
  public String server;
  public int portNumber = -1; // < 0 use universal type 2 connection
                              // > 0 use universal type 4 connection
  public String userId;
  public String password;
  public Connection con = null;
  
  public String SqlFile="bhm_db2_metrics.xml"; 

  public Db()
  {
  }

  public Db(String argv[]) throws Exception
  {
    if( argv.length > 6 ||
        ( argv.length == 1 &&
          ( argv[0].equals( "?" )               ||
            argv[0].equals( "-?" )              ||
            argv[0].equals( "/?" )              ||
            argv[0].equalsIgnoreCase( "-h" )    ||
            argv[0].equalsIgnoreCase( "/h" )    ||
            argv[0].equalsIgnoreCase( "-help" ) ||
            argv[0].equalsIgnoreCase( "/help" ) ) ) )
    {
      throw new Exception(
        "Usage: prog_name [dbAlias] [userId passwd] (use universal JDBC type 2 driver)\n" +
        "       prog_name [dbAlias] server portNum userId passwd (use universal JDBC type 4 driver)" );
    }

    switch (argv.length)
    {
      case 0:  // Type 2, use all defaults
        alias = "sample";
        userId = "";
        password = "";
        break;
      case 1:  // Type 2, dbAlias specified
        alias = argv[0];
        userId = "";
        password = "";
        break;
      case 2:  // Type 2, userId & passwd specified
        alias = "sample";
        userId = argv[0];
        password = argv[1];
        break;
      case 3:  // Type 2, dbAlias, userId & passwd specified
        alias = argv[0];
        userId = argv[1];
        password = argv[2];
        break;
      case 4:  // Type 4, use default dbAlias
        alias = "sample";
        server = argv[0];
        portNumber = Integer.valueOf( argv[1] ).intValue();
        userId = argv[2];
        password = argv[3];
        break;
      case 5:  // Type 4, everything specified
        alias = argv[0];
        server = argv[1];
        portNumber = Integer.valueOf( argv[2] ).intValue();
        userId = argv[3];
        password = argv[4];
        break;
      case 6:  // Type 4, everything specified and the external SQLs
        alias = argv[0];
        server = argv[1];
        portNumber = Integer.valueOf( argv[2] ).intValue();
        userId = argv[3];
        password = argv[4];
        SqlFile = argv[5];
        break;
    }
  } // Db Constructor

  public Connection connect() throws Exception
  {
    String url = null;

    // In Partitioned Database environment, set this to the node number
    // to which you wish to connect (leave as "0" in non-Partitioned Database environment)
    String nodeNumber = "0";

    Properties props = new Properties();

    if ( portNumber < 0 )
    {
      url = "jdbc:db2:" + alias;
 //     System.out.println("  Connect to '" + alias + "' database using JDBC Universal type 2 driver." );
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
    }
    else
    {
      url = "jdbc:db2://" + server + ":" + portNumber + "/" + alias;
//      System.out.println("  Connect to '" + alias + "' database using JDBC Universal type 4 driver." );
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
    }

    if( null != userId )
    {
      props.setProperty("user", userId);
      props.setProperty("password", password);
    }

    props.setProperty("CONNECTNODE", nodeNumber);

    con = DriverManager.getConnection( url, props );

    // enable transactions
    con.setAutoCommit(false);
    return con;
  } // connect

  public void disconnect() throws Exception
  {
 //   System.out.println();
 //   System.out.println("  Disconnect from '" + alias + "' database.");

    // makes all changes made since the previous commit/rollback permanent
    // and releases any database locks currrently held by the Connection.
    con.commit();

    // immediately disconnects from database and releases JDBC resources
    con.close();
  } // disconnect
} // Db

class JdbcException extends Exception
{
  Connection conn;

  public JdbcException(Exception e)
  {
    super(e.getMessage());
    conn = null;
  }

  public JdbcException(Exception e, Connection con)
  {
    super(e.getMessage());
    conn = con;
  }

  public void handle()
  {
    System.out.println(getMessage());
    System.out.println();

    if (conn != null)
    {
      try
      {
        System.out.println("--Rollback the transaction-----");
        conn.rollback();
        System.out.println("  Rollback done!");
      }
      catch (Exception e)
      {
      };
    }
  } // handle

  public void handleExpectedErr()
  {
    System.out.println();
    System.out.println(
      "**************** Expected Error ******************\n");
    System.out.println(getMessage());
    System.out.println(
      "**************************************************");
  } // handleExpectedError
} // JdbcException

