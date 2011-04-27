/**
 *desc: query tomcat's mbean value and store for bhm; 
 *author: yangshengcheng@gzcss.net
 *date : 2011.4
 *
 *
 */
 
 
package jmx;
import java.lang.*;
import java.util.*;   
import javax.management.AttributeList;
import javax.management.Attribute; 
import javax.management.MBeanAttributeInfo; 
import javax.management.MBeanInfo;   
import javax.management.MBeanServerConnection;   
import javax.management.MBeanServerInvocationHandler;   
import javax.management.ObjectInstance;   
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

//jdom xml
import org.jdom.*;
import org.jdom.Element;
import org.jdom.input.*;

//时间处理
import java.text.SimpleDateFormat;

 
public class TomcatMbeanQuery {   
    public static void main(String[] args) throws Exception 
    {   

		   Options opts = new Options();
		   opts.addOption("h", false, "Print help for this application");
		   opts.addOption("p", true, "rmi port");
		   opts.addOption("l", true, "list matching mbeans's attribute and method,all for all mbeans");
		   opts.addOption("f",true, "the mbean describe file");
		   
		   BasicParser parser = new BasicParser();
		   CommandLine cl = parser.parse(opts, args);
		   
		   if (cl.hasOption('h')) 
		   {
			    HelpFormatter hf = new HelpFormatter();
			    hf.printHelp("OptionsTip", opts);
			    System.exit(0);
		   } 
		   	else 
		   {
		   	if(! cl.hasOption('p'))
		   	{
		   		System.out.println("use -p port appoint the rmi port\n");
		   		System.exit(0);		   			
		   	}
		   	
		   	//connect jmx rmi
			JMXServiceURL url = new JMXServiceURL("service:jmx:rmi:///jndi/rmi://localhost:"+ cl.getOptionValue("p") +"/jmxrmi");      
			JMXConnector jmxc = JMXConnectorFactory.connect(url, null);
			MBeanServerConnection mbsc = jmxc.getMBeanServerConnection();  

		   	
		   	//列举指定关键字的mbean属性
			if(cl.hasOption('l'))
			{			   		
			   	
				//历遍相关的mbean及其属性
				String key = cl.getOptionValue("l");
		     
			    Set set = mbsc.queryMBeans(null, null); 
			    if(key.equalsIgnoreCase("all") ) 
			    {
				      for (Iterator it = set.iterator(); it.hasNext();) 
				      {        
						  	ObjectInstance oi = (ObjectInstance) it.next();
						//System.out.println("\t" + oi.getObjectName());
						           	 

							  System.out.println(oi.getObjectName()+ "\n");
							  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
							           		
							  //列举mbean属性
							  for(int i = 0;i < info.getAttributes().length;i++ )
							  {
							  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName() + "\n");
							  }
							 //列举mbean操作
							  for(int i = 0;i < info.getOperations().length;i++ )
							  {
							  	System.out.println("operation" + ":" +info.getOperations()[i].getName() + "\n");
							  }		           		
						           			       
				     }			        		
			        		
			     } 
			     else
			        		
			     {
			        			    
				      for (Iterator it = set.iterator(); it.hasNext();) 
				      {        
						  ObjectInstance oi = (ObjectInstance) it.next();
						//System.out.println("\t" + oi.getObjectName());
						           	 
						  if(oi.getObjectName().toString().toLowerCase().indexOf(key) != -1)
						 {
							  System.out.println(oi.getObjectName()+ "\n");
							  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
							           		
							  //列举mbean属性
							  for(int i = 0;i < info.getAttributes().length;i++ )
							  {
							  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName() + "\n");
							  }
							 //列举mbean操作
							  for(int i = 0;i < info.getOperations().length;i++ )
							  {
							  	System.out.println("operation" + ":" +info.getOperations()[i].getName() + "\n");
							  }		           		
						           			
						 }       
				     }
				} 
			    
			    jmxc.close();  
			}
			else
			{
				if(!cl.hasOption('f'))
				{
		   			System.out.println("use -f filename appoint the mbean describe file\n");
		   			System.exit(0);						
				}
				
				String xml_file_name = cl.getOptionValue("f");
				//String xmldir;
				String xmlFile;
				String tmp = getEnv("OvDataDir");

				if(tmp.equals("") || tmp == null)
				{
					xmlFile = "C:\\Documents and Settings\\All Users\\Application Data\\HP\\HP BTO Software\\bin\\instrumentation\\" + xml_file_name ;
				}
				else
				{
					if(separator(tmp))
					{
						xmlFile = tmp + "\bin\\instrumentation\\" + xml_file_name;	
					}
					else
					{
						xmlFile = tmp + "\\bin\\instrumentation\\" + xml_file_name ;	
					}
				}
				
				boolean exists = (new File(xml_file_name)).exists();
				if(!exists)
				{
					System.out.println("mbean describe file is not exists\n");
					System.exit(1);
				}
				
				
				
				// 获取mbean 描述文件中的mbean信息//
				
				//定义一个临时缓冲
				HashMap<Integer,HashMap<Object,Object>> tmp_hash = new HashMap<Integer,HashMap<Object,Object>>();
				List allChildren;
				Document doc;
				Element foo;
				SAXBuilder builder;
				String timestamp = getFormatTime();
				
				//读出xml内的mbean结构
				try
				{				
					builder = new SAXBuilder();  
					doc = builder.build(new File(xml_file_name)); 
					foo = doc.getRootElement();  
					allChildren = foo.getChildren(); 
				//历遍mbeans到查询数据到临时缓冲
					for(int i =0;i < allChildren.size();i++)
					{
						HashMap<Object,Object> temp = new HashMap<Object,Object>();
							
						ObjectName obj = new ObjectName(((Element)allChildren.get(i)).getChild("ObjectName").getText());
						String att = ((Element)allChildren.get(i)).getChild("Attribute").getText();
						
						temp.put("value",mbsc.getAttribute(obj,att));
						temp.put("timestamp",timestamp);
						temp.put("class",((Element)allChildren.get(i)).getChild("class").getText());
						temp.put("instance",((Element)allChildren.get(i)).getChild("instance").getText());
						temp.put("MetricName",((Element)allChildren.get(i)).getChild("MetricName").getText());
						
						tmp_hash.put(i,temp);	
							
					} 
				
				//缓冲写入数据文件					
					flush(tmp_hash,"");
				}
				catch(Exception e)
				{
					e.printStackTrace();
				}
				
		        jmxc.close(); 
			}
		}
  
	}
	
	//获取环境变量
	private static String getEnv(String name) throws Exception
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
	}
	
	//判断路径后是否有路径分隔符
	public static boolean  separator (String path)
	{
		if(path != null && !path.equals(""))
		{
			if(path.charAt(path.length() - 1) == '\\' || path.charAt(path.length() - 1) == '/' )
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		else
		{
			return false;
		}
	}
	
	private static void flush(HashMap<Integer,HashMap<Object,Object>> hm,String dataFile) throws Exception
	{
		String ostype = "MSwin";
		Set s = hm.keySet();
		if(dataFile == null || dataFile.equals(""))
		{
			for (Iterator it = s.iterator(); it.hasNext();) 
			{
				Object str = (Object)it.next();
				System.out.println(hm.get(str).get("timestamp")+"|"+hm.get(str).get("class")+"|"+hm.get(str).get("MetricName")+"|"+hm.get(str).get("instance")+"|"+hm.get(str).get("value")+"|"+ ostype + "\n");
			}
		}
		
	}
	
	public static String getFormatTime()throws Exception
	{
		Date now = new Date();
		SimpleDateFormat f = new SimpleDateFormat("yyyymmddHHmmss");
		return f.format(now).toString();
	}
	   
}   
