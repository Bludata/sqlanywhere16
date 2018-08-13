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

-----------------------------------------------------------
-- test_request_db.sql
--
-- Small example site for collecting test case requests.
-- Start page is the service 'show_groups' which lists the
-- test groupings, you can from there generate a new group
-- or click on an existing group for details.
-- The details for a group basically consist of a listing 
-- of the tests with the possibility of clicking tests to 
-- view/edit details or create a new test request.
--
-- Setup:
--   dbinit <your_db>.db
--   dbspawn dbsrvNN -xs http <your_db>.db
--   dbisql -c "UID=DBA;PWD=sql;SERVER=<your_db>" test_request_db.sql
-- After the script has finished you should be able to 
-- access the site with your browser at the following url:
--   http://localhost/<your_db>/show_groups
--
-- To add test groups or tests you will need to login as a user 
-- that is a member of the "authors" group, DBA is the only default
-- member.

------------
-- Tables --
------------

create table if not exists test_group (
	tg_id integer not null default autoincrement,
	tg_name varchar( 128 ),
	primary key ( tg_id )
	);
go

create table if not exists test (
	tg_id integer not null,
	foreign key references test_group,
	t_id integer default autoincrement,
	t_description long varchar not null,
	t_result long varchar not null,
	t_comment long varchar default null,
	u_id unsigned int default null,
	primary key ( tg_id, t_id )
	);
go

commit work
go

-----------
-- Users --
-----------

-- User for anonymous HTTP access
if exists(select * from SYS.SYSUSERPERM where user_name = 'http') then
    revoke connect from http;
end if
go

grant connect to http identified by 'sqlany'
go

-- Group for test authors
if exists(select * from SYS.SYSUSERPERM where user_name = 'authors') then
    revoke connect from authors;
end if
go

grant connect to authors
go

grant group to authors
go

grant membership in group authors to DBA
go

commit work
go

----------------
-- Procedures --
----------------

-- show_groups

create or replace procedure show_groups () result( res long varchar )
begin
    declare err_notfound exception for SQLSTATE '02000';
    declare rslt long    varchar;
    declare db_name      varchar(40);
    declare crlf         char(4);
    declare line         long varchar;
    declare cur_test_group cursor for
	select '<tr><td><a href="/'
		|| html_encode( db_name )
		|| '/list_group?group_id='
		|| html_encode( tg.tg_id )
		|| '">'
		|| html_encode( tg.tg_name )
		|| '</a></td><td>'
		|| count(t.tg_id)
		|| '</td></tr>'
		|| crlf
	 from test_group tg left join test t on (tg.tg_id=t.tg_id)
	group by t.tg_id, tg.tg_name, tg.tg_id;

    select db_property('Name') into db_name;

    set crlf = '\x0d\x0a';
    set rslt = '<html>' || crlf
	 || '<head>' || crlf
	 || '<link rel="stylesheet" href="/' || html_encode( db_name ) || '/css" type="text/css">' || crlf
	 || '<title>Test Groups</title>'|| crlf
	 || '</head>' || crlf
	 || '<body>' || crlf
	 || '<h2>Test Groups</h2>' || crlf
	 || '<table>' || crlf
	 || '<tr><th align="left" width=200>Test Group</th><th align="left" width=150>Number of tests</th></tr>' || crlf;

    open cur_test_group;
test_group_loop:
    loop
	fetch next cur_test_group into line;
	if SQLSTATE = err_notfound then
	    leave test_group_loop;
	end if;
	set rslt = rslt || line;
    end loop test_group_loop;
    close cur_test_group;

    set rslt = rslt
	 || '</table>' || crlf
	 || '<br><hr>' || crlf
	 || '<p><a href="/' || html_encode( db_name ) || '/add_test_group">Add new test group</a></p>' || crlf
	 || '</body>' || crlf
	 || '</html>' || crlf;

    call sa_set_http_header( 'Content-Type', 'text/html' );
    select rslt;
end
go

grant execute on show_groups to http
go

-- list_group

create or replace procedure list_group ( group_id int )
result( res long varchar )
begin
    declare err_notfound exception for SQLSTATE '02000';
    declare rslt         long varchar;
    declare group_name   long varchar;
    declare db_name      varchar(40);
    declare crlf         char(4);
    declare line         long varchar;
    declare cur_test_list cursor for
	    select '<tr><td align="right">'
		    || html_encode( t_id )
		    || '</td>'
		    || crlf
		    || '<td><a href="/'
		    || html_encode( db_name )
		    || '/show_test?group_id='
		    || html_encode( group_id )
		    || '&test_id='
		    || html_encode( t_id )
		    || '">'
		    || replace(html_encode(t_description),'\x0d\x0a','<br>')
		    || '</a></td><td>'
		    || html_encode( t.t_result )
		    || '</td><td>'
		    || ifnull( t.u_id, 'not assigned', html_encode(u.user_name) )
		    || '</td></tr>'
	      from DBA.test t left outer join SYS.SYSUSERPERMS u on ( t.u_id = u.user_id )
	     where t.tg_id = group_id;

    set crlf = '\x0d\x0a';

    select tg_name into group_name from test_group where tg_id = group_id;
    select db_property('Name') into db_name;

    set rslt = '<html>' || crlf
	 || '<head>' || crlf
	 || '<link rel="stylesheet" href="/' || html_encode( db_name ) || '/css" type="text/css">' || crlf
	 || '<title>Test group &quot;' || html_encode( group_name ) || '&quot;</title>' || crlf
	 || '</head>' || crlf
	 || '<body>' || crlf
	 || '<h2>Test group &quot;' || html_encode( group_name ) || '&quot;</h2>' || crlf
	 || '<table>' || crlf
	 || '<tr><th>Test Id</th><th>Description</th><th>Expected result</th><th>Author</th></tr>' || crlf;

    open cur_test_list;
test_list_loop:
    loop
	fetch next cur_test_list into line;
	if SQLSTATE = err_notfound then
	    leave test_list_loop;
	end if;
	set rslt = rslt || line || crlf;
    end loop test_list_loop;
    close cur_test_list;

    set rslt = rslt
	 || '</table>' || crlf
	 || '<br><hr>' || crlf
	 || '<p>' || crlf
	 || '<a href="/' || html_encode( db_name ) || '/show_test?group_id=' || html_encode( group_id )
	 || '">Add new test</a><br>' || crlf
	 || '<a href="/' || html_encode( db_name ) || '/show_groups">Back to Test Groups</a></p>' || crlf
	 || '</body>' || crlf
	 || '</html>' || crlf;

    call sa_set_http_header( 'Content-Type', 'text/html' );
    select rslt;
end
go

grant execute on DBA.list_group to http
go

-- add_test_group

create or replace procedure add_test_group ( group_name long varchar )
result( res long varchar )
begin
    declare err_notfound exception for SQLSTATE '02000';
    declare group_id     integer;
    declare rslt         long varchar;
    declare db_name      varchar(40);
    declare crlf         char(4);
    declare line         long varchar;

    select db_property('Name') into db_name;

    set crlf = '\x0d\x0a';
    set rslt = '<html>' || crlf
	 || '<head>' || crlf
	 || '<link rel="stylesheet" href="/' || html_encode( db_name ) || '/css" type="text/css">' || crlf;

    if group_name is null then
	set rslt = rslt
		|| '<title>Add Test Group</title>' || crlf
		|| '</head>' || crlf
		|| '<body>' || crlf
		|| '<form action="/' || html_encode( db_name ) || '/add_test_group" method="GET">' || crlf
		|| '<table class="form">' || crlf
		|| '<tr>' || crlf
		|| '<td class="form"><b>Group Name:</b></td>' || crlf
		|| '<td class="form"><input name="group_name" type="text" size="64"  class="post"></td>' || crlf
		|| '</tr>' || crlf
		|| '<tr><td class="form">&nbsp;</td>' || crlf
		|| '<td class="form"><input type="submit" value="Submit" class="button"></td>' || crlf
		|| '</table>' || crlf
		|| '</form>' || crlf;
    else
	set rslt = rslt
		|| '<title>Creating Test Group ' || html_encode( group_name ) || '</title>' || crlf
		|| '</head>' || crlf
		|| '<body>' || crlf;

	select tg_id into group_id from test_group where tg_name = group_name;
	if SQLSTATE = err_notfound then
	    begin
		insert into test_group (tg_name) values(group_name);
		set rslt = rslt || '<h2>Test Group "' || html_encode( group_name ) || '" added</h2>' || crlf;
	    exception
		when others then
		    set rslt = rslt || '<h2>Error occured while creating test group "'
			 || html_encode( group_name ) || '"</h2>' || crlf
			 || '<p>Message:<br>' || html_encode( ERRORMSG(SQLSTATE) ) || '</p>' || crlf;
	    end;
	else
	    set rslt = rslt || '<h2>Test Group "' || html_encode( group_name ) || '" already exists</h2>' || crlf;
	end if;
    end if;
    set rslt = rslt || '<br><hr>' || crlf
	 || '<p><a href="/' || html_encode( db_name ) || '/show_groups">Test Groups</a></p>' || crlf
	 || '</body>' || crlf
	 || '</html>' || crlf;

    call sa_set_http_header( 'Content-Type', 'text/html' );
    select rslt;
end
go

grant execute on add_test_group to authors
go

-- show_test

create or replace procedure show_test ( group_id integer, test_id integer, test_description long varchar, test_result long varchar, test_author varchar( 128 ), test_comment long varchar )
result( res long varchar )
begin
    declare err_notfound exception for SQLSTATE '02000';
    declare test_uid     unsigned int;
    declare group_name   varchar(60);
    declare rslt         long varchar;
    declare failed       bit;
    declare db_name      varchar(40);
    declare crlf         char(4);
    declare line         long varchar;
    declare cnt          integer;

    select db_property('Name') into db_name;

    set crlf = '\x0d\x0a';
    set rslt = '<html>' || crlf
	 || '<head>' || crlf
	 || '<link rel="stylesheet" href="/' || html_encode( db_name ) || '/css" type="text/css">' || crlf;
    
    if group_id is null then
	-- This is an error!
	set rslt = rslt
		|| '<title>Error when Adding New Test</title>'|| crlf
		|| '</head>' || crlf
		|| '<body>' || crlf
		|| '<h2>New Test can only be added if test group is known!</h2>' || crlf
		|| '<p>To select a test group click <a href="/' || html_encode( db_name )
		|| '/show_groups">Test Groups</a></p>' || crlf;
    elseif test_id is null then
	-- This means it is either a new test or the form is empty
	select tg_name into group_name from test_group where tg_id = group_id;
	if test_description is null or test_result is null then
	    set rslt = rslt
		 || '<title>Add New Test to Group "' || html_encode( group_name ) || '"</title>' || crlf
		 || '</head>' || crlf
		 || '<body>'|| crlf
		 || '<h2>Add Test to Group "' || html_encode( group_name ) || '"</h2>' || crlf
		 || '<form action="/'|| html_encode( db_name ) || '/show_test" method="GET">' || crlf
		 || '<input type="hidden" value="'|| html_encode( group_id ) || '" name="group_id">' || crlf
		 || '<table class="form">' || crlf
		 || '<tr>' || crlf
		 || '<td class="form"><b>Test Description:</b></td>' || crlf
		 || '<td class="form"><textarea name="test_description" cols="50" rows="5" class="post"></textarea></td>' || crlf
		 || '</tr>'|| crlf
		 || '<tr>' || crlf
		 || '<td class="form"><b>Expected Result:</b></td>' || crlf
		 || '<td class="form"><textarea name="test_result" cols="50" rows="2" class="post"></textarea></td>' || crlf
		 || '</tr>' || crlf
		 || '<tr>' || crlf
		 || '<td class="form"><b>Assigned Author (optional):</b></td>' || crlf
		 || '<td class="form"><input type="text" name="test_author" size="50" maxlength="128" class="post"></td>' || crlf
		 || '</tr>' || crlf
		 || '<tr>' || crlf
		 || '<td class="form"><b>Comments (Optional):</b></td>' || crlf
		 || '<td class="form"><textarea name="test_comment" cols="50" rows="5" class="post"></textarea></td>' || crlf
		 || '</tr>' || crlf
		 || '<tr><td class="form">&nbsp;</td>' || crlf
		 || '<td class="form"><input type="submit" value="Submit" class="button"></td>' || crlf
		 || '</table>' || crlf
		 || '</form>' || crlf;
	else
	    -- We should have enough info to INSERT INTO DB...
	    -- Get  user id if test_author is not null
	    set failed = 0;
	    if test_author is not null then
		begin
		    select user_id into test_uid from SYS.SYSUSERPERMS where user_name = test_author;
		exception
		    when others then
			set failed = 1;
			set rslt = rslt
				|| '<title>Error while adding new test to group "' || html_encode( group_name ) || '"</title>' || crlf
				|| '</head>' || crlf
				|| '<body>'|| crlf
				|| '<h2>Error while adding new test to group "' || html_encode( group_name ) || '"</h2>' || crlf
				|| '<p>Could not find user name "' || html_encode( test_author ) ||'".</p><br>' || crlf;
		end;
	    else
		set test_uid = null;
	    end if;
	    begin
		insert into test ( tg_id, t_description, t_result, t_comment, u_id )
			 values( group_id, test_description, test_result, test_comment, test_uid );
		set rslt = rslt
			|| '<title>Adding new test to group "' || html_encode( group_name ) ||'"</title>' || crlf
			|| '</head>' || crlf
			|| '<body>' || crlf
			|| '<h2>Successfully added new test to group "' || html_encode( group_name ) || '".</h2>' || crlf;
	    exception
		when others then
		    if failed = 0 then
			set rslt = rslt
				|| '<title>Error while adding new test to group "' || html_encode( group_name ) || '"</title>' || crlf
				||'</head>' || crlf
				|| '<body>' || crlf
				|| '<h2>Error while adding new test to group "' || html_encode( group_name ) || '"</h2>' || crlf;
		    end if;
		    set failed = 1;
		    set rslt = rslt
		    		|| '<p>INSERT failed with this error:<br>' || crlf
				|| html_encode( ERRORMSG(SQLSTATE) ) ||'</p><br>' || crlf;
	    end;
	end if;
    else
	select tg_name into group_name from test_group where tg_id = group_id;

	if test_description is not null
		and test_result is not null
		and length(test_description) > 0
		and length(test_result) > 0
	then
	    -- Looks like this is an update!
	    -- Check if test exists
	    select count(*) into cnt
	      from test t
	     where t.tg_id = group_id and t.t_id = test_id;
	    if cnt <> 1 then
		-- This means the test is unknown -> INSERT instead of UPDATE
		set failed = 0;
		if test_author is not null then
		    begin
			select user_id into test_uid from SYS.SYSUSERPERMS where user_name = test_author;
		    exception
			when others then
			    set failed = 1;
			    set rslt = rslt
				|| '<title>Error while adding new test to group "' || html_encode( group_name ) || '"</title>' || crlf
				|| '</head>' || crlf
				|| '<body>' || crlf
				|| '<h2>Error while adding new test to group "' || html_encode( group_name ) || '"</h2>' || crlf
				|| '<p>Could not find user name "' || html_encode( test_author ) || '".</p><br>' || crlf;
		    end;
		else
		    set test_uid = null;
		end if;
		begin
		    insert into test ( tg_id, t_description, t_result, t_comment, u_id )
			 values( group_id, test_description, test_result, test_comment, test_uid );
		    set rslt = rslt
			     || '<title>Adding new test to group "' || html_encode( group_name ) || '"</title>' || crlf
			     || '</head>' || crlf
			     || '<body>' || crlf
			     || '<h2>Successfully added new test to group "' || html_encode( group_name ) || '".</h2>' || crlf;
		exception
		    when others then
			if failed = 0 then
			    set rslt = rslt
				|| '<title>Error while adding new test to group "' || html_encode( group_name ) || '"</title>' || crlf
				|| '</head>' || crlf
				|| '<body>' || crlf
				|| '<h2>Error while adding new test to group "' || html_encode( group_name ) || '"</h2>' || crlf;
			end if;
			set failed = 1;
			set rslt = rslt
				|| '<p>INSERT failed with this error:<br>' || crlf
				|| html_encode( ERRORMSG(SQLSTATE) ) || '</p><br>' || crlf;
		end;
	    else
		-- Updating a test...
		set failed = 0;
		if test_author is not null then
		    begin
			select user_id
			  into test_uid
			  from SYS.SYSUSERPERMS
			 where user_name = test_author;
		    exception
			when others then
			    set failed = 1;
			    set rslt = rslt
				|| '<title>Error while updating test in group "' || html_encode( group_name ) || '"</title>' || crlf
				|| '</head>' || crlf
				|| '<body>' || crlf
				|| '<h2>Error while updating test (id ' || test_id || ') in group "' || html_encode( group_name ) || '"</h2>' || crlf
				|| '<p>Could not find user name "' || html_encode( test_author ) || '".</p><br>' || crlf;
		    end;
		else
		    set test_uid = null;
		end if;
		begin
		    update test
			set t_description = test_description,
			    t_result = test_result,
			    t_comment = test_comment,
			    u_id = test_uid
			where tg_id = group_id and t_id = test_id;
		    set rslt = rslt
			  || '<title>Updating test in group "' || html_encode( group_name ) || '"</title>' || crlf
			  || '</head>' || crlf
			  || '<body>' || crlf
			  || '<h2>Successfully updated test (id ' || test_id || ') in group "' || html_encode( group_name ) || '".</h2>' || crlf;
		exception
		    when others then
			if failed = 0 then
			    set rslt = rslt
				 || '<title>Error while updating test in group "' || html_encode( group_name ) || '"</title>' || crlf
				 || '</head>' || crlf
				 || '<body>' || crlf
				 || '<h2>Error while updating test (id ' || test_id || ') in group "' || html_encode( group_name ) || '"</h2>' || crlf;
			end if;
			set failed = 1;
			set rslt = rslt
				 || '<p>UPDATE failed with this error:<br>' || crlf
				 || html_encode( ERRORMSG(SQLSTATE) ) || '</p><br>' || crlf;
		    RESIGNAL;
		end;
	    end if;
	else
	    select t.t_description, t.t_result, t.t_comment, u.user_name
	      into test_description, test_result, test_comment, test_author 
	      from test t left join SYS.SYSUSERPERMS u on ( t.u_id = u.user_id )
	     where t.tg_id = group_id and t.t_id = test_id;
	    if SQLSTATE = err_notfound then
		set rslt = rslt
			 || '<h2>Test Group "' || html_encode( group_name ) || '" does not feature a test with ID ' || test_id || '</h2>';
	    else
		set rslt = rslt
			 || '<h2>Details of Test in Group "' || html_encode( group_name ) || '"</h2>' || crlf
			 || '<form action="/' || html_encode( db_name ) || '/show_test" method="GET">' || crlf
			 || '<input type="hidden" value="'|| html_encode( group_id ) || '" name="group_id">' || crlf
			 || '<input type="hidden" value="'|| html_encode( test_id ) || '" name="test_id">' || crlf
			 || '<table>' || crlf
			 || '<tr>' || crlf
			 || '<td class="form"><b>Test Description:</b></td>' || crlf
			 || '<td class="form"><textarea name="test_description" cols="50" rows="5" class="post">' || html_encode( test_description ) || '</textarea></td>' || crlf
			 || '</tr>' || crlf
			 || '<tr>' || crlf
			 || '<td class="form"><b>Expected Result:</b></td>' || crlf
			 || '<td class="form"><textarea name="test_result" cols="50" rows="2" class="post">' || html_encode( test_result ) || '</textarea></td>' || crlf
			 || '</tr>' || crlf
			 || '<tr>' || crlf
			 || '<td class="form"><b>Assigned Author (optional):</b></td>' || crlf
			 || '<td class="form"><input type="text" name="test_author" size="50" maxlength="128" class="post" value="' || html_encode( test_author ) || '"></td>' || crlf
			 || '</tr>' || crlf
			 || '<tr>' || crlf
			 || '<td class="form"><b>Comments (Optional):</b></td>' || crlf
			 || '<td class="form"><textarea name="test_comment" cols="50" rows="5" class="post">' || html_encode( test_comment ) || '</textarea></td>' || crlf
			 || '</tr>' || crlf
			 || '<tr><td class="form">&nbsp;</td>' || crlf
			 || '<td class="form"><input type="submit" value="Submit" class="button"></td>' || crlf
			 || '</table>' || crlf
			 || '</form>' || crlf;
	    end if;
	end if;
    end if;
    set rslt = rslt 
	     || '<br><hr>' || crlf
	     || '<p><a href="/' || html_encode( db_name ) || '/list_group?group_id=' || html_encode( group_id )
	     || '">Back to Test Group "' || html_encode( group_name ) || '"</a></p>' || crlf
	     || '</body>' || crlf
	     || '</html>' || crlf;

    call sa_set_http_header( 'Content-Type', 'text/html' );
    select rslt;
end
go

grant execute on show_test to authors
go

-- css

create or replace procedure css ( )
result( res long varchar )
begin
    declare rslt long varchar;
    declare crlf char(4);
    set crlf='\x0d\x0a';
    set rslt = string(	'body {', crlf,
			'background-color: #222222;', crlf,
			'color: #DDDDDD;', crlf,
			'scrollbar-face-color: #552288;', crlf,
			'scrollbar-highlight-color: #552288;', crlf,
			'scrollbar-shadow-color: #552288;', crlf,
			'scrollbar-3dlight-color: #663399;', crlf,
			'scrollbar-arrow-color:  #CC6600;', crlf,
			'scrollbar-track-color: #441177;', crlf,
			'scrollbar-darkshadow-color: #222222; }', crlf,
			'font,th,td,p,a { font-family: Verdana, Arial, Helvetica, sans-serif; }', crlf,
			'p, td { font-size: 13px; }', crlf,
			'a:link,a:active,a:visited { text-decoration: none; color : #DDDDDD; }', crlf,
			'a:hover { text-decoration: none; color : #FFFF99; }', crlf,
			'h1,h2 {', crlf,
			'font-weight: bold; font-size: 22px; font-family: "Trebuchet MS", Verdana, Arial, Helvetica, sans-serif;', crlf,
			'text-decoration: none; line-height : 120%; color : #DDDDDD; }', crlf,
			'input,textarea,select {', crlf,
			'color : #DDDDDD;', crlf,
			'font: normal 12px Verdana, Arial, Helvetica, sans-serif;', crlf,
			'border-color : #777777; }', crlf,
			'input.post, textarea.post {', crlf,
			'background-color : #222222; }', crlf,
			'select {', crlf,
			'background-color : #222222; }', crlf,
			'input { text-indent : 2px; }', crlf,
			'input.button {', crlf,
			'background-color : #DDDDDD;', crlf,
			'color : #000000;', crlf,
			'font-size: 11px; font-family: Verdana, Arial, Helvetica, sans-serif; }', crlf,
			'hr { color : #DDDDDD; }', crlf,
			'table { padding:0px; spacing: 2px; border:0px; background: #222222; }', crlf,
			'td { padding:5px; border: 1px solid #999999; background: #222222; }', crlf,
			'th { padding:5px; border: 0px solid #999999; background: #222222; color: #DDDDDD; }', crlf,
			'table.form,td.form { padding: 3px; spacing: 2px; border: 0px; background: #222222; }', crlf
		);

    call sa_set_http_header( 'Content-Type', 'text/html' );
    select rslt;
end
go

grant execute on css to http
go

commit work
go

------------------
-- Web Services --
------------------

-- show_groups
if exists(select * from SYS.SYSWEBSERVICE where service_name='show_groups') then
    drop service show_groups;
end if
go

create service show_groups type 'raw' authorization off user http
    as call DBA.show_groups()
go

-- list_group
if exists(select * from SYS.SYSWEBSERVICE where service_name='list_group') then
    drop service list_group;
end if
go

create service list_group type 'raw' authorization off user http
    as call DBA.list_group( :group_id )
go

-- add_test_group
if exists(select * from SYS.SYSWEBSERVICE where service_name='add_test_group') then
    drop service add_test_group;
end if
go

create service add_test_group type 'raw' authorization on user authors
    as call DBA.add_test_group( :group_name )
go

-- show_test
if exists(select * from SYS.SYSWEBSERVICE where service_name='show_test') then
    drop service show_test;
end if
go

create service show_test type 'raw' authorization on user authors
    as call DBA.show_test( :group_id, :test_id, :test_description, :test_result, :test_author, :test_comment )
go

-- css
if exists(select * from SYS.SYSWEBSERVICE where service_name='css') then
    drop service css;
end if
go

create service css type 'raw' authorization off user http
    as call DBA.css()
go
