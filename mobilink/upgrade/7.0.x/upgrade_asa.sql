
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- a Sybase ASA consolidated database.
--


--
-- Create temporary tables.
--
create table #ml_user_temp (
    user_id		    integer	    not null,
    name		    varchar( 128 )  not null unique,
    hashed_password	    binary( 32 )    null )
go

create table #ml_database_temp (
    rid			    integer	    not null,
    remote_id		    varchar( 128 )  not null unique,
    description		    varchar( 128 )  null )
go

create table #ml_subscription_temp (
    rid			    integer	    not null,
    subscription_id	    varchar( 128 )  default '<unknown>' not null,
    user_id		    integer	    not null,
    progress		    numeric( 20 )   default 0 not null,
    publication_name	    varchar( 128 )  default '<unknown>' not null,
    last_upload_time	    timestamp	    default '1900-01-01 00:00:00' not null,
    last_download_time	    timestamp	    default '1900-01-01 00:00:00' not null )
go

--
-- Store the old information into the temporary tables.
--
insert into #ml_user_temp ( user_id, name, hashed_password )
    select user_id, name, hashed_password
	from ml_user
go

insert into #ml_database_temp ( rid, remote_id, description )
    select user_id, name, name
	from ml_user
go

insert into #ml_subscription_temp ( rid, user_id, progress )
    select user_id, user_id, commit_state
	from ml_user where commit_state <> 0
go

insert into #ml_subscription_temp ( rid, user_id, progress )
    select user_id, user_id, progress
	from ml_user where progress <> 0
go

--
-- Drop the old ml_user table.
--
drop table ml_user
go

--
-- Add new tables for user authentication using LDAP servers
--
create table ml_ldap_server (
    ldsrv_id		integer		not null default autoincrement,
    ldsrv_name		varchar(128)	not null unique,
    search_url		varchar(1024)	not null,
    access_dn		varchar(1024)	not null,
    access_dn_pwd	varchar(256)	not null,
    auth_url		varchar(1024)	not null,
    num_retries		tinyint		not null default 3,
    timeout		integer		not null default 10,
    start_tls		tinyint		not null default 0,
    primary key ( ldsrv_id ) )
go

create table ml_trusted_certificates_file (
    file_name		varchar(1024) not null ) 
go

create table ml_user_auth_policy (
    policy_id			integer		not null default autoincrement,
    policy_name			varchar(128)	not null unique,
    primary_ldsrv_id		integer		not null,
    secondary_ldsrv_id		integer		null,
    ldap_auto_failback_period	integer		not null default 900,
    ldap_failover_to_std	tinyint		not null default 1,
    foreign key( primary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    foreign key( secondary_ldsrv_id ) references ml_ldap_server( ldsrv_id ),
    primary key( policy_id ) ) 
go

--
-- Restructure the ml_user table.
--
create table ml_user (
    user_id		integer		not null default autoincrement,
    name		varchar(128)	not null unique,
    hashed_password	binary(32)	null,
    policy_id		integer		null,
    user_dn		varchar(1024)	null,
    foreign key( policy_id ) references ml_user_auth_policy( policy_id ),
    primary key( user_id ) ) 
go

insert into ml_user ( user_id, name, hashed_password )
    select user_id, name, hashed_password
	from #ml_user_temp
go
    
--
-- Create and populate the ml_database table.
--
create table ml_database (
    rid			integer		not null default autoincrement,
    remote_id		varchar( 128 )	not null,
    script_ldt		timestamp	not null default '1900/01/01 00:00:00',
    seq_id		binary(16)	null,
    seq_uploaded	integer		not null default 0,
    sync_key		varchar( 40 ),
    description		varchar( 128 ),
    unique( remote_id ),
    primary key( rid ) )
go

insert into ml_database ( rid, remote_id, description )
    select rid, remote_id, description
	from #ml_database_temp
go
    
--
-- Restructure the ml_subscription table.
--
create table ml_subscription (
    rid			integer		not null,
    subscription_id	varchar( 128 )	not null default '<unknown>',
    user_id		integer		not null,
    progress		numeric( 20 )	not null default 0,
    publication_name	varchar( 128 )	not null default '<unknown>',
    last_upload_time	timestamp	not null default '1900/01/01 00:00:00',
    last_download_time	timestamp	not null default '1900/01/01 00:00:00',
    primary key( rid, subscription_id ),
    not null foreign key references ml_database,
    not null foreign key references ml_user )
go

insert into ml_subscription ( rid, user_id, subscription_id,
			      progress, publication_name,
			      last_upload_time, last_download_time )
    select rid, user_id, subscription_id, progress,
	   publication_name, last_upload_time, last_download_time
    from #ml_subscription_temp
go

--
-- Replace the ml_add_user stored procedure.
--
drop procedure ml_add_user
go

create procedure ml_add_user(
    in @user		varchar( 128 ),
    in @password	binary( 32 ),
    in @policy_name	varchar( 128 ) )
begin
    declare @user_id	integer;
    declare @policy_id	integer;
    declare @error	integer;
    declare @msg	varchar( 1024 );
    
    if @user is not null then
	set @error = 0;
	if @policy_name is not null then
	    select policy_id into @policy_id from ml_user_auth_policy
		where policy_name = @policy_name;
	    if @policy_id is null then
		set @msg = 'Unable to find the user authentication policy: "' +
			    @policy_name + '"';
		raiserror 20000 @msg;
		set @error = 1;
	    end if;
	else 
	    set @policy_id = null;
	end if;
	if @error = 0 then
	    select user_id into @user_id from ml_user where name = @user;
	    if @user_id is null then
		insert into ml_user ( name, hashed_password, policy_id )
		    values ( @user, @password, @policy_id );
	    else
		update ml_user set hashed_password = @password,
				    policy_id = @policy_id
		    where user_id = @user_id;
	    end if;
	end if;
    end if;
end
go

-- If error is raised then caller must rollback
create procedure ml_delete_remote_id(
    in @remote_id	varchar(128) )
begin
    declare @rid integer;
    
    select rid into @rid from ml_database where remote_id = @remote_id;
    delete from ml_subscription where rid = @rid;
    if SQLCODE < 0 then return endif;
    delete from ml_passthrough_status where remote_id = @remote_id;
    if SQLCODE < 0 then return endif;
    delete from ml_passthrough where remote_id = @remote_id;
    if SQLCODE < 0 then return endif;
    delete from ml_database where rid = @rid;
end
go

create procedure ml_delete_user_state(
    in @user		varchar( 128 ) )
begin
    declare @uid	integer;
    declare @rid	integer;
    declare @remote_id	varchar(128);
    
    declare remotes cursor for
	select rid from ml_subscription
	    where user_id = @uid;
    
    select user_id into @uid from ml_user where name = @user;
    if @uid is not null then
	open remotes;
	dbs: loop
	    fetch remotes into @rid;
	    if SQLCODE <> 0 then
		leave dbs
	    end if;
	    delete from ml_subscription
		where user_id = @uid and rid = @rid;
	    if not exists (select * from ml_subscription
		    where rid = @rid) then
		select remote_id into @remote_id from ml_database where rid = @rid;
		call ml_delete_remote_id(@remote_id);
	    end if;
	end loop;
	close remotes;
    end if;
end
go

create procedure ml_delete_user(
    in @user		varchar( 128 ) )
begin
    call ml_delete_user_state( @user );
    delete from ml_user where name = @user;
end
go

--
-- Add the new stored procedures
--
create procedure ml_delete_sync_state(
    in @user		varchar( 128 ),
    in @remote_id	varchar( 128 ) )
begin
    declare @uid	integer;
    declare @rid	integer;
    
    declare remotes cursor for
	select rid from ml_subscription where user_id = @uid;
    
    select user_id into @uid from ml_user where name = @user;
    select rid into @rid from ml_database where remote_id = @remote_id;
    
    if @user is not null and @remote_id is not null then
	delete from ml_subscription where user_id = @uid and rid = @rid;
	if not exists (select * from ml_subscription where rid = @rid) then
	    call ml_delete_remote_id(@remote_id);
	end if;
    elseif @user is not null then
	call ml_delete_user_state( @user );
    elseif @remote_id is not null then
	call ml_delete_remote_id(@remote_id);
    end if;
end
go

create procedure ml_reset_sync_state(
    in @user		varchar( 128 ),
    in @remote_id	varchar( 128 ) )
begin
    declare @uid	integer;
    declare @rid	integer;
	
    select user_id into @uid from ml_user where name = @user;
    select rid into @rid from ml_database where remote_id = @remote_id;
    
    if @user is not null and @remote_id is not null then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = @uid and rid = @rid
    elseif @user is not null then
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where user_id = @uid
    elseif @remote_id is not null then	
	update ml_subscription
	    set progress = 0,
		last_upload_time   = '1900/01/01 00:00:00',
		last_download_time = '1900/01/01 00:00:00'
	    where rid = @rid
    end if;
    
    update ml_database
	set sync_key = NULL,
	    seq_id = NULL,
	    seq_uploaded = 0,
	    script_ldt = '1900/01/01 00:00:00'
	where remote_id = @remote_id;
end
go

create procedure ml_delete_sync_state_before( in @ts timestamp )
begin
    declare @rid	integer;
    declare @remote_id	varchar(128);
    
    declare remotes cursor for
	select rid from ml_subscription where last_upload_time < @ts and
					      last_download_time < @ts;
    if @ts is not null then
	open remotes;
	dbs: loop
	    fetch remotes into @rid;
	    if SQLCODE <> 0 then
		leave dbs
	    end if;
	    delete from ml_subscription where rid = @rid and
					      last_upload_time < @ts and
					      last_download_time < @ts;
	    if not exists (select * from ml_subscription
					      where rid = @rid) then
		select remote_id into @remote_id from ml_database where rid = @rid;
		call ml_delete_remote_id(@remote_id);
	    end if;
	end loop;
	close remotes;
    end if;
end
go

create procedure ml_share_all_scripts( 
    in @version		varchar( 128 ),
    in @other_version	varchar( 128 ) )
begin
    declare @version_id		integer;
    declare @other_version_id	integer;
    
    select version_id into @version_id from ml_script_version 
		where name = @version;
    select version_id into @other_version_id from ml_script_version 
		where name = @other_version;

    if @version_id is null then
	insert into ml_script_version ( name ) values ( @version );
	set @version_id = @@identity;
    end if;

    insert into ml_table_script( version_id, table_id, event, script_id )
	select @version_id, table_id, event, script_id from ml_table_script 
	    where version_id = @other_version_id;
    
    insert into ml_connection_script( version_id, event, script_id )
	select @version_id, event, script_id from ml_connection_script 
	    where version_id = @other_version_id;
end
go

create procedure ml_add_missing_dnld_scripts(
    in @script_version	varchar( 128 ) )
begin
    declare @version_id	integer;
    declare @table_id	integer;
    declare @count_1	integer;
    declare @count_2	integer;
    declare @table_name	varchar(128);
    declare @first	integer;
    declare @tid	integer;
    declare crsr cursor for
	    select t.table_id from ml_table_script t, ml_script_version v
		where t.version_id = v.version_id and
		      v.name = @script_version order by 1;
    
    select version_id into @version_id from ml_script_version
	where name = @script_version;
    if @version_id is not null then
	set @first = 1;
	open crsr;
	tid: loop
	    fetch crsr into @table_id;
	    if SQLCODE <> 0 then 
		leave tid;
	    end if;
	    if @first = 1 or @table_id <> @tid then
		if not exists (select * from ml_table_script
				where version_id = @version_id and
				    table_id = @table_id and
				    event = 'download_cursor') then
		    set @count_1 = 0;
		else
		    set @count_1 = 1;
		end if;
		if not exists (select * from ml_table_script
				where version_id = @version_id and
				    table_id = @table_id and
				    event = 'download_delete_cursor') then
		    set @count_2 = 0;
		else
		    set @count_2 = 1;
		end if;
		if @count_1 = 0 or @count_2 = 0 then
		    select name into @table_name from ml_table where table_id = @table_id;
		    if @count_1 = 0 then
			call ml_add_table_script( @script_version, @table_name,
			    'download_cursor', '--{ml_ignore}' );
		    end if;
		    if @count_2 = 0 then
			call ml_add_table_script( @script_version, @table_name,
			    'download_delete_cursor', '--{ml_ignore}' );
		    end if;
		end if;
		set @first = 0;
		set @tid = @table_id;
	    end if;
	end loop;
	close crsr;
    end if;
end
go

create procedure ml_add_column(
    in @version	varchar( 128 ),
    in @table	varchar( 128 ),
    in @column	varchar( 128 ),
    in @type	varchar( 128 ) )
begin
    declare @version_id		integer;
    declare @table_id		integer;
    declare @script_id		integer;
    declare @idx		integer;
    
    select version_id into @version_id from ml_script_version 
	where name = @version;
    select table_id into @table_id from ml_table where name = @table;
    if @column is not null then
	if @version_id is null then
	    insert into ml_script_version ( name ) values ( @version );
	    set @version_id = @@identity;
	end if;
	if @table_id is null then
	    insert into ml_table ( name ) values ( @table );
	    set @table_id = @@identity;
	end if;
	select max( idx ) + 1 into @idx from ml_column
	    where version_id = @version_id and table_id = @table_id;
	if @idx is null then
	    set @idx = 1
	end if;
	insert into ml_column ( version_id, table_id, idx, name, type ) 
	    values ( @version_id, @table_id, @idx, @column, @type );
    else
	if @version_id is not null and @table_id is not null then
	    delete from ml_column 
	        where version_id = @version_id and table_id = @table_id;
	end if;
    end if;
end
go

create procedure ml_lock_rid(
    in @rid		integer,
    inout @sync_key	varchar( 40 ),
    inout @failure	integer )
begin
    declare @locked_out	exception for SQLSTATE '42W18';
    
    SET @failure = 0;
    SET TEMPORARY OPTION blocking='off';
    SELECT sync_key into @sync_key FROM ml_database WITH (XLOCK) WHERE rid = @rid;
    SET TEMPORARY OPTION blocking='on';
    exception
	when @locked_out then
	    SET TEMPORARY OPTION blocking='on';
	    SET @failure = 1;
end
go

--
-- Add the new script_language column to the ml_script table.
--
-- This column must allow nulls, as not all ASE servers support adding non-null columns.
-- Also, depending on the database options of those that do, they may not either.
--
alter table ml_script add 
    script_language varchar( 128 ) default 'sql' null
go

alter table ml_script add
    checksum		varchar( 64 )	null
go

create table ml_column (
    version_id	integer		not null,
    table_id	integer		not null,
    idx		integer		not null,
    name	varchar( 128 )	not null,
    type	varchar( 128 )	null,
    not null foreign key references ml_script_version,
    not null foreign key references ml_table,
    primary key( idx, version_id, table_id ),
    unique( version_id, table_id, name ) )
go

create trigger ml_column_trigger 
    after insert, update, delete on ml_column
    for each row
begin
    update ml_scripts_modified set last_modified = dateformat( CURRENT TIMESTAMP, 'yyyy/mm/dd hh:nn:ss' );
end
go

create view ml_columns
as
    select ml_script_version.name version,
	  ml_table.name table_name,
	  ml_column.name column_name,
	  ml_column.type data_type,
	  ml_column.idx column_order
	from ml_script_version,
	     ml_table,
	     ml_column
	where ml_column.version_id = ml_script_version.version_id and
	      ml_column.table_id = ml_table.table_id
go

--
-- Add the ml_primary_server table
--
create table ml_primary_server (
    server_id		integer		not null default autoincrement,
    name		varchar( 128 )	not null,
    connection_info	varchar( 2048 )	not null,
    instance_key	binary( 32 )	not null,
    start_time		timestamp	not null default current timestamp,
    unique( name ),
    primary key( server_id ) )
go

--
-- Add SQL Batch tables and related procedures
--
create table ml_passthrough_script (
    script_id			integer		not null default autoincrement,
    script_name			varchar( 128 )	not null unique,
    flags			varchar( 256 )	null,
    affected_pubs		text		null,
    script			text		not null,
    description 		varchar( 2000 )	null,
    primary key( script_id ) )
go

create table ml_passthrough (
    remote_id			varchar( 128 )	not null,
    run_order			integer		not null,
    script_id			integer		not null,
    last_modified 		timestamp	not null default current timestamp,
    primary key( remote_id, run_order ),
    foreign key( remote_id ) references ml_database( remote_id ),
    foreign key( script_id ) references ml_passthrough_script( script_id ) )
go

create table ml_passthrough_status (
    status_id			integer		not null default autoincrement,
    remote_id			varchar( 128 )	not null,
    run_order			integer		not null,
    script_id			integer		not null,
    script_status		char( 1 )	not null,
    error_code			integer		null,
    error_text			text		null,
    remote_run_time		timestamp	not null,
    primary key( status_id ),
    unique( remote_id, run_order, remote_run_time ),
    foreign key( remote_id ) references ml_database( remote_id ) )
go

create table ml_passthrough_repair (
    failed_script_id		integer		not null,
    error_code			integer		not null,
    new_script_id		integer		null,
    action			char( 1 )	not null,
    primary key( failed_script_id, error_code ),
    foreign key( failed_script_id ) references ml_passthrough_script( script_id ) )
go

create trigger ml_passthrough_trigger before update of
    remote_id, run_order, script_id on ml_passthrough
    referencing new as pt
    for each row
begin
    set pt.last_modified = CURRENT TIMESTAMP;
end
go

create procedure ml_add_passthrough_script(
    in @script_name		varchar( 128 ),
    in @flags			varchar( 256 ),
    in @affected_pubs		text,
    in @script			text,
    in @description		varchar( 2000 ) )
begin
    declare @v_substr		varchar( 256 );
    declare @v_str		varchar( 256 );
    declare @v_start		integer;
    declare @v_end		integer;
    declare @v_done		integer;
    declare @v_error		integer;
    declare @v_msg		varchar( 300 );
    
    if @script_name is not null and @script is not null then
	set @v_error = 0;
	if @flags is not null then
	    set @v_str = @flags;
	    set @v_start = 1;
	    set @v_done = 0;
	    myr: loop
		set @v_end = charindex( ';', @v_str );
		if @v_end = 0 then
		    set @v_end = datalength( @flags ) + 1;
		    set @v_done = 1;
		end if;
		set @v_substr = substring( @v_str, @v_start, @v_end - @v_start );
		if @v_substr is not null and datalength( @v_substr ) <> 0 then
		    if @v_substr not in ( 'manual', 'exclusive', 'schema_diff' ) then
			set @v_msg = 'Invalid flag: "' + @v_substr + '"';
			raiserror 20000 @v_msg;
			set @v_error = 1;
			leave myr;
		    end if;
		end if;
		if @v_done = 1 then
		    leave myr;
		end if;
		set @v_str = substring( @v_str, @v_end + 1, datalength( @flags ) - @v_end );
	    end loop;
	end if;
	if @v_error = 0 then
	    if not exists ( select * from ml_passthrough_script where script_name = @script_name ) then
		insert into ml_passthrough_script( script_name, flags, affected_pubs,
				      script, description )
		    values( @script_name, @flags, @affected_pubs,
			    @script, @description );
	    else
		set @v_msg = 'The script name "' + @script_name + '" already exists in the ml_passthrough_script table.  Please choose another script name.';
		raiserror 20000 @v_msg;
	    end if;
	end if;
    else
	set @v_msg = 'Neither passthrough script name nor script content can be null.';
	raiserror 20000 @v_msg;
    end if;
end
go

create procedure ml_delete_passthrough_script(
    in @script_name		varchar( 128 ) )
begin
    declare @script_id integer;
    
    select script_id into @script_id from ml_passthrough_script where script_name = @script_name;
    if @script_id is not null then
        if not exists ( select * from ml_passthrough
			    where script_id = @script_id ) and
	   not exists ( select * from ml_passthrough_repair
			    where failed_script_id = @script_id ) and
	   not exists ( select * from ml_passthrough_repair
			    where new_script_id = @script_id ) then
	    delete from ml_passthrough_script where script_id = @script_id;
	end if;
    end if;
end
go

create procedure ml_add_passthrough(
    in @remote_id		varchar( 128 ),
    in @script_name		varchar( 128 ),
    in @run_order		integer )
begin
    declare rid_crsr cursor for select remote_id from ml_database;
    declare @rid varchar( 128 );
    declare @name varchar( 128 );
    declare @order integer;
    declare @script_id integer;
    declare @msg varchar( 300 );
    
    select script_id into @script_id from ml_passthrough_script where script_name = @script_name;
    if @script_id is not null then
	if @run_order is not null and @run_order < 0 then
	    set @msg = 'A negative value for run_order is not allowed';
	    raiserror 20000 @msg;
	else
	    if @remote_id is null then
		if @run_order is null then
		    select isnull( max( run_order ) + 10, 10 ) into @order
			from ml_passthrough;
		else
		    set @order = @run_order;
		end if;
		open rid_crsr;
		mld: loop
		    fetch rid_crsr into @rid;
		    if SQLCODE <> 0 then
			leave mld;
		    else
			insert into ml_passthrough( remote_id, run_order, script_id )
			    values( @rid, @order, @script_id );
		    end if;
		end loop;
		close rid_crsr;
	    else
		if @run_order is null then
		    select isnull( max( run_order ) + 10, 10 ) into @order
			from ml_passthrough where remote_id = @remote_id;
		    insert into ml_passthrough( remote_id, run_order, script_id )
			values( @remote_id, @order, @script_id );
		else 
		    if exists (select * from ml_passthrough
			       where remote_id = @remote_id and run_order = @run_order) then
			update ml_passthrough set script_id = @script_id,
			    last_modified = current timestamp
			    where remote_id = @remote_id and run_order = @run_order;
		    else
			insert into ml_passthrough( remote_id, run_order, script_id )
			    values( @remote_id, @run_order, @script_id );
		    end if;
		end if;
	    end if;
	end if;
    else
	set @msg = 'Passthrough script name: "' + @name +
			'" does not exist in the ml_passthrough_script table.';
	raiserror 20000 @msg;
    end if;
end
go

create procedure ml_delete_passthrough(
    in @remote_id		varchar( 128 ),
    in @script_name		varchar( 128 ),
    in @run_order		integer )
begin
    if @remote_id is null then
	if @run_order is null then
	    delete from ml_passthrough
		where script_id in
		    (select script_id from ml_passthrough_script where script_name = @script_name);
	else
	    delete from ml_passthrough
		where run_order = @run_order and script_id in
		    (select script_id from ml_passthrough_script where script_name = @script_name);
	end if;
    else 
	if @run_order is null then
	    delete from ml_passthrough
		where remote_id = @remote_id and script_id in
		    (select script_id from ml_passthrough_script where script_name = @script_name);
	else
	    delete from ml_passthrough
		where remote_id = @remote_id and run_order = @run_order and script_id in
		    (select script_id from ml_passthrough_script where script_name = @script_name);
	end if;
    end if;
end
go

create procedure ml_add_passthrough_repair(
    in @failed_script_name	varchar( 128 ),
    in @error_code		integer,
    in @new_script_name		varchar( 128 ),
    in @action			char( 1 ) )
begin
    declare @failed_script_id integer;
    declare @name varchar( 128 );
    declare @msg varchar( 300 );
    declare @new_script_id integer;
    
    select script_id into @failed_script_id from ml_passthrough_script
	where script_name = @failed_script_name;
    if @failed_script_id is not null then
	if @action in ( 'R', 'S', 'P', 'H', 'r', 's', 'p', 'h' ) then
	    if @action in ( 'R', 'r' ) and @new_script_name is null then
		set @msg = 'The new_script_name cannot be null for action "' + @action + '".';
		raiserror 20000 @msg;
	    elseif @action in ( 'S', 'P', 'H', 's', 'p', 'h' ) and @new_script_name is not null then
		set @msg = 'The new_script_name should be null for action "' + @action + '".';
		raiserror 20000 @msg;
	    elseif @new_script_name is not null and
		not exists ( select * from ml_passthrough_script
			       where script_name = @new_script_name ) then
		set @msg = 'Invalid new_script_name: "' + @new_script_name + '".';
		raiserror 20000 @msg;
	    else
		select script_id into @new_script_id from ml_passthrough_script
		    where script_name = @new_script_name;
		if exists ( select * from ml_passthrough_repair
			       where failed_script_id = @failed_script_id and
				     error_code = @error_code ) then
		    update ml_passthrough_repair
			set new_script_id = @new_script_id, action = @action
			where failed_script_id = @failed_script_id and
			     error_code = @error_code;
		else 
		    insert into ml_passthrough_repair
			(failed_script_id, error_code, new_script_id, action)
			values( @failed_script_id, @error_code,
				@new_script_id, @action );
		end if;
	    end if;
	else
	    set @msg = 'Invalid action: "' + @action + '".';
	    raiserror 20000 @msg;
	end if;
    else
	set @msg = 'Invalid failed_script_name: "' + @failed_script_name + '".';
	raiserror 20000 @msg;
    end if;
end
go

create procedure ml_delete_passthrough_repair(
    in @failed_script_name	varchar( 128 ),
    in @error_code		integer )
begin
    if @error_code is null then
	delete from ml_passthrough_repair
	    where failed_script_id =
		(select script_id from ml_passthrough_script where script_name = @failed_script_name);
    else
	delete from ml_passthrough_repair
	    where failed_script_id =
		(select script_id from ml_passthrough_script where script_name = @failed_script_name) and
		error_code = @error_code;
    end if;
end
go


--
-- Replace the ml_add_table_script stored procedure, and add some new ones.
--
drop procedure ml_add_table_script
go

create procedure ml_add_lang_table_script_chk( 
    in @version		varchar( 128 ),
    in @table		varchar( 128 ),
    in @event		varchar( 128 ),
    in @script_language	varchar( 128 ),
    in @script		text,
    in @checksum	varchar( 64 ) )
begin
    declare @version_id		integer;
    declare @table_id		integer;
    declare @script_id		integer;
    declare @upd_script_id	integer;
    
    select version_id into @version_id from ml_script_version 
		where name = @version;
    select table_id into @table_id from ml_table where name = @table;
    if @script is not null then
	if @version_id is null then
	    insert into ml_script_version ( name ) values ( @version );
	    set @version_id = @@identity;
	end if;
	if @table_id is null then
	    insert into ml_table ( name ) values ( @table );
	    set @table_id = @@identity;
	end if;
	insert into ml_script ( script_language, script, checksum )
	    values ( @script_language, @script, @checksum );
	set @script_id = @@identity;
	select script_id into @upd_script_id from ml_table_script
	    where table_id = @table_id and version_id = @version_id
	    and event = @event;
	if @upd_script_id is null then
	    insert into ml_table_script
		    ( version_id, table_id, event, script_id ) 
		    values ( @version_id, @table_id, @event, @script_id );
	else
	    update ml_table_script set script_id = @script_id
		    where table_id = @table_id and version_id = @version_id
		    and event = @event;
	end if;
    else
	delete from ml_table_script where version_id = @version_id
	    and table_id = @table_id and event = @event;
    end if;
end
go

create procedure ml_add_lang_table_script(
    in @version		varchar( 128 ),
    in @table		varchar( 128 ),
    in @event		varchar( 128 ),
    in @script_language	varchar( 128 ),
    in @script		text )
begin
    call ml_add_lang_table_script_chk( @version, @table, @event, @script_language, @script, null )
end
go

create procedure ml_add_table_script( 
    in @version	varchar( 128 ),
    in @table	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_table_script( @version, @table, @event, 'sql', @script )
end
go

create procedure ml_add_java_table_script( 
    in @version	varchar( 128 ),
    in @table	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_table_script( @version, @table, @event, 'java', @script )
end
go

create procedure ml_add_dnet_table_script( 
    in @version	varchar( 128 ),
    in @table	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_table_script( @version, @table, @event, 'dnet', @script )
end
go


--
-- Replace the ml_add_connection_script stored procedure, and add some new ones.
--
drop procedure ml_add_connection_script
go

create procedure ml_add_lang_conn_script_chk( 
    in @version		varchar( 128 ),
    in @event		varchar( 128 ),
    in @script_language	varchar( 128 ),
    in @script		text,
    in @checksum	varchar( 64 ) )
begin
    declare @version_id		integer;
    declare @script_id		integer;
    declare @upd_script_id	integer;
    
    select version_id into @version_id from ml_script_version 
		where name = @version;
    if @script is not null then
	if @version_id is null then
	    insert into ml_script_version ( name ) values ( @version );
	    set @version_id = @@identity;
	end if;
	insert into ml_script ( script_language, script, checksum )
	    values ( @script_language, @script, @checksum );
	set @script_id = @@identity;
	select script_id into @upd_script_id from ml_connection_script
	    where version_id = @version_id and event = @event;
	if @upd_script_id is null then
	    insert into ml_connection_script 
		( version_id, event, script_id )
		values ( @version_id, @event, @script_id );
	else
	    update ml_connection_script set script_id = @script_id
		where version_id = @version_id and event = @event;
	end if;
    else
	if @version_id is not null then
	    delete from ml_connection_script where 
		version_id = @version_id and event = @event;
	end if;
    end if;
end
go

create procedure ml_add_lang_connection_script(
    in @version		varchar( 128 ),
    in @event		varchar( 128 ),
    in @script_language	char( 128 ),
    in @script		text )
begin
    call ml_add_lang_conn_script_chk( @version, @event, @script_language, @script, null )
end
go

create procedure ml_add_connection_script( 
    in @version	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_connection_script( @version, @event, 'sql', @script )
end
go

create procedure ml_add_java_connection_script( 
    in @version	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_connection_script( @version, @event, 'java', @script )
end
go

create procedure ml_add_dnet_connection_script( 
    in @version	varchar( 128 ),
    in @event	varchar( 128 ),
    in @script	text )
begin
    call ml_add_lang_connection_script( @version, @event, 'dnet', @script )
end
go

--
-- Add a stored procedure for retrieving locking/blocking information
--
-- Create a stored procedure to get the connections
-- that are currently blocking the connections given
-- by @spids for more than @block_time seconds

create procedure ml_get_blocked_info(
    @spids		varchar(2000),
    @block_time		integer )
begin
    declare @sql	varchar( 2100 );

    set @sql = 'select Number, BlockedOn, datediff(second,LastReqTime, getdate()), 1, LockTable' +
	' from sa_conn_info()' +
	' where BlockedOn > 0 and datediff(second,LastReqTime,getdate()) > ' + cast( @block_time as varchar(20) ) +
	' and Number in (' + @spids +
	' ) order by 1';

    EXECUTE IMMEDIATE WITH RESULT SET ON @sql ;
end
go

--
-- Add new stored procedures for user authentication using LDAP servers
--
create procedure ml_add_ldap_server (
    in @ldsrv_name	varchar(128),
    in @search_url    	varchar(1024),
    in @access_dn    	varchar(1024),
    in @access_dn_pwd   varchar(256),
    in @auth_url	varchar(1024),
    in @conn_retries	tinyint,
    in @conn_timeout	tinyint,
    in @start_tls	tinyint )
begin
    declare @sh_url	varchar(1024);
    declare @as_dn	varchar(1024);
    declare @as_pwd	varchar(256);
    declare @au_url	varchar(1024);
    declare @timeout	tinyint;
    declare @retries	tinyint;
    declare @tls	tinyint;
    
    if @ldsrv_name is not null then
	if @search_url is null and
	    @access_dn is null and
	    @access_dn_pwd is null and
	    @auth_url is null and
	    @conn_timeout is null and
	    @conn_retries is null and
	    @start_tls is null then
	    
	    -- delete the server if not used
	    if not exists (select s.ldsrv_id from ml_ldap_server s,
				ml_user_auth_policy p
		where ( s.ldsrv_id = p.primary_ldsrv_id or
			s.ldsrv_id = p.secondary_ldsrv_id ) and
			s.ldsrv_name = @ldsrv_name ) then
		delete from ml_ldap_server where ldsrv_name = @ldsrv_name; 
	    end if;
	else
	    if not exists ( select * from ml_ldap_server where
				ldsrv_name = @ldsrv_name ) then
		-- add a new ldap server
		if @conn_timeout is null then
		    set @timeout = 10;
		else
		    set @timeout = @conn_timeout;
		end if;
		if @conn_retries is null then
		    set @retries = 3;
		else
		    set @retries = @conn_retries;
		end if;
		if @start_tls is null then
		    set @tls = 0;
		else
		    set @tls = @start_tls;
		end if;
		
		insert into ml_ldap_server ( ldsrv_name, search_url,
			access_dn, access_dn_pwd, auth_url,
			timeout, num_retries, start_tls )
		values( @ldsrv_name, @search_url,
			@access_dn, @access_dn_pwd,
			@auth_url, @timeout, @retries, @tls );
	    else
		-- update the ldap server info
		select search_url, access_dn, access_dn_pwd, auth_url,
			    timeout, num_retries, start_tls into
			@sh_url, @as_dn, @as_pwd, @au_url, @timeout,
			    @retries, @tls from
		    ml_ldap_server where ldsrv_name = @ldsrv_name;
		    
		if @search_url is not null then
		    set @sh_url = @search_url;
		end if;
		if @access_dn is not null then
		    set @as_dn = @access_dn;
		end if;
		if @access_dn_pwd is not null then
		    set @as_pwd = @access_dn_pwd;
		end if;
		if @auth_url is not null then
		    set @au_url = @auth_url;
		end if;
		if @conn_timeout is not null then
		    set @timeout = @conn_timeout;
		end if;
		if @conn_retries is not null then
		    set @retries = @conn_retries;
		end if;
		if @start_tls is not null then
		    set @tls = @start_tls;
		end if;
		    
		update ml_ldap_server set
			search_url = @sh_url,
			access_dn = @as_dn,
			access_dn_pwd = @as_pwd,
			auth_url = @au_url,
			timeout = @timeout,
			num_retries = @retries,
			start_tls = @tls
		where ldsrv_name = @ldsrv_name;
	    end if;
	end if;
    end if;
end
go

create procedure ml_add_certificates_file (
    in @name		varchar(1024) )
begin
    if @name is not null then
	delete from ml_trusted_certificates_file;
	insert into ml_trusted_certificates_file ( name ) values( @name );
    end if;
end
go

create procedure ml_add_user_auth_policy(
    in @policy_name			varchar(128),
    in @primary_ldsrv_name		varchar(128),
    in @secondary_ldsrv_name		varchar(128),
    in @ldap_auto_failback_period	integer,
    in @ldap_failover_to_std		integer )
begin
    declare @pldsrv_id	integer;
    declare @sldsrv_id	integer;
    declare @pid	integer;
    declare @sid	integer;
    declare @period	integer;
    declare @failover	integer;
    declare @error	integer;
    declare @msg	varchar(1024);
    
    if @policy_name is not null then
	if @primary_ldsrv_name is null and 
	    @secondary_ldsrv_name is null and 
	    @ldap_auto_failback_period is null and 
	    @ldap_failover_to_std is null then
	    
	    -- delete the policy name if not used
	    if not exists ( select p.policy_id from ml_user u,
				ml_user_auth_policy p where
				    u.policy_id = p.policy_id and
				    policy_name = @policy_name ) then
		delete from ml_user_auth_policy
		    where policy_name = @policy_name;
	    end if;
	elseif @primary_ldsrv_name is null then
	   -- error
	   set @msg = 'The primary LDAP server cannot be NULL.';
	   raiserror 20000 @msg;
	else
	    set @error = 0;
	    if @primary_ldsrv_name is not null then
		select ldsrv_id into @pldsrv_id from ml_ldap_server where
		    ldsrv_name = @primary_ldsrv_name;
		if @pldsrv_id is null then
		    set @error = 1;
		    set @msg = 'Primary LDAP server "' + @primary_ldsrv_name + '" is not defined.';
		    raiserror 20000 @msg;
		end if;
	    else
		set @pldsrv_id = null;
	    end if;
	    if @secondary_ldsrv_name is not null then
		select ldsrv_id into @sldsrv_id from ml_ldap_server where
		    ldsrv_name = @secondary_ldsrv_name;
		if @sldsrv_id is null then
		    set @error = 1;
		    set @msg = 'Secondary LDAP server "' + @secondary_ldsrv_name + '" is not defined.';
		    raiserror 20000 @msg;
		end if;
	    else
		set @sldsrv_id = null;
	    end if;
	    if @error = 0 then
		if not exists ( select * from ml_user_auth_policy
				where policy_name = @policy_name ) then
		    if @ldap_auto_failback_period is null then
			set @period = 900;
		    else
			set @period = @ldap_auto_failback_period;
		    end if;
		    if @ldap_failover_to_std is null then
			set @failover = 1;
		    else
			set @failover = @ldap_failover_to_std;
		    end if;
		    
		    -- add a new user auth policy
		    insert into ml_user_auth_policy
			( policy_name, primary_ldsrv_id, secondary_ldsrv_id,
			  ldap_auto_failback_period, ldap_failover_to_std )
			values( @policy_name, @pldsrv_id, @sldsrv_id,
				@period, @failover );
		else
		    select primary_ldsrv_id, secondary_ldsrv_id,
			    ldap_auto_failback_period,
			    ldap_failover_to_std into
			@pid, @sid, @period, @failover from
			ml_user_auth_policy where policy_name = @policy_name;
    
		    if @pldsrv_id is not null then
			set @pid = @pldsrv_id;
		    end if;
		    if @sldsrv_id is not null then
			set @sid = @sldsrv_id;
		    end if;
		    if @ldap_auto_failback_period is not null then
			set @period = @ldap_auto_failback_period;
		    end if;
		    if @ldap_failover_to_std is not null then
			set @failover = @ldap_failover_to_std;
		    end if;

		    -- update the user auth policy
		    update ml_user_auth_policy set
				primary_ldsrv_id = @pid,
				secondary_ldsrv_id = @sid,
				ldap_auto_failback_period = @period,
				ldap_failover_to_std = @failover
			where policy_name = @policy_name;
		end if;
	    end if;
	end if;
    end if;
end
go

--
-- Add the views for table and connection scripts
--

create view ml_connection_scripts
as
    select ml_script_version.name version,
	   ml_connection_script.event,
	   ml_script.script_language,
	   ml_script.script
	from ml_connection_script,
	     ml_script_version,
	     ml_script
	where ml_connection_script.version_id = ml_script_version.version_id and
	      ml_connection_script.script_id = ml_script.script_id
go

create view ml_table_scripts
as
    select ml_script_version.name version,
	   ml_table_script.event,
	   ml_table.name table_name,
	   ml_script.script_language,
	   ml_script.script
	from ml_table_script,
	     ml_script_version,
	     ml_script,
	     ml_table
	where ml_table_script.version_id = ml_script_version.version_id and
	      ml_table_script.script_id = ml_script.script_id and
	      ml_table_script.table_id = ml_table.table_id
go

create table ml_property (
    component_name	varchar( 128 )	not null,
    property_set_name	varchar( 128 )	not null,
    property_name	varchar( 128 )	not null,
    property_value	text		not null,
    primary key( component_name, property_set_name, property_name ) )
go

create procedure ml_add_property(
    in @comp_name	varchar( 128 ),
    in @prop_set_name	varchar( 128 ),
    in @prop_name	varchar( 128 ),
    in @prop_value	varchar( 4000 ) )
begin
    if @prop_value is null then
	delete from ml_property
	    where component_name  = @comp_name
	    and property_set_name = @prop_set_name
	    and property_name     = @prop_name;
    else
	if not exists ( select * from ml_property 
				 where component_name    = @comp_name
				  and property_set_name  = @prop_set_name
				  and property_name	 = @prop_name ) then
	    insert into ml_property
		( component_name, property_set_name, property_name, property_value )
		values ( @comp_name, @prop_set_name, @prop_name, @prop_value );
	else
	    update ml_property set property_value = @prop_value
				    where component_name    = @comp_name
				      and property_set_name = @prop_set_name
				      and property_name	    = @prop_name;
	end if;
    end if;
end
go

------------------------------------------------------------------------------
-- Server Initiated Synchronization Schema and Logic
------------------------------------------------------------------------------

create table ml_device (
    device_name		varchar( 255 )	not null primary key,
    listener_version	varchar( 128 )	not null,
    listener_protocol	integer		not null,
    info		varchar( 255 )	not null,
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null )
go

create table ml_device_address (
    device_name		varchar( 255 )	not null reference ml_device,
    medium		varchar( 255 )	not null,
    address		varchar( 255 )	not null,
    active		varchar( 1 )	not null,
    last_modified	timestamp	not null default timestamp,
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null,
    primary key( device_name, medium ) )
go

create table ml_listening (
    name		varchar( 128 )	not null primary key,
    device_name		varchar( 255 )	not null reference ml_device,
    listening		varchar( 1 )	not null,
    ignore_tracking	varchar( 1 )	not null,
    source		varchar( 255 )	not null )
go

create table ml_sis_sync_state (
    remote_id		varchar( 128 )	not null,
    subscription_id	varchar( 128 )	not null,
    publication_name	varchar( 128 )	not null,
    user_name		varchar( 128 )	not null,
    last_upload		timestamp	not null,
    last_download	timestamp	not null,
    primary key( remote_id, subscription_id ) )
go

create procedure ml_set_device(
    in @device			varchar( 255 ),
    in @listener_version	varchar( 128 ),
    in @listener_protocol	integer,
    in @info			varchar( 255 ),
    in @ignore_tracking		varchar( 1 ),
    in @source			varchar( 255 ) )
begin
    if not exists( select * from ml_device where device_name = @device ) then
	insert into ml_device( device_name, listener_version, listener_protocol, info, ignore_tracking, source )
	       values( @device, @listener_version, @listener_protocol, @info, @ignore_tracking, @source )
    elseif @source = 'tracking' then
	update ml_device 
	    set listener_version = @listener_version,
		listener_protocol = @listener_protocol,
		info = @info,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where device_name = @device and ignore_tracking = 'n'
    else
	update ml_device 
	    set listener_version = @listener_version,
		listener_protocol = @listener_protocol,
		info = @info,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where device_name = @device
    end if;
end
go

create procedure ml_set_device_address(
    in @device		varchar( 255 ),
    in @medium		varchar( 255 ),
    in @address		varchar( 255 ),
    in @active		varchar( 1 ),
    in @ignore_tracking	varchar( 1 ),
    in @source		varchar( 255 ) )
begin
    if not exists( select * from ml_device_address
		where device_name = @device and medium = @medium ) then
	insert into ml_device_address( device_name, medium, address, active, ignore_tracking, source )
		values( @device, @medium, @address, @active, @ignore_tracking, @source )
    elseif @source = 'tracking' then
	update ml_device_address 
	    set address = @address,
		active = @active,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where device_name = @device and medium = @medium and ignore_tracking = 'n'
    else
	update ml_device_address 
	    set address = @address,
		active = @active,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where device_name = @device and medium = @medium
    end if;
end
go

create procedure ml_upload_update_device_address(
    in @address		varchar( 255 ),
    in @active		varchar( 1 ),
    in @device		varchar( 255 ),
    in @medium		varchar( 255 ) )
begin
    call ml_set_device_address( @device, @medium, @address, @active, 'n', 'tracking' );
end
go

create procedure ml_set_listening(
    in @name		varchar( 128 ),
    in @device		varchar( 255 ),
    in @listening	varchar( 1 ),
    in @ignore_tracking	varchar( 1 ),
    in @source		varchar( 255 ) )
begin
    if not exists( select * from ml_listening where name = @name ) then
	insert into ml_listening( name, device_name, listening, ignore_tracking, source )
	    values( @name, @device, @listening, @ignore_tracking, @source )
    elseif @source = 'tracking' then
	update ml_listening
	    set device_name = @device,
		listening = @listening,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where name = @name and ignore_tracking = 'n'
    else
	update ml_listening
	    set device_name = @device,
		listening = @listening,
		ignore_tracking = @ignore_tracking,
		source = @source
	    where name = @name
    end if;
end
go

create procedure ml_set_sis_sync_state(
    in @remote_id	    varchar( 128 ),
    in @subscription_id	    varchar( 128 ),
    in @publication_name    varchar( 128 ),
    in @user_name	    varchar( 128 ),
    in @last_upload	    timestamp,
    in @last_download	    timestamp )
begin
    DECLARE sid varchar( 128 );
    DECLARE lut timestamp;
        
    if @subscription_id IS NULL then
	SET sid = 's:' + @publication_name;
    else 
	SET sid = @subscription_id;
    end if;
				    
    if @last_upload IS NULL then 
	SET lut = ( SELECT last_upload FROM ml_sis_sync_state 
			    WHERE remote_id = @remote_id AND subscription_id = sid );
	if lut IS NULL then
	    SET lut = '1900-01-01 00:00:00.000';
	end if ;
    else 
	SET lut = @last_upload;
    end if;
												    
    if not exists( select * from ml_sis_sync_state 
		    where remote_id = @remote_id
		    and subscription_id = sid ) then
	insert into ml_sis_sync_state( remote_id, subscription_id, publication_name, 
					user_name, last_upload, last_download )
	values( @remote_id, sid, @publication_name, 
		@user_name, lut, @last_download );
    else
	update ml_sis_sync_state
	set publication_name = @publication_name,
	    user_name = @user_name,
	    last_upload = lut, 
	    last_download = @last_download
	where remote_id = @remote_id and subscription_id = sid;
    end if;
end
go

create procedure ml_upload_update_listening(
    in @device		varchar( 255 ),
    in @listening	varchar( 1 ),
    in @name		varchar( 128 ) )
begin
    call ml_set_listening( @name, @device, @listening, 'n', 'tracking' );
end
go

create procedure ml_delete_device_address(
    in @device		varchar( 255 ),
    in @medium		varchar( 255 ) )
begin
    delete from ml_device_address where device_name = @device and medium = @medium
end
go

create procedure ml_delete_listening( in @name varchar( 128 ) )
begin
    delete from ml_listening where name = @name
end
go

create procedure ml_delete_device( in @device varchar( 255 ) )
begin
    delete from ml_device_address where device_name = @device;
    delete from ml_listening where device_name = @device;
    delete from ml_device where device_name = @device;
end
go

--
-- Out-of-the-box SIS settings
--
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'smtp_gateway', 'Default-SMTP' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'udp_gateway', 'Default-UDP' );
call ml_add_property( 'SIS', 'DeviceTracker(Default-DeviceTracker)', 'sync_gateway', 'Default-SYNC' );
call ml_add_property( 'SIS', 'SMTP(Default-SMTP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'UDP(Default-UDP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'SYNC(Default-SYNC)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'bes', 'localhost' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'port', '8080' );
call ml_add_property( 'SIS', 'BESHTTP(BES_HTTP)', 'client_port', '4400' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'network_provider_id', 'ROGERS' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'sms_email_user_prefix', '1' );
call ml_add_property( 'SIS', 'Carrier(Rogers)', 'sms_email_domain', 'pcs.rogers.com' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'network_provider_id', 'BELL' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility)', 'sms_email_domain', 'txt.bellmobility.ca' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'enable', 'yes' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'network_provider_id', 'CDMA1x:16420:65535' );
call ml_add_property( 'SIS', 'Carrier(Bell Mobility 1x)', 'sms_email_domain', 'txt.bellmobility.ca' );
go


---------------------------------------------------
--   Schema for ML Remote administration
---------------------------------------------------

create table ml_ra_agent (
    aid                            integer NOT NULL DEFAULT autoincrement
   ,agent_id                       varchar(128) NOT NULL
   ,taskdb_rid                     integer NULL
   ,PRIMARY KEY (aid) 
)
go

alter table ml_ra_agent ADD UNIQUE ( agent_id )
go

create unique index tdb_rid on ml_ra_agent( taskdb_rid ) 
go

create table ml_ra_task (
    task_id                        bigint NOT NULL DEFAULT autoincrement
   ,task_name                      varchar(128) NOT NULL
   ,schema_name			   varchar(128) NULL
   ,max_running_time               integer NULL
   ,max_number_of_attempts         integer NULL
   ,delay_between_attempts         integer NULL
   ,flags                          bigint NOT NULL
   ,cond                           long varchar NULL
   ,remote_event                   long varchar NULL
   ,random_delay_interval	   integer NOT NULL DEFAULT 0
   ,PRIMARY KEY (task_id) 
)
go

ALTER TABLE ml_ra_task ADD UNIQUE ( task_name )
go

create table ml_ra_deployed_task (
    task_instance_id               bigint NOT NULL DEFAULT autoincrement
   ,aid                            integer NOT NULL
   ,task_id                        bigint NOT NULL
   ,assignment_time                timestamp NOT NULL DEFAULT current timestamp
   ,state                          varchar(4) NOT NULL DEFAULT 'P'
   ,previous_exec_count            bigint NOT NULL DEFAULT 0
   ,previous_error_count           bigint NOT NULL DEFAULT 0
   ,previous_attempt_count         bigint NOT NULL DEFAULT 0
   ,reported_exec_count            bigint NOT NULL DEFAULT 0
   ,reported_error_count           bigint NOT NULL DEFAULT 0
   ,reported_attempt_count         bigint NOT NULL DEFAULT 0
   ,last_modified                  timestamp NOT NULL
   ,PRIMARY KEY (task_instance_id) 
)
go

ALTER TABLE ml_ra_deployed_task ADD UNIQUE ( aid, task_id )
go

create index dt_tid_idx on ml_ra_deployed_task( task_id )
go

create table ml_ra_task_command (
    task_id                        bigint NOT NULL
   ,command_number                 integer NOT NULL
   ,flags                          bigint NOT NULL DEFAULT 0
   ,action_type                    varchar(4) NOT NULL
   ,action_parm                    long varchar NOT NULL
   ,PRIMARY KEY (task_id,command_number) 
)
go

create table ml_ra_event (
    event_id                       bigint NOT NULL DEFAULT autoincrement
   ,event_class                    varchar(4) NOT NULL
   ,event_type                     varchar(8) NOT NULL
   ,aid				   integer NULL
   ,task_id			   bigint NULL
   ,command_number                 integer NULL
   ,run_number                     bigint NULL
   ,duration                       integer NULL
   ,event_time                     timestamp NOT NULL
   ,event_received                 timestamp NOT NULL DEFAULT current timestamp
   ,result_code                    bigint NULL
   ,result_text                    long varchar NULL
   ,PRIMARY KEY (event_id) 
)
go

create index ev_tid_idx on ml_ra_event( task_id )
go

create index ev_time_idx on ml_ra_event( event_received )
go

create index ev_agent_idx on ml_ra_event( aid )
go

create table ml_ra_event_staging (
    taskdb_rid			   integer NOT NULL
   ,remote_event_id                bigint NOT NULL
   ,event_class                    varchar(4) NOT NULL
   ,event_type                     varchar(8) NOT NULL
   ,task_instance_id               bigint NULL
   ,command_number                 integer NULL
   ,run_number                     bigint NULL
   ,duration                       integer NULL
   ,event_time                     timestamp NOT NULL
   ,result_code                    bigint NULL
   ,result_text                    long varchar NULL
   ,PRIMARY KEY (taskdb_rid, remote_event_id) 
)
go

create index evs_type_idx on ml_ra_event_staging( event_type )
go

create table ml_ra_notify (
   agent_poll_key                 varchar(128) NOT NULL
   ,task_instance_id               bigint NOT NULL
   ,last_modified                  timestamp NOT NULL
   ,PRIMARY KEY (agent_poll_key, task_instance_id) 
)
go

create table ml_ra_task_property (
    task_id                        bigint NOT NULL
   ,property_name                  varchar(128) NOT NULL
   ,last_modified                  timestamp NOT NULL
   ,property_value                 long varchar NULL
   ,PRIMARY KEY (property_name,task_id) 
)
go

create table ml_ra_task_command_property (
    task_id                        bigint NOT NULL
   ,command_number                 integer NOT NULL
   ,property_name                  varchar(128) NOT NULL
   ,property_value                 varchar(2048) NULL
   ,last_modified                  timestamp NOT NULL
   ,PRIMARY KEY (task_id,command_number,property_name) 
)
go

create table ml_ra_managed_remote (
    mrid			   integer default autoincrement
   ,remote_id			   varchar(128) NULL
   ,aid                            integer NOT NULL
   ,schema_name			   varchar(128) NOT NULL
   ,conn_str		           varchar(2048) NOT NULL
   ,last_modified                  timestamp NOT NULL
   ,PRIMARY KEY (mrid) 
)
go

alter table ml_ra_managed_remote ADD UNIQUE ( aid, schema_name )
go

create table ml_ra_schema_name (
    schema_name                    varchar(128) NOT NULL
   ,remote_type                    varchar(1) NOT NULL
   ,last_modified                  timestamp NOT NULL
   ,description			   varchar(2048) NULL
   ,PRIMARY KEY (schema_name) 
)
go

create table ml_ra_agent_property (
    aid                            integer NOT NULL
   ,property_name                  varchar(128) NOT NULL
   ,property_value                 varchar(2048) NULL
   ,last_modified                  timestamp NOT NULL
   ,PRIMARY KEY (aid, property_name ) 
)
go

create table ml_ra_agent_staging (
    taskdb_rid			   integer NOT NULL
   ,property_name                  varchar(128) NOT NULL
   ,property_value                 varchar(2048) NULL
   ,PRIMARY KEY (taskdb_rid, property_name) 
)
go

ALTER TABLE ml_ra_managed_remote
    ADD FOREIGN KEY schema_name (schema_name)
    REFERENCES ml_ra_schema_name (schema_name)
go

ALTER TABLE ml_ra_task
    ADD FOREIGN KEY schema_name (schema_name)
    REFERENCES ml_ra_schema_name(schema_name)
go

ALTER TABLE ml_ra_deployed_task
    ADD FOREIGN KEY task (task_id)
    REFERENCES ml_ra_task (task_id)
go

ALTER TABLE ml_ra_deployed_task
    ADD FOREIGN KEY aid (aid)
    REFERENCES ml_ra_agent (aid)
go

ALTER TABLE ml_ra_task_command
    ADD FOREIGN KEY task (task_id)
    REFERENCES ml_ra_task (task_id)
go

ALTER TABLE ml_ra_notify
    ADD FOREIGN KEY agent_id (agent_poll_key)
    REFERENCES ml_ra_agent (agent_id)
go

ALTER TABLE ml_ra_task_property
    ADD FOREIGN KEY task (task_id)
    REFERENCES ml_ra_task (task_id)
go

ALTER TABLE ml_ra_task_command_property
    ADD FOREIGN KEY command (task_id,command_number)
    REFERENCES ml_ra_task_command (task_id,command_number)
go

ALTER TABLE ml_ra_managed_remote
    ADD FOREIGN KEY aid (aid)
    REFERENCES ml_ra_agent (aid)
go

ALTER TABLE ml_ra_agent_property
    ADD FOREIGN KEY aid (aid)
    REFERENCES ml_ra_agent (aid)
go

ALTER TABLE ml_ra_agent
    ADD FOREIGN KEY taskdb_rid (taskdb_rid)
    REFERENCES ml_database (rid)
go

-----------------------------------------------------------------
-- Stored procedures for Tasks
-----------------------------------------------------------------

-- Assign a remote task to a specific agent.
create procedure ml_ra_assign_task(
    in @agent_id  varchar(128),  
    in @task_name   varchar(128) ) 
begin
    declare @task_id bigint;
    declare @task_instance_id bigint;
    declare @old_state varchar(4);
    declare @aid integer;
    declare @rid integer;
    declare bad_task_name exception for sqlstate '99001';
    declare bad_agent_id exception for sqlstate '99002';

    select task_id into @task_id from ml_ra_task where task_name = @task_name;
    if @task_id is null then
	signal bad_task_name;
    end if;

    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    if @aid is null then 
	signal bad_agent_id;
    end if;

    select state, task_instance_id into @old_state, @task_instance_id
    from ml_ra_deployed_task
    where task_id = @task_id and aid = @aid;

    if @task_instance_id is null then
	insert into ml_ra_deployed_task( aid, task_id, last_modified ) 
	    values ( @aid, @task_id, now() );
    elseif @old_state != 'A' and @old_state != 'P' then
	-- Re-activate the task
	update ml_ra_deployed_task 
	    set state = 'P',
	    previous_exec_count = reported_exec_count + previous_exec_count,
	    previous_error_count = reported_error_count + previous_error_count,
	    previous_attempt_count = reported_attempt_count + previous_attempt_count,
	    reported_exec_count = 0,
	    reported_error_count = 0,
	    reported_attempt_count = 0,
	    last_modified = now()
	where task_instance_id = @task_instance_id;
    end if;
    -- if the task is already active then do nothing 
end
go

create procedure ml_ra_cancel_task_instance(
    in @agent_id varchar(128), 
    in @task_name varchar(128) )
begin
    declare @task_id bigint;
    declare @aid integer;
    declare bad_task_instance exception for sqlstate '99001';

    select task_id into @task_id from ml_ra_task where task_name = @task_name;
    select ml_ra_agent.aid into @aid from ml_ra_agent where agent_id = @agent_id;
    update ml_ra_deployed_task set state = 'CP', last_modified = now()
	where aid = @aid and task_id = @task_id 
	    and ( state = 'A' or state = 'P' );
    if SQLCODE = 100 then
	signal bad_task_instance;
    end if;

    call ml_ra_cancel_notification( @agent_id, @task_name );
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_delete_task(
    in @task_name varchar(128) )
begin
    declare @task_id bigint;
    declare bad_task_name exception for sqlstate '99001';

    select task_id into @task_id from ml_ra_task where task_name = @task_name;
    if @task_id is null then
	signal bad_task_name;
    end if;

    -- Only delete inactive instances, operation
    -- will fail if active instances exist.
    delete from ml_ra_deployed_task where task_id = @task_id 
	and ( state != 'A' and state != 'P' and state != 'CP' );
    delete from ml_ra_task_command_property where task_id = @task_id;	
    delete from ml_ra_task_command where task_id = @task_id;	
    delete from ml_ra_task_property where task_id = @task_id;	
    delete from ml_ra_task where task_id = @task_id;	
end
go

-- result contains a row for each deployed instance of every task
create procedure ml_ra_get_task_status( in @agent_id varchar(128), in @task_name varchar(128) )
result(
    agent_id		    varchar(128),
    remote_id		    varchar(128),
    task_name		    varchar(128),
    task_id		    bigint,
    state		    varchar(4),
    reported_exec_count	    bigint,
    reported_error_count    bigint,
    reported_attempt_count  bigint,
    last_status_update	    timestamp,
    last_success	    timestamp,
    assignment_time	    timestamp
)
begin
    select
	agent_id,
	mr.remote_id,
	t.task_name,
	t.task_id,
	dt.state,
	dt.reported_exec_count + dt.previous_exec_count,
	dt.reported_error_count + dt.previous_error_count,
	dt.reported_attempt_count + dt.previous_attempt_count,
	dt.last_modified,
	( select max( event_time ) from ml_ra_event 
	    where ml_ra_event.task_id = t.task_id ),
	dt.assignment_time
    from
	ml_ra_task t 
	join ml_ra_deployed_task dt on t.task_id = dt.task_id
	join ml_ra_agent a on a.aid = dt.aid
	left outer join ml_ra_managed_remote mr on mr.schema_name = t.schema_name
	    and mr.aid = a.aid
    where
	( @agent_id is null or a.agent_id = @agent_id )
	and ( @task_name is null or t.task_name = @task_name )
    order by agent_id, t.task_name;
end
go

create procedure ml_ra_notify_agent_sync( in @agent_id varchar(128) )
begin
    declare @aid integer;
    
    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    if @aid is null then
	return;
    end if;
    insert into ml_ra_notify( agent_poll_key, task_instance_id, last_modified )
	on existing update values( @agent_id, -1, now() ); 
end
go

create procedure ml_ra_notify_task(
    in @agent_id varchar(128), 
    in @task_name varchar(128) )
begin
    declare @task_instance_id bigint;

    select task_instance_id into @task_instance_id 
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = @agent_id 
	    and task_name = @task_name;

    insert into ml_ra_notify( agent_poll_key, task_instance_id, last_modified )
	on existing update values( @agent_id, @task_instance_id, now() ); 
end
go

create procedure ml_ra_int_cancel_notification(
    in @agent_id varchar(128),
    in @task_instance_id bigint,
    in @request_time timestamp )
begin
    delete from ml_ra_notify where 
	agent_poll_key = @agent_id
	and task_instance_id = @task_instance_id
	and last_modified <= @request_time;
end
go

create procedure ml_ra_cancel_notification(
    in @agent_id varchar(128),
    in @task_name varchar(128) )
begin
    declare @task_instance_id bigint;

    select task_instance_id into @task_instance_id 
	from ml_ra_agent
	    join ml_ra_deployed_task on ml_ra_deployed_task.aid = ml_ra_agent.aid
	    join ml_ra_task on ml_ra_deployed_task.task_id = ml_ra_task.task_id
	where agent_id = @agent_id 
	    and task_name = @task_name;

    call ml_ra_int_cancel_notification( @agent_id, @task_instance_id, now() );
end
go

create procedure ml_ra_get_latest_event_id( out @event_id bigint )
begin
    select max( event_id ) into @event_id from ml_ra_event;
end
go

create procedure ml_ra_get_agent_events( 
    in @start_at_event_id bigint, 
    in @max_events_to_fetch bigint )
result(
    event_id		bigint,
    event_class	        varchar(1),
    event_type		varchar(8),
    agent_id		varchar(128),
    remote_id		varchar(128),
    task_name		varchar(128),
    command_number	integer,
    run_number		bigint,
    duration		integer,
    event_time		timestamp,
    event_received	timestamp,
    result_code		bigint,
    result_text		long varchar
)
begin
    select top @max_events_to_fetch 
	event_id, 
	event_class, 
	event_type,
	ml_ra_agent.agent_id, 
	mr.remote_id,
	t.task_name,
	command_number,
	run_number,
	duration,
	event_time, 
	event_received,
	result_code, 
	result_text
    from ml_ra_event e
	left outer join ml_ra_agent on ml_ra_agent.aid = e.aid
	left outer join ml_ra_task t on t.task_id = e.task_id
	left outer join ml_ra_managed_remote mr on 
	    mr.schema_name = t.schema_name and mr.aid = ml_ra_agent.aid
    where
	event_id >= @start_at_event_id
    order by event_id;
end
go

create procedure ml_ra_get_task_results( 
    in @agent_id varchar(128), 
    in @task_name varchar(128),
    in @run_number integer )
result(
    event_id		bigint,
    event_class	        varchar(1),
    event_type		varchar(8),
    agent_id		varchar(128),
    remote_id		varchar(128),
    task_name		varchar(128),
    command_number	integer,
    run_number		bigint,
    duration		integer,
    event_time		timestamp,
    event_received	timestamp,
    result_code		bigint,
    result_text		long varchar
)
begin
    declare @aid integer;
    declare @task_id bigint;
    declare @remote_id varchar(128);

    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    select task_id, remote_id into @task_id, @remote_id from ml_ra_task t
	left outer join ml_ra_managed_remote mr 
	    on mr.schema_name = t.schema_name and mr.aid = @aid
	where task_name = @task_name;

    if @run_number is null then
	-- get the latest run
	select max( run_number ) into @run_number from ml_ra_event
	where ml_ra_event.aid = @aid and ml_ra_event.task_id = @task_id;
    end if;

    select 
	event_id, 
	event_class, 
	event_type,
	@agent_id, 
	@remote_id,
	@task_name,
	command_number,
	run_number,
	duration,
	event_time, 
	event_received,
	result_code, 
	result_text
    from ml_ra_event e where
	e.aid = @aid and e.task_id = @task_id and e.run_number = @run_number
    order by event_id;
end
go


-- Maintenance functions ----------------------------------

create procedure ml_ra_get_agent_ids()
result(
    agent_id		varchar(128),
    last_download_time	timestamp,
    last_upload_time	timestamp,
    active_task_count	integer,
    taskdb_remote_id	varchar(128),
    description		varchar(2048)
)
begin
    select agent_id, 
	( select max( last_download_time ) from ml_subscription mlsb where mlsb.rid = taskdb_rid ), 
	( select max( last_upload_time ) from ml_subscription mlsb where mlsb.rid = taskdb_rid ), 
	( select count(*) from ml_ra_deployed_task where ml_ra_deployed_task.aid = ml_ra_agent.aid
	    and (state = 'A' or state = 'P' or state = 'CP') ), 
	remote_id,
	property_value
    from ml_ra_agent 
    left outer join ml_database on ml_database.rid = taskdb_rid
    left outer join ml_ra_agent_property
	on ml_ra_agent.aid = ml_ra_agent_property.aid
	    and property_name = 'ml_ra_description'
    order by agent_id;
end
go

create procedure ml_ra_get_remote_ids()
result(
    remote_id		varchar(128),
    schema_name	varchar(128),
    agent_id		varchar(128),
    agent_conn_str	varchar(2048),
    last_download_time	timestamp,
    last_upload_time	timestamp,
    description		varchar(128)
)
begin
    select ml_database.remote_id,
	schema_name,
	agent.agent_id,
	conn_str,
	( select max( last_download_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ), 
	( select max( last_upload_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ), 
	description
    from ml_database 
	left outer join ml_ra_managed_remote on ml_database.remote_id = ml_ra_managed_remote.remote_id
	left outer join ml_ra_agent agent on agent.aid = ml_ra_managed_remote.aid
	left outer join ml_ra_agent_staging s on s.taskdb_rid = ml_database.rid and property_name = 'agent_id'
    where property_value is null
    order by ml_database.remote_id;
end
go

create procedure ml_ra_set_agent_property(
    in @agent_id       varchar(128),
    in @property_name  varchar(128),
    in @property_value varchar(2048) )
begin
    declare @aid integer;
    declare @server_interval integer;
    declare @old_agent_interval integer;
    declare @new_agent_interval integer;
    declare @autoset varchar(3);

    select aid into @aid from ml_ra_agent where agent_id = @agent_id;

    if @property_name = 'lwp_freq' then
	select property_value into @autoset from ml_property where 
	    component_name = 'SIRT'
	    and property_set_name = 'RTNotifier(RTNotifier1)'
	    and property_name = 'autoset_poll_every';
	if @autoset = 'yes' then
	    select property_value into @server_interval from ml_property where 
		component_name = 'SIRT'
		and property_set_name = 'RTNotifier(RTNotifier1)'
		and property_name = 'poll_every';
	    set @new_agent_interval = @property_value;
	    if @new_agent_interval < @server_interval then
		call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', @property_value );
	    elseif @new_agent_interval > @server_interval then
		select property_value into @old_agent_interval from ml_ra_agent_property where
		    aid = @aid
		    and property_name = 'lwp_freq';
		if @new_agent_interval > @old_agent_interval and @old_agent_interval <= @server_interval then
		    -- This agents interval is increasing, check if server interval should increase too
		    if not exists( select * from ml_ra_agent_property where property_name = 'lwp_freq'
			    and cast(property_value as integer) <= @old_agent_interval
			    and aid != @aid ) then
			-- Need to compute the new server interval
			select min( cast( property_value as integer ) ) into @server_interval from ml_ra_agent_property 
			    where property_name = 'lwp_freq' and aid != @aid;
			if @server_interval is null then 
			    set @server_interval = @new_agent_interval;
			end if;
			call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', @server_interval );
		    end if;
		end if;
	    end if;
	end if;
    end if;

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	on existing update values( @aid, @property_name, @property_value, now() );
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_clone_agent_properties(
    in @dst_agent_id  varchar(128),
    in @src_agent_id  varchar(128) )
begin
    declare @dst_aid integer;
    declare @src_aid integer;
    declare bad_src exception for sqlstate '99001';

    select aid into @dst_aid from ml_ra_agent where agent_id = @dst_agent_id;

    select aid into @src_aid from ml_ra_agent where agent_id = @src_agent_id;
    if @src_aid is null then
	signal bad_src;
    end if;

    delete from ml_ra_agent_property where aid = @dst_aid and property_name != 'agent_id' and
	property_name not like 'ml+_ra+_%' escape '+';

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	select @dst_aid, src.property_name, src.property_value, now() 
	from ml_ra_agent_property src 
	where src.aid = @src_aid 
	    and property_name != 'agent_id' 
	    and property_name not like 'ml+_ra+_%' escape '+';
end
go

create procedure ml_ra_get_agent_properties(
    in @agent_id        varchar(128) )
result(
    property_name	varchar(128),
    property_value	varchar(2048),
    last_modified	timestamp 
)
begin
    declare @aid integer;
    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    select property_name, property_value, last_modified from ml_ra_agent_property 
	where aid = @aid
	    and property_name != 'agent_id'
	    and property_name not like 'ml+_ra+_%' escape '+'
	order by property_name;
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_add_agent_id( 
    in @agent_id varchar(128) )
begin
    declare @aid integer;

    insert into ml_ra_agent( agent_id ) values ( @agent_id );

    select @@identity into @aid;
    insert into ml_ra_event(event_class, event_type, aid, event_time ) 
	values( 'I', 'ANEW', @aid, now() );
    call ml_ra_set_agent_property( @agent_id, 'agent_id', @agent_id );
    call ml_ra_set_agent_property( @agent_id, 'max_taskdb_sync_interval', 86400 );
    call ml_ra_set_agent_property( @agent_id, 'lwp_freq', 900 );
    call ml_ra_set_agent_property( @agent_id, 'agent_id_status', 'OK' );
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_manage_remote_db(
    in @agent_id varchar(128),
    in @schema_name varchar(128),
    in @conn_str varchar( 2048 ) )
begin
    declare @aid integer;
    declare @ldt timestamp;

    select aid, last_download_time into @aid, @ldt from 
	ml_ra_agent left outer join ml_subscription on taskdb_rid = rid
    where agent_id = @agent_id;

    insert into ml_ra_managed_remote(aid, remote_id, schema_name, conn_str, last_modified )
        values( @aid, null, @schema_name, @conn_str, now() );

    update ml_ra_deployed_task dt set state = 'A' 
	where aid = @aid and state = 'P' and last_modified < @ldt
	    and exists( select * from ml_ra_task t where t.task_id = dt.task_id and t.schema_name = @schema_name );
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_unmanage_remote_db(
    in @agent_id varchar(128),
    in @schema_name varchar(128) )
begin
    declare @aid integer;
    declare @has_tasks integer;
    declare has_active_tasks exception for sqlstate '99001';

    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    select if exists( select * from ml_ra_deployed_task dt join ml_ra_task t
	on dt.task_id = t.task_id
	where dt.aid = @aid and t.schema_name = @schema_name
	    and (state = 'A' or state = 'P' or state = 'CP') ) 
	then 1 else 0 endif
    into @has_tasks;

    if @has_tasks = 1 then
	signal has_active_tasks;
    end if;

    delete from ml_ra_deployed_task where aid = @aid and 
	state != 'A' and state != 'P' and state != 'CP'
	and exists( select * from ml_ra_task where ml_ra_task.task_id = ml_ra_deployed_task.task_id
	    and ml_ra_task.schema_name = @schema_name );
    delete from ml_ra_managed_remote where aid = @aid and schema_name = @schema_name;
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_delete_agent_id( in @agent_id varchar(128) )
begin
    declare @aid integer;
    declare @taskdb_rid integer;
    declare @taskdb_remote_id varchar(128);
    declare taskdb_crsr cursor for select taskdb_rid, remote_id from ml_ra_agent_staging 
	join ml_database on ml_database.rid = taskdb_rid
	where property_name = 'agent_id' and property_value = @agent_id;
    declare bad_agent_id exception for sqlstate '99001';

    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
    if @aid is null then
	signal bad_agent_id;
    end if;

    call ml_ra_set_agent_property( @agent_id, 'lwp_freq', '2147483647' );

    -- Delete all dependent rows
    delete from ml_ra_agent_property where aid = @aid;
    delete from ml_ra_deployed_task where aid = @aid;
    delete from ml_ra_notify where agent_poll_key = @agent_id;
    delete from ml_ra_managed_remote where aid = @aid;

    -- Delete the agent
    delete from ml_ra_agent where aid = @aid;

    -- Clean up any task databases that were associated with this agent_id
    open taskdb_crsr;
    taskdbs: loop
	fetch taskdb_crsr into @taskdb_rid, @taskdb_remote_id;
	if SQLCODE != 0 then leave taskdbs end if;
	delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid;
	delete from ml_ra_event_staging where taskdb_rid = @taskdb_rid;
	call ml_delete_remote_id( @taskdb_remote_id );
	if @@ERROR != 0 then return end if;
    end loop;
    close taskdb_crsr;
end
go

create procedure ml_ra_int_move_events( 
    @aid integer, 
    @taskdb_rid integer )
begin
    -- Copy events into ml_ra_event from staging table
    insert into ml_ra_event( 
	event_class, event_type, aid, task_id, command_number, run_number, 
	duration, event_time, event_received, result_code, result_text )
    select event_class, event_type, @aid, dt.task_id, command_number,
	run_number, duration, event_time, now(), result_code, result_text
    from ml_ra_event_staging es
	left outer join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
    where es.taskdb_rid = @taskdb_rid
    order by remote_event_id;

    -- Clean up staged values
    delete from ml_ra_event_staging where taskdb_rid = @taskdb_rid;
end
go

create procedure ml_ra_delete_events_before(
    in @delete_rows_older_than timestamp )
begin
    delete from ml_ra_event where event_received <= @delete_rows_older_than;
end
go

create procedure ml_ra_get_orphan_taskdbs()
result (
    remote_id	    varchar(128),
    orig_agent_id   varchar(128),
    last_sync	    timestamp )
begin
    select remote_id,
	property_value,
	( select max( last_upload_time ) from ml_subscription mlsb where mlsb.rid = ml_database.rid ) 
    from ml_database
	left outer join ml_ra_agent agent on agent.taskdb_rid = rid
	left outer join ml_ra_agent_staging s on s.taskdb_rid = rid and property_name = 'agent_id'
    where property_value is not null and agent_id is null
    order by remote_id;
end
go

-- If error is raised then caller must rollback
create procedure ml_ra_reassign_taskdb( 
    in @taskdb_remote_id varchar(128),
    in @new_agent_id varchar(128) )
begin
    declare @other_taskdb_rid integer;
    declare @taskdb_rid integer;
    declare @other_agent_aid integer;
    declare @old_agent_id varchar(128);
    declare @new_aid integer;
    declare bad_remote exception for sqlstate '99001';
    declare bad_agent exception for sqlstate '99002';

    select rid into @taskdb_rid from ml_database where remote_id = @taskdb_remote_id;
    if @taskdb_rid is null then
	signal bad_remote;
    end if;

    select property_value into @old_agent_id from ml_ra_agent_staging 
    where taskdb_rid = @taskdb_rid and property_name = 'agent_id';
    if @old_agent_id is null then
	signal bad_remote;
    end if;

    select taskdb_rid into @other_taskdb_rid from ml_ra_agent where agent_id = @new_agent_id;
    if SQLCODE = 100 then
	call ml_ra_add_agent_id( @new_agent_id );	
    end if;
    -- if @other_taskdb_rid is not null then it becomes a new orphan taskdb

    -- If the taskdb isn't already orphaned then break the link with its original agent_id
    update ml_ra_agent set taskdb_rid = null where taskdb_rid = @taskdb_rid;

    update ml_ra_agent_staging set property_value = @new_agent_id
	where taskdb_rid = @taskdb_rid
	    and property_name = 'agent_id';

    -- Preserve any events that have been uploaded
    -- Note, no task state is updated here, these
    -- events are stale and may no longer apply.
    select aid into @new_aid from ml_ra_agent where agent_id = @new_agent_id;
    call ml_ra_int_move_events( @new_aid, @taskdb_rid );
    if @@error != 0 then return end if;

    -- The next time the agent syncs it will receive its new agent_id
    call ml_ra_notify_agent_sync( @old_agent_id );
end
go

-----------------------------------------------------------------
-- Synchronization scripts for the remote agent's task database
-- Note, there is no authenticate user script here, this will need
-- to be provided by the user.
-----------------------------------------------------------------

create procedure ml_ra_ss_end_upload( 
    in @taskdb_remote_id varchar(128) )
begin
    declare @taskdb_rid integer;
    declare @consdb_taskdb_rid integer;
    declare @consdb_taskdb_remote_id varchar(128);
    declare @agent_id varchar(128);
    declare @provided_id varchar(128);
    declare @old_machine_name varchar(128);
    declare @new_machine_name varchar(128);
    declare @aid integer;
    declare @used varchar(128);

    select rid, agent_id, aid into @taskdb_rid, @agent_id, @aid
	from ml_database left outer join ml_ra_agent on taskdb_rid = rid 
	where remote_id = @taskdb_remote_id;

    if @agent_id is null then 
	-- This taskdb isn't linked to an agent_id in the consolidated yet
	delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid and property_name = 'agent_id_status';
	select property_value into @provided_id from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid and property_name = 'agent_id';
	if @provided_id is null then
	    -- Agent failed to provide an agent_id
	    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
		values( @taskdb_rid, 'agent_id_status', 'RESET' );
	    return;
	end if;
	    
	select taskdb_rid, aid into @consdb_taskdb_rid, @aid from ml_ra_agent where agent_id = @provided_id;
	if @consdb_taskdb_rid is not null then
	    -- We have 2 remote task databases using the same agent_id.
	    -- Attempt to determine if its a reset of an agent or 2 separate 
	    -- agents conflicting with each other.
	    select remote_id into @consdb_taskdb_remote_id 
		from ml_database where rid = @consdb_taskdb_rid;
	    select substr( @consdb_taskdb_remote_id, 7, length(@consdb_taskdb_remote_id) - 43 )
		into @old_machine_name; 
	    select substr( @taskdb_remote_id, 7, length(@taskdb_remote_id) - 43 )
		into @new_machine_name; 
	    if @old_machine_name != @new_machine_name then
		-- There are 2 agents with conflicting agent_ids
		-- This taskdb will not be allowed to download tasks.
		insert into ml_ra_event(event_class, event_type, aid, event_time, result_text ) 
		    values( 'E', 'ADUP', @aid, now(), @taskdb_remote_id );
		insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
		    values( @taskdb_rid, 'agent_id_status', 'DUP' );
		return;
	    end if; -- Otherwise, we allow replacement of the taskdb
	end if;	    

	set @agent_id = @provided_id;
	if @aid is null then
	    -- We have a new agent_id
	    call ml_ra_add_agent_id( @agent_id );
	    select aid into @aid from ml_ra_agent where agent_id = @agent_id;
	end if;

	select property_value into @used from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid and property_name = 'ml_ra_used';
	if @used is not null then
	    -- We can only establish a mapping between new taskdb_remote_ids and agent_ids
	    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
		values( @taskdb_rid, 'agent_id_status', 'RESET' );
	    -- Preserve any events that may have been uploaded
	    -- Note, no task state is updated here, these
	    -- events could be stale and may no longer apply.
	    call ml_ra_int_move_events( @aid, @taskdb_rid );
	    return;
	else	    
	    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
		values( @taskdb_rid, 'ml_ra_used', '1' );
	end if;

	-- Store the link between this agent_id and remote_id
	update ml_ra_agent set taskdb_rid = @taskdb_rid where agent_id = @agent_id;

	select property_value into @used from ml_ra_agent_property
	    where aid = @aid and property_name = 'ml_ra_used';
	if @used is null then
	    -- This is the first taskdb for an agent
	    insert into ml_ra_event(event_class, event_type, aid, event_time ) 
		values( 'I', 'AFIRST', @aid, now() );
	    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
		values( @aid, 'ml_ra_used', '1', now() );
	else
	    -- A new taskdb is taking over
	    insert into ml_ra_event(event_class, event_type, aid, event_time, result_text ) 
		values( 'I', 'ARESET', @aid, now(), @consdb_taskdb_remote_id );

	    update ml_ra_deployed_task set
		state = ( case state 
		    when 'A' then 'P'
		    when 'CP' then 'C'
		    else state end case ),
		previous_exec_count = reported_exec_count + previous_exec_count,
		previous_error_count = reported_error_count + previous_error_count,
		previous_attempt_count = reported_attempt_count + previous_attempt_count,
		reported_exec_count = 0,
		reported_error_count = 0,
		reported_attempt_count = 0,
		last_modified = now()
	    where aid = @aid;
	end if;
    end if;

    -- Update the status of deployed tasks
    update ml_ra_deployed_task dt 
	set reported_exec_count = if event_type = 'TIE' then result_code else reported_exec_count endif,
	    reported_error_count = if event_type = 'TIF' then result_code else reported_error_count endif,
	    reported_attempt_count = if event_type = 'TIA' then result_code else reported_attempt_count endif,
	    state = if event_type like('TF%') then substr( event_type, 3 ) else state endif
    from ml_ra_event_staging es
    where taskdb_rid = @taskdb_rid
	and ( event_type like 'TI%' or event_type like 'TF%' )
	and dt.task_instance_id = es.task_instance_id;

    -- TI status rows are not true events
    delete from ml_ra_event_staging
    	where taskdb_rid = @taskdb_rid and event_type like 'TI%';

    -- Process SIRT ack
    delete from ml_ra_notify
	from ml_ra_event_staging
	where taskdb_rid = @taskdb_rid and event_type like 'TS%'
	    and ml_ra_notify.task_instance_id = ml_ra_event_staging.task_instance_id 
	    and last_modified <= event_time;

    -- Cleanup any obsolete SIRT requests
    delete from ml_ra_notify where agent_poll_key = @agent_id and task_instance_id != -1 
    	and not exists(	select * from ml_ra_deployed_task where
    	    ml_ra_deployed_task.task_instance_id = ml_ra_notify.task_instance_id );

    -- Store any updated remote_ids
    update ml_ra_managed_remote mr set mr.remote_id = result_text 
	from ml_ra_event_staging es
	    join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
	    join ml_ra_task on ml_ra_task.task_id = dt.task_id
	where es.taskdb_rid = @taskdb_rid
	    and es.event_type = 'TRID'
	    and mr.aid = @aid
	    and mr.schema_name = ml_ra_task.schema_name;

    if( exists( select * from ml_ra_event_staging es
	    where es.taskdb_rid = @taskdb_rid
		and es.event_type = 'CR'
		and es.result_text like 'CHSN:%' ) ) then
	-- Update remote schema name
	update ml_ra_managed_remote mr set mr.schema_name = rdbc.schema_name
	    from ml_ra_event_staging es
		join ml_ra_deployed_task dt on dt.task_instance_id = es.task_instance_id
		join ml_ra_task t on t.task_id = dt.task_id
		join ml_ra_schema_name rdbc on rdbc.schema_name = substr( es.result_text, 6 )
	    where es.taskdb_rid = @taskdb_rid
		and es.event_type = 'CR'
		and es.result_text like 'CHSN:%'
		and mr.aid = @aid
		and mr.schema_name = t.schema_name;

	-- Old tasks go back to pending after schema name change
	update ml_ra_deployed_task dt set state = 'P' 
	    where dt.aid = @aid and state = 'A'
		and exists( select * from ml_ra_task t left outer join ml_ra_managed_remote mr
			on t.schema_name = mr.schema_name and mr.aid = @aid
			where t.task_id = dt.task_id
			    and t.schema_name is not null 
			    and mr.schema_name is null );
    endif;
  
    -- Get properties from the agent
    update ml_ra_agent_property set property_value = st.property_value, last_modified = now()
	from ml_ra_agent_staging st 
	where st.taskdb_rid = @taskdb_rid
	    and ml_ra_agent_property.aid = @aid
	    and ml_ra_agent_property.property_name = st.property_name
	    and st.property_name not like 'ml+_ra+_%' escape '+'
	    and ( (ml_ra_agent_property.property_value is null and st.property_value is not null )
		or (ml_ra_agent_property.property_value is not null and st.property_value is null )
		or (st.property_value != ml_ra_agent_property.property_value) );

    insert into ml_ra_agent_property( aid, property_name, property_value, last_modified )
	    on existing skip
	select @aid, st.property_name, st.property_value, now() 
	    from ml_ra_agent_staging st 
	    where st.taskdb_rid = @taskdb_rid 
		and st.property_name not like 'ml+_ra+_%' escape '+';

    delete from ml_ra_agent_staging where taskdb_rid = @taskdb_rid 
	and property_name not like 'ml+_ra+_%' escape '+'
	and property_name != 'agent_id';
    call ml_ra_int_move_events( @aid, @taskdb_rid );
end
go

call ml_add_connection_script ( 'ml_ra_agent_12', 'end_upload',
   'call ml_ra_ss_end_upload( {ml s.remote_id} )' )
go

create procedure ml_ra_ss_download_prop(
    in @taskdb_remote_id varchar(128), 
    in @last_table_download timestamp )
begin
    declare @aid integer;
    declare @taskdb_rid integer;

    select a.aid, d.rid into @aid, @taskdb_rid from ml_database d 
	left outer join ml_ra_agent a on a.taskdb_rid = d.rid
	where d.remote_id = @taskdb_remote_id;

    if @aid is null then
	select property_name, property_value from ml_ra_agent_staging 
	    where taskdb_rid = @taskdb_rid 
		and property_name not like 'ml+_ra+_%' escape '+'
    else
	select property_name, property_value from ml_ra_agent_property p 
	    where p.aid = @aid and property_name not like 'ml+_ra+_%' escape '+' 
		and last_modified >= @last_table_download;
    end if
end
go

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_cursor', 
   'call ml_ra_ss_download_prop( {ml s.remote_id}, {ml s.last_table_download} )' )
go
call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'download_delete_cursor', '--{ml_ignore}' )
go

create procedure ml_ra_ss_upload_prop(
    in @taskdb_remote_id varchar(128), 
    in @property_name varchar(128), 
    in @property_value varchar(2048) )
begin
    declare @taskdb_rid integer;

    select rid into @taskdb_rid from ml_database where remote_id = @taskdb_remote_id;

    insert into ml_ra_agent_staging( taskdb_rid, property_name, property_value )
	on existing update values( @taskdb_rid, @property_name, @property_value ); 
end
go

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_insert', 
    'call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} )' )
go

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_adminprop', 'upload_update', 
    'call ml_ra_ss_upload_prop( {ml s.remote_id}, {ml r.name}, {ml r.value} )' )
go

call ml_add_connection_script ( 'ml_ra_agent_12', 'nonblocking_download_ack',
   'call ml_ra_ss_download_ack( {ml s.remote_id}, {ml s.last_download} )' )
go

create procedure ml_ra_ss_download_task( 
    in @taskdb_remote_id varchar(128) )
result ( task_instance_id bigint,
	task_name varchar(128),
	schema_name varchar(128), 
	max_number_of_attempts integer,
	delay_between_attempts integer,
	max_running_time integer,
	flags bigint,
	state varchar(4),
	cond long varchar, 
	remote_event long varchar )
begin
    select task_instance_id, task_name, ml_ra_task.schema_name, max_number_of_attempts, 
	delay_between_attempts, max_running_time, ml_ra_task.flags,
	case dt.state 
	    when 'P' then 'A'
	    when 'CP' then 'C'
	end case,
	cond, remote_event
    from ml_database task_db
    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
    join ml_ra_task on dt.task_id = ml_ra_task.task_id
    where task_db.remote_id = @taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' );
end
go

call ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_cursor', 
   'call ml_ra_ss_download_task( {ml s.remote_id} )' )
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_task', 'download_delete_cursor', '--{ml_ignore}' )
go

create procedure ml_ra_ss_download_task_cmd( 
    in @taskdb_remote_id varchar(128) )
result ( 
    task_instance_id bigint, 
    command_number integer,
    flags bigint,
    action_type varchar(4),
    action_parm long varchar )
begin
    select task_instance_id, command_number, ml_ra_task_command.flags, action_type, action_parm
    from ml_database task_db
    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
    join ml_ra_task on dt.task_id = ml_ra_task.task_id
    join ml_ra_task_command on dt.task_id = ml_ra_task_command.task_id
    where task_db.remote_id = @taskdb_remote_id
	and dt.state = 'P';
end
go

CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_cursor', 
  'call ml_ra_ss_download_task_cmd( {ml s.remote_id} )' )
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_command', 'download_delete_cursor', '--{ml_ignore}' )
go


create procedure ml_ra_ss_download_remote_dbs(
    in @taskdb_remote_id varchar(128),
    in @last_download timestamp )
result(
    schema_name varchar(128),
    remote_id varchar(128),
    conn_str varchar(2048),
    remote_type varchar(1) )
begin
  select mr.schema_name, mr.remote_id, conn_str, remote_type 
  from ml_database taskdb
  join ml_ra_agent on ml_ra_agent.taskdb_rid = taskdb.rid
  join ml_ra_managed_remote mr on mr.aid = ml_ra_agent.aid
  join ml_ra_schema_name on ml_ra_schema_name.schema_name = mr.schema_name
  where taskdb.remote_id = @taskdb_remote_id
    and mr.last_modified >= @last_download;
end
go

CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_cursor', 
    'call ml_ra_ss_download_remote_dbs( {ml s.remote_id}, {ml s.last_table_download} )' );
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'download_delete_cursor', '--{ml_ignore}' )
go

create procedure ml_ra_ss_upload_event(
    @taskdb_remote_id varchar(128), 
    @remote_event_id bigint, 
    @event_class varchar(1), 
    @event_type varchar(4), 
    @task_instance_id bigint, 
    @command_number integer, 
    @run_number bigint, 
    @duration integer,
    @event_time timestamp,
    @result_code bigint, 
    @result_text long varchar )
begin
    declare @taskdb_rid integer;

    select rid into @taskdb_rid from ml_database
    where remote_id = @taskdb_remote_id;

    insert into ml_ra_event_staging( taskdb_rid, remote_event_id, 
    	event_class, event_type, task_instance_id, command_number, 
    	run_number, duration, event_time, result_code, result_text )
     on existing skip
     values ( @taskdb_rid, @remote_event_id, @event_class, @event_type,
    	@task_instance_id, @command_number, @run_number, 
	@duration, @event_time, @result_code, @result_text );
end
go


CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_insert', 
    'call ml_ra_ss_upload_event( '
    +   '{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, '
    +	'{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, '
    +	'{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )' )
go

CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'upload_update', 
    'call ml_ra_ss_upload_event( '
    +   '{ml s.remote_id}, {ml r.id}, {ml r.class}, {ml r.status}, '
    +	'{ml r.task_instance_id}, {ml r.command_number}, {ml r.exec_count}, '
    +	'{ml r.duration}, {ml r.status_time}, {ml r.status_code}, {ml r.text} )' )
go

create procedure ml_ra_ss_download_ack( 
    in @taskdb_remote_id varchar(128), 
    in @ldt timestamp )
begin
    declare @aid integer;
    declare @agent_id varchar(128);

    select aid, agent_id into @aid, @agent_id from ml_ra_agent
	join ml_database on taskdb_rid = rid
	where remote_id = @taskdb_remote_id;

    update ml_ra_deployed_task dt set state = 'A' 
	where dt.aid = @aid and state = 'P' and last_modified < @ldt
	    and exists( select * from ml_ra_task t left outer join ml_ra_managed_remote mr
		    on t.schema_name = mr.schema_name and mr.aid = @aid
		    where t.task_id = dt.task_id
			and ( t.schema_name is null or mr.schema_name is not null ) );
  
    delete from ml_ra_notify where 
	agent_poll_key = @agent_id
	and task_instance_id = -1 
	and last_modified <= @ldt;
end
go

-- Default file transfer scripts for upload and download

create procedure ml_ra_ss_agent_auth_file_xfer(
    in	    requested_direction varchar(1),
    inout   auth_code	INTEGER,
    in	    ml_user	varchar( 128 ),
    in	    remote_key	varchar( 128 ),
    in	    fsize	BIGINT,
    inout   filename	varchar( 128 ),
    inout   sub_dir	varchar( 128 ) ) 
begin
    declare @offset integer;
    declare @cmd_num integer;
    declare @tiid bigint;
    declare @tid bigint;
    declare @aid integer;
    declare @task_state varchar(4);
    declare @max_size bigint;
    declare @direction varchar(1);
    declare @server_sub_dir varchar(128);
    declare @server_filename varchar(128);

    -- By convention file transfer commands will send up the remote key with...
    -- task_instance_id command_number
    -- eg 1 5	-- task_instance_id=1 command_number=5
    select locate( remote_key, ' ' ) into @offset;
    if @offset = 0 then
	set auth_code = 2000;
	return;
    end if;

    select cast( substr( remote_key, 0, @offset ) as BIGINT ), 
	cast( substr( remote_key, @offset ) as BIGINT ) into @tiid, @cmd_num;
    if @tiid is null or @tiid < 1 or @cmd_num is null or @cmd_num < 0 then	
	set auth_code = 2000;
	return;
    end if;

    -- fetch properties of the task
    select task_id, aid, state into @tid, @aid, @task_state from ml_ra_deployed_task 
	where task_instance_id = @tiid;

    -- Disallow transfer if the task is no longer active
    if @task_state is null or (@task_state != 'A' and @task_state != 'P') then 
	set auth_code = 2001;
	return;
    end if;

    -- Make sure the file isn't too big
    select property_value into @max_size from ml_ra_task_command_property where 
	task_id = @tid and command_number = @cmd_num and property_name = 'mlft_max_file_size';
    if @max_size > 0 and fsize > @max_size then
	set auth_code = 2002;
	return;
    end if;

    -- Make sure the direction is correct
    select property_value into @direction from ml_ra_task_command_property where 
	task_id = @tid and command_number = @cmd_num and property_name = 'mlft_transfer_direction';
    if @direction != requested_direction then
	set auth_code = 2003;
	return;
    end if;

    -- set the filename output parameter
    select property_value into @server_filename from ml_ra_task_command_property where 
	task_id = @tid and command_number = @cmd_num and property_name = 'mlft_server_filename';
    if @server_filename is not null then
	select replace( replace( @server_filename, '{ml_username}', ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
	    into filename;
    end if;

    -- set the sub_dir output parameter
    select property_value into @server_sub_dir from ml_ra_task_command_property where 
	task_id = @tid and command_number = @cmd_num and property_name = 'mlft_server_sub_dir';

    if @server_sub_dir is null then
	set sub_dir = '';
    else
	select replace( replace( @server_sub_dir, '{ml_username}', ml_user ), '{agent_id}',
	    ( select agent_id from ml_ra_agent where aid = @aid ) )
	    into sub_dir;
    end if;

    -- Everything is ok, allow the file transfer
    set auth_code = 1000;
end
go

call ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_upload', 
    'call ml_ra_ss_agent_auth_file_xfer( ''U'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, {ml s.file_size}, {ml s.filename}, {ml s.subdir} )' );
go

call ml_add_connection_script( 'ml_ra_agent_12', 'authenticate_file_transfer', 
    'call ml_ra_ss_agent_auth_file_xfer( ''D'', {ml s.file_authentication_code}, {ml s.username}, {ml s.remote_key}, 0, {ml s.filename}, {ml s.subdir} )' );
go

CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_cursor', '--{ml_ignore}' )
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_status', 'download_delete_cursor', '--{ml_ignore}' )
go

CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_insert', '--{ml_ignore}' )
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_update', '--{ml_ignore}' )
go
CALL ml_add_table_script( 'ml_ra_agent_12', 'ml_ra_agent_remote_db', 'upload_delete', '--{ml_ignore}' )
go

call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'request_cursor', 'select agent_poll_key,task_instance_id,last_modified from ml_ra_notify order by agent_poll_key' );
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'poll_every', '2147483647' ); -- RT Notifier doesn't begin polling until an agent is created
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'autoset_poll_every', 'yes' ); -- Set to 'no' to disable auto setting 'poll_every', then manually set 'poll_every'
call ml_add_property( 'SIRT', 'RTNotifier(RTNotifier1)', 'enable', 'yes' );
call ml_add_property( 'SIRT', 'Global', 'update_poll_every', '60' ); -- Check for updates to started notifiers every minute
go

create procedure ml_ra_ss_download_task2( 
    in @taskdb_remote_id varchar(128) )
result ( task_instance_id bigint,
	task_name varchar(128),
	schema_name varchar(128), 
	max_number_of_attempts integer,
	delay_between_attempts integer,
	max_running_time integer,
	flags bigint,
	state varchar(4),
	cond long varchar, 
	remote_event long varchar,
	random_delay_interval integer 
	)
begin
    select task_instance_id, task_name, ml_ra_task.schema_name, max_number_of_attempts, 
	delay_between_attempts, max_running_time, ml_ra_task.flags,
	case dt.state 
	    when 'P' then 'A'
	    when 'CP' then 'C'
	end case,
	cond, remote_event, random_delay_interval
    from ml_database task_db
    join ml_ra_agent on ml_ra_agent.taskdb_rid = task_db.rid
    join ml_ra_deployed_task dt on dt.aid = ml_ra_agent.aid
    join ml_ra_task on dt.task_id = ml_ra_task.task_id
    where task_db.remote_id = @taskdb_remote_id
	and ( dt.state = 'CP' or dt.state = 'P' );
end
go

/* Updated Script for 12.0.1 */
CALL ml_share_all_scripts( 'ml_ra_agent_12_1', 'ml_ra_agent_12' )
go
CALL ml_add_table_script( 'ml_ra_agent_12_1', 'ml_ra_agent_task', 'download_cursor', 
   'call ml_ra_ss_download_task2( {ml s.remote_id} )' )
go

--
-- Add new objects to support deploying synchronization models from Sybase Central
--

create table ml_model_schema (
    schema_type		varchar( 32 )	not null,
    schema_owner	varchar( 128 )  not null,
    table_name		varchar( 128 )  not null,
    object_name		varchar( 128 )  not null,
    drop_stmt		varchar( 4000 ) not null,
    checksum		varchar( 64 )   not null,
    db_checksum		varchar( 64 )   null,
    locked		bit,
    primary key( schema_type, schema_owner, table_name, object_name ) )
go

create table ml_model_schema_use (
    version_id		integer		not null,
    schema_type		varchar( 32 )   not null,
    schema_owner	varchar( 128 )  not null,
    table_name		varchar( 128 )  not null,
    object_name		varchar( 128 )  not null,
    checksum		varchar( 64 )   not null,
    primary key( version_id, schema_type, schema_owner, table_name, object_name ) )
go

create procedure ml_model_begin_check(
    in @version		varchar( 128 ) )
begin
    declare @version_id		integer;

    select version_id into @version_id from ml_script_version 
	where name = @version;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_model_schema_use where version_id = @version_id;
end
go

create procedure ml_model_begin_install(
    in @version		varchar( 128 ) )
begin
    declare @version_id		integer;

    select version_id into @version_id from ml_script_version 
	where name = @version;

    -- If this same script version was previously installed, 
    -- clean-up any meta-data associated with it.
    delete from ml_column where version_id = @version_id;
    delete from ml_connection_script where version_id = @version_id;
    delete from ml_table_script where version_id = @version_id;
    delete from ml_model_schema_use where version_id = @version_id;
    delete from ml_script_version where version_id = @version_id;
end
go

create function ml_model_get_catalog_checksum(
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ) )
    returns varchar(64)
begin
    return null;
end
go

create procedure ml_model_register_schema (
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ),
    in @drop_stmt	varchar( 4000 ),
    in @checksum	varchar( 64 ),
    in @locked		bit )
begin
    declare @db_checksum varchar(64);

    if @drop_stmt is null then
	select drop_stmt into @drop_stmt from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name;
    end if;

    if @checksum is null then
	select checksum into @checksum from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name;
    end if;

    if @locked is null then
	select locked into @locked from ml_model_schema 
	    where schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name;
    end if;

    set @db_checksum = ml_model_get_catalog_checksum( @schema_type, @schema_owner, @table_name, @object_name );

    insert into ml_model_schema
	( schema_type, schema_owner, table_name, object_name, drop_stmt, checksum, db_checksum, locked )
	on existing update
	values( @schema_type, @schema_owner, @table_name, @object_name, @drop_stmt, @checksum, @db_checksum, @locked );
end
go

create procedure ml_model_deregister_schema (
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ) )
begin
    if @schema_type = 'TABLE' then
	delete from ml_model_schema 
	    where schema_type = @schema_type 
		and schema_owner = @schema_owner 
		and table_name = @table_name;
    else 
	delete from ml_model_schema 
	    where schema_type = @schema_type 
		and schema_owner = @schema_owner 
		and table_name = @table_name
		and object_name = @object_name;
    end if;	    
end
go

create procedure ml_model_register_schema_use (
    in @version		varchar( 128 ),
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ),
    in @checksum	varchar( 64 ) )
begin
    declare @version_id		integer;

    select version_id into @version_id from ml_script_version 
	where name = @version;
    if @version_id is null then
	insert into ml_script_version ( name ) values ( @version );
	set @version_id = @@identity;
    end if;

    insert into ml_model_schema_use
	( version_id, schema_type, schema_owner, table_name, object_name, checksum )
	on existing update
	values( @version_id, @schema_type, @schema_owner, @table_name, @object_name, @checksum );
end
go

create procedure ml_model_mark_schema_verified (
    in @version		varchar( 128 ),
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ) )
begin
    declare @checksum	varchar( 64 );
    declare @version_id	integer;

    select version_id into @version_id from ml_script_version 
	where name = @version;

    select checksum into @checksum from ml_model_schema
	where schema_type = @schema_type and schema_owner = @schema_owner
	    and table_name = @table_name and object_name = @object_name;

    if @checksum is not null then
	update ml_model_schema_use set checksum = 'IGNORE' 
	    where version_id = @version_id and schema_type = @schema_type and schema_owner = @schema_owner
		and table_name = @table_name and object_name = @object_name and checksum != @checksum;
    else
	select checksum into @checksum from ml_model_schema_use 
	    where version_id = @version_id and schema_type = @schema_type
		and schema_owner = @schema_owner and table_name = @table_name
		and object_name = @object_name;
	call ml_model_register_schema( @schema_type, @schema_owner, @table_name, @object_name, 
	    '-- Not dropped during uninstall', @checksum, if @schema_type = 'COLUMN' then 1 else 0 end if );
    end if;
end
go

create function ml_model_check_catalog(
    @schema_type	varchar( 32 ),
    @schema_owner	varchar( 128 ),
    @table_name		varchar( 128 ),
    @object_name	varchar( 128 ) )
    returns varchar( 32 )
begin
    declare @checksum	      varchar(64);
    declare @orig_db_checksum varchar(64);
    declare @db_checksum      varchar(64);
    
    -- Return values
    -- 'UNUSED' - The requested schema isn't referenced by any ML meta-data
    -- 'MISSING' - The requested schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match the ML meta-data
    -- 'UNVERIFIED' - A full schema comparison wasn't done, 
    --                generally we assume the schema is correct in this case
    -- 'INSTALLED' - The required schema is correctly installed.
     if ( @schema_type = 'TABLE'
           and exists( select 1 from sys.systable join sys.sysuser on user_id = creator
               where table_name = @table_name and user_name = @schema_owner ) )
       or ( @schema_type = 'TRIGGER'
           and exists( select 1 from SYS.SYSTRIGGERS
               where owner = @schema_owner and trigname = @object_name and tname = @table_name ) )
       or ( @schema_type = 'INDEX'
           and exists( select 1 from SYS.SYSINDEXES
               where creator = @schema_owner and iname = @object_name and tname = @table_name ) )
       or ( @schema_type = 'COLUMN'
           and exists( select 1 from SYS.SYSCOLUMNS
            where creator = @schema_owner and cname = @object_name and tname = @table_name ) )
       or ( @schema_type = 'PROCEDURE'
           and exists( select 1 from SYS.SYSPROCS
            where creator = @schema_owner and procname = @object_name ) )
     then
	-- The schema exists
	set @db_checksum = ml_model_get_catalog_checksum( @schema_type, @schema_owner, @table_name, @object_name );
	select s.checksum, s.db_checksum into @checksum, @orig_db_checksum from ml_model_schema s
		where s.schema_type = @schema_type and s.schema_owner = @schema_owner 
		    and s.table_name = @table_name and s.object_name = @object_name;

	if @checksum is null then return 'UNUSED' end if;
	if @orig_db_checksum is null or @db_checksum is null then return 'UNVERIFIED' end if;
	if @orig_db_checksum = @db_checksum then return 'INSTALLED' end if;
	return 'MISMATCH';
    end if;
	   
    -- The schema does not exist
    return 'MISSING';
end
go

create procedure ml_model_check_all_schema()
begin
    select 
	if s.schema_owner is null then u.schema_owner else s.schema_owner end if schema_owner, 
	if s.table_name is null then u.table_name else s.table_name end if table_name, 
	if s.schema_type is null then u.schema_type else s.schema_type end if schema_type, 
	if s.object_name is null then u.object_name else s.object_name end if object_name, 
	s.locked, 
	ver.name used_by,
	ml_model_check_schema( ver.name, schema_type, schema_owner, table_name, object_name ) status,
	if used_by is null then null else ml_model_get_schema_action( ver.name, schema_type, schema_owner, table_name, object_name, 'OVERWRITE' ) end if overwrite_action,
	if used_by is null then null else ml_model_get_schema_action( ver.name, schema_type, schema_owner, table_name, object_name, 'PRESERVE_EXISTING_SCHEMA' ) end if preserve_action
    from ml_model_schema s 
	full outer join ml_model_schema_use u on
	    u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
	    and u.table_name = s.table_name and u.object_name = s.object_name
	left outer join ml_script_version ver on
	    u.version_id = ver.version_id
    order by schema_owner, table_name, schema_type, object_name, used_by;
end
go

create procedure ml_model_check_version_schema(
    in @version		varchar( 128 ) )
begin
    select u.schema_owner, u.table_name, u.schema_type, u.object_name, s.locked,
	ml_model_check_schema( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name ) status,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'OVERWRITE' ) overwrite_action,
	ml_model_get_schema_action( ver.name, u.schema_type, u.schema_owner, u.table_name, u.object_name, 'PRESERVE_EXISTING_SCHEMA' ) preserve_action
    from ml_model_schema_use u join ml_script_version ver on u.version_id = ver.version_id
	left outer join ml_model_schema s on
	    u.schema_type = s.schema_type and u.schema_owner = s.schema_owner
	    and u.table_name = s.table_name and u.object_name = s.object_name
    where ver.name = @version
    order by u.schema_owner, u.table_name, u.schema_type, u.object_name
end
go

create function ml_model_check_schema (
    in @version		varchar( 128 ),
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ) )
    returns varchar(32)
begin
    declare @status		varchar(32);
    declare @db_status		varchar(32);

    -- Return values
    -- 'UNUSED' - The requested schema isn't needed for this version.
    -- 'MISSING' - The required schema is not installed.
    -- 'MISMATCH' - The current schema doesn't match what is needed and must be replaced.
    -- 'UNVERIFIED' - The existing schema must be manually checked to see if it matches what is needed.
    -- 'INSTALLED' - The required schema is correctly installed.

    select if s.checksum is null then 'MISSING'	else
	    if u.checksum = 'IGNORE' or u.checksum = s.checksum then 'INSTALLED' else 'MISMATCH' end if
	end if into @status
    from ml_model_schema_use u
	join ml_script_version v on v.version_id = u.version_id 
	left outer join ml_model_schema s 
	    on s.schema_type = u.schema_type and s.schema_owner = u.schema_owner 
		and s.table_name = u.table_name and s.object_name = u.object_name
    where v.name = @version and u.schema_type = @schema_type and u.schema_owner = @schema_owner 
	and u.table_name = @table_name and u.object_name = @object_name;
    
    if @status is null then set @status = 'UNUSED' end if;

    set @db_status = ml_model_check_catalog( @schema_type, @schema_owner, @table_name, @object_name );
    if @db_status = 'MISSING' then return 'MISSING' end if;
    if @status = 'UNUSED' or @status = 'MISMATCH' then return @status end if;
    if @status = 'MISSING' then return 'UNVERIFIED' end if;

    -- @status = 'INSTALLED'
    if @db_status = 'MISMATCH' then return 'MISMATCH' end if;

    -- If @db_status = 'UNVERIFIED' we are optimistic and assume it is correct
    return 'INSTALLED';
end
go

create function ml_model_get_schema_action (
    in @version		varchar( 128 ),
    in @schema_type	varchar( 32 ),
    in @schema_owner	varchar( 128 ),
    in @table_name	varchar( 128 ),
    in @object_name	varchar( 128 ),
    in @upd_mode	varchar( 32 ) )
    returns varchar(32)
begin
    declare @status		varchar(32);

    set @status = ml_model_check_schema( @version, @schema_type, @schema_owner, @table_name, @object_name );

    if @status = 'MISSING' then 
	return 'CREATE';
    elseif @status = 'UNUSED' or @status = 'INSTALLED' or @upd_mode != 'OVERWRITE' or @schema_type = 'COLUMN' then
	    -- Preserve the existing schema
	    -- Note, 'REPLACE' won't work for columns because the column is likely 
	    --     in an index and the drop will fail.  If the status is 'MISMATCH' 
	    --     then the column will need to be manually altered in the database.
	    return 'SKIP';
    end if;

    if exists ( select locked 
	    from ml_model_schema
	    where schema_type = @schema_type and schema_owner = @schema_owner and table_name = @table_name 
		and object_name = @object_name and locked != 0 ) then
	-- The schema is marked as locked, preserve it.
	return 'SKIP';
    end if;

    set @status = ml_model_check_catalog( @schema_type, @schema_owner, @table_name, @object_name );
    if @status = 'MISMATCH' then
	-- The schema was modified since ML was deployed, we are careful not to destroy any schema
	-- that was not created by ML
	return 'SKIP'
    end if;

    -- The existing schema doesn't match what is needed so replace it.
    return 'REPLACE';
end
go

create procedure ml_model_drop_unused_schema()
begin
    declare @status	    varchar(32);
    declare @schema_type    varchar(32);
    declare @schema_owner   varchar(128);
    declare @object_name    varchar(128);
    declare @table_name     varchar(128);
    declare @drop_stmt	    varchar(4000);

    declare drop_crsr cursor for 
	select s.schema_type, s.schema_owner, s.table_name, s.object_name, s.drop_stmt 
	from ml_model_schema s 
	    left outer join ml_model_schema_use u 
	    on u.schema_type = s.schema_type and u.schema_owner = s.schema_owner 
		and u.table_name = s.table_name and u.object_name = s.object_name
	where u.object_name is null and s.locked = 0 and s.drop_stmt not like '--%'
	    order by ( case s.schema_type
		when 'INDEX' then 1
		when 'TRIGGER' then 2
		when 'PROCEDURE' then 3
		when 'COLUMN' then 4
		when 'TABLE' then 5
		else 6
		end );
    
    open drop_crsr with hold;
    drop_loop: loop
	fetch drop_crsr into @schema_type, @schema_owner, @table_name, @object_name, @drop_stmt;
	if SQLCODE <> 0 then
	    leave drop_loop;
	else
	    set @status = ml_model_check_catalog( @schema_type, @schema_owner, @table_name, @object_name );
	    -- We don't drop any schema modified since ML was deployed.
	    if @status != 'MISMATCH' and @status != 'MISSING' then
		execute immediate @drop_stmt;
	    end if;
	    call ml_model_deregister_schema( @schema_type, @schema_owner, @table_name, @object_name );
	end if;
    end loop;
    close drop_crsr;
end
go

create procedure ml_model_drop(
    in @version	    varchar( 128 ) )
begin
    declare @version_id		integer;

    select version_id into @version_id from ml_script_version 
	where name = @version;

    delete from ml_model_schema_use where version_id = @version_id;
    delete from ml_column where version_id = @version_id;
    delete from ml_connection_script where version_id = @version_id;
    delete from ml_table_script where version_id = @version_id;
    delete from ml_script_version where version_id = @version_id;
    call ml_model_drop_unused_schema();
end
go

commit
go
