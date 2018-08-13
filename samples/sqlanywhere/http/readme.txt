// ***************************************************************************
// Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
// ***************************************************************************
/* *********************************************************************
// This sample code is provided AS IS, without warranty or liability
// of any kind.
// 
// You may use, reproduce, modify and distribute this sample code
// without limitation, on the condition that you retain the foregoing
// copyright notice and disclaimer as to the original code.  
// 
// ****************************************************************** */

cookie.sql
----------
A small demonstration on how to set and retrieve client-side cookies 
within a SQL procedure.

gallery.sql
-----------
A small demonstration on how to handle binary data within an HTTP web 
service procedure. This demonstration will accept a JPG or GIF image, 
store it in the database, and then allow the image to be displayed again 
at the client.

To use this example with larger images, set the server command line http
option MaxRequestSize to 3M or greater.
Example:  -xs http(port=80;MaxRequestSize=3m)

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/gallery 

to try out the example (replace 80 with the port number that was specified 
when the database server was started). A sample image, picture.jpg, has
been provided.

Once images have been loaded, you can also try the gallery_image service:

http://localhost:80/gallery_image?url=1 (or 2, 3, etc.)

html_select.sql
html_calendar.sql
html_cal_test.sql
----------
These three SQL files demonstrate how to use forms and HTML tables to 
display a simple calendar.

The SQL file html_select.sql contains a few utility routines which 
generate various types of HTML SELECT tag blocks.

The SQL file html_calendar.sql contains two routines to generate different 
formats of a calendars - a year at a time or a month at a time.

The SQL file html_cal_test.sql defines the web service that you will 
interact with using a web browser.

Load each of these files and compile them with Interactive SQL. Then
browse to http://localhost:80/html_calendar_test to try out the
example (replace 80 with the port number that was specified when 
the database server was started).

image_readfile.sql
------------------
A small demonstration of how to use xp_read_file to retrieve images from 
a local disk and return it as the response to an HTTP request.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/image?url=<install-dir>\Scripts\adata\CottonCap.jpg

to try out the example (replace 80 with the port number that was specified 
when the database server was started and replace <install-dir> with the 
location of the SQL Anywhere installation).

json_sample.sql
---------------
A small demonstration of how to implement auto-complete using a JSON service.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/getinfo

to try out the example (replace 80 with the port number that was specified 
when the database server was started). 

post_data.sql
-------------
A small demonstration of how to generate various types of HTML INPUT form types,
and how to handle their responses.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/post_data

to try out the example (replace 80 with the port number that was specified 
when the database server was started). 

put_data.sql
------------
A small demonstration of a service that uses HTTP PUT to upload binary and 
text files.

Compile the example with Interactive SQL. Try the following commands from
a command prompt. This demonstration uses the Curl application which is
avaiable from http://curl.haxx.se. 

curl -i -X PUT -H "Content-Type: text/plain" -d "hello world" http://localhost:80/resource/hellomsg
curl -T picture.jpg -H Content-Type:image/jpeg http://localhost:80/resource/picture
curl -i -X DELETE http://localhost:80/resource/hellomsg


Replace 80 with the port number that was specified when the database 
server was started. 

session.sql
-----------
A demonstration of how to create, use, and delete HTTP sessions.
The demonstration shows how to use cookies and URI parameters to keep 
track of the session ID.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/session

to try out the example (replace 80 with the port number that was specified 
when the database server was started). 

show_request_info.sql
---------------------
This example will display all of the HTTP headers and HTTP variables 
that are sent to the HTTP web server when the client make a request.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/show_request_info

and

http://localhost:80/show_request_info?var1=123&var2=456

to try out the example (replace 80 with the port number that was specified 
when the database server was started). 

show_table.sql
--------------
This example demonstrates a simple web service that allows the client 
user to browse the tables within the database.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/show_table

to try out the example (replace 80 with the port number that was specified 
when the database server was started). 

Provide a valid database userid and password when prompted.

soap.globalweather.sql
----------------------
This example demonstrates how to configure a simple soap client.  It 
explains how to use wsdlc to automatically generate the SQL code from 
a WSDL.

soap.gov.weather.sql
--------------------
This example demonstrates how to configure a more complex soap client.  It explains
how to use wsdlc to automatically generate the SQL code from a WSDL and openxml to
parse an XML document.

soapsession.sql
---------------
A small demonstration of how to incorporate HTTP sessions within a SOAP service.

test_request_db.sql
-------------------
A small example for collecting test case requests.

Compile the example with Interactive SQL. Then browse to 

http://localhost:80/show_groups

to try out the example (replace 80 with the port number that was specified 
when the database server was started).
