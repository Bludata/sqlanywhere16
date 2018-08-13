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

-- cookie
--     procedure definition and service of an example of how to set and use HTTP cookies

create or replace function http_cookie( name varchar(250) )
returns long varchar
begin
	declare str long varchar;	-- work str containing cookie value

	set str  = http_header( 'Cookie' );

	if str is not null then
	    begin
		declare i int;

		set name = name || '=';		-- we want to find 'name='
		set i = charindex( name, str );
		if i > 0 then
			set str = substr( str, i+length(name) );
			set i = charindex( ';', str );
			if i > 0 then
				set str = left( str, i );
			end if;
		else
			set str = NULL;
		end if;
	    end;
	end if;
	return str;
end;
go

create or replace procedure set_http_cookie(
			name	varchar(250),
			value	long varchar,
			max_age	integer,	-- expire cookie after this number of seconds
			path	varchar(250) default '/' )
begin
	call dbo.sa_set_http_header( 'Set-Cookie',
		name || '=' || value || ';'
--	||	' max-age=' || string( max_age ) || ';'	-- doesn't work with IE 6.0
        ||      ' expires=' || STRING( DATEFORMAT( DATEADD( SECOND, max_age, CURRENT TIMESTAMP ), 
					  'Ddd, DD-Mmm-YY hh:nn:ss' ), ' GMT' ) || ';'
	||	' path=' || http_encode(path) || ';' );
	-- Note: You may also want to add domain=...; comment=....; and secure
end;
go

create or replace procedure cookie( action varchar(10) )
result (html_document long varchar)
begin
	declare res long varchar;	-- ultimate result
	declare cur long varchar;	-- current cookie value
	declare str long varchar;	-- new cookie value

	set action = ifnull( action, 'welcome', action );

	-- determine current value of user's favorite cookie
	set cur = http_cookie( 'my_favorite_cookie_is' );
	if cur is not null then
		-- we need to 'decode' the cookie
		-- in this case, we just remove the '-' characters
		set cur = replace( cur, '-', ' ' );
	end if;

	set res =  '<html><head><title>Cookie</title></head>\n<body>\n';

	--------------------
	if action = 'welcome' then
		set res = res
		||	'<h1><center>Welcome to Cookies</center></h1>\n'
		||	'<hr><br>'
		||	'<br><center>This example shows you how you can set and retrieve HTTP cookies.</center>';

		if cur is not null then
			set res = res
			||	'<br><center>Your favorite cookie is currently set to <b>'
			||	html_encode(cur)
			||	'</b><br><a href="cookie?action=delete">'
			||	'Click here to delete the cookie</a></center>\n';
		end if;

		set res = res
		||	'<br><center>What is your favorite type of cookie?<br>\n'
		||	'<br><a href="cookie?action=set&value=Chocolate">Chocolate</a>\n'
		||	'<br><a href="cookie?action=set&value=Chocolate-Chip">Chocolate Chip</a>\n'
		||	'<br><a href="cookie?action=set&value=Peanut-Butter">Peanut Butter</a>\n'
		||	'<br><a href="cookie?action=set&value=Raisin">Raisin</a>\n'
		||	'<br><a href="cookie?action=set&value=Orio">Orio</a>\n'
		||	'<br><a href="cookie?action=set&value=Butter-Pecan">Butter Pecan</a>\n'
		||	'<br><a href="cookie?action=set&value=Coconut">Coconut</a>\n'
		||	'<br><a href="cookie?action=set&value=Shortbread">Shortbread</a>\n'
		||	'<br><a href="cookie?action=set&value=Gingerbread">Gingerbread</a>\n'
		||	'</center>\n';

	--------------------
	elseif action = 'set' then
		set res = res
		||	'<h1><center>Set Cookies</center></h1>\n'
		||	'<hr><br>';

		if cur is not null then
			set res = res
			||	'<br><center>Your favorite cookie was previously set to <b>'
			||	html_encode(cur)
			||	'</b><br><a href="cookie?action=delete">'
			||	'Click here to delete the cookie</a></center>\n';
		end if;

		set str = http_variable( 'value' );
		if str is null or str = '' then
			set str = 'Unknown';
		end if;

		-- set cookie to last for 365 days
		call set_http_cookie( 'my_favorite_cookie_is', str, 365*24*60*60 );

		set str = replace( str, '-', ' ' );
		set res = res
		||	'<br><center>When you return next time, I will say that your favorite cookie is '
		||	'<b>' || str || '</b></center>'
		||	'<br>\n'
		||	'<br><center><a href="cookie?action=welcome">Back to Welcome page</a></center>\n';

	--------------------
	elseif action = 'delete' then
		set res = res
		||	'<h1><center>Delete Cookies</center></h1>\n'
		||	'<hr><br>';

		if cur is not null then
			set res = res
			||	'<br><center>Your favorite cookie was previously set to <b>'
			||	html_encode(cur)
			||	'</b></center><br>\n';
		end if;

		-- age of 0 causes cookie to be deleted
		call set_http_cookie( 'my_favorite_cookie_is', str, 0 );

		set res = res
		||	'<br><center>You now have no cookie preference selected</center>'
		||	'<br>\n'
		||	'<br><center><a href="cookie?action=welcome">Back to Welcome page</a></center>\n';

	--------------------
	else
		set res = res
		||	'<h1><center>Huh?</center></h1>\n'
			|| '<br>Huh? unknown action (' || html_encode(action) || ' - please try again !<br>';
	end if;	

	set res = res
	||	'<br><br><br><hr>'
	||	'<center>For more information on how to use cookies (the HTTP type), see'
	||	'<br><a href="http://curl.haxx.se/rfc/cookie_spec.html">'
	||	'http://curl.haxx.se/rfc/cookie_spec.html'
	||	'</a>\n'
	||	'<br>or'
	||	'<br><a href="http://www.ietf.org/rfc/rfc2109.txt?number=2109">'
	||	'http://www.ietf.org/rfc/rfc2109.txt?number=2109'
	||	'</a></center><hr>\n';

	set res = res	
	||	'<div class=powered><center>POWERED BY<br>'
	||	'<i>' || html_encode( property('ProductName') || ' ' || property('ProductVersion') ) || '</i><br>'
	||	'<small><i>' || html_encode( property('LegalCopyright') ) || '</i></small></center><hr></div>\n'
	||	'</body>\n</html>\n';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	select res;
end
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='cookie') then
    drop service cookie;
end if;
go

create service cookie type 'raw' authorization off user dba secure off
  as call cookie( :action )
go
