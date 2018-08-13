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

-- show_request_info

-- Sample urls:
--	http://localhost/show_request_info
--	http://localhost/show_request_info?var1=123&var2=456

create or replace procedure show_request_info( set_http_status int )
result( vars long varchar )
begin
	declare res    long varchar;
	declare var    long varchar;
	declare varval long varchar;
	declare i      int;

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	if set_http_status is not null then
		call dbo.sa_set_http_header( '@HttpStatus', string(set_http_status) );
	end if;

	set res =  '<html><head><title>Request Information</title></head>\n<body>\n'
		|| '<h1><center>Request Information</center></h1>\n'
		|| '<center><table border=1 align=center valign=top>\n'
		|| '<tr><th colspan=2 align=center>Headers</th></tr>\n'
		|| '<tr><th>Key</th><th>Value</th></tr>\n';

	set var  = NULL;
loop_h:	
	loop
		set var = next_http_header( var );
		if var is null then leave loop_h end if;
		set res = res
			|| '<tr align=center><td>' || html_encode(var) || '</td><td>'
			|| html_encode( http_header(var) ) || '</td>\n';
	end loop;
	set res = res || '</table></center><br>\n';

	set res = res
		|| '<center><table border=1 align=center valign=top>\n'
		|| '<tr><th colspan=2 align=center>Variables</th></tr>\n'
		|| '<tr><th>Name</th><th>Value</th></tr>\n';

	set var  = NULL;
loop_v:	
	loop
		set var = next_http_variable( var );
		if var is null then leave loop_v end if;
		set i = 1;
	loop_i:
		loop
			set varval = http_variable( var, i );
			if varval is null then leave loop_i end if;
			set res = res
				|| '<tr align=center><td>' || html_encode(var) || '</td><td>'
				|| html_encode(varval) || '</td>\n';
			set i = i + 1;
		end loop;
	end loop;
	set res = res || '</table></center>\n';
	set res = res || '</body></html>';

	select res;
end
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='show_request_info') then
    drop service show_request_info;
end if
go

create service show_request_info type 'raw' authorization off user dba secure off
  as call show_request_info( :set_http_status )
go
