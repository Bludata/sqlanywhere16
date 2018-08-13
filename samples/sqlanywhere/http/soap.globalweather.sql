// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
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
 * of this script contains procedure calls to test and run the example.
 *
 * The task is to access weather information based on city and country
 * from a web service documented at:
 *      http://www.webservicex.net/WCF/ServiceDetails.aspx?SID=48
 *
 * The above document provides the location for the WSDL at:
 *      http://www.webservicex.net/globalweather.asmx?wsdl
 *
 * The following two SQL Anywhere procedures were generated using
 * wsdlc.  As in the case of soap.gov.weather.sql, both procedures
 * return a STRING type containing an XML document.  As explained in the
 * soap.gov.weather.sql example, it is most efficient to generate SQL
 * Anywhere SOAP stored procedures rather than functions when working with
 * SOAP operations that return XML documents.  "GlobalWeather.GetWeather" and
 * "GlobalWeather.GetCitiesByCountry" were generated using the following:
 *	wsdlc -l sql -f globalweather.sql -x http://www.webservicex.net/globalweather.asmx?wsdl
 * producing:
 *      globalweathersoap.sql
 *
 * Unlike soap.gov.weather.sql, this web service produced SQL that
 * required no manual tweaking, since all parameters are simple data types.
 * Please reference the steps described in soap.gov.weather.sql for a general
 * approach to developing HTTP/SOAP client applications.
 *
 * globalweather.wsdl is a snapshot of the webservicesx.net WSDL taken at
 * the time of this writing (Jan. 15, 2008).  It may be referenced in the
 * event that changes have occured in the web service definitions.  Be aware
 * that the SQL generated using globalweather.wsdl may not work if it
 * is out of date.
 */

--
-- The following two procedures were generated using wsdlc
-- ( ~/net.webservicex/globalweathersoap.sql copied here for convenience)
--
create or replace procedure "GlobalWeather.GetWeather"( "CityName" long varchar
                        , "CountryName" long varchar
)
    url 'http://www.webservicex.net/globalweather.asmx'
    type 'SOAP:DOC'
    set 'SOAP(OP=GetWeather)'
    namespace 'http://www.webserviceX.NET';

create or replace procedure "GlobalWeather.GetCitiesByCountry"( "CountryName" long varchar
)
    url 'http://www.webservicex.net/globalweather.asmx'
    type 'SOAP:DOC'
    set 'SOAP(OP=GetCitiesByCountry)'
    namespace 'http://www.webserviceX.NET';

-- End WSDLC generated SQL

/*
 * Simply by calling the above procedures with valid parameters, it was
 * immediately evident that XML content was being returned by both SOAP
 * operations.  Examining the WSDL only reveals that a single element
 * of type string named GetWeatherResult and GetCitiesByCountryResult
 * respectively are returned by the two SOAP operations.
 * The following is a brief examination of the WSDL output specification:
 *   The GetWeather and GetCitiesByCountry <wsdl:operation> elements 
 *   specify GetWeatherSoapOut and GetCitiesByCountrySoapOut <wsdl:output>
 *   message elements respectively.
 *   These in turn map to <wsdl:message> names which map to the
 *   TargetNameSpace (tns) elements GetWeatherResponse and
 *   GetCitiesByCountryResponse elements within the schema section of
 *   the WSDL.  These in turn define a single element of type string
 *   named GetWeatherResult and GetCitiesByCountryResult.  Calling the
 *   above procedures and examining the WebClientLogFile (described in
 *   step 3) within the soap.gov.weather.sql example) we can verify that
 *   an HTTP/XML encoded document is contained within GetWeatherResult and
 *   GetCitiesByCountryResult elements for the respective procedures.
 */

--
-- The following wrapper procedures generate SQL result sets
-- from the returned XML documents for the above SOAP operations.
--
create or replace procedure CanadianCities()
begin
    declare cities_response xml;

    // SQL client procedures do not support the RESULT clause.
    // The following select statement uses the WITH clause to
    // describe the shape of the result set returned by the
    // SOAP client procedure call.  The SOAP call result is stored
    // in cities_response.
    select response
      into cities_response
      from "GlobalWeather.GetCitiesByCountry"( 'Canada' )
            with ("response" xml);

-- Uncomment the following to view the response XML document
-- Alternatively, create a RAW SQL Anywhere service to relay the response.
//    select cities_response;

    // The XML document is not namespace qualified - only local names
    // are used.  Therefore, in the following openxml the XPATH parameter
    // and WITH clause do not need to provide a namespace prefix qualifier.
    // (See soap.gov.weather.sql example where XPATH == '//*:dwml/*:data')
    select *
      from
        openxml( cities_response, '//NewDataSet/Table' )
                with (  "city" long varchar 'City' ) order by city;
end;

create or replace procedure GetWeather( city long varchar, country long varchar)
begin
    declare weather_response xml;

    select response
      into weather_response
      from "GlobalWeather.GetWeather"( city, country )
            WITH ("response" xml);

-- Uncomment the following to view the response XML document
-- Alternatively, create a RAW SQL Anywhere service to relay the response.
//    select weather_response;

    // Within the WITH clause of the following openxml statement
    // we use the meta element @mp:localname to select the element
    // name of the current element followed by its text value
    select *
      from
        openxml( weather_response, '//CurrentWeather/*' )
                with (  "attribute" long varchar '@mp:localname',
                        "value" long varchar 'text()' );
end;

/*
 * Test
 *

call CanadianCities();
call "GetWeather"( 'Waterloo', 'Canada' );

 */
 
/*
 * Cleanup
 *

drop procedure "GlobalWeather.GetCitiesByCountry";
drop procedure "GlobalWeather.GetWeather";
drop procedure "GetWeather";
drop procedure "CanadianCities";

 */
