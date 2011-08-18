/*	author:	yangshengcheng@gzcss.net
 * 	description: use jmx protocol(SOAP Connector) to query websphere mbeans
 * 	date: 2011.6 
 * 
 */

import java.util.Properties;
import java.util.ResourceBundle;
import java.util.Set;
import java.util.Iterator;
import java.util.*;

import javax.management.AttributeNotFoundException;
import javax.management.InstanceNotFoundException;
import javax.management.MBeanException;
import javax.management.MalformedObjectNameException;
import javax.management.ObjectName;
import javax.management.ObjectInstance;
import javax.management.ReflectionException;
import javax.management.MBeanInfo;

//follow classes come from com.ibm.ws.admin.client_xxx.jar, add this package to classpath

import com.ibm.websphere.management.AdminClient;
import com.ibm.websphere.management.AdminClientFactory;
import com.ibm.websphere.management.exception.ConnectorException;
import com.ibm.websphere.management.statistics.*;

//use jmx obtain pmi(performent monitoring infrastructure) data
import com.ibm.websphere.pmi.*;
import com.ibm.websphere.pmi.client.*;
import com.ibm.websphere.pmi.stat.*;


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


public class WasAdminClient implements PmiConstants
{ 
	private String hostname = "localhost";    // default
	private String port = "8880";             // default 
	
	private String username;
	private String password; 
	private String connector_security_enabled;
	private String connector_soap_config;
	
	private String ssl_trustStore;
	private String ssl_keyStore; 
	private String ssl_trustStorePassword;
	private String ssl_keyStorePassword;
	
	private ResourceBundle soapClient;
	private String soap_client_properties;
	
	private AdminClient adminClient;
	
	
	//objetcNames
	private ObjectName perfOName = null;
	private ObjectName orbtpOName = null;
	private ObjectName jvmOName = null;
	private ObjectName serverOName = null;
	private ObjectName wlmOName = null;
	

	
	
	
	public WasAdminClient() throws ConnectorException 
	{ 
		 soap_client_properties = "soap_client";
	}
	
	public WasAdminClient(String soap_client_properties) throws ConnectorException
	{
		this.soap_client_properties = soap_client_properties;
	}  
	
	public AdminClient getAdminClient() 
	{
		return adminClient;
	}  
	
	public AdminClient create() throws ConnectorException 
	{
		getResourceBundle(soap_client_properties);
		
		Properties props = new Properties(); 
		props.setProperty(AdminClient.CONNECTOR_TYPE, AdminClient.CONNECTOR_TYPE_SOAP); 
		props.setProperty(AdminClient.CONNECTOR_HOST, hostname); 
		props.setProperty(AdminClient.CONNECTOR_PORT, port); 
		props.setProperty(AdminClient.CACHE_DISABLED, "false");
		
		 if (connector_security_enabled == "false") 
		 {
			 adminClient = AdminClientFactory.createAdminClient(props); 
			 return adminClient;
		 }
		 
		 props.setProperty(AdminClient.CONNECTOR_SECURITY_ENABLED, "true"); 
		 props.setProperty(AdminClient.CONNECTOR_AUTO_ACCEPT_SIGNER, "true"); 
		 props.setProperty("javax.net.ssl.trustStore", ssl_trustStore); 
		 props.setProperty("javax.net.ssl.keyStore", ssl_keyStore);
		 props.setProperty("javax.net.ssl.trustStorePassword", ssl_trustStorePassword); 
		 props.setProperty("javax.net.ssl.keyStorePassword", ssl_keyStorePassword); 
		 
		 if (username == null || password == null) 
		 {
			 props.setProperty(AdminClient.CONNECTOR_SOAP_CONFIG, connector_soap_config); 
		 }
		 else
		 {
			 props.setProperty(AdminClient.USERNAME, username); 
			 props.setProperty(AdminClient.PASSWORD, password); 
		 }
		 
		 adminClient = AdminClientFactory.createAdminClient(props); 
		 
		 return adminClient;
		 
	}
	
	 public ResourceBundle getResourceBundle(String properties)
	 {
		  soapClient = ResourceBundle.getBundle(properties); 
		  hostname = soapClient.getString("hostname");
		  port = soapClient.getString("port"); 
		  connector_security_enabled = soapClient.getString("connector_security_enabled"); 
		  ssl_trustStore = soapClient.getString("ssl_trustStore"); 
		  ssl_keyStore = soapClient.getString("ssl_keyStore"); 
		  
		  ssl_trustStorePassword = soapClient.getString("ssl_trustStorePassword"); 
		  ssl_keyStorePassword = soapClient.getString("ssl_keyStorePassword"); 
		  
		  
		  if (soapClient.containsKey("connector_soap_config")) 
		  {
			  connector_soap_config = soapClient.getString("connector_soap_config"); 
		  }
		  
		  if (soapClient.containsKey("username"))
		  {
			  username = soapClient.getString("username"); 
		  }
		  
		  if (soapClient.containsKey("password"))
		  {
			  password = soapClient.getString("password"); 
		  }
		  
		  if (soapClient.containsKey("hostname")) 
		  {
			  hostname = soapClient.getString("hostname"); 
		  }
		  
		  if (soapClient.containsKey("port")) 
		  {
			  port = soapClient.getString("port"); 
		  }
		  
		  return soapClient;
	 }
	 
	 
	 
	 
	 public  ArrayList<ObjectName> getObjectNames()
	 {
		 
		 ArrayList<ObjectName> al = new ArrayList<ObjectName>();
		 
		 try
		 {
			 Set set = adminClient.queryNames(null,null);
			 
			 for (Iterator it = set.iterator(); it.hasNext();) 
		      {        
				 	ObjectName oi = (ObjectName) it.next();	
				 	
				 	al.add(oi);
				 	
				 	//this.listStatMembers(oi);
				 	
	                String type = oi.getKeyProperty("type");
	                   
	                if(type != null && type.equals("Perf"))
	                {
	                  //System.out.println("\nMBean: perf =" + oi.toString());
	                  perfOName = oi;
	                  
	                  
	                  
	                }
	                if(type != null && type.equals("JVM"))
	                {
	                	//System.out.println("\nMBean: JVM =" + oi.toString());
	                	jvmOName = oi;	                  
	                }
	                
	                if(type != null && type.equals("Server"))
	                {
	                	//System.out.println("\nMBean: JVM =" + oi.toString());
	                	serverOName = oi;	                  
	                }
	                
	                	                
					MBeanInfo info = adminClient.getMBeanInfo(oi);
							           		
							  //list mbeans attributes
					for(int i = 0;i < info.getAttributes().length;i++ )
					{
						//System.out.println("Attribute" + ":" +info.getAttributes()[i].getName());
					}
							//list mbeans operations
					for(int i = 0;i < info.getOperations().length;i++ )
					{
						//System.out.println("Operation" + ":" +info.getOperations()[i].getName());
					}	
				           			       
		     }
			 return al;
		 }
		 catch(Exception e)
		 {
			 e.printStackTrace();
			 return null;
		 }
	 }
	 
	 public void test(AdminClient adminClient)
	 {
		 try 
		 {
			 PmiModuleConfig[] configs = (PmiModuleConfig[])adminClient.invoke(perfOName, "getConfigs", null, null);
	         for(int i=0; i<configs.length;i++)
	         {
	             //System.out.println("config: moduleName=" + configs[i].getShortName() + ", mbeanType=" + configs[i].getMbeanType());
	         }
		 }
		 catch(Exception e)
		 {
			 e.printStackTrace();
		 }
         // print out all the PMI modules and matching mbean types

	 }
	 
	 public  boolean listStatMembers(ArrayList<ObjectName> al)
	 {
	        try
	        {
	        	for(int j=0; j < al.size(); j++)
	        	{
		            Object[] params = new Object[]{al.get(j)};
		            String[] signature= new String[]{"javax.management.ObjectName"};
		            MBeanStatDescriptor[] msds = (MBeanStatDescriptor[])adminClient.invoke(perfOName, "listStatMembers", params, signature);
		            if(msds == null)
		            {
		            	//System.out.println("msds is null");
		                continue;
		            }
		            
		            for(int i=0; i<msds.length; i++)
		            {
		            	if(msds[i].getName() != null)
		            	{
		            		//System.out.println("mbean->" + al.get(j).toString());
		            		//System.out.println("MBeanStatDescriptor->" + msds[i].getName());
		            		//PMIQuery(msds[i]);
		            	}
		            }
	        	}
	            return true;
	        }
	        catch(Exception e)
	        {
	        	e.printStackTrace();
	            System.out.println("listStatMembers: Exception Thrown");
	            return false;
	        }

	 }
	 
	 
	 
	 public WSStats ListMbeanPMIData(ObjectName objName,boolean recursive)
	 {
	     if(objName == null)
	     {
	            return null;
	     }
	     
	    //System.out.println("\ntest getStatsObject\n");

	        try
	        {
	            Object[] params  = new Object[]{objName, new Boolean(recursive)};
	            String[] signature = new String[] { "javax.management.ObjectName","java.lang.Boolean"};
	            WSStats wsstat = (WSStats)adminClient.invoke(perfOName, "getStatsObject", params,signature);
	            System.out.println(wsstat.toString());
	            return  wsstat;

	        }
	        catch(Exception e)
	        {
	        	e.printStackTrace();
	            System.out.println("getStatsObject: Exception Thrown");
	            return null;
	        }
	 }
	 
	 
	 public void PMIQuery(MBeanStatDescriptor MD)
	 {
		 try
		 {
			 Object[] params = new Object[]{MD,new Boolean(false)};  
			 String[] signature= new String[]{"com.ibm.websphere.pmi.stat.MBeanStatDescriptor","java.lang.Boolean"}; 
			 WSStats myStats = (WSStats)adminClient.invoke(perfOName,"getStatsObject",params,signature);
			 System.out.println("***********************************************************************");
			 System.out.println(myStats.toString());
		 }
	     catch(Exception e)
	     {
	        	e.printStackTrace();
	            //System.out.println("getStatsObject: Exception Thrown");
	     }
	 }
	 
	 
	 private void processStats(WSStats stat, String indent)
	    {
	        if(stat == null)  return;

	        // get name of the Stats
	        System.out.println("**************************************");
	        String name = stat.getName();
	        System.out.println(indent + "stats name=" + name);

	        // list data names
//	        String[] dataNames = stat.getStatisticNames();
//	        for(int i=0; i<dataNames.length;i++)
//	        	System.out.println(" data name=" + dataNames[i]);
//	        	System.out.println("");

	        // list all datas
	        //com.ibm.websphere.management.statistics.Statistic[] allData = stat.getStatistics();
	        com.ibm.websphere.pmi.stat.WSStatistic[] dataMembers = stat.getStatistics();

	        // cast it to be PMI's Statistic type so that we can have get more
	        // Also show how to do translation.
	        //Statistic[] dataMembers = (Statistic[])allData;
	        if(dataMembers != null)
	        {
	            for(int i=0; i<dataMembers.length;i++) 
	            {
	                System.out.println(indent + "  " +"data name=" + dataMembers[i].getName() + ", description=" + dataMembers[i].getDescription()+ ", startTime=" + dataMembers[i].getStartTime()+ ",lastSampleTime=" + dataMembers[i].getLastSampleTime());
	                //System.out.println(dataMembers[i].getDataInfo().getType() + " " + dataMembers[i].getDataInfo().getDescription());
	                //if(dataMembers[i].getDataInfo().getType() == TYPE_LONG)
	                if(dataMembers[i] instanceof WSCountStatistic)
	                {
	                    System.out.println("count=" + ((WSCountStatistic)dataMembers[i]).getCount());
	                }
	                else if(dataMembers[i].getDataInfo().getType() == TYPE_STAT)
	                {
	                	WSAverageStatistic data = (WSAverageStatistic)dataMembers[i];
	                    System.out.println(", count=" + data.getCount() + ", total=" + data.getTotal() + ", mean=" + data.getMean() + ", min=" + data.getMin() + ", max=" + data.getMax());
	                }
	                else if(dataMembers[i].getDataInfo().getType() == TYPE_LOAD)
	                {
	                	WSRangeStatistic data = (WSRangeStatistic)dataMembers[i];
	                    System.out.println(", current=" + data.getCurrent()
	                                       + ", integral=" + data.getIntegral()
	                                       + ", avg=" + data.getMean()
	                                       + ", lowWaterMark=" + data.getLowWaterMark()
	                                       + ", highWaterMark=" + data.getHighWaterMark());
	                }
	            }
	        }

	        // recursively for sub-stats
	        WSStats[] substats = (WSStats[])stat.getSubStats();
	        if(substats == null || substats.length == 0)
	            return;
	        for(int i=0; i<substats.length; i++)
	        {
	            processStats(substats[i], " ");
	        }
	      }
	 
	 
	    public static void main(String[] args) throws Exception 
	    { 
	    	WasAdminClient wasc = new WasAdminClient();
	    	AdminClient adc = null;
	    	 ArrayList<ObjectName> al = new ArrayList<ObjectName>();
	    	
	    	
	    	try 
	    	{
	    		adc = wasc.create();
	    		al = wasc.getObjectNames();
	    		wasc.test(adc);
	    		
	    		wasc.listStatMembers(al);
//	    		
//	        	for(int j=0; j < al.size(); j++)
//	        	{
//	    		WSStats ws = wasc.ListMbeanPMIData(wasc.serverOName,true);
//	    		System.out.println(ws.getName());
	    		
//	    		for(int i=0;i < names.length;i++)
//	    		{
//	    			System.out.println("StatisticName = " + names[i]);
//	    		}
	        		//wasc.ListMbeanPMIData(wasc.orbtpOName,true);
	        		//wasc.ListMbeanPMIData(wasc.jvmOName,true);
	    		WSStats wss = wasc.ListMbeanPMIData(wasc.serverOName,true);
	    		//wasc.processStats(wss," ");
	        		//wasc.ListMbeanPMIData(wasc.wlmOName,true);
//	        	}
	    	}
	    	catch (Exception e)
	    	{
	    		e.printStackTrace();
	    	}
	    	
	    	
	    }
	 
}
	  
	  
	 
	 