/*	
 * @author:	yangshengcheng@gzcss.net
 * 	@description: create weblogic monitor xml file for wlsConnectRemote.java
 * 	@create: 2011.7 
 *  @version :20110729
 *  @modifiedInfo : release
 *  @update:20110810
 *  @update info: extends class wlsConnectRemote,addOption(t),addOption(c)
 */

import java.util.Properties;
import java.util.ResourceBundle;
import java.util.Set;
import java.util.Iterator;
import java.util.*;
import java.util.regex.*;

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

//arguments manager
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
import org.jdom.output.*;

//timeformat
import java.text.SimpleDateFormat;

//manager the mbean attribute which return CompositeDataSupport object
import javax.management.openmbean.CompositeData;


public class wlsCreateMbeanXml extends wlsConnectRemote
{	
	   //private static MBeanServerConnection connection;
	   //private static JMXConnector connector;			   
	
	public static void main(String[] args)
	{
		Options opts = new Options();
		opts.addOption("h", false, "Print help for this application");
		opts.addOption("d", true, "the hostname or ip where the weblogic deploy");
		opts.addOption("p", true, "rmi port");
		opts.addOption("l", true, "list matching mbeans's attribute and method,all for all mbeans");
		opts.addOption("i",true, "the mbean desc file");
		opts.addOption("o",true, "the mbean xml file");
		opts.addOption("u",true, "weblogic console username");
		opts.addOption("w",true, "weblogic console user password");
		opts.addOption("t",true, "weblogic jndi type:domainruntime,runtime,edit");
		opts.addOption("c",true, "weblogic connect type: remote,native");
		
		
		BasicParser parser = null;
		CommandLine cl = null;
		String xml = "bhm_wls_mbean.xml";
		String descTxt = "mbean_console_perf.txt";
		
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
			   	
			   	if(cl.hasOption('i'))
			   	{
			   		descTxt =  cl.getOptionValue("i");
			   	}
			   	
			   	if(cl.hasOption('o'))
			   	{
			   		xml =  cl.getOptionValue("o");
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
		 
		 
		 wlsCreateMbeanXml wcr = new wlsCreateMbeanXml();
		 
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
			//create mbean xml file
			String descFile = wcr.getDescFile(descTxt);
			String xmlFile  = wcr.getxmlfile(xml);
			
			try
			{
				wcr.generateMbeanXml(connection,xmlFile,descFile);			
				connector.close();
			}
			catch (Exception e)
			{
				e.printStackTrace();
			}

				
		}
		 
	}//main
		
	private void generateMbeanXml(MBeanServerConnection mbsc,String xmlFile,String descFile) throws Exception
	{
		HashMap<Object,HashMap<String,String>> hm = new HashMap<Object,HashMap<String,String>>();
		//HashMap<String,String> temp = new HashMap<String,String>();
		//parser descfile first
		try
		{
			File Rfile = new File(descFile);
			FileReader fr = new FileReader(Rfile);
			BufferedReader br = new BufferedReader(fr);
			String currentLine ;
			
			int index = 0;
			while((currentLine = br.readLine()) != null)
			{								
				if(currentLine.matches("\\s*(\\w+)\\s*(\\w+)\\s*(\\S+)\\s*(\\w+)\\s*"))
				{
					HashMap<String,String> temp = new HashMap<String,String>();
					
					//System.out.println(currentLine.split("\\s+")[0] + " " + currentLine.split("\\s+")[1] + " " + currentLine.split("\\s+")[2]);
					temp.put("attribute",currentLine.split("\\s+")[1]);
					temp.put("metricName",currentLine.split("\\s+")[2]);
					temp.put("type",currentLine.split("\\s+")[3]);
					
					String mbeanName = currentLine.split("\\s+")[0];
					if(mbeanName.indexOf("MBean") != -1)
					{
						mbeanName = mbeanName.substring(0,mbeanName.length()-5);
					}
					temp.put("objectName",mbeanName);
					
					hm.put(index,temp);
					index++;
				}
				else
				{
					continue;
				}								
			}
			br.close();	
			
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
		//scan mbean tree
		try
		{
			
			Element root;			
			root = new Element("MetricDefinitions");
			Document doc = new Document(root); //make root element
			
			Set set = mbsc.queryMBeans(null, null);
			//Set s = hm.keySet();
			
	    	Iterator iter = hm.keySet().iterator();
			while(iter.hasNext())
			{	
				Object index = (Object)iter.next();
				
				String obj = hm.get(index).get("objectName");
				String att = hm.get(index).get("attribute");
				String metric = hm.get(index).get("metricName");
				String resultType = hm.get(index).get("type");
				
//				System.out.println(obj+" "+att + " " + metric);
				
				Element Metrics,className,MetricName,instance,ObjectNames,AttributeName,type;
				
		        Metrics = new Element("Metrics"); //Metrics(className,MetricName,instance,ObjectNames,AttributeName,type)                            		        												
				ObjectNames = new Element("ObjectNames");//ObjectNames(objname)
				
				boolean mark = false;
				for (Iterator it = set.iterator(); it.hasNext();) 
				{     					
					ObjectInstance oi = (ObjectInstance) it.next();
			    	if(oi.getObjectName().toString().indexOf("Type=" + obj) != -1)
			    	{			    		
			    		//check attribute
						MBeanInfo info = mbsc.getMBeanInfo(oi.getObjectName());
						//String att = hm.get(iter.next()).get("attribute");
						
						if(! MbeanAttributeExists(info,att))
						{
							continue;
						}
						
						if(!mark)
						{
							//Metrics = new Element("Metrics"); //Metrics(className,MetricName,instance,ObjectNames,AttributeName,type)                            
					        
					        className = new Element("class");
					        MetricName = new Element("MetricName");
					        instance = new Element("instance");
							AttributeName = new Element("Attribute");
							type = new Element("type");
							
					        className.setText("WLSSPI_UDM_METRICS");
					        MetricName.setText(metric);
					        instance.setText("null");		        
							AttributeName.setText(att);
							type.setText(resultType);														
							
					        Metrics.addContent(className);
					        Metrics.addContent(MetricName);
					        Metrics.addContent(instance);
							Metrics.addContent(AttributeName);
							Metrics.addContent(type);
							
							//ObjectNames = new Element("ObjectNames");//ObjectNames(objname)
							mark = true;							
						}
												
						Element objname;
						objname = new Element("ObjectName");
						objname.setText(oi.getObjectName().toString());
						ObjectNames.addContent(objname);
						
			    	}
			    	else
			    	{
			    		continue;
			    	}
				}
				
				if(mark)
				{
					Metrics.addContent(ObjectNames);
					root.addContent(Metrics);
				}
				
		    }
			
	        Format format = Format.getCompactFormat();

	        format.setEncoding("UTF-8"); //characterset set to UTF-8

	        format.setIndent("    "); //set 4 blank as indentation

	        XMLOutputter XMLOut = new XMLOutputter(format);//set child element style 
	        
	        XMLOut.output(doc, new FileOutputStream(xmlFile)); 
	        
	        System.out.println("create mbean describe xml file successfully~");
		}
		catch(Exception e)
		{
			e.printStackTrace();
		}
		
	}//generateMbeanXml
		
	private String getDescFile(String filename)
	{
		//¼ì²éovdatadirÄ¿Â¼
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
			return path+ File.separator +filename;
		}
		else
		{
			return "";
		}
	}//getDescFile
		
}