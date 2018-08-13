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

-- post_data
--     procedure definition and service

-- Usage: browse to http://localhost/post_data


create or replace procedure post_data( method varchar(4) )
result (html_document long varchar)
begin
	declare res long varchar;

	set res = '<html><head><title>Examples of Post Data</title></head>\n<body>\n';
	set res = res || '<h1>Examples of Post Data</h1>\n';

	set method = ifnull( method, 'post', method );
	if method <> 'post' and method <> 'get' then
		set res = res || 'Invalid form method requested "' || method || '"<br>\n';
		set method = 'POST';
	else
		set method = upper( method );
	end if;

	set res = res || 'Form submission type is set to "<b>' || method || '</b>".'
		      || ' Click <a href="post_data?method='
		      || ( if method = 'POST' then 'GET' else 'POST' endif )
		      || '">here to set it to '
		      || ( if method = 'POST' then 'GET' else 'POST' endif )
		      || '</a>'
		      || '<br><hr>\n';
	set res = res || '<form method="' || method || '" action="display_post_data">\n';
	set res = res || 'Hidden:'
		      || '<input type="hidden" name="hd" value="hidden-data"><br>\n';
	set res = res || 'Text:'
		      || '<input type="text" name="td" size=20><br>\n';
	set res = res || 'Password:'
		      || '<input type="password" name="pd" size=20><br>\n';
	set res = res || 'Text Area:<br>'
		      || '<textarea name="tad" rows=5 cols=40>'
		      || '</textarea><br>\n';
	set res = res || 'Radio: \n'
		      || '<input type="radio" default name="rd" value="A"> A\n'
		      || '<input type="radio" name="rd" value="B"> B\n'
		      || '<input type="radio" name="rd" value="C"> C<br>\n';
	set res = res || 'Checkbox: '
		      || '<input type="checkbox" checked name="cb">Com<br>\n';
	set res = res || 'Select: \n'
		      || '<select name="sd">\n'
		      || '<option selected>Select One</option>\n'
		      || '<option>Bruce</option>\n'
		      || '<option>Glenn</option>\n'
		      || '<option>John</option>\n'
		      || '<option>Mark</option>\n'
		      || '<option>Peter</option>\n'
		      || '</select><br>\n';
	set res = res || 'Multiple: \n'
		      || '<select name="sdm" size=3 multiple>\n'
		      || '<option>SQL Anywhere</option>\n'
		      || '<option>MobiLink</option>\n'
		      || '<option>UltraLite</option>\n'
		      || '<option>Sybase Central</option>\n'
		      || '<option>Interactive SQL</option>\n'
		      || '<option>SQL Anywhere Console Utility</option>\n'
		      || '</select><br>\n';
	set res = res || 'Image: '
		      || '<input type="image" src="http://www.december.com/html/images/world.gif"'
		      || ' name="id" align="bottom"><br>\n';
	set res = res || 'Submit: '
		      || '<input type="submit" value="Display"><br>\n';
	set res = res || 'Reset: '
		      || '<input type="reset" value="Clear"><br>\n';
	set res = res || '</form>\n';
	set res = res || '<hr><a href="http://www.w3.org/TR/html4/interact/forms.html">'
		      || 'See here for more information on HTML Forms</a>\n';
	set res = res || '<hr>\n</body>\n</html>';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	select res;
end
go

create or replace procedure display_post_data(
	 hd  long varchar,
	 td  long varchar,
	 pd  long varchar,
	 tad long varchar,
	 rd  long varchar,
	 cb  long varchar,
	 sd  long varchar,
	 idx long varchar,
	 idy long varchar
	)
result (html_document long varchar)
begin
	declare res long varchar;
	declare sdm long varchar;

	set res = '<html><head><title>Display Post Data</title></head>\n<body>\n';
	set res = res || '<h1>Display Post Data</h1>\n';
	set res = res || '<table border=1>';
	set res = res || '<tr><th>Input Type</th><th>Value</th></tr>';
	set res = res || '<tr><td>hidden</td><td>'
		      || ifnull( hd, '<i>-NULL-</i>', html_encode(hd) ) || '</td></tr>\n';
	set res = res || '<tr><td>text</td><td>'
		      || ifnull( td, '<i>-NULL-</i>', html_encode(td) ) || '</td></tr>\n';
	set res = res || '<tr><td>password</td><td>'
		      || ifnull( pd, '<i>-NULL-</i>', html_encode(pd) ) || '</td></tr>\n';
	set res = res || '<tr><td>textarea</td><td>'
		      || ifnull( tad, '<i>-NULL-</i>', html_encode(tad) ) || '</td></tr>\n';
	set res = res || '<tr><td>radio</td><td>'
		      || ifnull( rd, '<i>-NULL-</i>', html_encode(rd) ) || '</td></tr>\n';
	set res = res || '<tr><td>checkbox</td><td>'
		      || ifnull( cb, '<i>-NULL-</i>', html_encode(cb) ) || '</td></tr>\n';
	set res = res || '<tr><td>select</td><td>'
		      || ifnull( sd, '<i>-NULL-</i>', html_encode(sd) ) || '</td></tr>\n';
	set res = res || '<tr><td>Select<br>Multiple</td><td>';
	select list(html_encode(http_variable('sdm',row_num)),'<br>') into sdm
	from RowGenerator
	where row_num <= 10;
	set res = res || ifnull( sdm, '<i>-NULL-</i>', sdm ) || '</td></tr>\n';
	set res = res || '<tr><td>ImageX</td><td>'
		      || ifnull( idx, '<i>-NULL-</i>', html_encode(idx) ) || '</td></tr>\n';
	set res = res || '<tr><td>ImageY</td><td>'
		      || ifnull( idy, '<i>-NULL-</i>', html_encode(idy) ) || '</td></tr>\n';
	set res = res || '</table>';
	set res = res || '<hr><a href="http://www.w3.org/TR/html4/interact/forms.html">'
		      || 'See here for more information on HTML Forms</a>\n';
	set res = res || '<hr></body></html>';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	select res;
end
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='post_data') then
    drop service post_data
end if
go

if exists(select * from SYS.SYSWEBSERVICE where service_name='display_post_data') then
    drop service display_post_data;
end if
go

create service post_data type 'raw' authorization off user dba secure off
  as call post_data( :method )
go
create service display_post_data type 'raw' authorization off user dba secure off
  as call display_post_data(:hd,:td,:pd,:tad,:rd,:cb,:sd,:id.x,:id.y)
go
