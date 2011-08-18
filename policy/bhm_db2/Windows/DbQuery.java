//***************************************************************************
// author: yangshengcheng@gzcss.net
// SOURCE FILE NAME: DbQuery.java
//
// connect to db2 databases
//
// Classes used from Util.java are:
//         Db
//         JdbcException
//
// OUTPUT FILE: DbQuery.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//**************************************************************************/

import java.sql.*;
import java.io.*;
import java.util.*;
import java.util.List;
import java.util.regex.*;

//jdom 
import org.jdom.*;
import org.jdom.Element;
import org.jdom.input.*;

//time format
import java.text.SimpleDateFormat;

//file
import java.io.*;


class DbQuery
{
  public static void main(String argv[])
  {
	 Connection conn = null ;
	 
		//a hashmap for global class,which has only 1 instance
     HashMap<String,String> global = new HashMap<String,String>();
     
     //a hashmap for not global class,which has more than 1 instance
     HashMap<String,HashMap<Object,Object>> inst = new HashMap<String,HashMap<Object,Object>>();
     
     //temp HashMap for inst
     HashMap<Object,Object> temp = new HashMap<Object,Object>();
     
     DbQuery dbq = new DbQuery();
     
     String ostype = "MSWin32";
     //String ostype = dbp.getostype();
	  
    try
    {	
      Db  db = new Db(argv);
		
      //default connect to the 'sample' database
      db.connect();
      conn = db.con;
      
      if(conn != null)
      {				
	  		//parser xml and get metrics		
    	     String ExSql = null;
    	     String tmp = null;
    	      try
    	      {
    	    	  tmp = dbq.getEnv("OvDataDir").trim();
    	    	  if(tmp.equals("") || tmp == null)
    	    	  {
    	    		  ExSql = db.SqlFile;
    	    		  //ExSql = "C:\\Documents and Settings\\All Users\\Application Data\\HP\\HP BTO Software\\bin\\instrumentation\\" + db.SqlFile ;
    	    	  }
    	    	  else
    	    	  {
    	    		  ExSql = tmp + File.separator + "bin\\instrumentation" + File.separator +  db.SqlFile;
    	    	  }
    	      }
    	      catch(Exception e)
    	      {
    	    	  System.out.println("instrumentation dir get fail");
    	    	  e.printStackTrace();
    	      }
    	      
    	      boolean exists = (new File(ExSql)).exists();
    			
    	      if(!exists)
    	      {
    	    	  System.out.println("ERROR,external xml file is not exists");
    				
    				//destruct db object
    	    	  db = null;
    	    	  System.exit(1);			
    			}
    	  
          //open,parser xml file 
  		try
		{
  			//db2 data store file
	      	boolean file_exists_mark = false;
//	      	FileWriter fw = null;
//	      	BufferedWriter bw = null;
	      	File db2_data_file = null;
	    	  
	  	  	String dataFile = dbq.getdataFile("db2");
	  	  	if(! dataFile.equals(""))
	  	  	{
	  	  			file_exists_mark = true;
	  	  			try
	  	  			{
	  	  				db2_data_file = new File(dataFile);												
	  	  			}
	  	  			catch(Exception e)
	  	  			{
	  	  				e.printStackTrace();
	  	  			}
	  	  	}
	  	  	
  	  	
			SAXBuilder builder = new SAXBuilder();  
			Document doc = builder.build(new File(ExSql)); 
			Element foo = doc.getRootElement();  
			List allChildren = foo.getChildren();
			String timestamp = dbq.getFormatTime();
			String db2_instance = "";
			
			
			for(int i =0;i < allChildren.size();i++)
			{
				
				String sql = ((Element)allChildren.get(i)).getChild("sql").getText();
				String c = ((Element)allChildren.get(i)).getChild("class").getText();
				String db2_class = ((Element)allChildren.get(i)).getChild("class").getText();				
				String db2_index = ((Element)allChildren.get(i)).getChild("index").getText();

				
				
				//System.out.println(sql);
				
				Statement st = conn.createStatement();
				ResultSet rs = st.executeQuery(sql);
				
				List ls = ((Element)allChildren.get(i)).getChild("MetricNames").getChildren("MetricName");
				List ls2 = ((Element)allChildren.get(i)).getChild("instances").getChildren("instance");
	
				//System.out.println(((Element)allChildren.get(i)).getChild("index").getText());
				if(db2_index.equals("1"))
				{

					while(rs.next())
					{
						db2_instance = rs.getString("INST_NAME").trim()+ "/"+rs.getString("DB_NAME").trim();
						for(int j=0;j<ls.size();j++)
						{
							if(file_exists_mark)
							{
								//System.out.println("");
								FileWriter fw = new FileWriter(db2_data_file,true);
								BufferedWriter bw = new BufferedWriter(fw);
								bw.write(timestamp+"|"+ db2_class + "|"+((Element)ls.get(j)).getText() + "|" + rs.getString(((Element)ls.get(j)).getText()).trim()+ "|" + db2_instance+ "|"+ ostype);
								bw.newLine();
								bw.close();
								fw.close();
							}
							else
							{
								System.out.println(timestamp+"|"+ db2_class + "|"+((Element)ls.get(j)).getText() + "|" + rs.getString(((Element)ls.get(j)).getText()).trim()+ "|" + db2_instance+ "|"+ ostype);
							}
						}
					}
				}
				else if(c.equals("DB2_GLOBAL"))
				{
					while(rs.next())
					{
						
						for(int j=0;j<ls.size();j++)
						{							
							//System.out.println(((Element)ls.get(j)).getText());
							//System.out.println(rs.getString(((Element)ls.get(j)).getText()).trim());
							//System.out.println(((Element)ls.get(j)).getText()+"->"+rs.getString(((Element)ls.get(j)).getText()).trim());
							//global.put(((Element)ls.get(j)).getText(),rs.getString(((Element)ls.get(j)).getText()));
							if(file_exists_mark)
							{
								//System.out.println("write info to file");
								FileWriter fw = new FileWriter(db2_data_file,true);
								BufferedWriter bw = new BufferedWriter(fw);
								bw.write(timestamp+"|"+ db2_class + "|"+((Element)ls.get(j)).getText() + "|" + rs.getString(((Element)ls.get(j)).getText()).trim()+ "|" + db2_instance+ "|"+ ostype);
								bw.newLine();
								bw.close();
								fw.close();
							}
							else
							{
								System.out.println(timestamp+"|"+ db2_class + "|"+((Element)ls.get(j)).getText() + "|" + rs.getString(((Element)ls.get(j)).getText()).trim()+ "|" + db2_instance+ "|"+ ostype);
							}
							
						}
					}
				}
				else if(ls2.size() == 2 )
				{					
					while(rs.next())
					{
						String instanceName = rs.getString(((Element)ls2.get(1)).getText()).trim();
						for(int j=0;j<ls.size();j++)
						{	
							String instname_temp = db2_instance + "/" + instanceName;
							String metricName = ((Element)ls.get(j)).getText().trim();
							String Value = rs.getString(metricName).trim();
							//System.out.println(((Element)ls.get(j)).getText());
//							System.out.println(instanceName + "->" + ((Element)ls.get(j)).getText()+"->" + rs.getString(((Element)ls.get(j)).getText()).trim());
//							temp.put(((Element)ls.get(j)).getText(),rs.getString(((Element)ls.get(j)).getText()));								
//							inst.put(instanceName,temp);
							if(file_exists_mark)
							{
								//System.out.println("write info to file");
								FileWriter fw = new FileWriter(db2_data_file,true);
								BufferedWriter bw = new BufferedWriter(fw);
								bw.write(timestamp + "|" + db2_class + "|" + metricName+"|"+Value+"|"+ instname_temp+"|"+ostype);
								bw.newLine();
								bw.close();
								fw.close();
							}
							else
							{
								System.out.println(timestamp + "|" + db2_class + "|" + metricName+"|"+Value+"|"+ instname_temp+"|"+ostype);
							}
						}
					}
				}
				else
				{
					System.out.println("not handle function for more than 3 instance");
					System.exit(1);
				}
			}
			
//			if(! file_exists_mark)
//			{
//				bw.close();
//				fw.close();
//			}
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
      }     
      // disconnect from the 'sample' database
      db.disconnect();
      
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
    
//    try
//    {
//    	dbq.flush(inst,global,"");
//    }
//    catch(Exception e)
//    {
//    	e.printStackTrace();
//    }
    
  } // end of main
  
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
	}// end of getEnv
	
	private boolean flush(HashMap<String,HashMap<Object,Object>> inst,HashMap<String,String> global,String dataFile) throws Exception
	{
		
		String timestamp = this.getFormatTime();
		String ostype = "MSWin32";
		
		if(dataFile == null || dataFile.equals(""))
		{
			Set gl = global.keySet();
			
			for(Iterator it1 = gl.iterator(); it1.hasNext();)
			{
				String str1 = (String)it1.next();
				System.out.println(timestamp + "|"+"class"+ "|" + str1 + "|" +global.get(str1) + "|" + ostype);
			}
			
			Set in = inst.keySet();
			for (Iterator it2 = in.iterator(); it2.hasNext();) 
			{
				String str = (String)it2.next();
				Set tmp = inst.get(str).keySet();
				for(Iterator i =tmp.iterator();i.hasNext();)
				{
					Object obj = (Object)i.next();
					System.out.println(timestamp+"|"+"class"+ "|" + obj +"|"+ str +"|"+inst.get(str).get(obj)+"|"+ ostype);
				}
				
			}
		}
		
		return true;
	}//flush
	
	public  String getFormatTime()throws Exception
	{
		java.util.Date now = new java.util.Date();
		SimpleDateFormat f = new SimpleDateFormat("yyyyMMddHHmmss");
		return f.format(now).toString();
	}//getFormatTime
	
	private String getdataFile(String prefix)
	{
		//¼ì²éovdatadirÄ¿Â¼
		String path = "";
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
		
		if((new File(path)).isDirectory())
		{
			return path+this.getFileName(prefix);
		}
		else
		{
			return "";
		}
		
	}// end of getdataFile
	
	
	public  String getFileName(String prefix)
	{
		java.util.Date  now = new java.util.Date();
		SimpleDateFormat f = new SimpleDateFormat("HHmm");
		return prefix + "_"+f.format(now).toString()+".csv";
	}//getFileName
	
	
} // DbQuery

