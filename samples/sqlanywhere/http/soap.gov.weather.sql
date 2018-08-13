-- ***************************************************************************
-- Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
-- ***************************************************************************
// This sample code is provided AS IS, without warranty or liability of any kind.
// 
// You may use, reproduce, modify and distribute this sample code without
// limitation,  on the condition that you retain the foregoing copyright
// notice and disclaimer as to the original code.  
// 
// *******************************************************************

/*
 * Demonstrate the use of SQL Anywhere SOAP client services
 *
 * This discussion explains how SQL Anywhere utilities and APIs are
 * used to make outbound SOAP requests to third party (or SQL Anywhere)
 * SOAP endpoints from a SQL Anywhere (client) stored procedure.
 *
 * This script can be run as is.  The following describes how the
 * example evolved; the intent is to summarize the steps necessary to
 * develop a SQL Anywhere SOAP client.  A commented section at the end
 * of this script contains a call to test and run the SOAP client.
 *
 * The task is to access weather information based on longitude and latitude
 * co-ordinates by accessing the U.S. national weather web service at:
 *	http://www.weather.gov/xml/
 *
 * The above document provides the location of the WSDL at:
 *	http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php?wsdl
 *
 * Steps:
 * 1) Run wsdlc to generate SQL functions that map to SOAP operations defined
 *    by the target WSDL.  The WSDL may be specified as an URL or a file.
 *    For this example, we will target the WSDL defined by the above URL,
 *    however, please reference gov.weather.wsdl, included with this example,
 *    in the event that the web service has changed since the time of this
 *    writing (Jan 15, 2008).  Be aware that the SQL generated using
 *    gov.weather.wsdl may be out of date.
 *    
 *    The following wsdlc command generated a file called gov.weather.sql
 *	wsdlc -l sql -f gov.weather.sql http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php?wsdl

 *    NOTE: By default wsdlc will generate SQL functions using the naming
 *	convention "ServiceName.SoapOperation".  The intent is to minimize
 *	the risk of SQL namespace collisions.  The -f switch is required
 *	when generating SQL language code.
 *	The default behavior may be modified with the following switches:
 *		-p[=<prefix>] // In this example if <prefix> is "gov_" then the
 *			      // SQL procedure or function name for the SOAP
 *			      // "NDFDgen" SOAP operation would be "gov_NDFDgen"
 *			      // instead of "ndfdXML.NDFDgen".  If no argument
 *			      // is provided then the SQL name is the same as
 *			      // the SOAP operation name, ie. NDFDgen
 *		-x	      // generate a stored procedures rather than a
 *			      // functions.
 *	
 * 2) Edit gov.weather.sql. Notice that some parameters are commented out.
 *    This is a limitation of the SQL wsdlc implementation. It only
 *    understands parameters that are simple primitive types (such as integer,
 *    string, datetime). It cannot generate complex data representations of
 *    structures and arrays.  Complex data can be input, however, by setting the
 *    data type of a complex parameter to XML and using SQL XML statements such
 *    as XMLELEMENT, XMLATTRIBUTES,... to send raw XML fragments.  Therefore
 *    the application developer must manually analyze the WSDL and derive
 *    the XML requirement for any complex parameter exposed by wsdlc.
 * 3) When testing a client stored procedure (or function) it
 *    is frequently helpful to initiate a client log file to make it
 *    easier to analyze the responses from the SOAP server.  For example,
 *	    call sa_server_option('WebClientLogFile', 'c:\temp\test.txt');
 *    immediately turns on logging to record both HTTP request and response
 *    data to 'c:\temp\test.txt'.
 * 4) Once the SOAP requests are producing valid SOAP responses, the log
 *    file may be used to aid in understanding the format of the returned
 *    data.  Since the SOAP envelope returned within the response is a valid
 *    XML document we can parse it using OPENXML to extract data elements
 *    of interest.  This approach is typically used when the SOAP envelope
 *    contains XML data that is integral to the namespace and XML schema of
 *    the SOAP envelope, that is, the data are sub elements of the SOAP
 *    transport.  For this typical case, it is best to define the SQL Anywhere
 *    SOAP client as a function, since, a function will return the response
 *    SOAP envelope which can be parsed using OPENXML to extract the data.
 *    See the SQL Anywhere documentation for examples on how openxml can
 *    be used to parse XML data.
 *
 *    In this example, the response contains a single data element defined
 *    with a data type of string.  The data is a complete standalone XML
 *    document that has been HTML/XML encoded.  The encoding is necessary to
 *    ensure that the data (which is XML) does not invalidate the XML of the
 *    transport (the SOAP envelope).  Therefore, we have an XML document (the
 *    SOAP envelope) containing another XML document (the data).  The data
 *    encapsulates its own XML namespace and schema; it has no relation or
 *    dependence on the SOAP envelope.  In this example it is the XML document
 *    contained within the data section of the SOAP envelope that we wish to
 *    parse.  In contrast to a function, a SQL Anywhere SOAP procedure drills
 *    down into the SOAP body to return the data element as a result set.  The
 *    use of a procedure works best for data that has no XML subelements, only
 *    a single result value.  In this case the single value is a string
 *    representing an encoded XML document.  A SQL Anywhere SOAP procedure
 *    will decode and present the data as an XML document automatically.
 *    Openxml can now be used to parse the resultant XML document.

    SQL Anywhere client SOAP functions vs procedures:

	Define SQL Anywhere functions when:
	    - SOAP operation returns more than one data element.
	    - SOAP operation returns complex data that is integral to the
	      SOAP envelope.  That is, response data are subelements within
	      the context and namespace of the SOAP envelope.
	    Reasoning:
	      openxml can be used directly on the response SOAP envelope to
	      extract pertinent data elements.

	Define SQL Anywhere procedures when:
	    - SOAP operation returns a single simple type.
	    - SOAP operation returns an XML document, where the data and its
	      schema are integral to the XML document, not the SOAP envelope.
	    Reasoning:
	      In the first case the use of openxml is not required since the
	      data is returned directly.  That is, the data following the
	      *Response* element within the SOAP body is internally selected.
	      In the second case the desired data elements are located within
	      an independent XML document.  A SQL Anywhere SOAP procedure
	      will select the *Response* element within the SOAP body and
	      automatically HTML/XML decode it.  The result may then be parsed
	      using openxml to extract the pertinent elements.
 *
 */

--
-- A snippet generated from
--  wsdlc -l sql http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl
-- produced the following function
--
create or replace function "ndfdXML.NDFDgen"( "latitude" decimal
                        , "longitude" decimal
                        , "product" long varchar
                        , "startTime" datetime
                        , "endTime" datetime
                        /* , "weatherParameters" gov.weatherforecasts.xml.DWMLgen.wsdl.ndfdXML_wsdl.WeatherParametersType */
)
    returns xml
    url 'http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php'
    type 'SOAP:RPC'
    set 'SOAP(OP=NDFDgen)'
    namespace 'http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl';

--
-- Analysis using step 2) and 3) above produced the following:
-- NOTE: The weatherParameters parameter type has been changed.
--  NDFDgen is composed of input and output messages. Input refers to the
--  input requirements for the SOAP operation, in this case <input message>
--  is NDFDgenRequest.  <message name="NDFDgenRequest"> contains a 
--  <part name> called product with a data type of string.
--  weatherParameters is defined within the schema section of the WSDL as
--  weatherParametersType, where it defines a list of boolean definitions:
--  maxt, mint, etc.  weatherParameters is defined with a data type of xml
--  since we will have to manually construct an XML fragment for this parameter.
--  See also the WSDL documentation for the NDFDgen <operation> which explains
--  the usage of the product and weatherParameters parameters.
create or replace function "ndfdXML.NDFDgen"( "latitude" decimal
                        , "longitude" decimal
                        , "product" long varchar
                        , "startTime" datetime
                        , "endTime" datetime
                        , "weatherParameters" xml
)
    returns xml
    url 'http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php'
    type 'SOAP:RPC'
    set 'SOAP(OP=NDFDgen)'
    namespace 'http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl';

--
-- Analysis in step 4) above determines that the use of a SOAP procedure
-- call is favorable for the NDFDgen SOAP operation because it returns an
-- XML document.  We can generate stored procedures using wsdlc for all its
-- SOAP operations by specifying a -x option as follows:
--   wsdlc -l sql -f gov.weather.sql -x http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl
-- For this example, we will manually modify the function prototype generated
-- by wsdlc.
--
create or replace procedure "proc.ndfdXML.NDFDgen"( "latitude" decimal
                        , "longitude" decimal
                        , "product" long varchar
                        , "startTime" datetime
                        , "endTime" datetime
                        , "weatherParameters" xml
)
    url 'http://www.weather.gov/forecasts/xml/SOAP_server/ndfdXMLserver.php'
    type 'SOAP:RPC'
    set 'SOAP(OP=NDFDgen)'
    namespace 'http://www.weather.gov/forecasts/xml/DWMLgen/wsdl/ndfdXML.wsdl';

--
-- The following is a wrapper function that makes the SOAP operation call
-- to NDFDgen and extracts maximum temperature results using openxml.
--
create or replace procedure noaa_weather2()
begin
    declare noaa_response xml;

    // call the SOAP operation ndfdgen.
    // select the response into noaa_response variable
    // parameters determined from documentation: http://www.weather.gov/xml/
    // Note: weatherParameters element must be specified within the XML fragment
    //       maxt subelement type is fully qualified.  SOAP specification
    //	     requires that RPC parameters are typed, whereas, DOC parameters
    //       (which refer to data whose types are defined in the schema
    //       of the WSDL) do not.
    select response
      into noaa_response
      from "proc.ndfdXML.NDFDgen"(
            39.0,
            -77.0,
            'time-series',
            '2008-01-01 0:0:0.000',
            '2012-01-01 0:0:0.000',
            '<weatherParameters xsi:type="weatherParametersType"><maxt xsi:type="xsd:boolean">true</maxt></weatherParameters>' )
	    with ("response" xml);

-- Uncomment the following to view the NOAA response XML document
-- Alternatively, create a RAW SQL Anywhere service to relay the noaa_response.
//    select noaa_response;

-- The following is a simple openxml call to retrieve the first start-time,
--  end-time and temperature.  Openxml will generate multiple rows if the
--  subelements within the WITH clause occur multiple times under
--  the XPATH element (dwml/data in this case).
--  ie. each element within the WITH clause must be contained within
--      XPATH anchor element, eg:
--	<dwml><data>
--       <param><start><end><temp></param>
--       <param><start><end><temp></param>
-- Unfortunately, the XML document that we are trying to parse contains
-- two independent lists, eg:
--	<dwml><data>
--	    <time>...
--	    <time>...
--	    <temp>...
--	    <temp>...
--  
//    select *
//      from
//        openxml( noaa_response, '//*:dwml/*:data' )
//                with (  start_time long varchar '*:time-layout/*:start-valid-time/text()',
//                         end_time long varchar '*:time-layout/*:end-valid-time/text()',
//                         T_Fahrenheit long varchar '*:parameters/*:temperature/*:value/text()');


-- The final openxml implementation uses the openxml @mp:id metadata element
-- and row_number to join the results of multiple openxml queries.
-- The result set is a list: start-time, end-time, and max temperatures.
    select start_time, end_time, t_fahrenheit
      from
	(select row_number() over (order by location) id, * from openxml( noaa_response, '//*:start-valid-time' ) with (  location int '@mp:id', start_time long varchar 'text()' )) dt1,
	(select row_number() over (order by location) id, * from openxml( noaa_response, '//*:end-valid-time' ) with (  location int '@mp:id', end_time long varchar 'text()' )) dt2,
	(select row_number() over (order by location) id, * from openxml( noaa_response, '//*:temperature/*:value' ) with (  location int '@mp:id', T_Fahrenheit long varchar 'text()' )) dt3
	where dt1.id=dt2.id and dt2.id=dt3.id

end;

/* Test
 *

call noaa_weather2();

 *
 * Cleanup

drop function "ndfdXML.NDFDgen";
drop procedure "proc.ndfdXML.NDFDgen";
drop procedure noaa_weather2;

 *
 */
