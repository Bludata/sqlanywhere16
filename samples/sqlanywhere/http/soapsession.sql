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
 * Demonstrate how SOAP can leverage SA HTTP sessions to provide stateful
 *  applications.
 *
 *  The example requires that two SA servers are executed with one
 *  acting as the client and the other a server.  For this example
 *  we assume that the *server* starts an http listener on port 80,
 *  while the client is not required to start a listener (since it
 *  only makes outbound HTTP calls). eg:
 *	    dbsrv12 -n example_server -xs http a_server.db
 *	    dbsrv12 -n example_client a_client.db
 *  
 */

/*
  Server-side objects:
    - DISH service: exposes a SOAP endpoint and its SOAP operations
    - SOAP service: create_soap_session creates a new HTTP session
    - SOAP service: inc_soap_session increments and displays count
    - SOAP service: del_soap_session deletes an HTTP session
 */

-- DISH service
call sa_make_object( 'service', 'dish' );
alter service dish
    type 'DISH'
    user DBA
    authorization off
    secure off;

-- SOAP operation: CREATE HTTP Session
call sa_make_object( 'service', 'create_soap_session' );
alter service create_soap_session
    type 'SOAP'
    format 'concrete'
    user DBA
    authorization off
    secure off
    as call sp_create_soap_session( :the_sessionid );

create or replace procedure sp_create_soap_session( a_sessionid long varchar )
result( session_create long varchar )
begin
    call sa_set_http_option( 'sessionId', a_sessionid );
    create variable counter int;
    set counter = 0;

    select 'Created SessionId "' || a_sessionid || '"';
end;

-- SOAP operation: INCREMENT counter via HTTP Session
call sa_make_object( 'service', 'inc_soap_session' );
alter service inc_soap_session
    type 'SOAP'
    format 'concrete'
    user DBA
    authorization off
    secure off
    as call sp_inc_soap_session();

create or replace procedure sp_inc_soap_session()
result( session_counter int )
begin
    if VAREXISTS( 'counter' ) = 0 THEN
	    raiserror 20001 'SessionId is missing or invalid. HTTP cookie is "%1!"', isnull(http_header('cookie'), '');
    else
        set counter = counter +1;
        select counter;
    end if;
end;

-- SOAP operation: DELETE an HTTP Session
call sa_make_object( 'service', 'delete_soap_session' );
alter service delete_soap_session
    type 'SOAP'
    format 'concrete'
    user DBA
    authorization off
    secure off
    as call sp_delete_soap_session( :theSessionId );

create or replace procedure sp_delete_soap_session( theSessionId long varchar )
result( session_delete long varchar )
begin
    declare ses_id long varchar;
    // get our SessionId from connection property...
    select connection_property( 'sessionid' ) into ses_id;
    if ses_id = '' then
	    raiserror 20000 'SessionId contained in the cookie "%1!" does not exist.', isnull(http_header('cookie'),'');
    else
        call sa_set_http_option( 'sessionId', null );
        select 'Deleted SessionId "' || ses_id || '"';
    end if;
end;

/*
 * Client-side objects:
    cli_create_session is the SOAP request to create an HTTP session
    cli_inc_soap_session is the SOAP request to increment stateful counter
    cli_delete_session is the SOAP request to delete an HTTP session

   The client procedures make an HTTP/SOAP request to the *server*
   operations defined above.  The URL clause may need to be changed
   if the *server* is running on another host and/or is not using port 80.
 */

-- NOTE: SOAP operation parameter names must be identical to parameter names
--       defined within the SA SOAP service (the SA service may call
--       a procedure which uses alternate parameter names, see
--       sp_create_soap_session for an example of this)
create or replace procedure cli_create_session( the_sessionid long varchar )
    url 'http://localhost/dish'
    type 'SOAP:DOC'
    set 'SOAP(OP=create_soap_session)';

-- NOTE: a parameter cannot have an '_' within it when using parameter
--       substitution, therefore, we use mysession instead of the_sessionid
--       as a parameter for the following procedure.
create or replace procedure cli_inc_soap_session( mysession long varchar )
    url 'http://localhost/dish'
    type 'SOAP:DOC'
    set 'SOAP(OP=inc_soap_session)'
    header 'cookie:sessionId=!mysession';

create or replace procedure cli_delete_session( theSessionId long varchar )
    url 'http://localhost/dish'
    type 'SOAP:DOC'
    set 'SOAP(OP=delete_soap_session)'
    header 'cookie:sessionId=!theSessionId';

--
-- The following client objects demonstrate the use of openxml to increment
-- the soap_session.  In contrast to a procedure an SA client SOAP function
-- returns the SOAP envelope of the response.  We can pass this XML document
-- directly into openxml with an XPATH specification to pull out the
-- session_count.
-- NOTE: An SA SOAP client procedure is only really useful when calling a
-- SOAP operation that returns a single primitive type such as a STRING.
-- SA always returns a RESULT SET in the form of a Dataset XML structure
-- when the SA SOAP SERVICE FORMAT is 'CONCRETE'
-- ALSO: 'WSDLC -l sql ...' utility application could be used to automatically
-- generate the SA client functions or procedures for the above server-side
-- SOAP operations by specifying the URL to the *server* DISH service.
--

-- the following function returns an xml document containing the SOAP response
-- envelope
create or replace function fun_inc_soap_session( mysession long varchar )
returns xml
    url 'http://localhost/dish'
    type 'SOAP:DOC'
    set 'SOAP(OP=inc_soap_session)'
    header 'cookie:sessionId=!mysession';

create or replace procedure wrapper_session_inc( the_session long varchar )
result( session_count int )
begin
    declare soap_response long varchar;
    declare the_count int;
    declare crsr cursor for select * from
        openxml( soap_response, '//*:rowset/*:row' )
                with (  "the_count" int '*:session_counter/text()' );

    set soap_response = fun_inc_soap_session( the_session );

    open crsr;
    fetch crsr into the_count;
    close crsr;

    if the_count is null then
	    raiserror 20002 'SessionId "%1!" does not exist.', isnull(the_session, '');
    else
        select the_count;
    end if;
end;

/**
 * Test - to be executed from within the *client*

call cli_create_session( 'test12345' );
call cli_inc_soap_session( 'test12345' );
call cli_delete_session( 'test12345' );
call wrapper_session_inc( 'test12345' );

*/

