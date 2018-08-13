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

-- html "calendar" and "select" support routines test example
--
-- requires html_select_* functions
-- requires html_calendar_* functions

-- read '<samples-dir>\Samples\SQLAnywhere\HTTP\html_select.sql';
-- read '<samples-dir>\Samples\SQLAnywhere\HTTP\html_calendar.sql';

--

create or replace procedure html_calendar_test( year int, month int )
result (html_document long varchar)
begin
	declare res long varchar;
	declare the_date date;

	set month = if month < 1 then 1 else if month > 12 then 12 else month endif endif;
	
	if month is not null then
	    set the_date = ymd( year, month, 1 );
	else
	    set the_date = now();
	end if;

	set res = '<html><head><title>Examples of HTML Calendar Routines</title></head>\n<body>\n';
	set res = res || '<h1>Examples of HTML Calendar Routines</h1>\n';

	set res = res || '<hr>\n';

	set res = res
		|| '<table><tr>\n'
		|| '<td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| 'Select a different year: ' || html_select_year( 'year', year )
		|| '<input type="submit" value="Display Year">\n'
		|| '</form>\n'
		|| '</td><td>'
		|| ' or navigate years using '
		|| '</td><td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| '<input type="hidden" name="year" value="' || string( year-1 ) || '">\n'
		|| '<input type="submit" value="&nbsp;&lt;&nbsp;">\n'
		|| '</form>\n'
		|| '</td><td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| '<input type="hidden" name="year" value="'
		|| string( datepart( year, the_date ) ) || '">\n'
		|| '<input type="submit" value="Current">\n'
		|| '</form>\n'
		|| '</td><td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| '<input type="hidden" name="year" value="' || string( year+1 ) || '">\n'
		|| '<input type="submit" value="&nbsp;&gt;&nbsp;">\n'
		|| '</form>\n'
		|| '</tr></table>\n';

	set res = res
		|| '<table><tr><td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| 'or pick a year: ' || html_select_year( 'year', year )
		|| ' and a month: ' || html_select_month( 'month', month )
		|| '<input type="submit" value="Display Month"><br>\n'
		|| '</form>\n'
		|| '</td><td> or </td>';

	IF month is not NULL THEN
	    BEGIN
		declare prev date;
		set prev = dateadd( month, -1, the_date );
		set res = res
			|| '<td>'
			|| '<form method="GET" action="html_calendar_test">\n'
			|| '<input type="hidden" name="year" value="'
			|| string( datepart( year, prev ) ) || '">\n'
			|| '<input type="hidden" name="month" value="'
			|| string( datepart( month, prev ) ) || '">\n'
			|| '<input type="submit" value="&nbsp;&lt;&nbsp;">\n'
			|| '</form>\n'
			|| '</td>';
	    END;
	END IF;
	set res = res
		|| '<td>'
		|| '<form method="GET" action="html_calendar_test">\n'
		|| '<input type="hidden" name="year" value="'
		|| string( datepart( year, the_date ) ) || '">\n'
		|| '<input type="hidden" name="month" value="'
		|| string( datepart( month, the_date ) ) || '">\n'
		|| '<input type="submit" value="Current">\n'
		|| '</form>\n'
		|| '</td>';
	IF month is not NULL THEN
	    BEGIN
		declare next date;
		set next = dateadd( month,  1, the_date );
		set res = res
			|| '<td>'
			|| '<form method="GET" action="html_calendar_test">\n'
			|| '<input type="hidden" name="year" value="'
			|| string( datepart( year, next ) ) || '">\n'
			|| '<input type="hidden" name="month" value="'
			|| string( datepart( month, next ) ) || '">\n'
			|| '<input type="submit" value="&nbsp;&gt;&nbsp;">\n'
			|| '</form>\n'
			|| '</td>'
	    END;
	END IF;
	set res = res || '</tr></table>\n';

	set res = res || '<hr>';
	IF month IS NULL or month = '' THEN
		set res = res || html_calendar_by_year( year );
	ELSE
		set res = res || html_calendar_by_month( year, month );
	END IF;
	set res = res || '<hr>';
	set res = res || '</body></html>';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	select res;
end
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='html_calendar_test') then
    drop service html_calendar_test
end if
go

create service html_calendar_test type 'raw' authorization off user dba secure off
  as call html_calendar_test( :year, :month )
go
