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

-- session
--     procedure definition and service of an example of how to set and use HTTP sessions

-- Browse to http://localhost/session

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
	||	' max-age=' || string( max_age ) || ';'
	||	' path=' || http_encode(path) || ';' );
	-- Note: You may also want to add domain=...; comment=....; and secure
end;
go

create or replace function html_select_option( table_name char(32), name char(32), value char(32) )
returns long varchar
begin
    declare err_notfound EXCEPTION FOR SQLSTATE '02000';
    declare clue    long varchar;
    declare qry	    long varchar;
    declare res	    long varchar;

    set qry = 'select "clue" from ' || table_name;

    begin
	declare cur_lu  cursor using qry;

	set res = '<select name="' || html_encode( name ) || '">\n';

	open cur_lu;
	lu_loop:
	    loop
	    FETCH NEXT cur_lu into clue;
	    if SQLSTATE = err_notfound then
		leave lu_loop;
	    end if;
	    set res = res
	    || '<option value="' || html_encode( clue ) || '"'
	    || if( clue = value ) then ' selected' endif
	    || '>' || html_encode( clue );
	    end loop lu_loop;

	close cur_lu;

	set res = res || '</select>\n';
        
	return ( res );
    end;
end;
go

create or replace function set_session( session_prefix char(32) )
returns long varchar
begin
	declare session_id long varchar;
	declare ses_id     long varchar;
	declare ses_create long varchar;
	declare ses_last   long varchar;
	declare tm         timestamp;

	set tm = now(*);
	set session_id = session_prefix || '_' || 
	    convert( varchar, seconds(tm)*1000+datepart(millisecond,tm) );

	call sa_set_http_option( 'sessionid', session_id );

	select connection_property('sessionid') into ses_id;
	select connection_property('sessioncreatetime') into ses_create;
	select connection_property('sessionlasttime') into ses_last;

	set status = status
	|| 'set_session(): session (re)set'
	|| '<br>ses_id=' || html_encode( ses_id )
	|| '<br>ses_create=' || html_encode( ses_create )
	|| '<br>ses_last=' || html_encode( ses_last ) || '<br>';

	return( session_id );
end;
go

create or replace function delete_session( )
returns long varchar
begin
	declare session_id long varchar;
	declare res        long varchar;
	declare ses_id     long varchar;
	declare ses_create long varchar;
	declare ses_last   long varchar;

	call sa_set_http_option( 'sessionid', null );
	set res = res
	||	'<h1><center>Deleted session:'
	||	html_encode(ses_id)
	||	 '</center></h1>\n'
	||	'<hr><br>';

	set res = res
	||	'<br><center><a href="session?state=new">Create a new session</a><br></center>';

	select connection_property('sessionid') into ses_id;
	select connection_property('sessioncreatetime') into ses_create;
	select connection_property('sessionlasttime') into ses_last;

	set status = status
	|| 'delete_session(): session deleted'
	|| '<br>ses_id=' || html_encode( ses_id )
	|| '<br>ses_create=' || html_encode( ses_create )
	|| '<br>ses_last=' || html_encode( ses_last ) || '<br>';

	return( res );
end;
go

create or replace procedure session_proc( sessionid varchar(128), state varchar(32) )
	-- Procedure entry point for http service: session
	-- sessionid is the value of sessionid from the url
result (html_document long varchar)
begin
	declare res        long varchar;	-- ultimate result
	declare ses_id     long varchar;	-- client sessionid
	declare ses_create long varchar;	-- client session creation time
	declare ses_last   long varchar;	-- last client access to session

	if VAREXISTS( 'status' ) = 0 THEN
		create variable status long varchar;
	end if;
	if VAREXISTS( 'hostname' ) = 0 THEN
		create variable hostname long varchar;
	end if;

	set hostname = http_header( 'host' );

	-- ses_id is the sessionid property of the the connection.
	-- ses_id may be set by a cookie or url (url overrides cookie).
	-- If a procedure or function calls:
	--	sa_set_http_option('sessionid', ... ); to create or change
	-- the session id, then the 'sessionid' connection_property
	-- is immediately updated.
	select connection_property('sessionid') into ses_id;

	-- 'sessioncreatetime' connection_property only exists if
	-- the current connection is within a session context.
	select connection_property('sessioncreatetime') into ses_create;

	-- 'sessionlasttime' connection_property is the time
	-- the last request had terminated.  This property also only
	-- exists if the connection is within a session context.
	select connection_property('sessionlasttime') into ses_last;

	set res =  '<html><head><title>Session Sample</title></head>\n<body>\n';

	set status = '<br><br><br><hr><div>Status:<br><small>'
	|| '(url) sessionid='
	|| html_encode( sessionid )
	|| '<br>ses_id=' || html_encode( ses_id )
	|| '<br>ses_create=' || html_encode( ses_create )
	|| '<br>ses_last=' || html_encode( ses_last ) || '<br>';

	if ses_id is not null and ses_id != '' then
		-- Client is indicating that it wants/needs a session.
		if ses_create is null or ses_create = '' then
			-- There is no create time for the session;
			-- therefore, either the session no longer exists,
			-- or the client's hostname or ip address differs
			-- from the client that created the session.

			if http_variable( 'sessionid' ) is null then
				-- Session identifer originated from a cookie.
				set status = status
					|| 'Client used a cookie<br>';

				-- Age of 0 causes cookie to be deleted.
				-- Client browser may need to be restarted
				-- to clear the cookie.
				call set_http_cookie( 'sessionid', '', 0, '/session' );
				set status = status 
				|| 'Deleting cookie:' || html_encode( ses_id ) || '<br>';
			end if;

			set ses_id = null;

		end if;
	else
		set ses_id = null;
	end if;

	if state = 'delete' then
		set res = res
		|| delete_session();

		if sessionid is not null and sessionid != ses_id then
			call set_http_cookie( 'sessionid', '', 0, '/session' );
		end if;

	elseif ses_id is null or state = 'new' or state = 'cookie_or_url' then

		-- If new session being created from within an existing session
		-- and the session is managed by cookies, we must delete
		-- the client's cookie, so our app won't get confused.
		if ses_id is not null and sessionid is null then
			call set_http_cookie( 'sessionid', '', 0, '/session' );
			set status = status || 'sessionid cookie deleted<br>';
		end if;
		set res = res || session_new( state );

	else
		set res = res || session_process();
	end if;

	set status = status
	|| '<br></small></div><hr>';

	set res = res	
	||	'<br><br><br><div class=powered><center>Powered by<br>'
	||	'<i>' || html_encode( property('ProductName') || ' ' || property('ProductVersion') ) || '</i><br>'
	||	'<small><i>' || html_encode( property('LegalCopyright') ) || '</i></small></center><hr></div>\n'
	||	status
	||	'</body>\n</html>\n';

	call dbo.sa_set_http_header( 'Content-Type', 'text/html' );
	set status = '';
	select res;
end
go

create or replace function session_new( state varchar(250) )
returns long varchar
begin
	declare res          long varchar;
	declare service_name long varchar;
	declare ses_timeout  int;
	if VAREXISTS( 'session_url' ) = 0 THEN
		create variable session_url long varchar;
	end if;
	
	select connection_property('HttpServiceName') into service_name;

	if state is null or state = 'new' or state = '' then
		set session_url='session?state=cookie_or_url';

		set res=res
		||	'<form method=POST action="http://'
		||	http_encode( hostname ) || '/'
		||	http_encode( session_url ) || '"><p>'
		||	'<br><p>'
		||	'<h1><center>Welcome to the <em>' || html_encode(service_name) || '</em> example</center></h1>\n'
		||	'<center>This example demonstrates the use of HTTP sessions.</center><hr><br>'
		||	'<h3>Please select the method of session control</h3>'
		||	'<br>If selecting <b>cookie</b>, ensure that cookies are enabled in your client browser.<br>'
		||	'<input type="radio" checked name="session_type"'
		||	' value="url">url'
		||	'<input type="radio" name="session_type"'
		||	' value="cookie">cookie'
		||	'<br><br><input type=submit>'
		||	'</form>';
	else
		-- We've been called with a url parameter
		-- state=cookie_or_url. 

		-- We'll create a session for this connection,
		-- therefore any variables or global temporary tables
		-- that are created are cached within the session context.
		if VAREXISTS( 'session_id' ) = 0 THEN
		    create variable session_id   long varchar;
		    create variable seqno        integer;
		    create variable sel_opt_name long varchar;
		    create variable @question    long varchar;
		    create variable @answer      long varchar;
                    create variable @author      long varchar;
		end if;

		set sel_opt_name = 'quiz_answer';

		begin
			declare session_type long varchar;
			declare ses_id       long varchar;
			set session_type = http_variable( 'session_type' );

			set res = res
			||	'<h1><center>Welcome to the session example</center></h1>\n'
			|| '<center>This example demonstrates the use of HTTP sessions.</center><hr><br>';

			if session_type = 'url' then
				set session_id = set_session('url_session' );
				set session_url = 'session?sessionid='
						|| html_encode(session_id);

				set res = res
				||	'<center>Enter your new session using the URL method <b>'
				||	'</b><a href="'
				||	session_url
				||	'">'
				||	html_encode(session_id)
				||	'</a></center>\n';


			else	-- cookie method
				set session_id = set_session('cookie_session' );
				select connection_property('SessionTimeout') into ses_timeout;

				-- set the cookie header
				call set_http_cookie( 'sessionid', session_id, ses_timeout*60, '/session' );
			
				-- our session url remains the same for all
				-- cookie_type sessions, ie. no sessionid url
				-- variable

				set session_url = 'session';

				set res = res
				||	'<center>Enter your new session using the Cookie method <b>'
				||	'</b><a href="'
				||	session_url
				||	'">'
				||	html_encode(session_id)
				||	'</a></center>\n'

			end if;

			select connection_property( 'sessionid' ) into ses_id;

			set seqno = 1;
		end;
	end if;

	return( res );
end
go

create or replace function session_process()
returns long varchar
begin
	declare res          long varchar;
	declare @your_answer long varchar;
	declare delete_url   long varchar;
	declare ses_timeout  int;
	declare req_timeout  int;
	declare timeout      int;
	declare clue_table   long varchar;
	declare qcur cursor for SELECT q."question", q."answer", q."author" 
                                FROM quiz AS q;

	if session_url = 'session' then
		-- no sessionid specified, may be a cookie session...
		set delete_url = session_url || '?state=delete';
	else
		set delete_url = session_url || '&state=delete';
	end if;

	set res = res
	||	'<h1><center>Welcome to session:'
	||	html_encode(session_id)
	||	'<br>Quotations for Programmers to Live By</center></h1>\n'
	||	'<hr><br>';

	set res = res
	||	'<br><center><a href="session?state=new">Create a new session</a><br></center>'
	||	'<br><center><a href="'
	||	delete_url
	||	'">Delete the session</a><br></center>';

	if( seqno <= 5 ) then
		set req_timeout = http_variable( 'session_timeout' );
		select connection_property('SessionTimeout') into ses_timeout;
		set status = status
		|| 'req_timeout=' || html_encode(req_timeout)
		|| '<br>'
		|| 'ses_timeout=' || html_encode(ses_timeout)
		|| '<br>';

		if req_timeout <> ses_timeout then
		    call sa_set_http_option( 'SessionTimeout', req_timeout );
		end if;
		set @your_answer = http_variable( sel_opt_name );
		if @your_answer is not null then
		    insert into quiz_results values( @question, @answer, @your_answer, @author );
		    set seqno = seqno + 1;
		end if;
	end if;

	set status = status
	|| 'seqno=' || seqno || '<br>';

	open qcur;
	fetch absolute seqno qcur into @question, @answer, @author;
	close qcur;

	select connection_property('SessionTimeout') into ses_timeout;
	set status = status
	|| 'ses_timeout=' || ses_timeout || '<br>';

	if( seqno <= 5 ) then
		set clue_table = 'quiz_clue_1';
		set res = res
		||	'<form method=POST action="http://'
		||	html_encode(hostname) || '/'
		||	session_url || '"><p>'
		||	'<br>'
		||	html_encode( @question )
		||	html_select_option( clue_table, sel_opt_name, '' )
		||	'<br><br>'
		||	'<label>session_timeout </label>'
		||	'<input name=session_timeout type=text value='
		||	html_encode( ses_timeout )
		||	'></input>'
		||	'<label> minutes</label>'
		||	'<br><br><input type=submit>'
		||	'</form>';

	else
		set res = res
		|| '<h1>Your results are:</h1>'
		|| view_results();
		set seqno = 6;
	end if;

	return( res );
end
go

create or replace function view_results()
returns long varchar
begin
	declare err_notfound EXCEPTION FOR SQLSTATE '02000';
	declare res	    long varchar;
	declare qry	    long varchar;
	declare line        long varchar;

	declare cur_results  cursor for
	    select '<tr>'
	    || '<td>' || html_encode( t."question" ) || '</td>'
	    || '<td>' || html_encode( t."answer" ) || '</td>'
	    || '<td>' || html_encode( t."your_answer" ) || '</td>'
	    || '<td>' || html_encode( t."author" ) || '</td>'
	    || '</tr>\n'
	    from quiz_results as t;

	set res = '<center><table name="results" border="1">\n'
	|| '<tr><th>Question</th><th>Answer</th><th>Your Answer</th><th>Author</th></tr>\n';

	open cur_results;
	ans_loop:
	    loop
	    FETCH NEXT cur_results into line;
	    if SQLSTATE = err_notfound then
		leave ans_loop;
	    end if;
	    set res = res || line;
	    end loop ans_loop;

	close cur_results;

	set res = res || '</table></center>\n';
        
	return ( res );
end;
go

DROP TABLE IF EXISTS DBA.quiz;

CREATE TABLE DBA.quiz
(
    "seq_no"	int null default autoincrement,
    "question"	long varchar not null,
    "answer"	long varchar not null,
    "author"    long varchar not null
);
commit work;

DROP TABLE IF EXISTS DBA.quiz_clue_1;

CREATE TABLE DBA.quiz_clue_1
(
    "clue"	    long varchar not null
);
commit work;

DROP TABLE IF EXISTS DBA.quiz_results;

CREATE GLOBAL TEMPORARY TABLE quiz_results
(
    "question"	    long varchar null,
    "answer"	    long varchar null,
    "your_answer"   long varchar null,
    "author"        long varchar null
) NOT TRANSACTIONAL;
commit work;

INSERT INTO DBA.quiz ("question", "answer", "author")
VALUES(
    'If it''s not broken, ...',
    'don''t fix it',
    'Unknown' );
    
INSERT INTO DBA.quiz ("question", "answer", "author")
VALUES(
    'Better late than ...',
    'never',
    'Mathew Henry' );

INSERT INTO DBA.quiz ("question", "answer", "author")
VALUES( 
    'Great spirits have always encountered violent opposition...',
    'from mediocre minds',
    'Albert Einstein' );
    
INSERT INTO DBA.quiz ("question", "answer", "author")
VALUES( 
    'Whether you think that you can, or that you can''t, ...',
    'you are usually right',
    'Henry Ford' );
    
INSERT INTO DBA.quiz ("question", "answer", "author")
VALUES( -- Was mich nicht umbringt, macht mich stärker. 
    'What does not destroy me, ...',
    'makes me stronger',
    'Friedrich Nietzsche' );

INSERT INTO DBA.quiz_clue_1 ("clue")
VALUES('never');

INSERT INTO DBA.quiz_clue_1 ("clue")
VALUES('don''t fix it');

INSERT INTO DBA.quiz_clue_1 ("clue")
VALUES('you are usually right');

INSERT INTO DBA.quiz_clue_1 ("clue")
VALUES('makes me stronger');

INSERT INTO DBA.quiz_clue_1 ("clue")
VALUES('from mediocre minds');

commit work;

if exists(SELECT * FROM SYS.SYSWEBSERVICE 
  WHERE service_name='session' ) then
    DROP SERVICE "session";
end if;
go

CREATE SERVICE "session" 
  TYPE 'raw' 
  AUTHORIZATION OFF 
  USER DBA 
  SECURE OFF
  AS CALL session_proc( :sessionid, :state )
go
