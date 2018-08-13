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

-- image_readfile sample application
--
-- This example shows how you can read a variety of types of file.
--
-- requires:
--	<nothing> but perhaps some sample files to load

-- From a browser:
-- http://localhost/image?url=<install-dir>\Scripts\adata\CottonCap.jpg

create or replace procedure image_readfile( filename varchar(250) )
result (rawdoc long binary)
begin
	declare image long binary;

	set image = xp_read_file( http_decode( filename ) );
	if image is NULL then
		call sa_set_http_header( 'Content-Type', 'text/plain' );
		set image = 'Oops: Image ' || filename || ' not found\n';
		set image = csconvert( image, connection_property('CharSet') );
	else
		case
		when right( filename, 4 ) = '.txt' or right( filename, 4 ) = '.sql' then
			call sa_set_http_header( 'Content-Type', 'text/plain' );
			set image = csconvert( image, connection_property('CharSet') );

		when right( filename, 4 ) = '.bmp' then
			call sa_set_http_header( 'Content-Type', 'image/bmp' );
		when right( filename, 4 ) = '.jpg' or right( filename, 5 ) = '.jpeg' then
			call sa_set_http_header( 'Content-Type', 'image/jpeg' );
		when right( filename, 4 ) = '.gif' then
			call sa_set_http_header( 'Content-Type', 'image/gif' );

		when right( filename, 4 ) = '.wav' then
			call sa_set_http_header( 'Content-Type', 'audio/x-wav' );
		when right( filename, 4 ) = '.mp3' then
			call sa_set_http_header( 'Content-Type', 'audio/mp3' );
		when right( filename, 4 ) = '.mpg' then
			call sa_set_http_header( 'Content-Type', 'video/mpeg' );

		when right( filename, 4 ) = '.tar' then
			call sa_set_http_header( 'Content-Type', 'application/x-tar' );
		when right( filename, 4 ) = '.zip' then
			call sa_set_http_header( 'Content-Type', 'application/x-zip' );
		else
			-- ? what type is it? you can add to the above list of types
			-- we'll assume jpeg (but its only a guess)
			call sa_set_http_header( 'Content-Type', 'image/jpeg' );
		end case;
		call sa_set_http_header( 'Content-Length', string(length(image)) );
	end if;
	select image;
end;
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='image') then
    drop service image
end if
go

create service image type 'raw' authorization off user dba url on
    as call image_readfile( :url )
go
