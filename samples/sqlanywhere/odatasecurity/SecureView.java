// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// *********************************************************************
//
// This sample program contains a hard-coded userid and password
// to connect to the demo database. This is done to simplify the
// sample program. The use of hard-coded passwords is strongly
// discouraged in production code.  A best practice for production
// code would be to prompt the user for the userid and password.

import java.math.BigDecimal;
import org.odata4j.consumer.ODataConsumer;
import org.odata4j.consumer.ODataConsumers;
import org.odata4j.core.OEntity;
import org.odata4j.jersey.consumer.behaviors.AllowSelfSignedCertsBehavior;
import org.odata4j.consumer.behaviors.OClientBehaviors;
import org.odata4j.format.FormatType;


/**
 *
 * This sample demonstrates how to use various features available in the
 * SAP Sybase OData Producer including: Https, Authentication and OSDL models.
 *
 */

public class SecureView
{

    // The endpoint URL of the OData Producer.  
    public static final String	    SERVICE_ROOT    = "https://localhost:8090/odata/";

    /**
     * Run the sample
     */
    public static void main( String args[] )
    {
	ODataConsumer consumer = buildConsumer();

	viewPayroll( consumer, "Sales" );
    }

    /**
     * Create a new OData4J consumer to interact with the OData service. 
     * @return A configured OData consumer.
     */
    public static ODataConsumer buildConsumer() 
    /*****************************************/
    {
	return ODataConsumers.newBuilder( SERVICE_ROOT )
	    // Set the default trasnport format to be JSON
	    .setFormatType( FormatType.JSON )
	    // Set two client behaviors:
	    //   One to let use our own self-signed certificate
	    //   and one to set the Http Authentication credentials
	    .setClientBehaviors( AllowSelfSignedCertsBehavior.allowSelfSignedCerts(), 
				 OClientBehaviors.basicAuth( "UPDATER", "update" ) )
	    .build();
    }
    
    /**
     * Retrieves confidential employee details and displays them.
     * @param consumer		The OData4J consumer used to access the OData service
     * @param departmentName	We retrieve all employees belonging to this department
     */
    public static void viewPayroll( ODataConsumer consumer,
				    String departmentName )
    /*****************************************************/
    {
	OEntity			department;
	Iterable<OEntity>	employees;

	// When using OData4j the query parameters must be encoded manually.
	// Here we only need to encode spaces (%20) so we do it manually.  For
	// query parameters that require more characters to be encoded, you can
	// do so using java.net.URI.
	employees = consumer.getEntities( "EmployeeConfidential" )
		.filter( "DepartmentName%20eq%20'" + departmentName + "'" )
		.select( "EmployeeID" +
			 ",SocialSecurityNumber" +
			 ",ManagerID" +
			 ",Salary" )
		.orderBy( "EmployeeID%20asc" )
		.execute();

	if( employees != null ) {

	    System.out.println( "\nPayroll for Department: " + departmentName );
	    System.out.println( "ID\tSalary\tMgr ID\tSIN" );
	    System.out.println( "------\t------\t------\t----------" );

	    for( OEntity employee : employees ) {
		Integer employeeID	    = employee.getProperty( "EmployeeID", Integer.class ).getValue();
		BigDecimal salary	    = employee.getProperty( "Salary", BigDecimal.class ).getValue();
		Integer managerID	    = employee.getProperty( "ManagerID", Integer.class ).getValue();
		String SIN		    = employee.getProperty( "SocialSecurityNumber", String.class ).getValue();

		System.out.println( employeeID +
			     "\t" + salary.longValue() +
			     "\t" + managerID +
			     "\t" + SIN );
	    }

	} else {
	    System.out.println( "\nDepartment: " + departmentName + " doesn't exist" );
	}
    }
}

