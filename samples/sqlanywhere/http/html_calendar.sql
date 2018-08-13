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

-- html example "calendar" support routines
--

create or replace function html_mini_calendar(
			i_year  unsigned int,
			i_month unsigned int,
			i_nrows int default 1	-- min number of weeks in the calendar
		)
returns long varchar
begin
	declare day_1 date;  -- first day of the month

	set i_year  = coalesce( i_year, datepart( year, current date ) );
	set i_month = coalesce( i_month, datepart( month, current date ) );
	set i_nrows = coalesce( i_nrows, 4 );
	set day_1 = ymd( i_year, i_month, 1 );

	SELECT	DATEPART( Week, DATEADD( Day, day_of_month - 1, day_1 ) ) AS week_of_year,
		DOW( DATEADD( Day, day_of_month - 1, day_1 ) )            AS day_of_week,
		dbo.RowGenerator.row_num                                  AS day_of_month
	INTO #monthdays
	FROM dbo.RowGenerator
	WHERE dbo.RowGenerator.row_num <= DAYS( day_1, dateadd( month, 1, day_1 ) );

	-- get the list of distinct month days
	SELECT distinct #monthdays.week_of_year
	  INTO #weeks
	  FROM #monthdays;

	SELECT	#weeks.week_of_year as woy,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 1
		      and #monthdays.week_of_year = woy ),
		  '' ) as S,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 2
		      and #monthdays.week_of_year = woy ),
		  '' ) as M,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 3
		      and #monthdays.week_of_year = woy ),
		  '' ) as T,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 4
		      and #monthdays.week_of_year = woy ),
		  '' ) as W,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 5
		      and #monthdays.week_of_year = woy ),
		  '' ) as R,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 6
		      and #monthdays.week_of_year = woy ),
		  '' ) as F,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 7
		      and #monthdays.week_of_year = woy ),
		  '' ) as Z
	INTO #weekdays
	FROM #weeks
--	FROM ( select distinct #monthdays.week_of_year from #monthdays )
--		AS weeks( week_of_year )
	ORDER BY woy;

	WHILE ( select count(*) from #weekdays ) < i_nrows LOOP
		insert #weekdays values( 999, '&nbsp;', '', '', '', '', '', '' );
	END LOOP;

	return	'<TABLE><TR><TH COLSPAN=7>'
	||	string( monthname( day_1 ) )
	||	'</TH></TR>\n<TR>'
	||	'<TH WIDTH="14%">S</TH>'
	||	'<TH WIDTH="14%">M</TH>'
	||	'<TH WIDTH="14%">T</TH>'
	||	'<TH WIDTH="14%">W</TH>'
	||	'<TH WIDTH="14%">R</TH>'
	||	'<TH WIDTH="14%">F</TH>'
	||	'<TH WIDTH="14%">S</TH>'
	||	'</TR>\n'
	|| ( select list(
			'<TR align=right valign=top>'
		||	'<TD>' || S || '</TD>'
		||	'<TD>' || M || '</TD>'
		||	'<TD>' || T || '</TD>'
		||	'<TD>' || W || '</TD>'
		||	'<TD>' || R || '</TD>'
		||	'<TD>' || F || '</TD>'
		||	'<TD>' || Z || '</TD>'
		||	'</TR>\n',
			'' order by woy )
		from #weekdays
		)
	||	'</table>\n';
EXCEPTION
	WHEN OTHERS THEN
		return calendar_exception_doc(
				'html_mini_calendar', errormsg(), traceback(*), '' );
end
go

create or replace function html_calendar_by_year( i_year unsigned int )
returns long varchar
begin
	set i_year = coalesce( i_year, datepart( year, current date ) );

	return	'<TABLE BORDER=1>\n'
	||	'<TR><TH COLSPAN=7><BIG>' || string( i_year ) || '</BIG></TH></TR>\n'
	||	'<TR valign=top>'
	||	'<TD WIDTH="25%">' || html_mini_calendar( i_year, 1, 6 ) || '</TD>'
	||	'<TD WIDTH="25%">' || html_mini_calendar( i_year, 2, 6 ) || '</TD>'
	||	'<TD WIDTH="25%">' || html_mini_calendar( i_year, 3, 6 ) || '</TD>'
	||	'<TD WIDTH="25%">' || html_mini_calendar( i_year, 4 ) || '</TD></TR>\n'
	||	'<TR valign=top>'
	||	'<TD>' || html_mini_calendar( i_year, 5, 6 ) || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 6 ) || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 7 ) || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 8 ) || '</TD></TR>\n'
	||	'<TR valign=top>'
	||	'<TD>' || html_mini_calendar( i_year, 9, 6 )  || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 10 ) || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 11 ) || '</TD>'
	||	'<TD>' || html_mini_calendar( i_year, 12 ) || '</TD></TR>\n'
	||	'</table>\n';
end
go

create or replace function html_calendar_by_month( i_year unsigned int, i_month unsigned int, i_nrows int default 1 )
returns long varchar
begin
	declare day_1 date;  -- first day of the month

	set i_year  = coalesce( i_year, datepart( year, current date ) );
	set i_month = coalesce( i_month, datepart( month, current date ) );
	set i_nrows = coalesce( i_nrows, 4 );
	set day_1 = ymd( i_year, i_month, 1 );

	SELECT	DATEPART( Week, DATEADD( Day, day_of_month - 1, day_1 ) ) AS week_of_year,
		DOW( DATEADD( Day, day_of_month - 1, day_1 ) )            AS day_of_week,
		dbo.RowGenerator.row_num                                  AS day_of_month
	INTO #monthdays
	FROM dbo.RowGenerator
	WHERE dbo.RowGenerator.row_num <= DAYS( day_1, dateadd( month, 1, day_1 ) );

	SELECT	weeks.week_of_year as woy,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 1
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as S,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 2
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as M,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 3
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as T,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 4
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as W,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 5
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as R,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 6
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as F,
		coalesce(
		  ( select cast( #monthdays.day_of_month as varchar(6) )
		    from #monthdays
		    where #monthdays.day_of_week = 7
		      and #monthdays.week_of_year = weeks.week_of_year ),
		  '&nbsp;' ) as Z
	INTO #weekdays
	FROM ( select distinct #monthdays.week_of_year from #monthdays )
		AS weeks( week_of_year )
	ORDER BY weeks.week_of_year;

	WHILE ( select count(*) from #weekdays ) < i_nrows LOOP
		insert #weekdays values( 999, '&nbsp;', '&nbsp;', '&nbsp;',
					 '&nbsp;', '&nbsp;', '&nbsp;', '&nbsp;' );
	END LOOP;

	return	'<TABLE BORDER=1>\n'
	||	'<TR><TH COLSPAN=7><BIG>'
	||	string( monthname( day_1 ) ) || ' ' || string( i_year )
	||	'</BIG></TH></TR>\n<TR>'
	||	'<TH WIDTH="14%">Sunday</TH>'
	||	'<TH WIDTH="14%">Monday</TH>'
	||	'<TH WIDTH="14%">Tuesday</TH>'
	||	'<TH WIDTH="14%">Wednesday</TH>'
	||	'<TH WIDTH="14%">Thursday</TH>'
	||	'<TH WIDTH="14%">Friday</TH>'
	||	'<TH WIDTH="14%">Saturday</TH>'
	||	'</TR>\n'
	|| ( select list(
			'<TR align=left valign=top>'
		||	'<TD>' || S || '<br><br><br><br></TD>'
		||	'<TD>' || M || '</TD>'
		||	'<TD>' || T || '</TD>'
		||	'<TD>' || W || '</TD>'
		||	'<TD>' || R || '</TD>'
		||	'<TD>' || F || '</TD>'
		||	'<TD>' || Z || '</TD>'
		||	'</TR>\n',
			'' order by woy )
		from #weekdays
		)
	||	'</table>\n';
end
go
