
--
-- Upgrade the MobiLink Server system tables and stored procedures in
-- a Sybase SQL Anywhere consolidated database.
--


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
-- Alter the ml_user table to add two new columns
--
alter table ml_user add policy_id integer null
    references ml_user_auth_policy( policy_id )
go 

alter table ml_user add user_dn varchar( 1024 ) null
go 

--
-- Alter the ml_database table to add two new columns
--
alter table ml_database add seq_id binary(16) null
go

alter table ml_database add seq_uploaded integer not null default 0
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
-- Recreate the ml_add_user stored procedure
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
-- Recreate the ml_reset_sync_state stored procedure
--
drop procedure ml_reset_sync_state
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

--
-- Remove QAnywhere objects
--
call ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'gui', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'enable', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'poll_every', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_cursor', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyNotifier_client)', 'request_delete', null  )
go

call ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'gui', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'enable', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'poll_every', null  )
go
call ml_add_property( 'SIS', 'Notifier(QAnyLWNotifier_client)', 'request_cursor', null  )
go


call ml_add_connection_script( 'ml_qa_3', 'handle_error', null  )
go
call ml_add_java_connection_script( 'ml_qa_3', 'begin_publication', null  )
go
call ml_add_java_connection_script( 'ml_qa_3', 'nonblocking_download_ack', null  )
go
call ml_add_java_connection_script( 'ml_qa_3', 'prepare_for_download', null  )
go
call ml_add_java_connection_script( 'ml_qa_3', 'begin_download', null  )
go
call ml_add_java_connection_script( 'ml_qa_3', 'modify_next_last_download_timestamp', null  )
go

call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'upload_insert', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_delete_cursor', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_repository_client', 'download_cursor', null  )
	    
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_insert', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'upload_update', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_delete_cursor', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_delivery_client', 'download_cursor', null  )

go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_insert', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_update', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'upload_delete', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_delete_cursor', null  )
go
call ml_add_table_script( 'ml_qa_3', 'ml_qa_global_props_client', 'download_cursor', null  )	
go

drop procedure ml_qa_stage_status_from_client
go
drop procedure ml_qa_staged_status_for_client
go
drop table ml_qa_repository_staging
go
drop table ml_qa_status_staging
go

drop trigger ml_qa_delivery_trigger
go
drop procedure ml_qa_add_delivery
go
drop procedure ml_qa_add_message
go
drop procedure ml_qa_handle_error
go
drop procedure ml_qa_upsert_global_prop
go
drop function ml_qa_get_message_property
go
drop function ml_qa_get_agent_property
go
drop function ml_qa_get_agent_network_property
go
drop function ml_qa_get_agent_object_property
go

drop view ml_qa_messages
go
drop view ml_qa_messages_archive
go

drop table ml_qa_global_props
go
drop table ml_qa_delivery
go
drop table ml_qa_status_history
go
drop table ml_qa_repository_props
go
drop table ml_qa_repository
go
drop table ml_qa_notifications
go
drop table ml_qa_clients
go

drop table ml_qa_delivery_archive
go
drop table ml_qa_status_history_archive
go
drop table ml_qa_repository_props_archive
go
drop table ml_qa_repository_archive
go

delete from ml_script_version where name = 'ml_qa_3'
go

commit
go
