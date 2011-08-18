/*	
 *  @author:	yangshengcheng@gzcss.net
 * 	@description: use jmx protocol to query weblogic mbeans
 * 	@create: 2011.6 
 *  @version :20110729
 *  @modifiedInfo : release
 *  @update:20110810
 *  @update content: add initConnect2() method,addOption(t), addOption(c)
 */

import java.util.Properties;
import java.util.ResourceBundle;
import java.util.Set;
import java.util.Iterator;
import java.util.*;

import javax.naming.Context;

import javax.management.*;
import javax.management.MBeanServerConnection;
import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;
import javax.management.remote.JMXConnector;
import javax.management.remote.JMXConnectorFactory;
import javax.management.remote.JMXServiceURL;


//file
import java.io.*;

//参数处理
import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException; 
//
////jdom xml
import org.jdom.*;
import org.jdom.Element;
import org.jdom.input.*;

//时间处理
import java.text.SimpleDateFormat;

//处理返回类型为CompositeDataSupport的属性
import javax.management.openmbean.CompositeData;


public class wlsConnectRemote
{	
	   public static MBeanServerConnection connection;
	   public static JMXConnector connector;			   
	
	public static void main(String[] args)
	{
		Options opts = new Options();
		opts.addOption("h", false, "Print help for this application");
		opts.addOption("d", true, "the hostname or ip where the weblogic deploy");
		opts.addOption("p", true, "rmi port");
		opts.addOption("l", true, "list matching mbeans's attribute and method,all for all mbeans");
		opts.addOption("f",true, "the mbean xml file");
		opts.addOption("u",true, "weblogic console username");
		opts.addOption("w",true, "weblogic console user password");
		opts.addOption("t",true, "weblogic jndi type:domainruntime,runtime,edit");
		opts.addOption("c",true, "weblogic connect type: remote,native");
		
		
		BasicParser parser = null;
		CommandLine cl = null;
		String xml = "bhm_wls_mbean.xml";
		
		//String xml = null;
		
		try
		{
			parser = new BasicParser();
			cl = parser.parse(opts, args);
			if (cl.hasOption('h')) 
			{
				    HelpFormatter hf = new HelpFormatter();
				    hf.printHelp("OptionsTip", opts);
				    System.exit(0);
			} 
			else 
			{
			   	if(!cl.hasOption('p') || !cl.hasOption('u') || !cl.hasOption('w'))
			   	{
				    HelpFormatter hf = new HelpFormatter();
				    hf.printHelp("OptionsTip", opts);
			   		System.exit(0);		   			
			   	}
			   	
			   	if(cl.hasOption('f'))
			   	{
			   		xml =  cl.getOptionValue("f");
			   	}
			}
		}
		 catch(Exception e)
		 {
			 e.printStackTrace();
		 }	
		
		 //select connect type
		 if(!cl.hasOption('c'))
		 {
			 initConnect(cl);
		 }
		 else if(cl.getOptionValue("c").equals("remote"))
		 {
			 initConnect(cl);
		 }
		 else if(cl.getOptionValue("c").equals("native"))
		 {
			 initConnect2(cl);
		 }
		 else
		 {
			 initConnect2(cl);
		 }
		 
		 wlsConnectRemote wcr = new wlsConnectRemote();
		 
		if(cl.hasOption('l'))
		{	
			//navigator mbean
			try
			{
				wcr.listMbeanAttributeAndOperation(connection,cl);
				connector.close();  
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

		}
		else
		{
			//query and store mbean data
			String xmlFile  = wcr.getxmlfile(xml);
			String dataFile = wcr.getdatafile("weblogic_");
			
			try
			{
				wcr.bhmQuery(connection,xmlFile,dataFile);			
				connector.close();
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

				
		}
		 
	}
	
	
	// one instance should have only one connect
	public static void initConnect(CommandLine cl)
	{
		Hashtable<String,String> h = null;
		JMXServiceURL serviceURL = null;
		String hostname = "localhost";
		
		if(cl.hasOption('d'))
		{
			hostname = cl.getOptionValue("d");
		}
		
		
		String username = cl.getOptionValue("u");
		String password = cl.getOptionValue("w");
		
		int port = Integer.parseInt(cl.getOptionValue("p"));
		String protocol = "rmi";
		String jndiroot= new String("/jndi/iiop://" + hostname + ":" + port + "/");
		
		/* JNDI Names for WebLogic MBean Servers
		 * 1)Domain Runtime MBean Server -> weblogic.management.mbeanservers.domainruntime
		 * 2)Runtime MBean Server -> weblogic.management.mbeanservers.runtime
		 * 3)Edit MBean Server -> weblogic.management.mbeanservers.edit
		 */	
		
		String mserver = "weblogic.management.mbeanservers.";
		if(cl.hasOption('t'))
		{
			mserver += cl.getOptionValue("t");
		}
		else
		{
			mserver +="domainruntime";
		}
	
		try 
		{
			serviceURL = new JMXServiceURL(protocol, hostname, port,jndiroot + mserver);
		
			h = new Hashtable<String,String>();
			h.put(Context.SECURITY_PRINCIPAL, username);
			h.put(Context.SECURITY_CREDENTIALS, password);
		
			connector = JMXConnectorFactory.connect(serviceURL, h);
			connection = connector.getMBeanServerConnection();		
		}
		 catch(Exception e)
		 {
			 e.printStackTrace();
		 }
	}//initConnect
	
	// this connect base on wljmxclient.jar and wlclient.jar 
	public static void initConnect2(CommandLine cl)
	{
		Hashtable<String,String> h = null;
		JMXServiceURL serviceURL = null;
		String hostname = "localhost";
		
		if(cl.hasOption('d'))
		{
			hostname = cl.getOptionValue("d");
		}
		
		String username = cl.getOptionValue("u");
		String password = cl.getOptionValue("w");
		
		int port = Integer.parseInt(cl.getOptionValue("p"));
		String protocol = "t3";
		String jndiroot = "/jndi/";
		//String jndiroot= new String("/jndi/iiop://" + hostname + ":" + port + "/");
		
		/* JNDI Names for WebLogic MBean Servers
		 * 1)Domain Runtime MBean Server -> weblogic.management.mbeanservers.domainruntime
		 * 2)Runtime MBean Server -> weblogic.management.mbeanservers.runtime
		 * 3)Edit MBean Server -> weblogic.management.mbeanservers.edit
		 */	
		
		String mserver = "weblogic.management.mbeanservers.";
		if(cl.hasOption('t'))
		{
			mserver += cl.getOptionValue("t");
		}
		else
		{
			mserver +="domainruntime";
		}
	
		try 
		{
			serviceURL = new JMXServiceURL(protocol, hostname, port,jndiroot + mserver);
		
			h = new Hashtable<String,String>();
			h.put(Context.SECURITY_PRINCIPAL, username);
			h.put(Context.SECURITY_CREDENTIALS, password);
			h.put(JMXConnectorFactory.PROTOCOL_PROVIDER_PACKAGES,"weblogic.management.remote");
		
			connector = JMXConnectorFactory.connect(serviceURL, h);
			connection = connector.getMBeanServerConnection();		
		}
		 catch(Exception e)
		 {
			 e.printStackTrace();
		 }
	}//initConnect2
	
	public void listMbeanAttributeAndOperation(MBeanServerConnection mbsc,CommandLine cl)
	{
		//历遍相关的mbean及其属性
		String key = cl.getOptionValue("l");
     
		try
		{
			Set set = mbsc.queryMBeans(null, null);
		    if(key.equalsIgnoreCase("all") ) 
		    {
		    	int counter = 0; 
			      for (Iterator it = set.iterator(); it.hasNext();) 
			      {        
					  	ObjectInstance oi = (ObjectInstance) it.next();
					//System.out.println("\t" + oi.getObjectName());
					           	 
	
						  System.out.println("("+counter+ ")"+ " "+ oi.getObjectName());
						  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
						           		
						  //列举mbean属性
						  for(int i = 0;i < info.getAttributes().length;i++ )
						  {
						  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
						  }
						 //列举mbean操作
						  for(int i = 0;i < info.getOperations().length;i++ )
						  {
						  	System.out.println("Operation" + ":" +info.getOperations()[i].getName());
						  }	
						  
						  counter++;
					           			       
			     }			        		
		        		
		     } 
		     else
		        		
		     {
		        int counter = 0;			    
			      for (Iterator it = set.iterator(); it.hasNext();) 
			      {        
					  ObjectInstance oi = (ObjectInstance) it.next();
					//System.out.println("\t" + oi.getObjectName());
					           	 
					 // if(oi.getObjectName().toString().toLowerCase().indexOf(key) != -1) 
					  if(oi.getObjectName().toString().indexOf(key) != -1)
					 {
						  System.out.println("("+counter+ ")"+ " "+ oi.getObjectName());
						  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
						           		
						  //列举mbean属性
						  for(int i = 0;i < info.getAttributes().length;i++ )
						  {
						  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
						  }
						 //列举mbean操作
						  for(int i = 0;i < info.getOperations().length;i++ )
						  {
						  	System.out.println("operation" + ":" +info.getOperations()[i].getName());
						  }	
						  
						  counter++;					           			
					 }       
			     }
			} 
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	} //listMbeanAttributeAndOperation
	
	
	//将查询结果写入数据文件或输出到标准输出
	public  boolean flush(HashMap<Integer,HashMap<Object,Object>> hm,String dataFile) throws Exception
	{
		String ostype = this.getOsType();
		Set s = hm.keySet();
		if(dataFile == null || dataFile.equals(""))
		{
			for (Iterator it = s.iterator(); it.hasNext();) 
			{
				Object str = (Object)it.next();
				System.out.println(hm.get(str).get("timestamp")+"|"+hm.get(str).get("class")+"|"+hm.get(str).get("MetricName")+"|"+hm.get(str).get("instance")+"|"+hm.get(str).get("value")+"|"+ ostype);
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
				bw.write(hm.get(str).get("timestamp")+"|"+hm.get(str).get("class")+"|"+hm.get(str).get("MetricName")+"|"+hm.get(str).get("instance")+"|"+hm.get(str).get("value")+"|"+ ostype);
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
	
	public  String getFormatTime()throws Exception
	{
		Date now = new Date();
		SimpleDateFormat f = new SimpleDateFormat("yyyyMMddHHmmss");
		return f.format(now).toString();
	}//getFormatTime	
	
	public void bhmQuery(MBeanServerConnection mbsc,String xmlFile,String dataFile) throws Exception
	{
		// 获取mbean 描述文件中的mbean信息//
		
		//定义一个临时缓冲
		HashMap<Integer,HashMap<Object,Object>> tmp_hash = new HashMap<Integer,HashMap<Object,Object>>();
		List allChildren;
		Document doc;
		Element foo;
		SAXBuilder builder;
		String timestamp = this.getFormatTime();
		
		//读出xml内的mbean结构
		try
		{				
			builder = new SAXBuilder();  
			doc = builder.build(new File(xmlFile)); 
			foo = doc.getRootElement();  
			allChildren = foo.getChildren(); 
		//历遍mbeans到查询数据到临时缓冲
			for(int i =0;i < allChildren.size();i++)
			{
				HashMap<Object,Object> temp = new HashMap<Object,Object>();
				
				String arrType = ((Element)allChildren.get(i)).getChild("type").getText();				
				List ls = ((Element)allChildren.get(i)).getChild("ObjectNames").getChildren("ObjectName");				
				
				//ObjectName obj = new ObjectName(((Element)allChildren.get(i)).getChild("ObjectName").getText());
				
				double tempvalue = 0;
				int tempvalue1 = 0;
				String result = "";
				
				for(int k = 0; k < ls.size(); k++ )
				{
					String att = ((Element)allChildren.get(i)).getChild("Attribute").getText();
					
					ObjectName obj = new ObjectName(((Element)ls.get(k)).getText());
					MBeanInfo info = mbsc.getMBeanInfo(obj);
					//for test
					//System.out.println(obj);
					
					if(! MbeanAttributeExists(info,att))
					{
						continue;
					}

					CompositeData cd;
						
					temp.put("timestamp",timestamp);
					temp.put("class",((Element)allChildren.get(i)).getChild("class").getText());
					
					if(obj.getKeyProperty("Location") != null)
					{
						temp.put("instance",obj.getKeyProperty("Location"));
					}
					else
					{
						temp.put("instance",((Element)allChildren.get(i)).getChild("instance").getText());
					}
					
					temp.put("MetricName",((Element)allChildren.get(i)).getChild("MetricName").getText());
					
					
	//				if(obj.toString().indexOf("MemoryPool") > -1 )				
					if(mbsc.getAttribute(obj,att).getClass().getName().indexOf("CompositeData") != -1)
					{
						cd = (CompositeData)mbsc.getAttribute(obj,att);
						
						//获取到CompositeData类型中的key
						String ckey = ((Element)allChildren.get(i)).getChild("key").getText();
						temp.put("value",cd.get(ckey).toString());
	//					System.out.println(cd.get("used").toString());
					}
					else
					{
						//summation	for doule or int 
						if(arrType.equals("double"))
						{
							//System.out.println(mbsc.getAttribute(obj,att).toString());						
							tempvalue = tempvalue + Double.parseDouble(mbsc.getAttribute(obj,att).toString());	
						}
						else if(arrType.equals("int"))
						{
							tempvalue1 = tempvalue1 + Integer.parseInt(mbsc.getAttribute(obj,att).toString());
						}
						else
						{
							result = mbsc.getAttribute(obj,att).toString();
						}
					}
					
					if(k == ls.size() -1)
					{
						if(arrType.equals("double"))
						{
						
							temp.put("value",tempvalue);
						}
						else if(arrType.equals("int"))
						{
							temp.put("value",tempvalue1);
						}
						else
						{
							temp.put("value",result);
						}
					}
					
					
				}
				
				tmp_hash.put(i,temp);
					
			} 		
	
			//缓冲写入数据文件					
			this.flush(tmp_hash,dataFile);
			
			//for test
			//this.flush(tmp_hash,"");
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	} //bhmQuery
	
	
	public void resetMbeanCouter(MBeanServerConnection mbsc,String objString) throws Exception
	{
		//完成本次查询后，reset GlobalRequestProcessor 的计数值,使得每次取值为轮询间隔累计值
		ObjectName obj = new ObjectName(objString);
		
		//System.out.println("now reset mbean couter "+obj);
		try
		{
			mbsc.invoke(obj,"resetCounters",null,null);
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
//		System.out.println(obj);
	} //resetMbeanCouter
	
	
	public String[] findMbeanObjs(String key,String xmlFile)
	{
		//关键字包含最多不能超过100个mbean实例
		String[] array = new String[100];
		int index = 0;
		List allChildren;
		Document doc;
		Element foo;
		SAXBuilder builder;
		
		try
		{				
			builder = new SAXBuilder();  
			doc = builder.build(new File(xmlFile)); 
			foo = doc.getRootElement();  
			allChildren = foo.getChildren(); 
		//历遍mbeans到查询数据到临时缓冲
			for(int i =0;i < allChildren.size();i++)
			{
				if(((Element)allChildren.get(i)).getChild("ObjectName").getText().indexOf(key) > -1)
				{
					array[index] = ((Element)allChildren.get(i)).getChild("ObjectName").getText();
					index++;
					
					if(index > 99)
					{
						break;
					}
				}
			}
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		return array;
		
	}//findMbeanObjs
	
	public String getxmlfile(String xmlFileName)
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
				path = "C:\\Documents and Settings\\All Users\\Application Data\\HP\\HP BTO Software\\bin\\instrumentation\\";
			}
			else
			{
				path = path + File.separator +"bin"+File.separator+"instrumentation"+File.separator;
			}
		}
		else
		{
			path = "/var/opt/OV/bin/instrumentation/";
		}
		
		if((new File(path)).isDirectory())
		{
			return path+ File.separator +xmlFileName;
		}
		else
		{
			return "";
		}
		
	}//getxmlfile
	
	public String getdatafile(String prefix)
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
	
	public boolean MbeanExists(MBeanServerConnection mbsc,ObjectName obj)
	{
		boolean b = true;
		
		if(obj == null || obj.toString().equals(""))
		{
			return false;
		}
		
		try 
		{
			b = mbsc.isRegistered(obj);
		}
		catch (IOException e)
		{
			System.out.println("obj not found");
			e.printStackTrace();
		}
		
		return b;
		
	}//MbeanExists
	
	public boolean MbeanAttributeExists(MBeanInfo info,String attr)
	{
		  for(int i = 0;i < info.getAttributes().length;i++ )
		  {
		  	//System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
			  if(info.getAttributes()[i].getName().equals(attr))
			  {
				  return true;
			  }
		  }
		  
		  return false;
	}//MbeanAttributeExists
	
	//获取环境变量
	public String getEnv(String name) throws Exception
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
	
	public String getOsType()
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
	}	
}