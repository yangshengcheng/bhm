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
import javax.management.InstanceNotFoundException;
import javax.management.MBeanException;
import javax.management.ReflectionException;
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

//����������ΪCompositeDataSupport������
import javax.management.openmbean.CompositeData;

//file
import java.io.*;

//��������
import org.apache.commons.cli.BasicParser;
import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.HelpFormatter;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException; 

//jdom xml
import org.jdom.*;
import org.jdom.Element;
import org.jdom.input.*;

//ʱ�䴦��
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

		   	
			TomcatMbeanQuery tmq  = new TomcatMbeanQuery();
		   	//�о�ָ���ؼ��ֵ�mbean����
			if(cl.hasOption('l'))
			{			   		
				tmq.listMbeanAttributeAndOperation(mbsc,cl);
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
				String xmlFile = "";
				String tmp = ""; 
				try
				{
					tmp = tmq.getEnv("OvDataDir").trim();
	
					if(tmp.equals("") || tmp == null)
					{
						xmlFile = "C:\\Documents and Settings\\All Users\\Application Data\\HP\\HP BTO Software\\bin\\instrumentation\\" + xml_file_name ;
					}
					else
					{
						if(tmq.CheckSeparator(tmp))
						{
							xmlFile = tmp + "\bin\\instrumentation\\" + xml_file_name;	
						}
						else
						{
							xmlFile = tmp + "\\bin\\instrumentation\\" + xml_file_name ;	
						}
					}
				}
				catch (Exception e)
				{
					e.printStackTrace();
				}
				
				boolean exists = (new File(xml_file_name)).exists();
				if(!exists)
				{
					System.out.println("mbean describe file is not exists\n");
					System.exit(1);
				}
				
				//��ȡ���ݱ����ļ�����·��,·��������ʱ���ؿ�
				String dataFile = tmq.getdataFile("tomcat");
				
				tmq.bhmQuery(mbsc,xml_file_name,dataFile);
				
				//��xml�����ļ��в���type=GlobalRequestProcessor��mbean
				String[] mbeanArray = tmq.findMbeanObjs("GlobalRequestProcessor",xml_file_name);
				
				//����ָ��mbeans�ļ�����	
				for(int i =0;mbeanArray[i] != null && ! mbeanArray[i].equals("");i++)
				{
					if(i > 0)
					{
						//Ϊ�˱����ظ���mbean ������ǰ��Ƚ�һ��mbean����
						if(mbeanArray[i].equals(mbeanArray[i-1]))
						{
							continue;
						}
					}
					
					tmq.resetMbeanCouter(mbsc,mbeanArray[i]);
				}
				
		        jmxc.close(); 
			}
		} 
	}
    
	
	//��ȡ��������
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
	}
	
	//�ж�·�����Ƿ���·���ָ���
	public  boolean  CheckSeparator (String path)
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
	
	//����ѯ���д�������ļ����������׼���
	private  boolean flush(HashMap<Integer,HashMap<Object,Object>> hm,String dataFile) throws Exception
	{
		String ostype = "MSWin32";
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
		
	}
	
	public  String getFormatTime()throws Exception
	{
		Date now = new Date();
		SimpleDateFormat f = new SimpleDateFormat("yyyyMMddHHmmss");
		return f.format(now).toString();
	}
	
	private void listMbeanAttributeAndOperation(MBeanServerConnection mbsc,CommandLine cl)
	{
		//������ص�mbean��������
		String key = cl.getOptionValue("l");
     
		try
		{
			Set set = mbsc.queryMBeans(null, null);
		    if(key.equalsIgnoreCase("all") ) 
		    {
			      for (Iterator it = set.iterator(); it.hasNext();) 
			      {        
					  	ObjectInstance oi = (ObjectInstance) it.next();
					//System.out.println("\t" + oi.getObjectName());
					           	 
	
						  System.out.println(oi.getObjectName());
						  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
						           		
						  //�о�mbean����
						  for(int i = 0;i < info.getAttributes().length;i++ )
						  {
						  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
						  }
						 //�о�mbean����
						  for(int i = 0;i < info.getOperations().length;i++ )
						  {
						  	System.out.println("Operation" + ":" +info.getOperations()[i].getName());
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
						  System.out.println(oi.getObjectName());
						  MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
						           		
						  //�о�mbean����
						  for(int i = 0;i < info.getAttributes().length;i++ )
						  {
						  	System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
						  }
						 //�о�mbean����
						  for(int i = 0;i < info.getOperations().length;i++ )
						  {
						  	System.out.println("operation" + ":" +info.getOperations()[i].getName());
						  }		           		
					           			
					 }       
			     }
			} 
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
	
	private void bhmQuery(MBeanServerConnection mbsc,String xmlFile,String dataFile) throws Exception
	{
		// ��ȡmbean �����ļ��е�mbean��Ϣ//
		
		//����һ����ʱ����
		HashMap<Integer,HashMap<Object,Object>> tmp_hash = new HashMap<Integer,HashMap<Object,Object>>();
		List allChildren;
		Document doc;
		Element foo;
		SAXBuilder builder;
		String timestamp = this.getFormatTime();
		
		//����xml�ڵ�mbean�ṹ
		try
		{				
			builder = new SAXBuilder();  
			doc = builder.build(new File(xmlFile)); 
			foo = doc.getRootElement();  
			allChildren = foo.getChildren(); 
		//����mbeans����ѯ���ݵ���ʱ����
			for(int i =0;i < allChildren.size();i++)
			{
				HashMap<Object,Object> temp = new HashMap<Object,Object>();
					
				ObjectName obj = new ObjectName(((Element)allChildren.get(i)).getChild("ObjectName").getText());
				String att = ((Element)allChildren.get(i)).getChild("Attribute").getText();
				CompositeData cd;

				temp.put("timestamp",timestamp);
				temp.put("class",((Element)allChildren.get(i)).getChild("class").getText());
				temp.put("instance",((Element)allChildren.get(i)).getChild("instance").getText());
				temp.put("MetricName",((Element)allChildren.get(i)).getChild("MetricName").getText());
				
				
				if(obj.toString().indexOf("MemoryPool") > -1 )
				{
					cd = (CompositeData)mbsc.getAttribute(obj,att);
					temp.put("value",cd.get("used").toString());
//					System.out.println(cd.get("used").toString());
				}
				else
				{
					temp.put("value",mbsc.getAttribute(obj,att));
				}
				tmp_hash.put(i,temp);	
					
			} 		
	
			//����д�������ļ�					
			this.flush(tmp_hash,dataFile);		
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
	}
	
	
	private void resetMbeanCouter(MBeanServerConnection mbsc,String objString) throws Exception
	{
		//��ɱ��β�ѯ��reset GlobalRequestProcessor �ļ���ֵ,ʹ��ÿ��ȡֵΪ��ѯ����ۼ�ֵ
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
	}
	
	
	private String[] findMbeanObjs(String key,String xmlFile)
	{
		//�ؼ��ְ�����಻�ܳ���100��mbeanʵ��
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
		//����mbeans����ѯ���ݵ���ʱ����
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
		
	}
	
	private String getdataFile(String prefix)
	{
		//���ovdatadirĿ¼
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
		
	}
	
	
	public  String getFileName(String prefix)
	{
		Date now = new Date();
		SimpleDateFormat f = new SimpleDateFormat("HHmm");
		return prefix + "_"+f.format(now).toString()+".csv";
	}
	
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
		
	}
	   
}   
