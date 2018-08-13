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

-- html select support routines
--

create or replace function html_select_uint(
			name   varchar(30),
			minnum unsigned int,
			maxnum unsigned int,
			sel    unsigned int default NULL )
returns long varchar
begin
	declare len unsigned int;

	-- we should not be passed NULL, but default to something if we do
	set minnum = coalesce( minnum, 1 );
	set maxnum = coalesce( maxnum, 10 );
	if maxnum < minnum then
		set maxnum = minnum;
	end if;
	set sel = if sel >= minnum and sel <= maxnum then sel else (minnum-1) endif;
	set len = length( string( maxnum ) );
	return     '<select name="' || html_encode( name ) || '">\n'
		|| ' <option value=""' || (if sel < minnum then ' selected' else '' endif)
			|| '>' || repeat( '-', len ) || '</option>\n'
		|| ( select list(
			' <option value="'
			|| substr( cast( 1000000+minnum+row_num-1 as char(7) ), 8-len, len )
			|| '"'
			|| (if sel = minnum+row_num-1 then ' selected' else '' endif)
			|| '>'
			|| substr( cast( 1000000+minnum+row_num-1 as char(7) ), 8-len, len )
			|| '</option>\n', '' )
		     from dbo.rowgenerator
		     where row_num >= 1 and row_num <= maxnum-minnum+1 )
		|| '</select>\n';
end
go

create or replace function html_select_year(
			name    varchar(30),
			sel     unsigned int default NULL,
			minyear unsigned int default NULL,
			maxyear unsigned int default NULL )
returns long varchar
begin
	set minyear = coalesce( minyear, datepart( year, now(*) )-20 );
	set maxyear = coalesce( maxyear, datepart( year, now(*) )+20 );
	return html_select_uint( name, minyear, maxyear, sel );
end
go

create or replace function html_select_month( name varchar(30), sel int default NULL )
returns long varchar
begin
	set sel = if sel >= 1 or sel <= 12 then sel else coalesce( sel, 0 ) endif;
	return     '<select name="' || html_encode( name ) || '">\n'
		|| ' <option value=""' || (if sel = 0 then ' selected' else '' endif) || '>---</option>\n'
		|| ( select list(
			' <option value="'
			|| substr( cast( 100+row_num as char(3) ), 2, 2 )
			|| '"'
			|| (if sel = row_num then ' selected' else '' endif)
			|| '>'
			|| substr( monthname( dateadd( month, row_num-1, '2000/01/01' ) ), 1, 3 )
			|| '</option>\n', '' )
		     from dbo.rowgenerator
		     where row_num >= 1 and row_num <= 12 )
		|| '</select>\n';
end
go

create or replace function html_select_day( name varchar(30), sel int default NULL )
returns long varchar
begin
	return html_select_uint( name, 1, 31, sel );
end
go

create or replace function html_select_time(
			name   varchar(30),
			pphour unsigned int default 1,         -- parts per hour  
			sel    varchar(6)   default NULL,
			nullok bit default 1   )
returns long varchar
begin
	IF pphour is NULL or pphour < 1 THEN
		set pphour = 1;
	ELSEIF pphour > 60 THEN
		set pphour = 60;
	END IF;

	SELECT	hours.row_num as h, parts.row_num as p,
		(substr( cast( 101+mod( h+10, 12 ) as char(3) ), 2, 2 )
	||	':' ||substr( cast( 100+(p-1)*(60/pphour) as char(3) ), 2, 2 )
	||	( if h < 13 then 'a' else 'p' endif )) as T
	  INTO #timevalues
	  FROM dbo.rowgenerator hours cross join dbo.rowgenerator parts
	 WHERE h <= 24 and p <= pphour;

	-- we should not be passed NULL, but default to something if we do
	return     '<select name="' || html_encode( name ) || '">\n'
		|| ( if nullok = 1 then ' <option value=""' || (if sel is null then ' selected' else '' endif)
			|| '>-----</option>\n' else '' endif )
		|| ( select list( ' <option value="' || T || (if sel = T then ' selected' else '' endif)
				|| '">' || h || '.' || p || '=' || T || '</option>\n', '' order by h,p )
		      from #timevalues )
		|| '</select>\n';
end
go
