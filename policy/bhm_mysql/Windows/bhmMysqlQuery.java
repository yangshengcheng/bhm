/*	
 *  @author:	yangshengcheng@gzcss.net
 * 	@description: use connector/J connect mysql and query monitor data
 * 	@create: 2011.8.7
 *  @version :20110807
 *  @modifiedInfo : release
 */

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.SQLException;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.text.DecimalFormat;

import java.io.*;
import java.util.*;

import java.text.SimpleDateFormat;

//arguments manage
import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException; 

public class bhmMysqlQuery
{
	  private Connection dbConnection = null;
	  private Statement selectPro = null; 
	 // private Statement updatePro = null; 
	  private ResultSet dbResultSet = null; 
	    
	  private String driverName;
	  private String dbHost;
	  private String dbPort;
	  private String dbName;
	  private String dbUserName;
	  private String dbPassword;
	  private String enCoding; 
	  
	  public static void main(String[] args)
	  {
		  Options opts = null;
		  BasicParser parser = null;
		  CommandLine cl = null;
		  
		  try
		  {
			opts = new Options();
		   opts.addOption("h", false, "Print help for this application");
		   opts.addOption("d", true, "mysql hostname or ip");
		   opts.addOption("p", true, "mysql port");
		   opts.addOption("u", true, "mysql username");
		   opts.addOption("w",true, "password");
		   
		   
		   parser = new BasicParser();
		   cl = parser.parse(opts, args);
		  }
		  catch(Exception e)
		  {
			  e.printStackTrace();
		  }
		   
		   bhmMysqlQuery bmq = new bhmMysqlQuery(cl,opts);
		   
		   if(bmq.connectInit())
		   {
			   //ArrayList<String> fieldsList = new ArrayList<String>();
			   //fieldsList.add("Variable_name");
			   //fieldsList.add("Value");

			   String sql1 = "show global status where Variable_name in ('Threads_created','Threads_connected','Threads_running','Connections','Open_tables','Opened_tables','Key_reads','Key_writes','Key_read_requests','Key_write_requests','Qcache_hits','Qcache_inserts','Table_locks_immediate','Table_locks_waited','Innodb_buffer_pool_reads','Innodb_buffer_pool_read_requests','Table_locks_waited')";
			   String sql2 = "show  global variables where Variable_name in ('table_cache')";
			   
			   HashMap<String,Object> hm = bmq.dbSelect(sql1);
			   HashMap<String,Object> hm1 =  bmq.dbSelect(sql2);
			   
			   if(null != hm1)
			   {
				   hm.putAll(hm1);
			   }
			   
			   HashMap<String,Object> hm2 = bmq.caculate(hm);
			   
			   String datafile = bmq.getdatafile("mysql_");
			   bmq.flush(hm2,datafile);
			   bmq.closeDatabase();
		   }
		   
		   
	  }
	  
	  
	  public bhmMysqlQuery(CommandLine cl,Options opts)
	  {
		   if (cl.hasOption('h')) 
		   {
			    HelpFormatter hf = new HelpFormatter();
			    hf.printHelp("OptionsTip", opts);
			    System.exit(0);
		   } 

		   if(! cl.hasOption('p'))
		   {
		   		System.out.println("use -p port appoint the mysql port\n");
		   		System.exit(0);		   			
		   }
		   else
		   {
			   dbPort =  cl.getOptionValue("p");
		   }
		   
		   if(cl.hasOption('d'))
		   {
			   dbHost = cl.getOptionValue("d");
		   }
		   else
		   {
			   dbHost="localhost";
		   }
		   
		   if(cl.hasOption('u'))
		   {
			   dbUserName=cl.getOptionValue("u");
		   }
		   else
		   {
			   dbUserName="mysql";
		   }
		   
		   if(cl.hasOption('w'))
		   {
			   dbPassword=cl.getOptionValue("w");
		   }
		   else
		   {
			   dbPassword="";
		   }
		   
		   	dbName = "mysql";
	        driverName = "com.mysql.jdbc.Driver";
	        enCoding = "?useUnicode=true&characterEncoding=utf8&autoReconnect=true";
	        
	    }//end bhmMysqlQuery(...)
	  
	  
	  public boolean connectInit()
	  {
	        StringBuilder urlTem = new StringBuilder();
	        urlTem.append("jdbc:mysql://");
	        urlTem.append(dbHost);
	        urlTem.append(":");
	        urlTem.append(dbPort);
	        urlTem.append("/");
	        urlTem.append(dbName);
	        urlTem.append(enCoding);
	        String url = urlTem.toString();
	        try
	        {
	            Class.forName(driverName).newInstance();
	            dbConnection = DriverManager.getConnection(url, dbUserName, dbPassword);
	            return true;
	        }
	        catch(Exception e)
	        {
	            //System.err.println("mysql  connect fail！");
	            System.out.println("url = " + url);
	            e.printStackTrace();
	            return false;
	        }
	    }// end connectInit()
	  
	  public HashMap<String,Object> dbSelect(String selectSql)
	  {
	        //ArrayList<Map> selectResult = new ArrayList<Map>();
	        HashMap<String, Object> recordInfo = new HashMap<String, Object>();;
	        try{
	            selectPro = dbConnection.createStatement();
	            dbResultSet = selectPro.executeQuery(selectSql);
	            while(dbResultSet.next())
	            {	                
	                //selectResult.add(recordInfo);
	            	//System.out.println(dbResultSet.getString("Variable_name")+" "+dbResultSet.getString("Value"));
	            	recordInfo.put(dbResultSet.getString("Variable_name"),dbResultSet.getString("Value"));
	            }
	            dbResultSet.close(); 
	            selectPro.close(); 
	        }
	        catch(Exception e)
	        {
	            //System.out.println("select operation fail");
	            System.out.println("Sql = " + selectSql);
	            e.printStackTrace();
	        }
	        
	        return recordInfo;
	   }//end dbSelect
	  
	  public boolean closeDatabase()
	  {
	        try
	        {
	            if(dbConnection != null)
	            {
	                dbConnection.close();
	            }
	            return true;
	        }
	        catch (Exception e)
	        {
	            e.printStackTrace();
	            return false;
	        }
	   }//end closeDatabase()
	  
	  private  boolean flush(HashMap<String,Object> hm,String dataFile) 
		{
			String ostype = this.getOsType();
			String ts = this.getFormatTime();
			Set s = hm.keySet();
			if(dataFile == null || dataFile.equals(""))
			{
				for (Iterator it = s.iterator(); it.hasNext();) 
				{
					Object str = (Object)it.next();
					System.out.println(ts +"|"+ "MYSQL_GLOBAL" +"|"+ str +"|"+"NULL"+"|"+hm.get(str)+"|"+ ostype);
				}
				return false;
			}
			
			try 
			{
				File file = new File(dataFile);
				FileWriter fw = new FileWriter(file,true);
				BufferedWriter bw = new BufferedWriter(fw);
				
				for (Iterator it = s.iterator(); it.hasNext();) 
				{
					Object str = (Object)it.next();
					//System.out.println(hm.get(str).get("timestamp")+"|"+hm.get(str).get("class")+"|"+hm.get(str).get("MetricName")+"|"+hm.get(str).get("instance")+"|"+hm.get(str).get("value")+"|"+ ostype);
					bw.write(ts +"|"+ "MYSQL_GLOBAL" +"|"+ str +"|"+"NULL"+"|"+hm.get(str)+"|"+ ostype);
					bw.newLine();
				}
				bw.close();
				fw.close();
				
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}
			
			return true;
			
		} //flush
	  
	  private String getOsType()
	  {
			if(System.getProperty("os.name").toLowerCase().indexOf("win") > -1)
			{
				return "MSWin32";
			}
			else if(System.getProperty("os.name").toLowerCase().indexOf("hpux")> -1)
			{
				return "HP-UX";
			}
			else
			{
				return System.getProperty("os.name");
			}
		}//getOsType
	  
		private String getdatafile(String prefix)
		{
			//检查ovdatadir目录
			String path = "";
			if(this.getOsType().indexOf("MSWin32") > -1)
			{
				try
				{
					path=this.getEnv("OvDataDir").trim();
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
				
				if(path == null || path.equals(""))
				{
					path = "C:\\Documents and Settings\\All Users\\Application Data\\HP\\HP BTO Software\\bhm\\dsi\\";
				}
				else
				{
					path = path + File.separator +"bhm"+File.separator+"dsi"+File.separator;
				}
			
			}
			else
			{
				path = "/var/opt/OV/bhm/dsi/";
			}
			
			if((new File(path)).isDirectory())
			{
				return path+ File.separator + this.getFileName(prefix);
			}
			else
			{
				return "";
			}
			
		} //getdataFile
		
		
		public  String getFileName(String prefix)
		{
			Date now = new Date();
			SimpleDateFormat f = new SimpleDateFormat("HHmm");
			return prefix +f.format(now).toString()+".csv";
		}//getFileName
		
		public  String getFormatTime()
		{
			Date now = new Date();
			SimpleDateFormat f = new SimpleDateFormat("yyyyMMddHHmmss");
			return f.format(now).toString();
		}//getFormatTime
		
		
		//metrics caculate
		public HashMap<String,Object> caculate(HashMap<String,Object> hm)
		{
			HashMap<String,Object> rezult = new HashMap<String,Object>();
			
			//Threads_connected
			rezult.put("Threads_connected",hm.get("Threads_connected"));
			//Threads_running
			rezult.put("Threads_running",hm.get("Threads_running"));
			//Table_cache_util
			if(hm.containsKey("Open_tables") && hm.containsKey("table_cache"))
			{
				rezult.put("Table_cache_util", new DecimalFormat( ".00" ).format(100 * (Double.valueOf(hm.get("Open_tables").toString()).doubleValue() / Double.valueOf(hm.get("table_cache").toString()).doubleValue())));
			}
			else
			{
				rezult.put("Table_cache_util",-1);
			}
			
			//Opened_tables
			rezult.put("Opened_tables",hm.get("Opened_tables"));
			
			//key_buffer_read_hits
			if(hm.containsKey("Key_reads") && hm.containsKey("Key_read_requests"))
			{
				if(hm.get("Key_read_requests").toString().equals("0"))
				{
					rezult.put("key_buffer_read_hits",100);
				}
				else
				{
					rezult.put("key_buffer_read_hits", new DecimalFormat( ".00" ).format(100 * (1 - (Double.valueOf(hm.get("Key_reads").toString()).doubleValue() / Double.valueOf(hm.get("Key_read_requests").toString()).doubleValue()))));
				}
			}
			else
			{
				rezult.put("key_buffer_read_hits",-1);
			}
			
			//key_buffer_write_hits
			if(hm.containsKey("Key_writes") && hm.containsKey("Key_write_requests"))
			{
				if(hm.get("Key_write_requests").toString().equals("0"))
				{
					rezult.put("key_buffer_write_hits",100);
				}
				else
				{
					rezult.put("key_buffer_write_hits", new DecimalFormat( ".00" ).format(100 * (1 - (Double.valueOf(hm.get("Key_writes").toString()).doubleValue() / Double.valueOf(hm.get("Key_write_requests").toString()).doubleValue()))));
				}
			}
			else
			{
				rezult.put("key_buffer_write_hits",-1);
			}
			
			//Query_cache_hits
			if(hm.containsKey("Qcache_hits") && hm.containsKey("Qcache_inserts"))
			{
				if((Integer.parseInt(hm.get("Qcache_hits").toString()) + Integer.parseInt(hm.get("Qcache_inserts").toString())) == 0)
				{
					rezult.put("Query_cache_hits",100);
				}
				else
				{
					rezult.put("Query_cache_hits", new DecimalFormat( ".00" ).format(100 * (Double.valueOf(hm.get("Qcache_hits").toString()).doubleValue() / (Double.valueOf(hm.get("Qcache_inserts").toString()).doubleValue() + Double.valueOf(hm.get("Qcache_hits").toString()).doubleValue()))));
				}
			}
			else
			{
				rezult.put("Query_cache_hits",-1);
			}
			
			//Thread_cache_hits
			if(hm.containsKey("Threads_created") && hm.containsKey("Connections"))
			{
				if(hm.get("Connections").toString().equals("0"))
				{
					rezult.put("Thread_cache_hits",100);
				}
				else
				{
					rezult.put("Thread_cache_hits", new DecimalFormat( ".00" ).format(100 * (Double.valueOf(hm.get("Threads_created").toString()).doubleValue() / Double.valueOf(hm.get("Connections").toString()).doubleValue())));
				}
			}
			else
			{
				rezult.put("Thread_cache_hits",-1);
			}
			
			//innodb_buffer_read_hit
			if(hm.containsKey("Innodb_buffer_pool_reads") && hm.containsKey("Innodb_buffer_pool_read_requests"))
			{
				if(hm.get("Innodb_buffer_pool_read_requests").toString().equals("0"))
				{
					rezult.put("innodb_buffer_read_hits",100);
				}
				else
				{
					rezult.put("innodb_buffer_read_hits", new DecimalFormat( ".00" ).format(100 * (1 - (Double.valueOf(hm.get("Innodb_buffer_pool_reads").toString()).doubleValue() / Double.valueOf(hm.get("Innodb_buffer_pool_read_requests").toString()).doubleValue()))));
				}
			}
			else
			{
				rezult.put("innodb_buffer_read_hits",-1);
			}
			
			//Table_lock_hits
			if(hm.containsKey("Table_locks_immediate") && hm.containsKey("Table_locks_waited"))
			{
				if((Integer.parseInt(hm.get("Table_locks_immediate").toString()) + Integer.parseInt(hm.get("Table_locks_waited").toString())) == 0)
				{
					rezult.put("Table_lock_hits",100);
				}
				else
				{
					rezult.put("Table_lock_hits", new DecimalFormat( ".00" ).format(100 * (Double.valueOf(hm.get("Table_locks_immediate").toString()).doubleValue() / (Double.valueOf(hm.get("Table_locks_immediate").toString()).doubleValue() + Double.valueOf(hm.get("Table_locks_waited").toString()).doubleValue()))));
				}
			}
			else
			{
				rezult.put("Table_lock_hits",-1);
			}
			
			//Table_locks_waited
			rezult.put("Table_locks_waited",hm.get("Table_locks_waited"));
			
			
			return rezult;
		}
		
		//获取环境变量
		private String getEnv(String name) throws Exception
		{
			Process p = null;
			String value = "";
			String key;
			try 
			{
				p = Runtime.getRuntime().exec("cmd /c set");
				BufferedReader br = new BufferedReader(new InputStreamReader(p.getInputStream()));
				String l;
				while((l = br.readLine()) != null )
				{
					int i = l.indexOf("=");
					if(i > -1)
					{
						 key = l.substring(0,i);
						 if(key.indexOf(name) > -1 )
						 {
						 	value = l.substring(i+1);
						 	break;
						 }
						 else
						 {
						 	continue;
						 }
					}
				}
			}
			catch(Exception e)
			{
				e.printStackTrace();
			}
			
			return value;
		} //getEnv
	  
	  	
}