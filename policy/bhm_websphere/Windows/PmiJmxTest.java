package com.ibm.websphere.pmi;

import com.ibm.websphere.management.AdminClient;
import com.ibm.websphere.management.AdminClientFactory;
import com.ibm.websphere.management.exception.ConnectorException;
import com.ibm.websphere.management.exception.InvalidAdminClientTypeException;
import com.ibm.websphere.management.exception.*;

import java.util.*;
import javax.management.*;
import com.ibm.websphere.pmi.*;
import com.ibm.websphere.pmi.client.*;
import com.ibm.websphere.pmi.stat.*;

/**
 * Sample code to use AdminClient API directly to get PMI data from PerfMBean
 * and individual MBeans which support getStats method.
 */

public class PmiJmxTest implements PmiConstants
{
    private AdminClient    ac = null;
    private ObjectName     perfOName   = null;
    private ObjectName     serverOName = null;
    private ObjectName     wlmOName    = null;
    private ObjectName     jvmOName    = null;
    private ObjectName     orbtpOName    = null;
    private boolean failed = false;
    private PmiModuleConfig[] configs = null;

    /**
     *  Creates a new test object
     *  (Need a default constructor for the testing framework)
     */
    public PmiJmxTest()
    {
    }

    /**
     * @param args[0] host
     * @param args[1] port, optional, default is 8880
     * @param args[2] connectorType, optional, default is SOAP connector
     *   
     */
    public static void main(String[] args)
    {
        PmiJmxTest instance = new PmiJmxTest();

        // parse arguments and create AdminClient object
        instance.init(args);

        // navigate all the MBean ObjectNames and cache those we are interested
        instance.getObjectNames();

        // set level, get data, display data
        instance.doTest();

        // test for EJB data
        instance.testEJB();

        // how to use JSR77 getStats method for individual MBean other than PerfMBean
        instance.testJSR77Stats();

    }

    /**
     * parse args and getAdminClient
     */
    public void init(String[] args)
    {
        try
        {
            String  host    = null;
            String  port    = "8880";
            String  connector = "SOAP";
            if(args.length < 1)
            {
              System.err.println("ERROR: Usage: PmiJmxTest <host> [<port>] [<connector>]");
              System.exit(2);
            }
            else
            {
                host = args[0];

                if(args.length > 1)
                    port = args[1];

                if(args.length > 2)
                    connector = args[2];
            }

            if(host == null)
            {
                host = "localhost";
            }
            if(port == null)
            {
                port = "8880";
            }
            if(connector == null)
            {
                connector = AdminClient.CONNECTOR_TYPE_SOAP;
            }
            System.out.println("host=" + host + " , port=" + port + ", connector=" + connector);

            //----------------------------------------------------------------------------
            // Get the ac object for the AppServer
            //----------------------------------------------------------------------------
            System.out.println("main: create the adminclient");
            ac = getAdminClient(host, port, connector);

        }
        catch(Exception ex)
        {
            failed = true;
            new AdminException(ex).printStackTrace();
            ex.printStackTrace();
        }
    }

    /**
     * get AdminClient using the given host, port, and connector
     */
    public AdminClient getAdminClient(String hostStr, String portStr, String connector)
    {
        System.out.println("getAdminClient: host=" + hostStr + " , portStr=" + portStr);
        AdminClient ac = null;
        java.util.Properties props = new java.util.Properties();
        props.put(AdminClient.CONNECTOR_TYPE, connector);
        props.put(AdminClient.CONNECTOR_HOST, hostStr);
        props.put(AdminClient.CONNECTOR_PORT, portStr);
        try
        {
            ac = AdminClientFactory.createAdminClient(props);
        }
        catch(Exception ex)
        {
            failed = true;
            new AdminException(ex).printStackTrace();
            System.out.println("getAdminClient: exception");
        }
        return ac;
    }


    /**
     * get all the ObjectNames.
     */
    public void getObjectNames()
    {

        try
        {
            //----------------------------------------------------------------------------
            // Get a list of object names
            //----------------------------------------------------------------------------
            javax.management.ObjectName on = new javax.management.ObjectName("WebSphere:*");

            //----------------------------------------------------------------------------
            // get all objectnames for this server
            //----------------------------------------------------------------------------
            Set objectNameSet= ac.queryNames(on, null);

            //----------------------------------------------------------------------------
            // get the object names that we care about: Perf, Server, JVM, WLM 
            // (only applicable in ND)
            //----------------------------------------------------------------------------
            if(objectNameSet != null)
            {
                Iterator i = objectNameSet.iterator();
                while(i.hasNext())
                {
                    on = (ObjectName)i.next();
                    String type = on.getKeyProperty("type");

                    // uncomment it if you want to print the ObjectName for each MBean
                    // System.out.println("\n\n" + on.toString());

                    // find the MBeans we are interested
                    if(type != null && type.equals("Perf"))
                    {
                        System.out.println("\nMBean: perf =" + on.toString());
                        perfOName = on;
                    }
                    if(type != null && type.equals("Server"))
                    {
                        System.out.println("\nMBean: Server =" + on.toString());
                        serverOName = on;
                    }
                    if(type != null && type.equals("JVM"))
                    {
                        System.out.println("\nMBean: jvm =" + on.toString());
                        jvmOName = on;
                    }
                    if(type != null && type.equals("WLMAppServer"))
                    {
                        System.out.println("\nmain: WLM =" + on.toString());
                        wlmOName = on;
                    }
                    if(type != null && type.equals("ThreadPool"))
                    {
                        String name = on.getKeyProperty("name");
                        if(name.equals("ORB.thread.pool"))
                            System.out.println("\nMBean: ORB ThreadPool =" + on.toString());
                        orbtpOName = on;
                    }
                }
            }
            else
            {
                System.err.println("main: ERROR: no object names found");
                System.exit(2);
            }

            // You must have Perf MBean in order to get PMI data.
            if(perfOName == null)
            {
                System.err.println("main: cannot get PerfMBean. Make sure PMI is enabled");
                System.exit(3);
            }
        }
        catch(Exception ex)
        {
            failed = true;
            new AdminException(ex).printStackTrace();
            ex.printStackTrace();
        }

    }

    /**
     * Some sample code to set level, get data, and display data.
     */
    public void doTest()
    {
        try
        {
            // first get all the configs  - used to set static info for Stats 
            // Note: server only returns the value and time info. 
            //       No description, unit, etc is returned with PMI data to reduce 
            //       communication cost.
            //       You have to call setConfig to bind the static info and Stats data later.
            configs = (PmiModuleConfig[])ac.invoke(perfOName, "getConfigs", null, null);

            // print out all the PMI modules and matching mbean types
            for(int i=0; i<configs.length;i++>
                System.out.println("config: moduleName=" + configs[i].getShortName() 
                + ", mbeanType=" + configs[i].getMbeanType());

            // set the instrumentation level for the server
            setInstrumentationLevel(serverOName, null, PmiConstants.LEVEL_HIGH);

            // example to use StatDescriptor.
            // Note WLM module is only available in ND.
            StatDescriptor sd = new StatDescriptor(new String[]{"wlmModule.server"});
            setInstrumentationLevel(wlmOName, sd, PmiConstants.LEVEL_HIGH);

            // example to getInstrumentationLevel
            MBeanLevelSpec[] mlss = getInstrumentationLevel(wlmOName, sd, true);
            // you can call getLevel(), getObjectName(), getStatDescriptor() on mlss[i]

            // get data for the server
            Stats stats = getStatsObject(serverOName, true);
            System.out.println(stats.toString());

            // get data for WLM server submodule
            stats = getStatsObject(wlmOName, sd, true)
             if(stats == null)
                System.out.println("Cannot get Stats for WLM data");
            else
                System.out.println(stats.toString());

            // get data for JVM MBean
            stats = getStatsObject(jvmOName, true);
            processStats(stats);

            // get data for multiple MBeans
            ObjectName[] onames = new ObjectName[]{orbtpOName, jvmOName};
            Object[] params = new Object[]{onames, new Boolean(true)};
            String[] signature = new String[]{"javax.management.ObjectName","java.lang.Boolean"};
            Stats[] statsArray = (Stats[])ac.invoke(perfOName, "getStatsArray",params, signature);
            // you can call toString or processStats on statsArray[i]

            if(!failed)
                System.out.println("All tests passed");
            else
                System.out.println("Some tests failed");
        }
        catch(Exception ex)
        {
            new AdminException(ex).printStackTrace();
            ex.printStackTrace();
        }
    }


    /**
     * Sample code to get level
     */
    protected MBeanLevelSpec[] getInstrumentationLevel(ObjectName on, StatDescriptor sd, boolean recursive)
    {
        if(sd == null)
            return getInstrumentationLevel(on, recursive);
        System.out.println("\ntest getInstrumentationLevel\n");
        try
        {
            Object[] params = new Object[2];
            params[0] = new MBeanStatDescriptor(on, sd);
            params[1] = new Boolean(recursive);
            String[] signature= new String[]{ "com.ibm.websphere.pmi.stat.MBeanStatDescriptor",
                "java.lang.Boolean"};
            MBeanLevelSpec[] mlss = (MBeanLevelSpec[])ac.invoke(perfOName, 
                "getInstrumentationLevel", params, signature);
            return mlss;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            System.out.println("getInstrumentationLevel: Exception Thrown");
            return null;
        }
    }

    /**
     * Sample code to get level
     */
    protected MBeanLevelSpec[] getInstrumentationLevel(ObjectName on, boolean recursive)
    {
        if(on == null)
            return null;
        System.out.println("\ntest getInstrumentationLevel\n");
        try
        {
            Object[] params = new Object[]{on, new Boolean(recursive)};
            String[] signature= new String[]{ "javax.management.ObjectName", 
                "java.lang.Boolean"};
            MBeanLevelSpec[] mlss = (MBeanLevelSpec[])ac.invoke(perfOName, 
                "getInstrumentationLevel", params, signature);
            return mlss;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            failed = true;
            System.out.println("getInstrumentationLevel: Exception Thrown");
            return null;
        }
    }

    /**
     * Sample code to set level
     */
    protected void setInstrumentationLevel(ObjectName on, StatDescriptor sd, int level)
    {
        System.out.println("\ntest setInstrumentationLevel\n");
        try
        {
            Object[] params       = new Object[2];
            String[] signature    = null;
            MBeanLevelSpec[] mlss = null; 
            params[0] = new MBeanLevelSpec(on, sd, level);
            params[1] = new Boolean(true);

            signature= new String[]{ "com.ibm.websphere.pmi.stat.MBeanLevelSpec", 
                "java.lang.Boolean"};
            ac.invoke(perfOName, "setInstrumentationLevel", params, signature);
        }
        catch(Exception e)
        {
            failed = true;
            new AdminException(e).printStackTrace();
            System.out.println("setInstrumentationLevel: FAILED: Exception Thrown");
        }
    }

    /**
     * Sample code to get a Stats object
     */
    public Stats getStatsObject(ObjectName on, StatDescriptor sd, boolean recursive)
    {

        if(sd == null)
            return getStatsObject(on, recursive);

        System.out.println("\ntest getStatsObject\n");
        try
        {
            Object[] params    = new Object[2];
            params[0] = new MBeanStatDescriptor(on, sd);  // construct MBeanStatDescriptor
            params[1] = new Boolean(recursive);
            String[] signature = new String[] { 
                "com.ibm.websphere.pmi.stat.MBeanStatDescriptor", "java.lang.Boolean"};
            Stats stats  = (Stats)ac.invoke(perfOName, "getStatsObject", params, signature);

            if(stats == null) return null;

            // find the PmiModuleConfig and bind it with the data
            String type = on.getKeyProperty("type");
            if(type.equals(MBeanTypeList.SERVER_MBEAN))
                setServerConfig(stats);
            else
                stats.setConfig(PmiClient.findConfig(configs, on));

            return stats;

        }
        catch(Exception e)
        {
            failed = true;
            new AdminException(e).printStackTrace();
            System.out.println("getStatsObject: Exception Thrown");
            return null;
        }
    }

      /**
     * Sample code to get a Stats object
     */
    public Stats getStatsObject(ObjectName on, boolean recursive)
    {
        if(on == null)
            return null;
    System.out.println("\ntest getStatsObject\n");

        try
        {
            Object[] params  = new Object[]{on, new Boolean(recursive)};
            String[] signature = new String[] { "javax.management.ObjectName", 
                "java.lang.Boolean"};
            Stats stats  = (Stats)ac.invoke(perfOName, "getStatsObject", params, 
                                            signature);

            // find the PmiModuleConfig and bind it with the data
            String type = on.getKeyProperty("type");
            if(type.equals(MBeanTypeList.SERVER_MBEAN))
                setServerConfig(stats);
            else
                stats.setConfig(PmiClient.findConfig(configs, on));

            return stats;

        }
        catch(Exception e)
        {
            failed = true;
            new AdminException(e).printStackTrace();
            System.out.println("getStatsObject: Exception Thrown");
            return null;
        }
    }

    /**
     * Sample code to navigate and get the data value from the Stats object.
     */
    private void processStats(Stats stat)
    {
        processStats(stat, "");
    }

    /**
     * Sample code to navigate and get the data value from the Stats and Statistic object.
     */
    private void processStats(Stats stat, String indent)
    {
        if(stat == null)  return;

        System.out.println("\n\n");

        // get name of the Stats
        String name = stat.getName();
        System.out.println(indent + "stats name=" + name);

        // list data names
        String[] dataNames = stat.getStatisticNames();
        for(int i=0; i<dataNames.length;i++)
          System.out.println(indent + "    " + "data name=" + dataNames[i]);
        System.out.println("");

        // list all datas
        com.ibm.websphere.management.statistics.Statistic[] allData = stat.getStatistics();

        // cast it to be PMI's Statistic type so that we can have get more
        // Also show how to do translation.
        Statistic[] dataMembers = (Statistic[])allData;
        if(dataMembers != null)
        {
            for(int i=0; i<dataMembers.length;i++) 
            {
                System.out.print(indent + "    " + "data name=" + 
                                 PmiClient.getNLSValue(dataMembers[i].getName())
                                 + ", description=" + 
                                 PmiClient.getNLSValue(dataMembers[i].getDescription())
                                 + ", startTime=" + dataMembers[i].getStartTime()
                                 + ", lastSampleTime=" + dataMembers[i].getLastSampleTime());
                if(dataMembers[i].getDataInfo().getType() == TYPE_LONG)
                {
                    System.out.println(", count=" + 
                                       ((CountStatisticImpl)dataMembers[i]).getCount());
                }
                else if(dataMembers[i].getDataInfo().getType() == TYPE_STAT)
                {
                    TimeStatisticImpl data = (TimeStatisticImpl)dataMembers[i];
                    System.out.println(", count=" + data.getCount()
                                       + ", total=" + data.getTotal()
                                       + ", mean=" + data.getMean()
                                       + ", min=" + data.getMin()
                                       + ", max=" + data.getMax());
                }
                else if(dataMembers[i].getDataInfo().getType() == TYPE_LOAD)
                {
                    RangeStatisticImpl data = (RangeStatisticImpl)dataMembers[i];
                    System.out.println(", current=" + data.getCurrent()
                                       + ", integral=" + data.getIntegral()
                                       + ", avg=" + data.getMean()
                                       + ", lowWaterMark=" + data.getLowWaterMark()
                                       + ", highWaterMark=" + data.getHighWaterMark());
                }
            }
        }

        // recursively for sub-stats
        Stats[] substats = (Stats[])stat.getSubStats();
        if(substats == null || substats.length == 0)
            return;
        for(int i=0; i<substats.length; i++)
        {
            processStats(substats[i], indent + "    ");
        }
      }


    /**
     * The Stats object returned from server does not have static config info. 
     * You have to set it on client side.
     */
    public void setServerConfig(Stats stats)
    {
        if(stats == null) return;
        if(stats.getType() != TYPE_SERVER) return;

        PmiModuleConfig config = null;

        Stats[] statList = stats.getSubStats();
        if(statList == null || statList.length == 0)
            return;
        Stats oneStat = null;
        for(int i=0; i<statList.length; i++)
        {
            oneStat = statList[i];
            if(oneStat == null) continue;
            config = PmiClient.findConfig(configs, oneStat.getName()); 
            if(config != null)
                oneStat.setConfig(config);
            else
                System.out.println("Error: get null config for " + oneStat.getName());
        }
    }

    /**
     * sample code to show how to get a specific MBeanStatDescriptor
     */
    public MBeanStatDescriptor getStatDescriptor(ObjectName oName, String name)
    {
        try
        {
            Object[] params = new Object[]{serverOName};
            String[] signature= new String[]{"javax.management.ObjectName"};
            MBeanStatDescriptor[] msds = (MBeanStatDescriptor[])ac.invoke(perfOName, 
                                          "listStatMembers", params, signature);
            if(msds == null)
                return null;
            for(int i=0; i<msds.length; i++)
            {
                if(msds[i].getName().equals(name))
                    return msds[i];
            }
            return null;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            System.out.println("listStatMembers: Exception Thrown");
            return null;
        }

    }

    /** 
     * sample code to show you how to navigate MBeanStatDescriptor via listStatMembers 
     */
    public MBeanStatDescriptor[] listStatMembers(ObjectName mName)
    {
        if(mName == null)
            return null;

        try
        {
            Object[] params = new Object[]{mName};
            String[] signature= new String[]{"javax.management.ObjectName"};
            MBeanStatDescriptor[] msds = (MBeanStatDescriptor[])ac.invoke(perfOName, 
                                          "listStatMembers", params, signature);
            if(msds == null)
                return null;
            for(int i=0; i<msds.length; i++)
            {
                if(msds[i].getName().equals(name))
                    return msds[i];
            }
            return null;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            System.out.println("listStatMembers: Exception Thrown");
            return null;
        }

    }

    /** 
     * sample code to show you how to navigate MBeanStatDescriptor via listStatMembers 
     */
    public MBeanStatDescriptor[] listStatMembers(ObjectName mName)
    {
        if(mName == null)
            return null;

        try
        {
            Object[] params = new Object[]{mName};
            String[] signature= new String[]{"javax.management.ObjectName"};
            MBeanStatDescriptor[] msds = (MBeanStatDescriptor[])ac.invoke(perfOName, 
                                          "listStatMembers", params, signature);
            if(msds == null)
                return null;
            for(int i=0; i<msds.length; i++)
            {
                MBeanStatDescriptor[] msds2 = listStatMembers(msds[i]);
            }
            return null;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            System.out.println("listStatMembers: Exception Thrown");
            return null;
        }

    }


    /**
     * Sample code to get MBeanStatDescriptors
     */
    public MBeanStatDescriptor[] listStatMembers(MBeanStatDescriptor mName)
    {
        if(mName == null)
            return null;

        try
        {
            Object[] params = new Object[]{mName};
            String[] signature= new String[]{"com.ibm.websphere.pmi.stat.MBeanStatDescriptor"};
            MBeanStatDescriptor[] msds = (MBeanStatDescriptor[])ac.invoke(perfOName, 
                                          "listStatMembers", params, signature);
            if(msds == null)
                return null;
            for(int i=0; i<msds.length; i++)
            {
                MBeanStatDescriptor[] msds2 = listStatMembers(msds[i]);
                // you may recursively call listStatMembers until find the one you want
            }
            return msds;
        }
        catch(Exception e)
        {
            new AdminException(e).printStackTrace();
            System.out.println("listStatMembers: Exception Thrown");
            return null;
        }

    }

    /** 
     * sample code to get PMI data from beanModule
     */
    public void testEJB()
    {

        // This is the MBeanStatDescriptor for Enterprise EJB
        MBeanStatDescriptor beanMsd = getStatDescriptor(serverOName, PmiConstants.BEAN_MODULE);
        if(beanMsd == null)
            System.out.println("Error: cannot find beanModule");

        // get the Stats for module level only since recursive is false
        Stats stats = getStatsObject(beanMsd.getObjectName(), beanMsd.getStatDescriptor(), 
                      false); // pass true if you wannt data from individual beans

                                             // find the avg method RT 
        TimeStatisticImpl rt = (TimeStatisticImpl)stats.getStatistic(EJBStatsImpl.METHOD_RT);
        System.out.println("rt is " + rt.getMean());

        try
        {
            java.lang.Thread.sleep(5000);
        }
        catch(Exception ex)
        {
            ex.printStackTrace();
        }

        // get the  Stats again
        Stats stats2 = getStatsObject(beanMsd.getObjectName(), beanMsd.getStatDescriptor(), 
                       false); // pass true if you wannt data from individual beans

                                              // find the avg method RT
        TimeStatisticImpl rt2 = (TimeStatisticImpl)stats2.getStatistic(EJBStatsImpl.METHOD_RT);
        System.out.println("rt2 is " + rt2.getMean());

        // calculate the difference between this time and last time.
        TimeStatisticImpl deltaRt = (TimeStatisticImpl)rt2.delta(rt);
        System.out.println("deltaRt is " + rt.getMean());

    }

    /**
     * Sample code to show how to call getStats on StatisticProvider MBean directly.
     */
    public void testJSR77Stats()
    {
        // first, find the MBean ObjectName you are interested.
        // Refer method getObjectNames for sample code.

        // assume we want to call getStats on JVM MBean to get statistics
        try
        {

            com.ibm.websphere.management.statistics.JVMStats stats = 
            (com.ibm.websphere.management.statistics.JVMStats)ac.invoke(jvmOName, 
                                                         "getStats", null, null);

            System.out.println("\n get data from JVM MBean");

            if(stats == null)
            {
                System.out.println("WARNING: getStats on JVM MBean returns null");
            }
            else
            {

                // first, link with the static info if you care
                ((Stats)stats).setConfig(PmiClient.findConfig(configs, jvmOName));

                // print out all the data if you want
                //System.out.println(stats.toString());

                // navigate and get the data in the stats object
                processStats((Stats)stats);

                // call JSR77 methods on JVMStats to get the related data
                com.ibm.websphere.management.statistics.CountStatistic upTime = 
                stats.getUpTime();
                com.ibm.websphere.management.statistics.BoundedRangeStatistic heapSize = 
                stats.getHeapSize();

                if(upTime != null)
                    System.out.println("\nJVM up time is " + upTime.getCount());
                if(heapSize != null)
                    System.out.println("\nheapSize is " + heapSize.getCurrent());
            }
        }
        catch(Exception ex)
        {
            ex.printStackTrace();
            new AdminException(ex).printStackTrace();
        }
    }
}        