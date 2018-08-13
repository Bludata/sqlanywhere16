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

-- put_data
--	an example of how to use the HTTP PUT and DELETE method
--	to upload and delete resource data.
--	Also supports GET and HEAD methods.
--
-- usage:
--	curl -i -X PUT -H "Content-Type: text/plain" -d "hello world" http://localhost/resource/hellomsg
--	curl -T picture.jpg -H Content-Type:image/jpeg http://localhost/resource/picture	
--	curl -i -X DELETE http://localhost/resource/hellomsg

-- For information on Curl, please see http://en.wikipedia.org/wiki/CURL

-- Curl is available from http://curl.haxx.se

DROP TABLE IF EXISTS DBA.myresources;

create table myresources(
	"url"		varchar(250)	not null,
	content_type	varchar(99) 	not null,
	content_data	long binary,
	primary key( url )
);

create or replace procedure sp_myresource()
result ( rawdoc long binary )
begin
	declare @url long varchar;
	set @url = http_header('@HttpURI');

	case http_header( '@HttpMethod' )
	when 'PUT' then
		-- store the body/text in a table using the pk column = @url

		if exists( select * from myresources where myresources.url = @url ) then
			update myresources
			    set content_data = isnull( http_variable('body'), http_variable('text') ),
				content_type = http_header('content-type')
			    where "url" = @url;
			call dbo.sa_set_http_header( '@HttpStatus', '200' );	-- 'ok' response .. meaning resource has been updated
		else
			insert into myresources( "url", content_type, content_data )
				values( @url, http_header('content-type'), isnull( http_variable('body'), http_variable('text') ) );
			call dbo.sa_set_http_header( '@HttpStatus', '201' );	-- 'created' response
		end if;
		call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
		select '';

	when 'GET' then
	    begin
		-- get content from table, convert text to user charset if required

		declare @content_type varchar(99);
		declare @content_data long binary;

		select content_type, content_data
			into @content_type, @content_data
			from myresources
			where myresources.url = @url;
		if @content_type is null then
			call dbo.sa_set_http_header( '@HttpStatus', '404' );	-- 'not found' response
			call dbo.sa_set_http_header( 'Content-Type', 'text/html' ); -- or whatever you want to pick !
			select '';
		else
			if @content_type like 'text/%' then
				set @content_data = csconvert( @content_data, connection_property('CharSet') );
			end if;
			call dbo.sa_set_http_header( '@HttpStatus', '200' );	-- 'not found' response
			call dbo.sa_set_http_header( 'Content-Type', @content_type );	-- or whatever content type the data is !
			select @content_data;
		end if;
	    end;

	when 'HEAD' then
	    begin
		-- get content from table, convert text to user charset if required

		declare @content_type varchar(99);
		declare @content_data long binary;

		select content_type, content_data
			into @content_type, @content_data
			from myresources
			where myresources.url = @url;
		if @content_type is null then
			call dbo.sa_set_http_header( '@HttpStatus', '404' );	-- 'not found' response
			call dbo.sa_set_http_header( 'Content-Type', 'text/html' ); -- or whatever you want to pick !
		else
			call dbo.sa_set_http_header( '@HttpStatus', '200' );	-- 'not found' response
			call dbo.sa_set_http_header( 'Content-Type', @content_type );	-- or whatever content type the data is !
		end if;
		select '';
	    end;

	when 'DELETE' then
	    begin
		declare @content_type varchar(99);
		delete from myresources where "url" = @URL;

	    end;

	else
		call dbo.sa_set_http_header( '@HttpStatus', '400' );	-- 'bad request' response
		call dbo.sa_set_http_header( 'Content-Type', 'text/html' ); -- or whatever you want to pick !
		select '';
	end case;
end;

call sa_make_object( 'service', 'resource' );
alter service "resource"
    type 'raw'
    authorization off
    user dba
    secure off
    url on
    methods 'HEAD,GET,PUT,DELETE'
    as call sp_myresource();

// select url, content_type, content_data from myresources;
